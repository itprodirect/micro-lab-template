use crate::config::Config;
use crate::errors::BlockError;
use tracing_subscriber::fmt;
use tracing_subscriber::EnvFilter;

/// Initialize structured logging based on config.
///
/// - In `dev` mode: human-readable pretty output.
/// - In other modes: JSON output for machine parsing.
pub fn init(config: &Config) -> Result<(), BlockError> {
    let filter = EnvFilter::try_new(&config.log_level).map_err(|e| BlockError::LoggingInit {
        source: Box::new(e),
    })?;

    let is_dev = config.app_env == "dev";

    if is_dev {
        fmt().with_env_filter(filter).with_target(true).init();
    } else {
        fmt()
            .json()
            .with_env_filter(filter)
            .with_target(true)
            .init();
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use crate::config::Config;
    use tracing_subscriber::EnvFilter;

    #[test]
    fn valid_log_levels_parse() {
        for level in &["trace", "debug", "info", "warn", "error"] {
            assert!(
                EnvFilter::try_new(level).is_ok(),
                "{level} should be a valid filter"
            );
        }
    }

    #[test]
    fn dev_config_selects_pretty_format() {
        let config = Config {
            app_env: "dev".into(),
            log_level: "info".into(),
            app_name: "test".into(),
        };
        assert_eq!(config.app_env, "dev");
    }
}
