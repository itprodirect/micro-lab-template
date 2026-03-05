#!/usr/bin/env bash
# Guard against CRLF in text files that must remain LF-only across OSes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

info "Checking for CRLF in tracked shell, markdown, and yaml files"

bad=0
while IFS= read -r file; do
  # grep exits 0 when a CR byte is found.
  if LC_ALL=C grep -q $'\r' "$file"; then
    warn "CRLF detected: $file"
    bad=1
  fi
done < <(git ls-files '*.sh' '*.md' '*.yml' '*.yaml')

if [[ $bad -ne 0 ]]; then
  die "Found CRLF line endings. Convert listed files to LF."
fi

info "Line-ending check passed"
