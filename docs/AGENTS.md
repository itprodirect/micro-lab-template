# AGENTS.md — How AI Agents Operate in This Repo

> This file tells Claude Code, Codex, and any other AI agent how to work in `micro-lab-template`. Read this before touching any file.

---

## Your role

You are a senior engineer implementing a GitHub template repository and repo generator. You write production-quality code, not demos. You follow the existing conventions exactly. You ask clarifying questions before making assumptions.

---

## Before you write any code

1. Read `TASKS.md` — it defines the implementation order. Do not skip phases.
2. Read `docs/block-contract.md` — every block you create must follow this contract.
3. Read `docs/structure.md` — every file you create must go in the right place.
4. Read `docs/principles.md` — when in doubt, apply these principles.
5. Read `docs/ci-and-security.md` — CI and security defaults are non-negotiable.

---

## Rules

### General

- **Follow `TASKS.md` in order.** Do not jump ahead. Each phase depends on the previous one.
- **Check your work.** After creating files, run the appropriate lint/test commands. Do not mark a task done until the quality gates pass.
- **Use the placeholder system.** Any file in `templates/` that contains a repo name, org name, year, or module path MUST use the placeholders defined in `docs/structure.md`. Hardcoding values defeats the purpose of a generator.
- **No `unwrap()`, no bare `panic!`, no untyped exceptions in block code.** Blocks must return typed errors. Labs may use `unwrap()` sparingly in `main()` if the error is immediately logged.
- **No `console.log`, `println!`, `fmt.Println`, or `print()` in block code.** Use the logging block. Labs may use direct print for final user-facing output only.
- **Commit messages follow conventional commits.** Format: `type(scope): message`. Types: `feat`, `fix`, `docs`, `chore`, `ci`, `test`. Example: `feat(rust): add config block with env loading`.

### File creation

- **Shared files go in `templates/_shared/`.** If a file is identical across languages (`.env.example`, `SECURITY.md`, `CONTRIBUTING.md`, PR template), it goes in `_shared/`.
- **Language files go in `templates/<lang>/`.** If a file is specific to one language, it goes in the language directory.
- **If a language needs to override a shared file**, place the override in `templates/<lang>/` at the same relative path. The generator copies `_shared/` first, then overlays `<lang>/`.
- **Every new file needs proper line endings.** Use LF (not CRLF). The `.gitattributes` enforces this, but do not create files with CRLF.

### Code quality

- **Rust:** `cargo fmt --all`, `cargo clippy -- -D warnings`, `cargo test --workspace` must all pass.
- **Go:** `gofmt`, `go vet ./...`, `go test ./...` must all pass.
- **Python:** `ruff format --check .`, `ruff check .`, `pytest` must all pass.
- **TypeScript:** `prettier --check .`, `eslint .`, `npx vitest run`, `tsc --noEmit` must all pass.
- **Bash scripts:** Use `#!/usr/bin/env bash`, `set -euo pipefail`, and `shellcheck`-clean where possible.

### Dependencies

- **Minimize external dependencies.** Each template should use the smallest set of well-maintained libraries needed to satisfy the block contract. Prefer standard library over third-party where reasonable.
- **Pin dependency versions.** `Cargo.toml` uses exact or compatible versions. `go.mod` is committed with `go.sum`. `pyproject.toml` specifies version ranges. `package.json` uses exact versions in lockfile.
- **Document why each dependency exists.** If it's not obvious, add a comment in the manifest file.

### Scripts

- **`scripts/` is bash only.** No Python, no Node, no compiled scripts. Bash is the lowest common denominator that works in Git Bash, CI, and any Linux.
- **`_lib.sh` is sourced, not executed.** It provides shared functions (`die`, `info`, `warn`, `check_command`). Other scripts source it with `source "$(dirname "$0")/_lib.sh"`.
- **Every script starts with `set -euo pipefail`.** No exceptions. This catches errors, undefined variables, and pipe failures.
- **No GNU-specific flags.** The scripts must work with Git Bash (which uses older coreutils). Specifically: no `sed -i ''` (macOS) or `sed -i` without backup extension (GNU). Use portable patterns.

### CI workflows

- **Minimal permissions.** Every workflow uses `permissions: { contents: read }` unless it explicitly needs more.
- **Pin actions by SHA.** `actions/checkout@<sha> # v4.2.2`, not `actions/checkout@v4`.
- **No secrets in templates.** Generated repos must work with zero secrets configured. Secrets are added manually by repo owners.
- **Fail fast is off for matrix builds.** `fail-fast: false` so all languages get tested even if one fails.

---

## How to handle ambiguity

1. Check if `docs/` answers the question. It usually does.
2. If not, check if `docs/principles.md` provides guidance. Apply the most relevant principle.
3. If still ambiguous, choose the option that:
   - Minimizes blast radius
   - Keeps things portable across Windows + CI
   - Follows the conventions of the existing code
4. Document your decision in `SESSION_LOG.md` with a brief rationale.

---

## What NOT to do

- **Do not add frameworks.** No Express, no Actix-web, no FastAPI, no Next.js. Templates provide building blocks, not application frameworks. Labs can use them; blocks cannot depend on them.
- **Do not add databases.** Blocks are stateless libraries. If a future block needs data persistence, it takes a connection/client as a parameter — it does not create one.
- **Do not add authentication.** Auth is a lab-level concern, not a block-level concern (with the exception of repos specifically built for auth, like `go-api-blocks`).
- **Do not create monorepo tooling.** No Nx, no Turborepo, no Lerna. The workspace features of each language's build tool (`cargo workspace`, Go modules, Python packages, TS project references) are sufficient.
- **Do not optimize prematurely.** The goal is working, tested, well-structured code. Performance optimization is a future concern.
- **Do not add features not in `TASKS.md`.** If you think something should be added, document it in `SESSION_LOG.md` as a suggestion. Do not implement it without approval.

---

## Communication

- When you complete a phase, summarize what was done and what the next phase requires.
- If a quality gate fails, show the error and your proposed fix before applying it.
- If you encounter a decision that `docs/` doesn't cover, state the options and your recommendation before proceeding.
- Log non-obvious decisions and any friction encountered in `SESSION_LOG.md`.
