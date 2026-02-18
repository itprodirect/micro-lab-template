#!/usr/bin/env bash
# Generator: scaffold a new repo from micro-lab-template.
# Usage: bash scripts/new-repo.sh --lang rust --name my-repo [--org myorg] [--dry-run] [--no-git]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

# ── Defaults ──────────────────────────────────────────────────────────

LANG=""
NAME=""
ORG="itprodirect"
DRY_RUN=false
NO_GIT=false
TEMPLATE_VERSION=""

# ── Parse args ────────────────────────────────────────────────────────

usage() {
  cat <<USAGE
Usage: bash scripts/new-repo.sh --lang <rust|go> --name <repo-name> [options]

Required:
  --lang <rust|go>     Language template to use
  --name <name>        Repository name (kebab-case)

Options:
  --org <org>          GitHub org/owner (default: itprodirect)
  --dry-run            Show what would be created without writing files
  --no-git             Skip git init
  -h, --help           Show this help
USAGE
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang)   LANG="$2"; shift 2 ;;
    --name)   NAME="$2"; shift 2 ;;
    --org)    ORG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --no-git) NO_GIT=true; shift ;;
    -h|--help) usage 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# ── Validate ──────────────────────────────────────────────────────────

[[ -n "$LANG" ]] || die "--lang is required (rust, go)"
[[ -n "$NAME" ]] || die "--name is required"

case "$LANG" in
  rust|go) ;;
  *) die "Unsupported language: $LANG (supported: rust, go)" ;;
esac

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

case "$LANG" in
  rust)
    TEST_COMMAND="cargo test --workspace"
    RUN_COMMAND="cargo run -p lab_cli"
    BLOCKS_DIR="crates/blocks"
    LABS_DIR="crates/lab_cli"
    ;;
  go)
    TEST_COMMAND="go test ./..."
    RUN_COMMAND="go run ./cmd/lab-cli"
    BLOCKS_DIR="internal/blocks"
    LABS_DIR="cmd/lab-cli"
    ;;
esac

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
  info "Files from templates/$LANG/:"
  (cd "$REPO_ROOT/templates/$LANG" && find . -type f | sort | sed 's|^\./|  |')
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
(cd "$REPO_ROOT/templates/$LANG" && find . -type f \
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
