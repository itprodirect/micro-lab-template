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
  local key="${3:-}"
  local python_bin

  python_bin="$(manifest_python)"

  "$python_bin" - "$CONFIG_PATH" "$mode" "$lang" "$key" <<'PY' | tr -d '\r'
import json
import sys

config_path, mode, lang_id, key = sys.argv[1:5]

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

if mode == "field":
    print(selected[key])
elif mode == "toolchains":
    for toolchain in selected["toolchains"]:
        print(toolchain)
elif mode == "command":
    print(selected["commands"][key])
else:
    print(f"Unknown manifest query mode: {mode}", file=sys.stderr)
    sys.exit(2)
PY
}

manifest_languages() {
  manifest_query languages
}

manifest_language_field() {
  manifest_query field "$1" "$2"
}

manifest_language_toolchains() {
  manifest_query toolchains "$1"
}

manifest_language_command() {
  manifest_query command "$1" "$2"
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
  local template_dir
  local tpl
  local artifact_matches

  template_dir="$(manifest_language_field "$lang" template_dir)" || {
    fail "$lang: template path missing from manifest"
    return
  }
  tpl="$REPO_ROOT/$template_dir"

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

command_label() {
  local command="$1"
  local first="${command%% *}"
  local rest="${command#"$first"}"
  local second

  rest="${rest#"${rest%%[![:space:]]*}"}"

  if [[ -z "$rest" || "$rest" == -* ]]; then
    printf '%s' "$first"
    return
  fi

  second="${rest%% *}"
  printf '%s %s' "$first" "$second"
}

language_title() {
  local lang="$1"
  local first="${lang%"${lang#?}"}"
  local rest="${lang#?}"

  printf '%s%s' "$(printf '%s' "$first" | tr '[:lower:]' '[:upper:]')" "$rest"
}

check_language_toolchains() {
  local lang="$1"
  local context="$2"
  local toolchains
  local toolchain
  local missing=0

  toolchains="$(manifest_language_toolchains "$lang")" || {
    fail "$context: toolchains missing from manifest"
    return 1
  }

  while IFS= read -r toolchain; do
    [[ -n "$toolchain" ]] || continue
    if ! command -v "$toolchain" >/dev/null 2>&1; then
      fail "$context: $toolchain not found on PATH"
      missing=1
    fi
  done <<< "$toolchains"

  [[ "$missing" -eq 0 ]]
}

run_manifest_command() {
  local dir="$1"
  local command="$2"
  local cargo_target_dir="${3:-}"

  if [[ -n "$cargo_target_dir" && "$command" == cargo\ * ]]; then
    (cd "$dir" && CARGO_TARGET_DIR="$cargo_target_dir" bash -c "$command")
  else
    (cd "$dir" && bash -c "$command")
  fi
}

test_language_template() {
  local lang="$1"
  local template_dir
  local tpl
  local format_cmd
  local lint_cmd
  local test_cmd
  local cargo_target_dir=""
  local label
  local format_output

  info "=== Testing $(language_title "$lang") template ==="

  template_dir="$(manifest_language_field "$lang" template_dir)" || {
    fail "$lang: template path missing from manifest"
    return
  }
  tpl="$REPO_ROOT/$template_dir"

  format_cmd="$(manifest_language_command "$lang" format_check)" || {
    fail "$lang: format command missing from manifest"
    return
  }
  lint_cmd="$(manifest_language_command "$lang" lint)" || {
    fail "$lang: lint command missing from manifest"
    return
  }
  test_cmd="$(manifest_language_command "$lang" test)" || {
    fail "$lang: test command missing from manifest"
    return
  }

  if ! check_language_toolchains "$lang" "$lang"; then
    return
  fi

  if [[ "$lang" == "rust" ]]; then
    cargo_target_dir="$REPO_ROOT/out/selftest-rust-target"
    CLEANUP_DIRS+=("$cargo_target_dir")
    mkdir -p "$REPO_ROOT/out"
  fi

  label="$(command_label "$format_cmd")"
  if format_output="$(run_manifest_command "$tpl" "$format_cmd" "$cargo_target_dir" 2>&1)"; then
    if [[ -z "$format_output" ]]; then
      pass "$lang: $label"
    else
      fail "$lang: $label (unformatted: $format_output)"
    fi
  else
    fail "$lang: $label"
  fi

  label="$(command_label "$lint_cmd")"
  if run_manifest_command "$tpl" "$lint_cmd" "$cargo_target_dir" >/dev/null 2>&1; then
    pass "$lang: $label"
  else
    fail "$lang: $label"
  fi

  label="$(command_label "$test_cmd")"
  if run_manifest_command "$tpl" "$test_cmd" "$cargo_target_dir" >/dev/null 2>&1; then
    pass "$lang: $label"
  else
    fail "$lang: $label"
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
  local generated_test_cmd
  local generated_test_label

  info "=== Testing generator: $lang ==="

  CLEANUP_DIRS+=("$out_dir")

  generated_test_cmd="$(manifest_language_command "$lang" test)" || {
    fail "generator($lang): test command missing from manifest"
    return
  }
  generated_test_label="$(command_label "$generated_test_cmd")"

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
        if run_manifest_command "$out_dir" "$generated_test_cmd" >/dev/null 2>&1; then
          pass "generator(rust): $generated_test_label passes"
        else
          fail "generator(rust): $generated_test_label failed"
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
        if run_manifest_command "$out_dir" "$generated_test_cmd" >/dev/null 2>&1; then
          pass "generator(go): $generated_test_label passes"
        else
          fail "generator(go): $generated_test_label failed"
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
check_template_artifacts "$LANG_FILTER"
test_language_template "$LANG_FILTER"
test_generator_dry_run "$LANG_FILTER"
test_generator "$LANG_FILTER"

info ""
info "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
  die "Selftest FAILED"
fi

info "Selftest PASSED"
