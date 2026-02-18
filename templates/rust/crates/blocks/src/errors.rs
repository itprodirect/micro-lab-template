use thiserror::Error;

/// Typed errors for all blocks. Every block function returns `Result<T, BlockError>`.
#[derive(Debug, Error)]
pub enum BlockError {
    #[error("config key missing: {key}")]
    ConfigMissing { key: String },

    #[error("config key invalid: {key} — {reason}")]
    ConfigInvalid { key: String, reason: String },

    #[error("logging initialization failed")]
    LoggingInit {
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_missing_displays_key() {
        let err = BlockError::ConfigMissing {
            key: "API_KEY".into(),
        };
        assert!(err.to_string().contains("API_KEY"));
    }

    #[test]
    fn config_invalid_displays_reason() {
        let err = BlockError::ConfigInvalid {
            key: "PORT".into(),
            reason: "must be a number".into(),
        };
        let msg = err.to_string();
        assert!(msg.contains("PORT"));
        assert!(msg.contains("must be a number"));
    }
}
