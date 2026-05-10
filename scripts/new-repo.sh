#!/usr/bin/env bash
# Generator: scaffold a new repo from micro-lab-template.
# Usage: bash scripts/new-repo.sh --lang rust --name my-repo [--org myorg] [--dry-run] [--no-git]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/config/languages.json"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

# ── Defaults ──────────────────────────────────────────────────────────

LANG=""
NAME=""
ORG="itprodirect"
DRY_RUN=false
NO_GIT=false
TEMPLATE_VERSION=""
TEMPLATE_DIR=""
TEST_COMMAND=""
RUN_COMMAND=""
BLOCKS_DIR=""
LABS_DIR=""

# ── Parse args ────────────────────────────────────────────────────────

usage() {
  cat <<USAGE
Usage: bash scripts/new-repo.sh --lang <language> --name <repo-name> [options]

Required:
  --lang <language>    Language template id from config/languages.json
  --name <name>        Repository name (kebab-case)

Options:
  --org <org>          GitHub org/owner (default: itprodirect)
  --dry-run            Show what would be created without writing files
  --no-git             Skip git init
  -h, --help           Show this help
USAGE
  exit "${1:-0}"
}

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
    commands = selected["commands"]
    paths = selected["paths"]
    print(f"template_dir={selected['template_dir']}")
    print(f"test_command={commands['test']}")
    print(f"run_command={commands['run']}")
    print(f"blocks_dir={paths['blocks']}")
    print(f"labs_dir={paths['labs']}")
else:
    print(f"Unknown manifest query mode: {mode}", file=sys.stderr)
    sys.exit(2)
PY
}

manifest_languages() {
  manifest_query languages
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

load_language_config() {
  local lang="$1"
  local manifest_output
  local line
  local key
  local value

  TEMPLATE_DIR=""
  TEST_COMMAND=""
  RUN_COMMAND=""
  BLOCKS_DIR=""
  LABS_DIR=""

  manifest_output="$(manifest_query language "$lang")" || return 1

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    key="${line%%=*}"
    value="${line#*=}"

    case "$key" in
      template_dir) TEMPLATE_DIR="$value" ;;
      test_command) TEST_COMMAND="$value" ;;
      run_command) RUN_COMMAND="$value" ;;
      blocks_dir) BLOCKS_DIR="$value" ;;
      labs_dir) LABS_DIR="$value" ;;
      *) return 1 ;;
    esac
  done <<< "$manifest_output"

  [[ -n "$TEMPLATE_DIR" \
    && -n "$TEST_COMMAND" \
    && -n "$RUN_COMMAND" \
    && -n "$BLOCKS_DIR" \
    && -n "$LABS_DIR" ]]
}

require_flag_value() {
  local flag="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    die "$flag requires a non-empty value"
  fi
  if [[ "$value" == -* ]]; then
    die "$flag requires a value, got another flag: $value"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)
      [[ $# -ge 2 ]] || die "--lang requires a value"
      require_flag_value "--lang" "$2"
      LANG="$2"
      shift 2
      ;;
    --name)
      [[ $# -ge 2 ]] || die "--name requires a value"
      require_flag_value "--name" "$2"
      NAME="$2"
      shift 2
      ;;
    --org)
      [[ $# -ge 2 ]] || die "--org requires a value"
      require_flag_value "--org" "$2"
      ORG="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-git) NO_GIT=true; shift ;;
    -h|--help) usage 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────

language_list="$(manifest_languages)" || die "Unable to read supported languages from $CONFIG_PATH"
supported_languages="$(supported_languages_display "$language_list")"

[[ -n "$LANG" ]] || die "--lang is required ($supported_languages)"
[[ -n "$NAME" ]] || die "--name is required"

if ! grep -Fxq "$LANG" <<< "$language_list"; then
  die "Unsupported language: $LANG (supported: $supported_languages)"
fi

load_language_config "$LANG" || die "Unable to read language configuration for: $LANG"

# Validate name is kebab-case
if [[ ! "$NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  die "Name must be kebab-case (lowercase, hyphens): $NAME"
fi

# Read template version
if [[ -f "$REPO_ROOT/.template-version" ]]; then
  TEMPLATE_VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/.template-version")"
else
  TEMPLATE_VERSION="0.1.0"
  warn ".template-version not found, using $TEMPLATE_VERSION"
fi

# ── Compute placeholders ─────────────────────────────────────────────

YEAR="$(date +%Y)"
PKG="${NAME//-/_}"  # kebab-case to snake_case for Python
MODULE_PATH="github.com/$ORG/$NAME"

# ── Output directory ──────────────────────────────────────────────────

OUT_DIR="$REPO_ROOT/out/$NAME"

if [[ "$DRY_RUN" == true ]]; then
  info "DRY RUN — no files will be written"
  info ""
  info "Configuration:"
  info "  Language:          $LANG"
  info "  Name:              $NAME"
  info "  Org:               $ORG"
  info "  Output:            $OUT_DIR"
  info "  Template version:  $TEMPLATE_VERSION"
  info ""
  info "Placeholders:"
  info "  __REPO_NAME__         → $NAME"
  info "  __ORG__               → $ORG"
  info "  __YEAR__              → $YEAR"
  info "  __TEMPLATE_VERSION__  → $TEMPLATE_VERSION"
  info "  __PKG__               → $PKG"
  info "  __MODULE_PATH__       → $MODULE_PATH"
  info "  __TEST_COMMAND__      → $TEST_COMMAND"
  info "  __RUN_COMMAND__       → $RUN_COMMAND"
  info "  __BLOCKS_DIR__        → $BLOCKS_DIR"
  info "  __LABS_DIR__          → $LABS_DIR"
  info ""
  info "Files from templates/_shared/:"
  (cd "$REPO_ROOT/templates/_shared" && find . -type f | sort | sed 's|^\./|  |')
  info ""
  info "Files from $TEMPLATE_DIR/:"
  (cd "$REPO_ROOT/$TEMPLATE_DIR" && find . -type f | sort | sed 's|^\./|  |')
  exit 0
fi

# ── Generate ──────────────────────────────────────────────────────────

if [[ -d "$OUT_DIR" ]]; then
  die "Output directory already exists: $OUT_DIR"
fi

info "Generating $LANG repo: $NAME"

# Step 1: Copy shared files
info "Copying shared template files..."
mkdir -p "$OUT_DIR"
cp -r "$REPO_ROOT/templates/_shared/." "$OUT_DIR/"

# Step 2: Overlay language-specific files (overrides shared if same path)
# Exclude build artifacts (target/, bin/, node_modules/, __pycache__/)
info "Overlaying $LANG template files..."
(cd "$REPO_ROOT/$TEMPLATE_DIR" && find . -type f \
  ! -path './target/*' \
  ! -path './bin/*' \
  ! -path './node_modules/*' \
  ! -path './__pycache__/*' \
  | while IFS= read -r f; do
    dir="$(dirname "$f")"
    mkdir -p "$OUT_DIR/$dir"
    cp "$f" "$OUT_DIR/$f"
  done
)

# Step 3: Replace placeholders in all text files
info "Replacing placeholders..."

is_binary_ext() {
  case "${1##*.}" in
    png|jpg|jpeg|gif|ico|wasm|exe|dll|so|dylib|zip|tar|gz|bz2) return 0 ;;
    *) return 1 ;;
  esac
}

replace_placeholders() {
  local file="$1"

  # Skip binary files by extension
  if is_binary_ext "$file"; then
    return
  fi

  # Use a temp file for portable sed (works on Git Bash + Linux)
  local tmp="${file}.tmp"
  sed \
    -e "s|__REPO_NAME__|$NAME|g" \
    -e "s|__ORG__|$ORG|g" \
    -e "s|__YEAR__|$YEAR|g" \
    -e "s|__TEMPLATE_VERSION__|$TEMPLATE_VERSION|g" \
    -e "s|__PKG__|$PKG|g" \
    -e "s|__MODULE_PATH__|$MODULE_PATH|g" \
    -e "s|__TEST_COMMAND__|$TEST_COMMAND|g" \
    -e "s|__RUN_COMMAND__|$RUN_COMMAND|g" \
    -e "s|__BLOCKS_DIR__|$BLOCKS_DIR|g" \
    -e "s|__LABS_DIR__|$LABS_DIR|g" \
    "$file" > "$tmp" && mv "$tmp" "$file"
}

# Find all files and replace placeholders
find "$OUT_DIR" -type f | while IFS= read -r file; do
  replace_placeholders "$file"
done

# Step 4: Language-specific post-processing
if [[ "$LANG" == "go" ]] && command -v go >/dev/null 2>&1; then
  info "Running go mod tidy..."
  (cd "$OUT_DIR" && go mod tidy)
fi

# Step 5: Git init (unless --no-git)
if [[ "$NO_GIT" == false ]]; then
  info "Initializing git repository..."
  (cd "$OUT_DIR" && git init -q && git add -A && git commit -q -m "feat: initial scaffold from micro-lab-template v$TEMPLATE_VERSION")
  info "Created initial commit"
fi

# ── Summary ───────────────────────────────────────────────────────────

info ""
info "Repository generated: $OUT_DIR"
info ""
info "Next steps:"
info "  cd out/$NAME"
info "  $TEST_COMMAND"
info "  $RUN_COMMAND"
