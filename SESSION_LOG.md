# Session Log

Running record of decisions, friction, and follow-up work for `micro-lab-template`.

Newest entries go at the top.

## 2026-05-10 - Manifest-Driven Selftest

### Goal

Make `scripts/selftest.sh` read language check commands from `config/languages.json` while preserving current Go and Rust selftest behavior.

### Decisions

| Decision | Rationale |
|---|---|
| `scripts/selftest.sh` reads language IDs, template paths, toolchains, and format/lint/test commands from `config/languages.json`. | Keeps selftest language checks aligned with the manifest without broadening this change into the generator. |
| `scripts/new-repo.sh` remains unchanged. | This is an incremental selftest refactor; generator placeholder command population stays as separate Phase 2 work. |
| Rust template checks still use `out/selftest-rust-target` for Cargo build output. | Preserves the existing artifact-directory guardrail for `templates/rust/`. |
| The manifest schema did not change. | Existing `commands.format_check`, `commands.lint`, and `commands.test` keys were enough for selftest. |

### Validation

- `bash scripts/check-line-endings.sh` passed.
- `bash scripts/validate-language-config.sh` passed.
- `bash scripts/selftest.sh go` passed.
- `bash scripts/selftest.sh rust` passed.
- `bash scripts/selftest.sh all` passed.
- `bash scripts/new-repo.sh --lang go --name codex-smoke-go --no-git --dry-run` passed.
- `bash scripts/new-repo.sh --lang rust --name codex-smoke-rust --no-git --dry-run` passed.
- `git diff --check` passed.
- `git status --short` reviewed.

## 2026-05-10 - Template Hygiene Guardrails

### Goal

Prevent generated build output from being mistaken for template source, and make selftest cover generator dry-runs directly.

### Decisions

| Decision | Rationale |
|---|---|
| `scripts/selftest.sh` fails when language templates contain build artifact directories. | Artifacts like `templates/rust/target/` make dry-run output noisy and can confuse future generator work. |
| Rust template checks use `out/selftest-rust-target` as `CARGO_TARGET_DIR`. | Keeps Cargo validation from recreating `templates/rust/target/` while preserving the existing Rust checks. |
| `scripts/validate-language-config.sh` keeps a narrow embedded-Python exception. | JSON validation is safer in Python than ad hoc Bash parsing; the generator and template behavior remain Bash-only. |

### Validation

- `bash scripts/check-line-endings.sh` passed.
- `bash scripts/selftest.sh all` passed.
- Go and Rust generator dry-run smoke checks passed.
- `git diff --check` passed.

## 2026-05-10 - Agent Operations Layer

### Goal

Create one canonical operating contract for future Codex and Claude sessions, and ensure generated repos receive their own agent guide.

### Decisions

| Decision | Rationale |
|---|---|
| Root `AGENTS.md` is canonical. | Existing docs already expected a root agent guide, and root is the standard discovery path for agents. |
| `docs/AGENTS.md` redirects to root `AGENTS.md`. | Keeps old links working without maintaining two competing contracts. |
| Generated repos get `templates/_shared/AGENTS.md`. | Shared guidance applies to both Rust and Go generated repos without generator changes. |

### Friction

| Issue | Status | Notes |
|---|---|---|
| The workspace did not expose a `.git` directory. | Open | `git status --short` cannot run until the checkout is inside a Git worktree. |

### Follow-Up

- Keep this root log current for non-obvious decisions and validation friction.
- Treat `docs/SESSION_LOG.md` as historical content unless it is intentionally reconciled later.
