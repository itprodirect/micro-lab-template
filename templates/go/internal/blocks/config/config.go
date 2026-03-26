// Package config loads application configuration from environment variables
// with a local-development .env fallback and sensible defaults.
package config

import (
	"os"
	"strings"

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

// Load reads config from environment variables, optionally loading .env for local
// development, then falling back to defaults.
func Load() (*Config, error) {
	loadDotEnvForLocalDev()

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

func loadDotEnvForLocalDev() {
	if appEnv, ok := os.LookupEnv("APP_ENV"); ok {
		if isLocalAppEnv(appEnv) {
			// Best-effort local-dev .env loading; production should use real env vars.
			_ = godotenv.Load()
		}
		return
	}

	values, err := godotenv.Read()
	if err != nil {
		return
	}

	if isLocalAppEnv(values["APP_ENV"]) {
		// Best-effort local-dev .env loading; production should use real env vars.
		_ = godotenv.Load()
	}
}

func isLocalAppEnv(appEnv string) bool {
	switch strings.ToLower(strings.TrimSpace(appEnv)) {
	case "dev", "development", "local", "test":
		return true
	default:
		return false
	}
}

func getEnvOrDefault(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
