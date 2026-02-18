// Package config loads application configuration from environment variables
// with .env file fallback and sensible defaults.
package config

import (
	"os"

	blockerrors "github.com/__ORG__/__REPO_NAME__/internal/blocks/errors"
	"github.com/joho/godotenv"
)

// Config holds application configuration.
type Config struct {
	// AppEnv is the runtime environment: dev, staging, production.
	AppEnv string

	// LogLevel controls logging verbosity: debug, info, warn, error.
	LogLevel string

	// AppName is used in structured log output.
	AppName string
}

// Load reads config from environment variables, falling back to .env file, then defaults.
func Load() (*Config, error) {
	// Best-effort .env loading — missing file is fine
	_ = godotenv.Load()

	cfg := &Config{
		AppEnv:   getEnvOrDefault("APP_ENV", "dev"),
		LogLevel: getEnvOrDefault("LOG_LEVEL", "info"),
		AppName:  getEnvOrDefault("APP_NAME", "__REPO_NAME__"),
	}

	// Validate log level
	switch cfg.LogLevel {
	case "debug", "info", "warn", "error":
		// valid
	default:
		return nil, &blockerrors.ConfigInvalidError{
			Key:    "LOG_LEVEL",
			Reason: "must be one of: debug, info, warn, error",
		}
	}

	return cfg, nil
}

func getEnvOrDefault(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
