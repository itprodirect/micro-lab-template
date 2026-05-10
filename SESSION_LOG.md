# Session Log

Running record of decisions, friction, and follow-up work for `micro-lab-template`.

Newest entries go at the top.

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
