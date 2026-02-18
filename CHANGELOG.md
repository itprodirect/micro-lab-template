# Changelog

All notable changes to this template will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## 0.1.0 - Unreleased

### Added

- Initial template structure with Rust and Go support
- Block contract documentation (`docs/block-contract.md`)
- Shared template layer (`templates/_shared/`)
- Rust template with config, logging, and errors blocks
- Go template with config, logging, and errors blocks
- Generator script (`scripts/new-repo.sh`) with `--lang`, `--name`, `--org`, `--dry-run`, `--no-git` flags
- Selftest script (`scripts/selftest.sh`)
- CI workflow with matrix over Rust and Go
- Baseline docs: principles, structure, CI/security, contributing, security policy
