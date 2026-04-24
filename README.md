# micro-lab-template

A GitHub template repository and generator for creating multi-language **micro-lab** repos with a standardized "portable blocks" architecture.

## What it generates

Each generated repo comes with:
- **Config block** — loads from env vars → local-dev `.env` → defaults
- **Logging block** — structured logging (JSON or pretty)
- **Errors block** — typed error handling with context
- **Lab CLI** — demonstrates composing all three blocks
- **CI, security workflows, dependency updates, and docs** — out of the box

## Supported languages

| Language | Status | Template |
|----------|--------|----------|
| Rust     | v0.1   | `templates/rust/` |
| Go       | v0.1   | `templates/go/` |

## Quick start

```bash
# Generate a new Rust repo
bash scripts/new-repo.sh --lang rust --name my-rust-project --org myorg

# Generate a new Go repo
bash scripts/new-repo.sh --lang go --name my-go-project --org myorg

# Preview without creating files
bash scripts/new-repo.sh --lang rust --name my-repo --dry-run
```

## Run checks

```bash
bash scripts/selftest.sh all      # canonical check: CI + local
bash scripts/selftest.sh go       # Go template + generator (Go)
bash scripts/selftest.sh rust     # Rust template + generator (Rust)
```

Direct template checks (without generator smoke tests):

- `templates/go`: `gofmt -l .`, `go vet ./...`, `go test ./...`
- `templates/rust`: `cargo fmt --all -- --check`, `cargo clippy -- -D warnings`, `cargo test --workspace`

### Generator flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--lang` | yes | — | `rust` or `go` |
| `--name` | yes | — | Repo name (kebab-case) |
| `--org` | no | `itprodirect` | GitHub org/owner |
| `--dry-run` | no | — | Preview output without creating files |
| `--no-git` | no | — | Skip `git init` |

## How "blocks" work

Blocks are small, reusable, tested library modules that follow a strict [block contract](docs/block-contract.md). Labs compose blocks into working applications. Dependencies flow one direction: labs → blocks.

```
┌─────────────────────────────────┐
│  Lab (CLI, server, etc.)        │
│  ┌────────┐ ┌───────┐ ┌──────┐ │
│  │ config │ │ logging│ │errors│ │
│  └────────┘ └───────┘ └──────┘ │
└─────────────────────────────────┘
```

## Docs

- `docs/canonical.md` — current workflow and branch policy (`master`)
- `docs/v2-roadmap.md` — active roadmap for ongoing work
- [Block contract](docs/block-contract.md) — the 6 rules every block must follow
- [Repo structure](docs/structure.md) — folder conventions and placeholder reference
- [Design principles](docs/principles.md) — the philosophy behind this template
- [CI & security](docs/ci-and-security.md) — CI architecture and security defaults
- [Contributing](CONTRIBUTING.md) — how to contribute to this template

## Validating the templates

```bash
bash scripts/selftest.sh all      # test everything
bash scripts/selftest.sh go       # test Go template only
bash scripts/selftest.sh rust     # test Rust template only
```
