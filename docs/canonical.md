# Canonical Workflow

This file is the source of truth for day-to-day repo workflow in `micro-lab-template`.

## Canonical Checks

Use this command for both local validation and CI parity:

```bash
bash scripts/selftest.sh all
```

The canonical selftest also validates `config/languages.json`, rejects build artifact directories inside language templates, and covers generator dry-runs before generated-repo smoke tests.

Direct template checks (when you need language-specific debugging):

- Use `commands.format_check`, `commands.lint`, and `commands.test` from `config/languages.json`.
- Current language templates are Go (`templates/go`) and Rust (`templates/rust`).

## Generator Source of Truth

`scripts/new-repo.sh` reads supported language ids, template directories, generated test/run commands, and generated block/lab paths from `config/languages.json`. The generator still handles repo-specific placeholders such as repo name, org, year, package name, module path, and template version directly.

## CI Source of Truth

- Workflow file: `.github/workflows/ci.yml`
- Linux and Windows jobs both run `bash scripts/selftest.sh all`
- Windows runner uses `shell: bash` and invokes `bash` explicitly

## Branch Policy

- Default and protected working branch: `master`
- PR target branch: `master`
- CI still listens to both `master` and `main` for compatibility during transition periods
- New work should target `master`

## Planning Source of Truth

- Active improvement plan: `docs/v2-roadmap.md`
- Historical implementation checklist: `docs/TASKS.md`
- `docs/TASKS.md` is reference material, not the day-to-day execution source for new work

## Agent Operations Source of Truth

- Canonical agent guide: `AGENTS.md`
- Legacy pointer only: `docs/AGENTS.md`
- Claude-specific entry point: `CLAUDE.md`
- Reusable Codex goal prompts: `docs/codex-goals/`

## Dependabot Auto-Merge Policy

- Workflow: `.github/workflows/dependabot-automerge.yml`
- Trigger: successful completion of the `CI` workflow for pull requests
- Scope: only Dependabot PRs for `github-actions` that modify `.github/workflows/*`
- Merge strategy: squash

## Update Rule

If workflow behavior changes, update these files in the same PR:

1. `docs/canonical.md`
2. `README.md`
3. `CONTRIBUTING.md`
4. `docs/ci-and-security.md`

If agent operating guidance changes, update `AGENTS.md` first and keep `CLAUDE.md`, `docs/AGENTS.md`, and `README.md` references aligned.
