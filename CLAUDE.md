# CLAUDE.md

This file is the Claude Code entry point for this repository. Shared agent rules live in `AGENTS.md`.

## What This Repo Is

A GitHub template repository and generator for creating multi-language micro-lab repos. Each generated repo follows the portable-blocks architecture: small, tested, importable library modules composed by application entrypoints called labs.

Currently supported templates: Rust and Go. Python and TypeScript are deferred until CI and generator behavior are proven.

## Key Docs

- `AGENTS.md` - canonical rules for AI agents operating in this repo
- `docs/canonical.md` - current workflow, CI source of truth, and branch policy
- `docs/v2-roadmap.md` - active improvement plan
- `docs/TASKS.md` - historical implementation checklist, not the active day-to-day plan
- `docs/block-contract.md` - the 6 mandatory rules every block must satisfy
- `docs/structure.md` - folder conventions and placeholder reference
- `docs/ci-and-security.md` - CI architecture and security defaults
- `docs/principles.md` - design principles
- `docs/codex-goals/` - reusable Codex `/goal` prompts for common repo work
- `docs/claude-review.md` - historical gap analysis and recommendations

## Build And Test Commands

### Template validation

```bash
bash scripts/selftest.sh all      # canonical check: all templates + generator
bash scripts/selftest.sh rust     # test only Rust template
bash scripts/selftest.sh go       # test only Go template
bash scripts/check-line-endings.sh
```

If `shellcheck` is installed:

```bash
cd scripts
shellcheck -x *.sh
```

### Rust template

Run from `templates/rust/`:

```bash
cargo fmt --all -- --check
cargo clippy -- -D warnings
cargo test --workspace
```

### Go template

Run from `templates/go/`:

```bash
gofmt -l .
go vet ./...
go test ./...
```

### Generator

```bash
bash scripts/new-repo.sh --lang rust --name my-repo --org myorg
bash scripts/new-repo.sh --lang go --name my-repo --no-git --dry-run
```

## Architecture

```text
templates/_shared/    -> files every generated repo gets
templates/rust/       -> Rust workspace: crates/blocks/ + crates/lab_cli/
templates/go/         -> Go module: internal/blocks/ + cmd/lab-cli/
scripts/new-repo.sh   -> generator that merges shared + language templates
scripts/selftest.sh   -> validates templates and generated output
scripts/_lib.sh       -> shared bash functions, sourced by scripts
```

Generated repos include:

- `blocks/config` - loads configuration from env, local `.env`, and defaults
- `blocks/logging` - structured logging
- `blocks/errors` - typed error handling with context
- `lab_cli` or `cmd/lab-cli` - sample lab that composes blocks

## Placeholder System

The generator replaces the template placeholders documented in `docs/structure.md`, including repo name, org, year, template version, module path, package name, command strings, block path, and lab path.

Do not hardcode values that should come from that placeholder system.

## Conventions

- Commit messages use conventional commits: `feat(scope): msg`, `fix(scope): msg`, `docs(scope): msg`.
- Repo script entry points are Bash with `#!/usr/bin/env bash` and `set -euo pipefail`.
- `scripts/validate-language-config.sh` has a narrow embedded-Python exception for JSON manifest validation only; do not extend this exception to generators or templates.
- Line endings are LF everywhere.
- Cross-platform support means Git Bash on Windows and GitHub Actions Ubuntu.
- Do not add symlinks.
- Rust block code avoids `unwrap()` and bare `panic!`.
- Go block code avoids bare `fmt.Println`.
- CI actions are pinned by SHA with version comments and minimal permissions.
- Dependencies are minimal, pinned, and documented when non-obvious.
