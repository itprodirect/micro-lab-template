# Block Contract

> This is the most important document in this repo. Every reusable component ("block") across every language and every generated repo MUST follow this contract. If a block violates this contract, it is not a block — it is a script.

## What is a block?

A block is a **small, reusable, tested library module** that does one thing well. Blocks are the atoms of every micro-lab repo. Labs compose blocks into working applications.

```
blocks/config   → loads configuration from env/files/defaults
blocks/logging  → structured logging with consistent format
blocks/errors   → typed error handling with context

labs/01_cli     → composes config + logging + errors into a working CLI
```

Blocks are **imported, not executed**. A block is a library, not a script. You `use`, `import`, or `require` a block — you never `bash run` it directly.

---

## The contract (all six rules are mandatory)

### Rule 1: Explicit initialization with Config

Every block exposes a public constructor or init function that accepts a configuration struct/object. No global state. No implicit setup.

```rust
// Rust
pub fn new(config: &Config) -> Result<Logger, BlockError>
```

```go
// Go
func New(cfg Config) (*Logger, error)
```

```python
# Python
def __init__(self, config: Config) -> None:
```

```typescript
// TypeScript
export function create(config: Config): Logger
```

**Why:** Blocks that silently read global state are impossible to test, impossible to compose, and impossible to run two instances of side by side.

### Rule 2: Structured logging (not raw print)

Blocks MUST use the repo's logging block (or the language's structured logging standard) for all output. No `println!`, no `fmt.Println`, no bare `print()`, no `console.log` in library code.

Acceptable:

| Language   | Logging approach                        |
|------------|-----------------------------------------|
| Rust       | `tracing` crate with structured fields  |
| Go         | `slog` (stdlib) with structured fields  |
| Python     | `structlog` or stdlib `logging` with JSON formatter |
| TypeScript | `pino` or a thin wrapper with JSON output |

**Why:** Structured logs are parseable. Print statements are noise. When a lab composes three blocks, their logs need to be filterable by source.

### Rule 3: Typed errors with context

Blocks MUST return typed errors. No panics. No untyped exceptions. No `unwrap()` in library code. No bare `raise Exception("something broke")`.

| Language   | Error pattern                                             |
|------------|-----------------------------------------------------------|
| Rust       | Custom `enum BlockError` implementing `std::error::Error` via `thiserror` |
| Go         | Sentinel errors + `fmt.Errorf("context: %w", err)` wrapping |
| Python     | Custom exception hierarchy: `class BlockError(Exception)` with subclasses |
| TypeScript | Custom error classes extending `Error`, or a `Result<T, E>` pattern |

Every error MUST carry enough context to diagnose without a debugger:

```rust
// Good
Err(BlockError::ConfigMissing { key: "API_KEY", source: "environment" })

// Bad
Err("config error")
```

**Why:** When a lab composes three blocks and something fails, the error must say which block, which operation, and what was missing — without reading source code.

### Rule 4: Tested without network access

Every block MUST have at least one test that passes with no network, no database, no external service. If a block talks to an external API, it must be testable with a mock or stub.

```bash
# This must work in a fresh CI container with no secrets configured
cargo test --workspace
go test ./...
pytest
npx vitest run
```

**Why:** Tests that need network access are flaky in CI, slow locally, and untestable on planes. The block contract guarantees that `selftest.sh` always works.

### Rule 5: Importable as a library

A block is usable by importing it into another module. It is NOT only usable as a CLI or standalone binary. If you can't write `import blocks.config` or `use blocks::config`, it's not a block.

The entry point for each block should be obvious:

| Language   | Import path convention                     |
|------------|--------------------------------------------|
| Rust       | `use __REPO_NAME__::blocks::config::Config;` (via workspace crate) |
| Go         | `import "__MODULE_PATH__/internal/blocks/config"` |
| Python     | `from __PKG__.blocks.config import Config` |
| TypeScript | `import { Config } from "./blocks/config"` |

**Why:** Labs compose blocks via imports. If a block can only run as a subprocess, composition means shelling out, which means losing type safety, error propagation, and structured logging.

### Rule 6: README with purpose, usage, and dependencies

Every block directory contains a `README.md` with exactly these sections:

```markdown
# config

One-line description of what this block does.

## Usage

\`\`\`<language>
// Minimal working example showing import + init + one operation
\`\`\`

## Configuration

| Variable       | Required | Default | Description          |
|----------------|----------|---------|----------------------|
| `APP_ENV`      | no       | `dev`   | Runtime environment  |
| `LOG_LEVEL`    | no       | `info`  | Logging verbosity    |

## Dependencies

List of external crates/modules this block requires (not stdlib).
```

**Why:** A block without a README forces you to read source code to use it. That kills velocity when you have 60 blocks across 10 repos.

---

## The SHOULD list (strongly recommended, not mandatory in v1)

These are patterns blocks SHOULD follow. They are not enforced by selftest, but they prevent pain at scale.

7. **Accept configuration via multiple sources** with a clear priority order: function args → environment variables → `.env` file → config file → hardcoded defaults. Never require only one source.

8. **Export a version constant.** Helps with debugging when blocks are composed across repos.

   ```rust
   pub const VERSION: &str = env!("CARGO_PKG_VERSION");
   ```

9. **Be stateless where possible.** If a block must hold state (connection pools, caches), make the state explicit in a struct — never in module-level globals.

10. **Use the language's standard formatting.** `cargo fmt`, `gofmt`, `ruff format`, `prettier`. No debates. The template enforces this via CI.

---

## How blocks relate to labs

```
┌─────────────────────────────────────────┐
│  Lab (01_cli, 02_server, etc.)          │
│                                         │
│  Composes blocks into a working app.    │
│  Has a main() or entrypoint.            │
│  May have its own config/args.          │
│  Is the thing a user actually runs.     │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │ config  │ │ logging │ │ errors   │  │
│  │ (block) │ │ (block) │ │ (block)  │  │
│  └─────────┘ └─────────┘ └──────────┘  │
└─────────────────────────────────────────┘
```

- **Blocks** are libraries. They export functions/types. They have no `main()`.
- **Labs** are applications. They have `main()`. They import blocks.
- A lab MAY import blocks from other repos (that's the whole point of the "LEGO blocks" system).
- A block MUST NOT import from a lab. Dependencies flow one direction: labs → blocks.

---

## Checklist for adding a new block

- [ ] Does it have a public init/constructor that accepts a Config?
- [ ] Does it use structured logging (not print)?
- [ ] Does it return typed errors with context?
- [ ] Does it have at least one test that works offline?
- [ ] Is it importable as a library?
- [ ] Does it have a README with usage example?
- [ ] Does it pass the repo's lint + format checks?

If all boxes are checked, it's a block. Ship it.
