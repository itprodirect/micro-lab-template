# TASKS.md — Implementation Checklist

This file is historical/reference material only. It is not the active roadmap for day-to-day work.

> Historical reference only: this checklist is kept for archival context and should not be used as active execution guidance.

---

## Phase 0 — Repository Setup

> **Goal:** Repo exists, is cloned locally, and marked as a GitHub Template.

- [ ] Create `itprodirect/micro-lab-template` on GitHub (public, Template repo)
- [ ] Clone locally: `git clone https://github.com/itprodirect/micro-lab-template.git`
- [ ] Verify you can push to `main`

**Done when:** Repo exists on GitHub and is marked as a Template repository.

---

## Phase 1 — Baseline Files

> **Goal:** A new contributor can understand "how we build" in 2 minutes.

### 1.1 — Hygiene files

- [ ] `.editorconfig` — 2-space indent for YAML/JSON/TS, 4-space for Python, tabs for Go, UTF-8 charset, LF newlines, final newline enforced, trailing whitespace trimmed
- [ ] `.gitattributes` — force LF everywhere (`* text=auto eol=lf`), mark binaries
- [ ] `.gitignore` — OS files, editor files, language build artifacts, secrets patterns (`.env`, `*.pem`, `*.key`)
- [ ] `LICENSE` — MIT, year `2025`, org `itprodirect`

### 1.2 — Docs and meta

- [ ] `AGENTS.md` — (see Phase 1 detail below)
- [ ] `CONTRIBUTING.md` — setup instructions, how to add blocks vs labs, PR conventions
- [ ] `CHANGELOG.md` — initial entry: `## 0.1.0 - Unreleased` with `### Added` section
- [ ] `SESSION_LOG.md` — initial entry with date, goals, and setup decisions
- [ ] `.template-version` — contains `0.1.0`

### 1.3 — Documentation

- [ ] `docs/block-contract.md` — (already written, copy from prepared docs)
- [ ] `docs/structure.md` — (already written, copy from prepared docs)
- [ ] `docs/ci-and-security.md` — (already written, copy from prepared docs)
- [ ] `docs/principles.md` — (already written, copy from prepared docs)
- [ ] `docs/claude-review.md` — (already written, copy from prepared docs)

### 1.4 — README (initial)

- [ ] `README.md` — What this repo is, what it generates, link to docs, quick start placeholder (will be updated in Phase 5)

**Done when:** All files exist, `git diff` shows only the new files, content is internally consistent.

---

## Phase 2 — Shared Template Layer

> **Goal:** Files common to all languages exist in one place with working placeholders.

- [ ] Create `templates/_shared/` directory
- [ ] `templates/_shared/.env.example` — annotated, with safe placeholder values
- [ ] `templates/_shared/.gitignore` — comprehensive ignore for generated repos (secrets, build artifacts, OS files)
- [ ] `templates/_shared/.dockerignore` — `.git`, `node_modules`, `target/`, `__pycache__/`, `.env`
- [ ] `templates/_shared/SECURITY.md` — with `__ORG__` placeholder
- [ ] `templates/_shared/CONTRIBUTING.md` — with `__REPO_NAME__`, `__TEST_COMMAND__`, `__RUN_COMMAND__` placeholders
- [ ] `templates/_shared/README.md` — with all placeholders from `docs/structure.md`
- [ ] `templates/_shared/.github/CODEOWNERS` — `* @__ORG__`
- [ ] `templates/_shared/.github/pull_request_template.md` — what/why/checklist
- [ ] `templates/_shared/.github/dependabot.yml` — github-actions weekly + placeholder for language ecosystem

**Done when:** Every file in `_shared/` uses the correct placeholders. No hardcoded repo names, org names, or years.

---

## Phase 3 — Rust Template

> **Goal:** `templates/rust/` is a minimal, working Rust workspace with three blocks and one lab.

### 3.1 — Workspace setup

- [ ] `templates/rust/Cargo.toml` — workspace with `members = ["crates/*"]`, resolver 2, workspace-level dependencies
- [ ] `templates/rust/rust-toolchain.toml` — pin stable channel

### 3.2 — Blocks crate

- [ ] `templates/rust/crates/blocks/Cargo.toml` — library crate, depends on: `thiserror`, `serde`, `dotenvy`, `tracing`, `tracing-subscriber`
- [ ] `templates/rust/crates/blocks/src/lib.rs` — re-exports `config`, `logging`, `errors`
- [ ] `templates/rust/crates/blocks/src/config.rs` — loads from env vars → `.env` → defaults. Uses `dotenvy` + `serde`. Returns `Result<Config, BlockError>`
- [ ] `templates/rust/crates/blocks/src/logging.rs` — initializes `tracing-subscriber` with JSON or pretty format based on config. Returns `Result<(), BlockError>`
- [ ] `templates/rust/crates/blocks/src/errors.rs` — `BlockError` enum with `thiserror` derives. Variants: `ConfigMissing { key }`, `ConfigInvalid { key, reason }`, `LoggingInit { source }`
- [ ] `templates/rust/crates/blocks/src/config.rs` includes README (or a `crates/blocks/README.md` covering all three)

### 3.3 — Lab CLI

- [ ] `templates/rust/crates/lab_cli/Cargo.toml` — binary crate, depends on `blocks` (workspace path dependency)
- [ ] `templates/rust/crates/lab_cli/src/main.rs` — loads config, inits logging, logs a structured message, handles errors gracefully (no `unwrap()`)

### 3.4 — Quality gates

- [ ] `cargo fmt --all` passes
- [ ] `cargo clippy -- -D warnings` passes
- [ ] `cargo test --workspace` passes (at least 1 test per block)
- [ ] No `unwrap()` or `expect()` in library code (blocks)
- [ ] `__REPO_NAME__` placeholder used in `Cargo.toml` where repo name appears

### 3.5 — Container

- [ ] `templates/rust/Dockerfile` — multi-stage build (builder + runtime), non-root user, pinned base image

### 3.6 — Task runner

- [ ] `templates/rust/justfile` — targets: `check` (fmt + lint + test), `fmt`, `lint`, `test`, `run`, `build`, `docker-build`

**Done when:** `cd templates/rust && cargo test --workspace` passes. `cargo clippy -- -D warnings` is clean. The lab CLI runs and produces structured log output.

---

## Phase 4 — Go Template

> **Goal:** `templates/go/` is a minimal, working Go module with three blocks and one lab.

### 4.1 — Module setup

- [ ] `templates/go/go.mod` — module path `github.com/__ORG__/__REPO_NAME__`, Go 1.26+

### 4.2 — Blocks

- [ ] `templates/go/internal/blocks/config/config.go` — loads from env vars → `.env` → defaults. Uses `os.Getenv` + `joho/godotenv`. Returns `(Config, error)`
- [ ] `templates/go/internal/blocks/config/config_test.go` — tests default values, env override, missing optional vs required
- [ ] `templates/go/internal/blocks/logging/logging.go` — wraps `slog` with JSON handler. Accepts config for level.
- [ ] `templates/go/internal/blocks/logging/logging_test.go`
- [ ] `templates/go/internal/blocks/errors/errors.go` — sentinel errors + `fmt.Errorf` wrapping patterns
- [ ] `templates/go/internal/blocks/errors/errors_test.go` — tests error wrapping and `errors.Is`

### 4.3 — Lab CLI

- [ ] `templates/go/cmd/lab-cli/main.go` — loads config, inits logger, logs structured message, exits with proper code on error

### 4.4 — Quality gates

- [ ] `gofmt -l .` produces no output
- [ ] `go vet ./...` passes
- [ ] `go test ./...` passes
- [ ] `__REPO_NAME__` and `__ORG__` placeholders used in `go.mod`

### 4.5 — Container + task runner

- [ ] `templates/go/Dockerfile` — multi-stage, non-root, pinned base
- [ ] `templates/go/justfile` — targets: `check`, `fmt`, `lint`, `test`, `run`, `build`, `docker-build`

**Done when:** `cd templates/go && go test ./...` passes. `go vet` is clean. Lab CLI runs.

---

## Phase 5 — Python Template

> **Goal:** `templates/python/` is a minimal, working Python package with three blocks and one lab.

### 5.1 — Package setup

- [ ] `templates/python/pyproject.toml` — `hatchling` backend, project name `__REPO_NAME__`, dependencies: `pydantic-settings`, `structlog`, dev dependencies: `ruff`, `pytest`
- [ ] `templates/python/src/__PKG__/__init__.py`
- [ ] `templates/python/src/__PKG__/blocks/__init__.py` — exports `Config`, `setup_logging`, `BlockError`

### 5.2 — Blocks

- [ ] `templates/python/src/__PKG__/blocks/config.py` — `pydantic-settings` `BaseSettings` subclass. Loads from env → `.env` → defaults.
- [ ] `templates/python/src/__PKG__/blocks/logging.py` — `structlog` configuration. JSON output in prod, pretty in dev. Accepts config.
- [ ] `templates/python/src/__PKG__/blocks/errors.py` — `BlockError` base class with `ConfigError`, `LoggingError` subclasses. All carry context attributes.

### 5.3 — Lab

- [ ] `templates/python/labs/01_cli.py` — imports blocks, loads config, inits logging, logs structured message, catches `BlockError`

### 5.4 — Quality gates

- [ ] `ruff format --check .` passes
- [ ] `ruff check .` passes
- [ ] `pytest` passes (at least 1 test per block in `tests/test_blocks.py`)
- [ ] `__PKG__` and `__REPO_NAME__` placeholders used correctly

### 5.5 — Container + task runner

- [ ] `templates/python/Dockerfile` — multi-stage, non-root, pinned `python:3.12-slim`
- [ ] `templates/python/justfile` — targets: `check`, `fmt`, `lint`, `test`, `run`, `docker-build`

**Done when:** `cd templates/python && pytest` passes. `ruff` is clean. Lab runs.

---

## Phase 6 — TypeScript Template

> **Goal:** `templates/ts/` is a minimal, working TS project with three blocks and one lab.

### 6.1 — Project setup

- [ ] `templates/ts/package.json` — name `__REPO_NAME__`, type `module`, scripts for lint/test/build, dependencies: `zod`, `dotenv`, `pino`, dev dependencies: `typescript`, `eslint`, `vitest`, `prettier`, `tsx`
- [ ] `templates/ts/tsconfig.json` — strict mode, ES2022 target, Node module resolution

### 6.2 — Blocks

- [ ] `templates/ts/src/blocks/config.ts` — Zod schema for config, loads from `process.env` + `dotenv`. Returns typed config or throws `ConfigError`
- [ ] `templates/ts/src/blocks/logging.ts` — Pino wrapper. JSON in prod, pretty in dev. Accepts config.
- [ ] `templates/ts/src/blocks/errors.ts` — `BlockError` base class, `ConfigError`, `LoggingError` subclasses
- [ ] `templates/ts/src/blocks/index.ts` — re-exports all blocks

### 6.3 — Lab

- [ ] `templates/ts/labs/01_cli.ts` — imports blocks, loads config, inits logging, logs message, catches errors

### 6.4 — Quality gates

- [ ] `prettier --check .` passes
- [ ] `eslint .` passes
- [ ] `npx vitest run` passes (at least 1 test per block)
- [ ] `tsc --noEmit` passes
- [ ] `__REPO_NAME__` placeholder used in `package.json`

### 6.5 — Container + task runner

- [ ] `templates/ts/Dockerfile` — multi-stage, non-root, pinned `node:22-slim`
- [ ] `templates/ts/justfile`

**Done when:** `cd templates/ts && npx vitest run` passes. `tsc` compiles. Lab runs.

---

## Phase 7 — Generator Script

> **Goal:** `bash scripts/new-repo.sh --lang rust --name my-repo --org itprodirect` produces a working repo.

- [ ] `scripts/_lib.sh` — shared functions: `die()`, `info()`, `warn()`, `check_command()`
- [ ] `scripts/new-repo.sh` — accepts args:
  - `--lang` (required): `rust`, `go`, `python`, `ts`
  - `--name` (required): repo name in kebab-case
  - `--org` (optional, default `itprodirect`): GitHub org
  - `--dry-run` (optional): show what would be created without creating
  - `--no-git` (optional): skip `git init`
  - `--no-docker` (optional): skip Dockerfile
- [ ] Generator logic:
  1. Validate args
  2. Check prerequisites (`cargo`/`go`/`python3`/`node` based on `--lang`)
  3. Copy `templates/_shared/` → `out/<name>/`
  4. Copy `templates/<lang>/` → `out/<name>/` (overlay, shared files can be overridden)
  5. Replace all placeholders in all files (recursive `sed` or similar)
  6. `git init` (unless `--no-git`)
  7. If `gh` CLI is available: offer to create GitHub repo
  8. Print summary and next steps
- [ ] Placeholder replacement handles:
  - `__REPO_NAME__` → kebab-case name
  - `__PKG__` → underscored name (for Python)
  - `__ORG__` → org name
  - `__YEAR__` → current year
  - `__TEMPLATE_VERSION__` → contents of `.template-version`
  - `__MODULE_PATH__` → `github.com/<org>/<name>` (for Go)
  - `__TEST_COMMAND__` → language-appropriate test command
  - `__RUN_COMMAND__` → language-appropriate run command
  - `__BLOCKS_DIR__` → language-appropriate blocks path
  - `__LABS_DIR__` → language-appropriate labs path
- [ ] `--dry-run` prints file list + placeholder replacements without writing
- [ ] Works in Git Bash on Windows (no GNU-only flags, no symlinks)

**Done when:** `bash scripts/new-repo.sh --lang rust --name test-repo` produces a directory that passes `cargo test` with no manual edits.

---

## Phase 8 — Selftest Script

> **Goal:** `bash scripts/selftest.sh` validates every template without leaving artifacts.

- [ ] `scripts/selftest.sh` — accepts optional `<lang>` arg to test one language, otherwise tests all
- [ ] For each language, runs: format check → lint → test
- [ ] Prints clear PASS/FAIL per language
- [ ] Exits 0 only if ALL languages pass
- [ ] Also tests the generator:
  1. Generate a repo with `--lang rust --name selftest-output --no-git`
  2. Verify no `__PLACEHOLDER__` strings remain: `grep -r '__[A-Z_]*__' out/selftest-output`
  3. Clean up `out/selftest-output`
- [ ] `scripts/setup-hooks.sh` — installs a pre-commit hook that runs `selftest.sh`

**Done when:** `bash scripts/selftest.sh` passes locally. Running it twice in a row works (no leftover state).

---

## Phase 9 — CI Workflows

> **Goal:** GitHub Actions runs checks on every push and PR.

- [ ] `.github/workflows/ci-selftest.yml` — runs `scripts/selftest.sh` on push to `main` and PRs
- [ ] `.github/workflows/ci-templates.yml` — matrix strategy (rust, go, python, ts) with path filters
- [ ] `.github/workflows/ci-generator.yml` — generates a repo per language, verifies no leftover placeholders, runs tests in generated repo
- [ ] `.github/dependabot.yml` — `github-actions` weekly updates
- [ ] All workflows use `permissions: { contents: read }` (minimal permissions)
- [ ] All action versions pinned by SHA with version comment

**Done when:** Push to GitHub → Actions run → all green.

---

## Phase 10 — Final README + Polish

> **Goal:** Someone new can use this repo without asking questions.

- [ ] Update `README.md` with:
  - What this repo is (template + generator for micro-lab repos)
  - Quick start: `bash scripts/new-repo.sh --lang rust --name my-repo`
  - What "micro-lab" means
  - What "LEGO blocks" means and how they work
  - Link to `docs/block-contract.md`
  - Link to `docs/structure.md`
  - Link to `docs/principles.md`
  - Supported languages table with status badges
  - Generator flags reference
- [ ] Update `SESSION_LOG.md` with decisions made during implementation
- [ ] Update `CHANGELOG.md` with everything added

**Done when:** A developer who has never seen this repo can generate a working Rust repo in under 3 minutes by following the README.

---

## Validation Checklist (final "ship it" gate)

- [ ] Repo marked as GitHub Template
- [ ] `bash scripts/selftest.sh` passes locally
- [ ] CI green on GitHub
- [ ] Generator produces a working repo for Rust, Go, Python, and TypeScript
- [ ] Generated repos have docs, CI, and security defaults automatically
- [ ] No `__PLACEHOLDER__` strings in any generated repo
- [ ] README answers: what, why, how, where do blocks live, how do I add one
- [ ] Block contract is linked from at least 3 places (README, CONTRIBUTING, generated README)
