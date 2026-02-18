# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A GitHub **template repository** and **generator** for creating multi-language "micro-lab" repos. Each generated repo follows the "portable blocks, not monoliths" architecture: small, tested, importable library modules (blocks) composed by application entrypoints (labs).

Currently supports: **Rust** and **Go** templates. Python and TypeScript are deferred until CI+generator are proven.

## Key Docs (read before changing anything)

- `TASKS.md` — ordered implementation checklist, execute in phase order
- `docs/block-contract.md` — the 6 mandatory rules every block must satisfy
- `docs/structure.md` — folder conventions and placeholder reference
- `docs/ci-and-security.md` — CI architecture and security defaults
- `docs/principles.md` — 10 design principles
- `docs/claude-review.md` — gap analysis with recommendations
- `AGENTS.md` — rules for AI agents operating in this repo

## Build & Test Commands

### Template validation
```bash
bash scripts/selftest.sh          # test all templates + generator
bash scripts/selftest.sh rust     # test only rust template
bash scripts/selftest.sh go       # test only go template
```

### Rust template (from templates/rust/)
```bash
cargo fmt --all -- --check        # format check
cargo clippy -- -D warnings       # lint (warnings-as-errors)
cargo test --workspace            # run tests
```

### Go template (from templates/go/)
```bash
gofmt -l .                        # format check (output must be empty)
go vet ./...                      # lint
go test ./...                     # run tests
```

### Generator
```bash
bash scripts/new-repo.sh --lang rust --name my-repo --org myorg
bash scripts/new-repo.sh --lang go --name my-repo --dry-run
```

## Architecture

```
templates/_shared/    → files every generated repo gets (any language)
templates/rust/       → Rust workspace: crates/blocks/ + crates/lab_cli/
templates/go/         → Go module: internal/blocks/ + cmd/lab-cli/
scripts/new-repo.sh   → generator (merges _shared + lang, replaces placeholders)
scripts/selftest.sh   → validates templates + generator output
scripts/_lib.sh       → shared bash functions (sourced, not executed)
```

### Block architecture (every generated repo)
- **blocks/config** — loads config from env vars → .env → defaults
- **blocks/logging** — structured logging (tracing/slog)
- **blocks/errors** — typed error enums with context
- **lab_cli** — composes all blocks into a working CLI

### Placeholder system
The generator replaces these in all template files:
`__REPO_NAME__`, `__ORG__`, `__YEAR__`, `__TEMPLATE_VERSION__`, `__MODULE_PATH__`, `__PKG__`, `__TEST_COMMAND__`, `__RUN_COMMAND__`, `__BLOCKS_DIR__`, `__LABS_DIR__`

## Conventions

- **Commit messages:** conventional commits — `feat(scope): msg`, `fix(scope): msg`, `docs(scope): msg`
- **Scripts:** bash only, `#!/usr/bin/env bash`, `set -euo pipefail`, no GNU-specific flags
- **Line endings:** LF everywhere (enforced by .gitattributes)
- **Cross-platform:** must work in Git Bash on Windows and GitHub Actions Ubuntu
- **No symlinks** (Git Bash on Windows handles them poorly)
- **Block code:** no `unwrap()`/`panic!()` in Rust blocks, no bare `fmt.Println` in Go blocks — use typed errors and structured logging
- **CI actions:** pin by SHA with version comment, minimal permissions (`contents: read`)
- **Dependencies:** minimal, pinned, documented
