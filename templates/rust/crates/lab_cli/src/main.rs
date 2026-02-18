use blocks::config::Config;
use blocks::errors::BlockError;

fn run() -> Result<(), BlockError> {
    let config = Config::load()?;
    blocks::logging::init(&config)?;

    tracing::info!(
        app_name = %config.app_name,
        app_env = %config.app_env,
        "lab_cli started"
    );

    tracing::info!("all blocks initialized successfully");
    Ok(())
}

fn main() {
    if let Err(e) = run() {
        eprintln!("error: {e}");
        std::process::exit(1);
    }
}
