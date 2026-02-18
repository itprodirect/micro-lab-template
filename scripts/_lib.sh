#!/usr/bin/env bash
# Shared bash functions for micro-lab-template scripts.
# Source this file; do not execute it directly.

set -euo pipefail

# Print an info message to stderr
info() {
  printf '\033[0;32m[INFO]\033[0m %s\n' "$*" >&2
}

# Print a warning message to stderr
warn() {
  printf '\033[0;33m[WARN]\033[0m %s\n' "$*" >&2
}

# Print an error message to stderr and exit
die() {
  printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

# Check that a command exists on PATH
check_command() {
  local cmd="$1"
  local msg="${2:-$cmd is required but not found on PATH}"
  command -v "$cmd" >/dev/null 2>&1 || die "$msg"
}
