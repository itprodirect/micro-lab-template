# AGENTS.md

Canonical operating guide for Claude Code, Codex, and other AI agents working in `micro-lab-template`.

## Authority

- This file is the repo's single canonical agent guide.
- `CLAUDE.md` is a Claude-specific entry point, but shared repo rules live here.
- `docs/AGENTS.md` is a compatibility pointer back to this file.
- When agent guidance changes, update this file first and keep cross-references aligned.

## Read First

Before changing files, read:

1. `docs/canonical.md` for current workflow, CI, and branch policy.
2. `docs/v2-roadmap.md` for the active improvement plan.
3. `docs/principles.md` for design rules when the docs do not cover a decision.
4. `docs/block-contract.md` before touching block code or templates.
5. `docs/structure.md` before creating, moving, or templating files.
6. `docs/ci-and-security.md` before changing workflows, generated CI, or security defaults.

## Operating Contract

- Keep changes scoped to the explicit request or active roadmap item.
- Prefer existing patterns over new abstractions.
- Do not revive stale checklist work from `docs/TASKS.md` without approval.
- Keep the generator, CI, and docs aligned when behavior changes.
- Preserve Windows Git Bash and GitHub Actions Ubuntu compatibility.
- Use LF line endings. Do not add symlinks.
- Do not add dependencies unless the task requires them and the reason is documented.
- Do not add Python or TypeScript templates unless the roadmap explicitly reopens that scope.
- Never commit secrets, generated credentials, or local machine paths.

## Template Rules

- Shared generated files go in `templates/_shared/`.
- Language-specific files go in `templates/rust/` or `templates/go/`.
- If a language overrides a shared file, use the same relative path under that language template.
- Template files must use the placeholder system documented in `docs/structure.md` for repo names, org names, years, module paths, command strings, block paths, and lab paths.
- Generated repos must receive enough guidance to run checks, understand blocks, and continue work without reading this template repo first.

## Block Rules

- Blocks are importable libraries, not scripts.
- Blocks must follow all mandatory rules in `docs/block-contract.md`.
- Labs compose blocks. Blocks must not depend on labs.
- Rust block code must avoid `unwrap()` and bare `panic!`.
- Go block code must avoid bare `fmt.Println` and unwrapped, context-free errors.
- Tests must pass offline with no secrets or external services.

## Validation

Use the narrowest meaningful check while iterating, then run the canonical gate before handoff:

```bash
bash scripts/selftest.sh all
bash scripts/check-line-endings.sh
```

If `shellcheck` is installed:

```bash
cd scripts
shellcheck -x *.sh
```

For generator smoke tests, use `--dry-run` first when inspecting output and a real generation when validating placeholder replacement.

## Decisions And Logs

- If docs answer the question, follow the docs.
- If docs conflict, prefer `docs/canonical.md` for workflow and this file for agent behavior.
- If still ambiguous, choose the option with the lowest blast radius and best portability.
- Record non-obvious decisions, friction, and follow-up work in `SESSION_LOG.md`.
- If `SESSION_LOG.md` is missing and existing docs require it, create it rather than writing a new log elsewhere.

## Communication

- State what changed and which checks ran.
- If a check fails, report the failing command and the relevant error.
- Keep summaries concise and operational.
