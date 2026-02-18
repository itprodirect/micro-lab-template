#!/usr/bin/env bash
# Selftest: validate templates and the generator.
# Usage: bash scripts/selftest.sh [rust|go|all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

LANG_FILTER="${1:-all}"

if [[ "$LANG_FILTER" == "all" ]]; then
  info "micro-lab-template selftest"
  info ""
  bash "$SCRIPT_DIR/selftest.sh" go
  bash "$SCRIPT_DIR/selftest.sh" rust
  exit 0
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

# -- Template checks --------------------------------------------------------

test_rust_template() {
  info "=== Testing Rust template ==="

  local tpl="$REPO_ROOT/templates/rust"

  if ! command -v cargo >/dev/null 2>&1; then
    warn "cargo not found, skipping Rust template tests"
    return
  fi

  # Format check
  if (cd "$tpl" && cargo fmt --all -- --check) >/dev/null 2>&1; then
    pass "rust: cargo fmt"
  else
    fail "rust: cargo fmt"
  fi

  # Lint check
  if (cd "$tpl" && cargo clippy -- -D warnings) >/dev/null 2>&1; then
    pass "rust: cargo clippy"
  else
    fail "rust: cargo clippy"
  fi

  # Tests
  if (cd "$tpl" && cargo test --workspace) >/dev/null 2>&1; then
    pass "rust: cargo test"
  else
    fail "rust: cargo test"
  fi
}

test_go_template() {
  info "=== Testing Go template ==="

  local tpl="$REPO_ROOT/templates/go"

  if ! command -v go >/dev/null 2>&1; then
    warn "go not found, skipping Go template tests"
    return
  fi

  # Format check
  local unformatted
  unformatted="$(cd "$tpl" && gofmt -l .)"
  if [[ -z "$unformatted" ]]; then
    pass "go: gofmt"
  else
    fail "go: gofmt (unformatted: $unformatted)"
  fi

  # Lint check
  if (cd "$tpl" && go vet ./...) >/dev/null 2>&1; then
    pass "go: go vet"
  else
    fail "go: go vet"
  fi

  # Tests
  if (cd "$tpl" && go test ./...) >/dev/null 2>&1; then
    pass "go: go test"
  else
    fail "go: go test"
  fi
}

# -- Generator integration test --------------------------------------------

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

  # Run language-specific tests in generated repo
  case "$lang" in
    rust)
      if command -v cargo >/dev/null 2>&1; then
        if (cd "$out_dir" && cargo test --workspace) >/dev/null 2>&1; then
          pass "generator(rust): cargo test passes"
        else
          fail "generator(rust): cargo test failed"
        fi
      fi
      ;;
    go)
      if command -v go >/dev/null 2>&1; then
        if (cd "$out_dir" && go test ./...) >/dev/null 2>&1; then
          pass "generator(go): go test passes"
        else
          fail "generator(go): go test failed"
        fi
      fi
      ;;
  esac
}

# -- Main ------------------------------------------------------------------

info "micro-lab-template selftest"
info ""

case "$LANG_FILTER" in
  rust)
    test_rust_template
    test_generator rust
    ;;
  go)
    test_go_template
    test_generator go
    ;;
  *)
    die "Unknown language: $LANG_FILTER (supported: rust, go, all)"
    ;;
esac

info ""
info "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ $FAIL_COUNT -gt 0 ]]; then
  die "Selftest FAILED"
fi

info "Selftest PASSED"
