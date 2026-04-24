# Repo Structure

> This document defines the folder conventions for both the `micro-lab-template` repo itself and for every repo it generates. AI agents (Claude Code, Codex) should follow these conventions exactly when creating or modifying files.

---

## Template repo structure (this repo)

```
micro-lab-template/
│
├── README.md                    # What this is, how to use it
├── LICENSE                      # MIT
├── AGENTS.md                    # How AI agents should behave here
├── TASKS.md                     # Historical/reference implementation checklist
├── CONTRIBUTING.md              # How to contribute (for humans)
├── CHANGELOG.md                 # Template-level version history
├── SESSION_LOG.md               # Decisions, friction, learnings
├── .template-version            # Semver string (e.g., "0.1.0")
├── .editorconfig                # Editor settings (indent, charset, newline)
├── .gitattributes               # Force LF line endings everywhere
├── .gitignore                   # Template repo ignores
│
├── docs/
│   ├── block-contract.md        # THE contract every block must follow
│   ├── structure.md             # This file
│   ├── principles.md            # Design philosophy
│   ├── ci-and-security.md       # CI pipeline and security defaults
│   └── claude-review.md         # Gap analysis from Claude (reference)
│
├── scripts/
│   ├── new-repo.sh              # Generator: scaffold a new repo from template
│   ├── selftest.sh              # Run lint/test across all templates
│   ├── setup-hooks.sh           # Install git pre-commit hooks
│   └── _lib.sh                  # Shared bash functions
│
├── templates/
│   ├── _shared/                 # Files every generated repo gets (any language)
│   │   ├── .env.example
│   │   ├── .gitignore
│   │   ├── .dockerignore
│   │   ├── SECURITY.md
│   │   ├── CONTRIBUTING.md
│   │   ├── README.md            # With __PLACEHOLDERS__
│   │   └── .github/
│   │       ├── CODEOWNERS
│   │       ├── pull_request_template.md
│   │       └── dependabot.yml
│   │
│   ├── rust/                    # Rust template skeleton
│   ├── go/                      # Go template skeleton
│   ├── python/                  # Python template skeleton
│   └── ts/                      # TypeScript template skeleton
│
└── .github/
    ├── workflows/
    │   ├── ci-selftest.yml      # Tests selftest.sh on push/PR
    │   ├── ci-templates.yml     # Matrix: test each language template
    │   └── ci-generator.yml     # Test the generator produces valid repos
    └── dependabot.yml           # Dependabot for this template repo
```

---

## Generated repo structure (what `new-repo.sh` produces)

Every generated repo follows the same shape, adapted to the language. Here are the four supported layouts:

### Rust

```
my-rust-repo/
├── Cargo.toml                   # Workspace root
├── Dockerfile
├── justfile
├── .env.example
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── .github/                     # CI + dependabot + PR template
│
├── crates/
│   ├── blocks/
│   │   ├── Cargo.toml           # Library crate — the blocks package
│   │   └── src/
│   │       ├── lib.rs           # Re-exports all blocks
│   │       ├── config.rs        # Config loading block
│   │       ├── logging.rs       # Structured logging block
│   │       └── errors.rs        # Error types block
│   │
│   └── lab_cli/
│       ├── Cargo.toml           # Binary crate — depends on blocks
│       └── src/
│           └── main.rs          # Lab: CLI that composes blocks
│
└── tests/                       # Integration tests (optional)
```

### Go

```
my-go-repo/
├── go.mod
├── go.sum
├── Dockerfile
├── justfile
├── .env.example
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── .github/
│
├── internal/
│   └── blocks/
│       ├── config/
│       │   ├── config.go        # Config loading block
│       │   └── config_test.go
│       ├── logging/
│       │   ├── logging.go       # Structured logging block
│       │   └── logging_test.go
│       └── errors/
│           ├── errors.go        # Error types block
│           └── errors_test.go
│
└── cmd/
    └── lab-cli/
        └── main.go              # Lab: CLI that composes blocks
```

### Python

```
my-python-repo/
├── pyproject.toml               # Modern packaging (hatchling backend)
├── Dockerfile
├── justfile
├── .env.example
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── .github/
│
├── src/
│   └── my_python_repo/          # Package name (underscored)
│       ├── __init__.py
│       └── blocks/
│           ├── __init__.py
│           ├── config.py        # Config loading block
│           ├── logging.py       # Structured logging block
│           └── errors.py        # Error types block
│
├── labs/
│   └── 01_cli.py               # Lab: CLI that composes blocks
│
└── tests/
    ├── __init__.py
    └── test_blocks.py
```

### TypeScript

```
my-ts-repo/
├── package.json
├── tsconfig.json
├── Dockerfile
├── justfile
├── .env.example
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── .github/
│
├── src/
│   └── blocks/
│       ├── index.ts             # Re-exports all blocks
│       ├── config.ts            # Config loading block
│       ├── logging.ts           # Structured logging block
│       └── errors.ts            # Error types block
│
├── labs/
│   └── 01_cli.ts               # Lab: CLI that composes blocks
│
└── tests/
    └── blocks.test.ts
```

---

## Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Repo name | kebab-case | `rust-security-toolkit` |
| Python package | snake_case (derived from repo name) | `rust_security_toolkit` |
| Block directory | singular noun, lowercase | `config`, `logging`, `errors` |
| Lab file/directory | numbered prefix + descriptive name | `01_cli`, `02_server` |
| Environment variables | UPPER_SNAKE_CASE with repo prefix | `MYAPP_LOG_LEVEL` |
| Config files | lowercase with dots | `config.toml`, `.env` |

---

## Placeholders in templates

The generator (`scripts/new-repo.sh`) replaces these placeholders during scaffolding:

| Placeholder | Replaced with | Example |
|-------------|--------------|---------|
| `__REPO_NAME__` | The `--name` argument | `rust-link-safety` |
| `__PKG__` | Python package name (underscored repo name) | `rust_link_safety` |
| `__ORG__` | The `--org` argument | `itprodirect` |
| `__YEAR__` | Current year | `2025` |
| `__TEMPLATE_VERSION__` | Contents of `.template-version` | `0.1.0` |
| `__MODULE_PATH__` | Go module path (`github.com/org/name`) | `github.com/itprodirect/rust-link-safety` |
| `__TEST_COMMAND__` | Language-appropriate test command | `cargo test --workspace` |
| `__RUN_COMMAND__` | Language-appropriate run command | `cargo run -p lab_cli` |
| `__BLOCKS_DIR__` | Path to blocks directory | `crates/blocks` |
| `__LABS_DIR__` | Path to labs directory | `crates/lab_cli` |

---

## Rules for AI agents

1. **Never create files outside this structure.** If a new file doesn't fit, the structure needs updating — not bypassing.
2. **Blocks go in the blocks directory. Labs go in the labs directory.** No exceptions.
3. **Shared files go in `templates/_shared/`.** Language-specific files go in `templates/<lang>/`.
4. **Tests live next to the code they test** (Go, Rust) or in a top-level `tests/` directory (Python, TS).
5. **Every new file needs to work with the placeholder system.** If it contains the repo name, org, or year, use the placeholder.
