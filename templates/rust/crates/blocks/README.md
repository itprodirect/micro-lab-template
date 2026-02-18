# blocks

Reusable library modules for __REPO_NAME__. Every block follows the [block contract](https://github.com/__ORG__/micro-lab-template/blob/main/docs/block-contract.md).

## Modules

### config

Loads application configuration from environment variables → `.env` file → defaults.

```rust
use blocks::config::Config;

let config = Config::load()?;
println!("env: {}", config.app_env);
```

| Variable    | Required | Default           | Description            |
|-------------|----------|-------------------|------------------------|
| `APP_ENV`   | no       | `dev`             | Runtime environment    |
| `LOG_LEVEL` | no       | `info`            | Logging verbosity      |
| `APP_NAME`  | no       | crate name        | Name in log output     |

### logging

Initializes structured logging. Pretty output in dev, JSON in production.

```rust
use blocks::config::Config;
use blocks::logging;

let config = Config::load()?;
logging::init(&config)?;
tracing::info!("started");
```

### errors

Typed error enum shared across all blocks.

```rust
use blocks::errors::BlockError;

fn example() -> Result<(), BlockError> {
    Err(BlockError::ConfigMissing { key: "API_KEY".into() })
}
```

## Dependencies

- `thiserror` — derive macro for error types
- `serde` — config deserialization
- `dotenvy` — `.env` file loading
- `tracing` + `tracing-subscriber` — structured logging
