use crate::errors::BlockError;
use serde::Deserialize;

/// Application configuration loaded from environment variables with `.env` fallback.
#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// Runtime environment: dev, staging, production
    #[serde(default = "default_app_env")]
    pub app_env: String,

    /// Logging level: trace, debug, info, warn, error
    #[serde(default = "default_log_level")]
    pub log_level: String,

    /// Application name used in structured log output
    #[serde(default = "default_app_name")]
    pub app_name: String,
}

fn default_app_env() -> String {
    "dev".into()
}

fn default_log_level() -> String {
    "info".into()
}

fn default_app_name() -> String {
    env!("CARGO_PKG_NAME").into()
}

impl Config {
    /// Load config from environment variables, falling back to `.env` file, then defaults.
    pub fn load() -> Result<Self, BlockError> {
        // Best-effort .env loading — missing file is fine
        let _ = dotenvy::dotenv();

        Ok(Config {
            app_env: std::env::var("APP_ENV").unwrap_or_else(|_| default_app_env()),
            log_level: std::env::var("LOG_LEVEL").unwrap_or_else(|_| default_log_level()),
            app_name: std::env::var("APP_NAME").unwrap_or_else(|_| default_app_name()),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_are_sensible() {
        assert_eq!(default_app_env(), "dev");
        assert_eq!(default_log_level(), "info");
        assert!(!default_app_name().is_empty());
    }

    #[test]
    fn config_fields_are_public() {
        let config = Config {
            app_env: "test".into(),
            log_level: "debug".into(),
            app_name: "myapp".into(),
        };
        assert_eq!(config.app_env, "test");
        assert_eq!(config.log_level, "debug");
        assert_eq!(config.app_name, "myapp");
    }
}
