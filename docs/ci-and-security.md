# CI and Security

For canonical workflow and branch policy, see `docs/canonical.md`.
This document describes the CI and security defaults that are currently implemented in `micro-lab-template`.

## Current CI in this repository

The template repo uses two workflow files:

- `.github/workflows/ci.yml`
- `.github/workflows/dependabot-automerge.yml`

It runs on:

- `push` to `master` and `main`
- `pull_request` targeting `master` and `main`

It contains three jobs:

1. `hygiene-linux`
2. `selftest-linux`
3. `selftest-windows`

`hygiene-linux` runs LF line-ending checks (`scripts/check-line-endings.sh`) and `shellcheck` on `scripts/*.sh`.
Both selftest jobs run `bash scripts/selftest.sh all` after installing Rust and Go toolchains.
The Windows selftest job uses `shell: bash` and explicitly invokes `bash` in the run step.
`dependabot-automerge` merges eligible Dependabot GitHub Actions PRs only after CI succeeds.

## What selftest currently enforces

`scripts/selftest.sh` validates both templates and generator output:

- Rust template: `cargo fmt --all -- --check`, `cargo clippy -- -D warnings`, `cargo test --workspace`
- Go template: `gofmt -l .`, `go vet ./...`, `go test ./...`
- `all` mode delegates to `go` then `rust` and fails fast on the first failing sub-run
- Generator smoke test for each language:
  - scaffold a repo with `scripts/new-repo.sh`
  - verify placeholders are removed
  - run language tests in the generated repo

Any failing check causes a non-zero exit.

## Security defaults currently present

1. Minimal workflow permissions

```yaml
permissions:
  contents: read
```

2. GitHub Actions dependency updates via `.github/dependabot.yml` (weekly).

3. Shared generated-repo safety defaults from `templates/_shared/`:

- `SECURITY.md`
- `.gitignore` with secret-oriented patterns (`.env`, key files, etc.)
- `.env.example` instead of committed `.env`

## Notes

- This repo currently validates Rust and Go templates only.
- If additional language templates are introduced, update both:
  - `scripts/selftest.sh`
  - `.github/workflows/ci.yml`
