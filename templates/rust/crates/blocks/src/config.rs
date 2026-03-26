use crate::errors::BlockError;
use serde::Deserialize;

/// Application configuration loaded from environment variables with a
/// local-development `.env` fallback.
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
    /// Load config from environment variables, optionally loading `.env` for
    /// local development, then defaults.
    pub fn load() -> Result<Self, BlockError> {
        load_dotenv_for_local_dev();

        Ok(Config {
            app_env: std::env::var("APP_ENV").unwrap_or_else(|_| default_app_env()),
            log_level: std::env::var("LOG_LEVEL").unwrap_or_else(|_| default_log_level()),
            app_name: std::env::var("APP_NAME").unwrap_or_else(|_| default_app_name()),
        })
    }
}

fn load_dotenv_for_local_dev() {
    match std::env::var("APP_ENV") {
        Ok(app_env) => {
            if is_local_app_env(&app_env) {
                // Best-effort local-dev `.env` loading; production should use real env vars.
                let _ = dotenvy::dotenv();
            }
            return;
        }
        Err(std::env::VarError::NotPresent) => {}
        Err(std::env::VarError::NotUnicode(_)) => return,
    }

    if let Ok(iter) = dotenvy::from_path_iter(".env") {
        for item in iter.flatten() {
            if item.0 == "APP_ENV" && is_local_app_env(&item.1) {
                // Best-effort local-dev `.env` loading; production should use real env vars.
                let _ = dotenvy::dotenv();
                break;
            }
        }
    }
}

fn is_local_app_env(app_env: &str) -> bool {
    matches!(
        app_env.trim().to_ascii_lowercase().as_str(),
        "dev" | "development" | "local" | "test"
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::sync::{Mutex, OnceLock};
    use std::time::{SystemTime, UNIX_EPOCH};

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

    #[test]
    fn load_reads_dotenv_for_local_development() {
        let _lock = test_lock().lock().unwrap();
        let guard = TestEnvGuard::new();
        let temp_dir = TempDirGuard::new("dotenv-local");

        clear_config_env();
        fs::write(
            temp_dir.path().join(".env"),
            "APP_ENV=dev\nLOG_LEVEL=debug\nAPP_NAME=dotenv-app\n",
        )
        .unwrap();

        let config = Config::load().unwrap();
        assert_eq!(config.app_env, "dev");
        assert_eq!(config.log_level, "debug");
        assert_eq!(config.app_name, "dotenv-app");

        drop(guard);
    }

    #[test]
    fn load_ignores_dotenv_for_non_local_env() {
        let _lock = test_lock().lock().unwrap();
        let guard = TestEnvGuard::new();
        let temp_dir = TempDirGuard::new("dotenv-production");

        clear_config_env();
        fs::write(
            temp_dir.path().join(".env"),
            "APP_ENV=production\nLOG_LEVEL=debug\nAPP_NAME=dotenv-app\n",
        )
        .unwrap();

        let config = Config::load().unwrap();
        assert_eq!(config.app_env, "dev");
        assert_eq!(config.log_level, "info");
        assert_eq!(config.app_name, default_app_name());

        drop(guard);
    }

    fn clear_config_env() {
        env::remove_var("APP_ENV");
        env::remove_var("LOG_LEVEL");
        env::remove_var("APP_NAME");
    }

    fn test_lock() -> &'static Mutex<()> {
        static LOCK: OnceLock<Mutex<()>> = OnceLock::new();
        LOCK.get_or_init(|| Mutex::new(()))
    }

    struct TestEnvGuard {
        original_dir: PathBuf,
        app_env: Option<String>,
        log_level: Option<String>,
        app_name: Option<String>,
    }

    impl TestEnvGuard {
        fn new() -> Self {
            Self {
                original_dir: env::current_dir().unwrap(),
                app_env: env::var("APP_ENV").ok(),
                log_level: env::var("LOG_LEVEL").ok(),
                app_name: env::var("APP_NAME").ok(),
            }
        }
    }

    impl Drop for TestEnvGuard {
        fn drop(&mut self) {
            env::set_current_dir(&self.original_dir).unwrap();
            restore_var("APP_ENV", self.app_env.as_deref());
            restore_var("LOG_LEVEL", self.log_level.as_deref());
            restore_var("APP_NAME", self.app_name.as_deref());
        }
    }

    fn restore_var(key: &str, value: Option<&str>) {
        match value {
            Some(value) => env::set_var(key, value),
            None => env::remove_var(key),
        }
    }

    struct TempDirGuard {
        path: PathBuf,
    }

    impl TempDirGuard {
        fn new(prefix: &str) -> Self {
            let unique = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos();
            let path = env::temp_dir().join(format!("micro-lab-template-{prefix}-{unique}"));
            fs::create_dir_all(&path).unwrap();
            env::set_current_dir(&path).unwrap();
            Self { path }
        }

        fn path(&self) -> &Path {
            &self.path
        }
    }

    impl Drop for TempDirGuard {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.path);
        }
    }
}
