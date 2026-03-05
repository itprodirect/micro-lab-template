# Canonical Workflow

This file is the source of truth for day-to-day repo workflow in `micro-lab-template`.

## Canonical Checks

Use this command for both local validation and CI parity:

```bash
bash scripts/selftest.sh all
```

Direct template checks (when you need language-specific debugging):

- Go (`templates/go`): `gofmt -l .`, `go vet ./...`, `go test ./...`
- Rust (`templates/rust`): `cargo fmt --all -- --check`, `cargo clippy -- -D warnings`, `cargo test --workspace`

## CI Source of Truth

- Workflow file: `.github/workflows/ci.yml`
- Linux and Windows jobs both run `bash scripts/selftest.sh all`
- Windows runner uses `shell: bash` and invokes `bash` explicitly

## Branch Policy

- Default and protected working branch: `master`
- PR target branch: `master`
- CI still listens to both `master` and `main` for compatibility during transition periods
- New work should target `master`

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
