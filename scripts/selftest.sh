#!/usr/bin/env bash
# Selftest: validate templates and the generator.
# Usage: bash scripts/selftest.sh [rust|go|all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/config/languages.json"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

LANG_FILTER="${1:-all}"
LANG_TEMPLATE_DIR=""
LANG_FORMAT_CHECK_CMD=""
LANG_LINT_CMD=""
LANG_TEST_CMD=""
LANG_TOOLCHAINS=()

manifest_python() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "python3"
  elif command -v python >/dev/null 2>&1; then
    printf '%s\n' "python"
  else
    die "python3 or python is required to read language manifest"
  fi
}

manifest_query() {
  local mode="$1"
  local lang="${2:-}"
  local python_bin

  python_bin="$(manifest_python)"

  "$python_bin" - "$CONFIG_PATH" "$mode" "$lang" <<'PY' | tr -d '\r'
import json
import sys

config_path, mode, lang_id = sys.argv[1:4]

with open(config_path, encoding="utf-8") as handle:
    payload = json.load(handle)

languages = payload.get("languages", [])

if mode == "languages":
    for lang in languages:
        print(lang["id"])
    sys.exit(0)

selected = next((lang for lang in languages if lang.get("id") == lang_id), None)
if selected is None:
    print(f"Language not found in manifest: {lang_id}", file=sys.stderr)
    sys.exit(2)

if mode == "language":
    print(f"template_dir={selected['template_dir']}")
    for toolchain in selected["toolchains"]:
        print(f"toolchain={toolchain}")
    commands = selected["commands"]
    for command_key in ("format_check", "lint", "test"):
        print(f"{command_key}={commands[command_key]}")
else:
    print(f"Unknown manifest query mode: {mode}", file=sys.stderr)
    sys.exit(2)
PY
}

manifest_languages() {
  manifest_query languages
}

load_language_config() {
  local lang="$1"
  local manifest_output
  local line
  local key
  local value

  LANG_TEMPLATE_DIR=""
  LANG_FORMAT_CHECK_CMD=""
  LANG_LINT_CMD=""
  LANG_TEST_CMD=""
  LANG_TOOLCHAINS=()

  manifest_output="$(manifest_query language "$lang")" || return 1

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    key="${line%%=*}"
    value="${line#*=}"

    case "$key" in
      template_dir) LANG_TEMPLATE_DIR="$value" ;;
      toolchain) LANG_TOOLCHAINS+=("$value") ;;
      format_check) LANG_FORMAT_CHECK_CMD="$value" ;;
      lint) LANG_LINT_CMD="$value" ;;
      test) LANG_TEST_CMD="$value" ;;
      *) return 1 ;;
    esac
  done <<< "$manifest_output"

  [[ -n "$LANG_TEMPLATE_DIR" \
    && -n "$LANG_FORMAT_CHECK_CMD" \
    && -n "$LANG_LINT_CMD" \
    && -n "$LANG_TEST_CMD" \
    && "${#LANG_TOOLCHAINS[@]}" -gt 0 ]]
}

supported_languages_display() {
  local language_list="$1"
  local supported=""
  local lang

  while IFS= read -r lang; do
    [[ -n "$lang" ]] || continue
    if [[ -n "$supported" ]]; then
      supported+=", "
    fi
    supported+="$lang"
  done <<< "$language_list"

  printf '%s' "$supported"
}

if [[ "$LANG_FILTER" == "all" ]]; then
  info "micro-lab-template selftest"
  info ""

  language_list="$(manifest_languages)" || die "Unable to read supported languages from $CONFIG_PATH"
  [[ -n "$language_list" ]] || die "No languages configured in $CONFIG_PATH"

  overall_status=0
  while IFS= read -r lang; do
    [[ -n "$lang" ]] || continue
    bash "$SCRIPT_DIR/selftest.sh" "$lang" || overall_status=1
  done <<< "$language_list"
  exit "$overall_status"
fi

PASS_COUNT=0
FAIL_COUNT=0
CLEANUP_DIRS=()

cleanup() {
  for dir in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      rm -rf "$dir"
    fi
  done
}
trap cleanup EXIT

pass() {
  info "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  warn "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

validate_language_manifest() {
  if bash "$SCRIPT_DIR/validate-language-config.sh" >/dev/null 2>&1; then
    pass "manifest: config/languages.json valid"
  else
    fail "manifest: language manifest validation failed"
  fi
}

check_template_artifacts() {
  local lang="$1"
  local tpl
  local artifact_matches

  tpl="$REPO_ROOT/$LANG_TEMPLATE_DIR"

  artifact_matches="$(find "$tpl" -type d \( \
    -name target -o \
    -name bin -o \
    -name node_modules -o \
    -name __pycache__ -o \
    -name dist -o \
    -name build \
  \) -print 2>/dev/null || true)"

  if [[ -z "$artifact_matches" ]]; then
    pass "$lang: template has no build artifacts"
  else
    fail "$lang: build artifacts found in template"
    echo "$artifact_matches" >&2
  fi
}

# -- Template checks --------------------------------------------------------

language_title() {
  local lang="$1"
  local first="${lang%"${lang#?}"}"
  local rest="${lang#?}"

  printf '%s%s' "$(printf '%s' "$first" | tr '[:lower:]' '[:upper:]')" "$rest"
}

check_language_toolchains() {
  local lang="$1"
  local context="$2"
  local toolchain
  local missing=0

  for toolchain in "${LANG_TOOLCHAINS[@]}"; do
    [[ -n "$toolchain" ]] || continue
    if ! command -v "$toolchain" >/dev/null 2>&1; then
      fail "$context: $toolchain not found on PATH"
      missing=1
    fi
  done

  [[ "$missing" -eq 0 ]]
}

run_manifest_command() {
  local dir="$1"
  local command="$2"
  local cargo_target_dir="${3:-}"

  case "$command" in
    *$'\n'*|*$'\r'*) return 2 ;;
  esac

  if [[ -n "$cargo_target_dir" && "$command" == cargo\ * ]]; then
    (cd "$dir" && CARGO_TARGET_DIR="$cargo_target_dir" bash -c "$command")
  else
    (cd "$dir" && bash -c "$command")
  fi
}

run_format_check() {
  local lang="$1"
  local tpl="$2"
  local command="$3"
  local cargo_target_dir="${4:-}"
  local format_output

  case "$command" in
    gofmt\ -l|gofmt\ -l\ *)
      if format_output="$(run_manifest_command "$tpl" "$command" "$cargo_target_dir" 2>/dev/null)"; then
        if [[ -z "$format_output" ]]; then
          pass "$lang: $command"
        else
          fail "$lang: $command (unformatted: $format_output)"
        fi
      else
        fail "$lang: $command"
      fi
      ;;
    *)
      if run_manifest_command "$tpl" "$command" "$cargo_target_dir" >/dev/null 2>&1; then
        pass "$lang: $command"
      else
        fail "$lang: $command"
      fi
      ;;
  esac
}

test_language_template() {
  local lang="$1"
  local tpl
  local cargo_target_dir=""

  info "=== Testing $(language_title "$lang") template ==="

  tpl="$REPO_ROOT/$LANG_TEMPLATE_DIR"

  if ! check_language_toolchains "$lang" "$lang"; then
    return
  fi

  if [[ "$lang" == "rust" ]]; then
    cargo_target_dir="$REPO_ROOT/out/selftest-rust-target"
    CLEANUP_DIRS+=("$cargo_target_dir")
    mkdir -p "$REPO_ROOT/out"
  fi

  run_format_check "$lang" "$tpl" "$LANG_FORMAT_CHECK_CMD" "$cargo_target_dir"

  if run_manifest_command "$tpl" "$LANG_LINT_CMD" "$cargo_target_dir" >/dev/null 2>&1; then
    pass "$lang: $LANG_LINT_CMD"
  else
    fail "$lang: $LANG_LINT_CMD"
  fi

  if run_manifest_command "$tpl" "$LANG_TEST_CMD" "$cargo_target_dir" >/dev/null 2>&1; then
    pass "$lang: $LANG_TEST_CMD"
  else
    fail "$lang: $LANG_TEST_CMD"
  fi
}

# -- Generator integration test --------------------------------------------

test_generator_dry_run() {
  local lang="$1"
  local name="selftest-dry-run-${lang}"

  info "=== Testing generator dry-run: $lang ==="

  if bash "$SCRIPT_DIR/new-repo.sh" --lang "$lang" --name "$name" --no-git --dry-run >/dev/null 2>&1; then
    pass "generator($lang): dry-run completed"
  else
    fail "generator($lang): dry-run failed"
  fi
}

test_generator() {
  local lang="$1"
  local name="selftest-${lang}"
  local out_dir="$REPO_ROOT/out/$name"

  info "=== Testing generator: $lang ==="

  CLEANUP_DIRS+=("$out_dir")

  # Generate
  if ! bash "$SCRIPT_DIR/new-repo.sh" --lang "$lang" --name "$name" --org selftestorg --no-git >/dev/null 2>&1; then
    fail "generator($lang): generation failed"
    return
  fi
  pass "generator($lang): repo created"

  # Check no placeholders remain in source files
  local placeholder_matches
  placeholder_matches="$(grep -r '__[A-Z_][A-Z_]*__' "$out_dir" \
    --include='*.rs' --include='*.go' --include='*.toml' \
    --include='*.mod' --include='*.md' --include='*.yml' \
    --include='*.yaml' --include='*.sh' --include='*.json' \
    2>/dev/null || true)"
  if [[ -z "$placeholder_matches" ]]; then
    pass "generator($lang): no placeholders remain"
  else
    fail "generator($lang): placeholders found"
    echo "$placeholder_matches" >&2
  fi

  # Check generated CI workflow exists with minimal permissions
  local ci_workflow="$out_dir/.github/workflows/ci.yml"
  if [[ -f "$ci_workflow" ]]; then
    pass "generator($lang): CI workflow present"
  else
    fail "generator($lang): CI workflow missing"
  fi

  if grep -q '^permissions:$' "$ci_workflow" && grep -q '^  contents: read$' "$ci_workflow"; then
    pass "generator($lang): CI workflow uses minimal permissions"
  else
    fail "generator($lang): CI workflow permissions not minimal"
  fi

  # Check generated security workflow exists with expected scanners
  local security_workflow="$out_dir/.github/workflows/security.yml"
  if [[ -f "$security_workflow" ]]; then
    pass "generator($lang): security workflow present"
  else
    fail "generator($lang): security workflow missing"
  fi

  if grep -q '^permissions:$' "$security_workflow" \
    && grep -q '^  contents: read$' "$security_workflow" \
    && grep -q 'gitleaks' "$security_workflow" \
    && grep -q 'trivy' "$security_workflow"; then
    pass "generator($lang): security workflow baseline present"
  else
    fail "generator($lang): security workflow baseline missing expected scanners"
  fi

  # Check generated Dependabot config exists with language-specific ecosystems
  local dependabot_config="$out_dir/.github/dependabot.yml"
  if [[ -f "$dependabot_config" ]]; then
    pass "generator($lang): Dependabot config present"
  else
    fail "generator($lang): Dependabot config missing"
  fi

  if grep -q 'package-ecosystem: "github-actions"' "$dependabot_config" \
    && grep -q 'package-ecosystem: "docker"' "$dependabot_config"; then
    pass "generator($lang): Dependabot baseline present"
  else
    fail "generator($lang): Dependabot baseline missing expected ecosystems"
  fi

  # Run language-specific tests in generated repo
  case "$lang" in
    rust)
      if grep -q 'package-ecosystem: "cargo"' "$dependabot_config" \
        && grep -q 'cargo audit' "$security_workflow"; then
        pass "generator(rust): Rust security tooling present"
      else
        fail "generator(rust): Rust security tooling missing"
      fi

      if check_language_toolchains "$lang" "generator($lang)"; then
        if run_manifest_command "$out_dir" "$LANG_TEST_CMD" >/dev/null 2>&1; then
          pass "generator(rust): $LANG_TEST_CMD passes"
        else
          fail "generator(rust): $LANG_TEST_CMD failed"
        fi
      fi
      ;;
    go)
      if grep -q 'package-ecosystem: "gomod"' "$dependabot_config" \
        && grep -q 'govulncheck' "$security_workflow"; then
        pass "generator(go): Go security tooling present"
      else
        fail "generator(go): Go security tooling missing"
      fi

      if check_language_toolchains "$lang" "generator($lang)"; then
        if run_manifest_command "$out_dir" "$LANG_TEST_CMD" >/dev/null 2>&1; then
          pass "generator(go): $LANG_TEST_CMD passes"
        else
          fail "generator(go): $LANG_TEST_CMD failed"
        fi
      fi
      ;;
  esac
}

# -- Main ------------------------------------------------------------------

info "micro-lab-template selftest"
info ""

language_list="$(manifest_languages)" || die "Unable to read supported languages from $CONFIG_PATH"
supported_languages="$(supported_languages_display "$language_list")"

if ! grep -Fxq "$LANG_FILTER" <<< "$language_list"; then
  die "Unknown language: $LANG_FILTER (supported: $supported_languages, all)"
fi

validate_language_manifest
if ! load_language_config "$LANG_FILTER"; then
  fail "$LANG_FILTER: language configuration could not be loaded"
else
  check_template_artifacts "$LANG_FILTER"
  test_language_template "$LANG_FILTER"
  test_generator_dry_run "$LANG_FILTER"
  test_generator "$LANG_FILTER"
fi

info ""
info "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
  die "Selftest FAILED"
fi

info "Selftest PASSED"
