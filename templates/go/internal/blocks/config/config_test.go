package config

import (
	"errors"
	"os"
	"testing"

	blockerrors "github.com/__ORG__/__REPO_NAME__/internal/blocks/errors"
)

func TestLoadReturnsDefaults(t *testing.T) {
	os.Unsetenv("APP_ENV")
	os.Unsetenv("LOG_LEVEL")
	os.Unsetenv("APP_NAME")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if cfg.AppEnv != "dev" {
		t.Errorf("expected AppEnv=dev, got %s", cfg.AppEnv)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("expected LogLevel=info, got %s", cfg.LogLevel)
	}
}

func TestLoadReadsEnvOverride(t *testing.T) {
	os.Setenv("APP_ENV", "production")
	defer os.Unsetenv("APP_ENV")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if cfg.AppEnv != "production" {
		t.Errorf("expected AppEnv=production, got %s", cfg.AppEnv)
	}
}

func TestLoadRejectsInvalidLogLevel(t *testing.T) {
	os.Setenv("LOG_LEVEL", "verbose")
	defer os.Unsetenv("LOG_LEVEL")

	_, err := Load()
	if err == nil {
		t.Fatal("expected error for invalid log level")
	}
	if !errors.Is(err, blockerrors.ErrConfigInvalid) {
		t.Errorf("expected ErrConfigInvalid, got: %v", err)
	}
}
