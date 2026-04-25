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
- Language manifest validation for required fields and `templates/<lang>` directory coverage
- Selftest script (`scripts/selftest.sh`)
- CI workflow with Linux and Windows selftest jobs covering Rust and Go
- Baseline docs: principles, structure, CI/security, contributing, security policy
- Hook installer script (`scripts/setup-hooks.sh`) for the local pre-commit check

### Changed

- Local `bash scripts/selftest.sh all` now fails when required Go or Rust toolchains are missing instead of reporting a green pass from skipped checks
- Contributor and agent workflow guidance now points to `docs/canonical.md` and `docs/v2-roadmap.md` for current execution guidance
- `docs/TASKS.md` is documented as historical/reference-only and no longer drives active work
- `scripts/new-repo.sh` now rejects missing, empty, or flag-like values for `--lang`, `--name`, and `--org`
- `scripts/validate-language-config.sh` now normalizes `template_dir` paths and verifies every `templates/<lang>` directory except `templates/_shared` has exactly one manifest entry
- `bash scripts/selftest.sh all` now includes language manifest validation through each language selftest path
