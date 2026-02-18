# Contributing to micro-lab-template

## Setup

```bash
git clone https://github.com/itprodirect/micro-lab-template.git
cd micro-lab-template
```

Ensure you have the toolchains for the templates you want to work on:
- **Rust:** `rustup`, `cargo` (stable)
- **Go:** `go` 1.22+

## How This Repo Works

This is a **template generator**. The `templates/` directory contains skeletons that `scripts/new-repo.sh` copies, merges, and personalizes into new repos.

- `templates/_shared/` — files every generated repo gets (any language)
- `templates/<lang>/` — language-specific template files
- `scripts/new-repo.sh` — the generator (merges _shared + lang, replaces placeholders)
- `scripts/selftest.sh` — validates all templates and the generator

## Adding a Block vs. a Lab

**Blocks** are reusable library modules. They go in the blocks directory (`crates/blocks/` for Rust, `internal/blocks/` for Go). Every block must follow the [block contract](docs/block-contract.md).

**Labs** are applications that compose blocks. They go in the labs directory (`crates/lab_cli/` for Rust, `cmd/lab-cli/` for Go).

## Making Changes

1. Read `TASKS.md` for the current implementation plan
2. Read `docs/block-contract.md` before creating or modifying blocks
3. Run `bash scripts/selftest.sh all` before submitting a PR
4. Use conventional commits: `feat(scope): message`, `fix(scope): message`

## Placeholder System

Files in `templates/` use placeholders like `__REPO_NAME__`, `__ORG__`, etc. See `docs/structure.md` for the full list. Never hardcode repo names, org names, or years in template files.

## PR Conventions

- Keep PRs focused on one phase or one logical change
- Ensure `bash scripts/selftest.sh all` passes
- Follow the block contract for any new blocks

## PR Checklist

- [ ] `bash scripts/selftest.sh all` passes locally
- [ ] Template placeholders are still used where required (`__REPO_NAME__`, `__ORG__`, etc.)
- [ ] Changes are scoped and documented if behavior changed
