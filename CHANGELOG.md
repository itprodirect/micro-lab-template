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
- CI workflow with Linux and Windows selftest jobs covering Rust and Go
- Baseline docs: principles, structure, CI/security, contributing, security policy
- Hook installer script (`scripts/setup-hooks.sh`) for the local pre-commit check
- Canonical agent guide (`AGENTS.md`) plus generated-repo agent guidance
- Language manifest (`config/languages.json`) with validation for supported language metadata

### Changed

- Local `bash scripts/selftest.sh all` now fails when required Go or Rust toolchains are missing instead of reporting a green pass from skipped checks
- Contributor and agent workflow guidance now points to `docs/canonical.md` and `docs/v2-roadmap.md` for current execution guidance
- `scripts/selftest.sh` now uses the language manifest for supported languages, template paths, toolchains, and check commands
- `scripts/new-repo.sh` now uses the language manifest for supported languages, template directories, generated test/run commands, and block/lab path placeholders
- Selftest now validates the language manifest, rejects build artifact directories in language templates, covers generator dry-runs, and keeps Rust build output outside `templates/rust/`
