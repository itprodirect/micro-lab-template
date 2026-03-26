package config

import (
	"errors"
	"os"
	"testing"

	blockerrors "github.com/__ORG__/__REPO_NAME__/internal/blocks/errors"
)

func TestLoadReturnsDefaults(t *testing.T) {
	clearConfigEnv(t)
	chdirTempDir(t, t.TempDir())

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
	clearConfigEnv(t)
	os.Setenv("APP_ENV", "production")
	t.Cleanup(func() {
		os.Unsetenv("APP_ENV")
	})
	chdirTempDir(t, t.TempDir())

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if cfg.AppEnv != "production" {
		t.Errorf("expected AppEnv=production, got %s", cfg.AppEnv)
	}
}

func TestLoadRejectsInvalidLogLevel(t *testing.T) {
	clearConfigEnv(t)
	os.Setenv("LOG_LEVEL", "verbose")
	t.Cleanup(func() {
		os.Unsetenv("LOG_LEVEL")
	})
	chdirTempDir(t, t.TempDir())

	_, err := Load()
	if err == nil {
		t.Fatal("expected error for invalid log level")
	}
	if !errors.Is(err, blockerrors.ErrConfigInvalid) {
		t.Errorf("expected ErrConfigInvalid, got: %v", err)
	}
}

func TestLoadReadsDotEnvForLocalDevelopment(t *testing.T) {
	tempDir := t.TempDir()
	chdirTempDir(t, tempDir)
	clearConfigEnv(t)

	err := os.WriteFile(".env", []byte("APP_ENV=dev\nLOG_LEVEL=debug\nAPP_NAME=dotenv-app\n"), 0o600)
	if err != nil {
		t.Fatalf("write .env: %v", err)
	}

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if cfg.AppEnv != "dev" {
		t.Fatalf("expected AppEnv from .env, got %s", cfg.AppEnv)
	}
	if cfg.LogLevel != "debug" {
		t.Fatalf("expected LogLevel from .env, got %s", cfg.LogLevel)
	}
	if cfg.AppName != "dotenv-app" {
		t.Fatalf("expected AppName from .env, got %s", cfg.AppName)
	}
}

func TestLoadIgnoresDotEnvForNonLocalEnv(t *testing.T) {
	tempDir := t.TempDir()
	chdirTempDir(t, tempDir)
	clearConfigEnv(t)

	err := os.WriteFile(".env", []byte("APP_ENV=production\nLOG_LEVEL=debug\nAPP_NAME=dotenv-app\n"), 0o600)
	if err != nil {
		t.Fatalf("write .env: %v", err)
	}

	cfg, err := Load()
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}
	if cfg.AppEnv != "dev" {
		t.Fatalf("expected AppEnv default when .env is ignored, got %s", cfg.AppEnv)
	}
	if cfg.LogLevel != "info" {
		t.Fatalf("expected LogLevel default when .env is ignored, got %s", cfg.LogLevel)
	}
	if cfg.AppName != "__REPO_NAME__" {
		t.Fatalf("expected AppName default when .env is ignored, got %s", cfg.AppName)
	}
}

func clearConfigEnv(t *testing.T) {
	t.Helper()
	restoreEnvVar(t, "APP_ENV")
	restoreEnvVar(t, "LOG_LEVEL")
	restoreEnvVar(t, "APP_NAME")
	os.Unsetenv("APP_ENV")
	os.Unsetenv("LOG_LEVEL")
	os.Unsetenv("APP_NAME")
}

func restoreEnvVar(t *testing.T, key string) {
	t.Helper()
	value, ok := os.LookupEnv(key)
	t.Cleanup(func() {
		if ok {
			os.Setenv(key, value)
			return
		}
		os.Unsetenv(key)
	})
}

func chdirTempDir(t *testing.T, dir string) {
	t.Helper()
	originalDir, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	if err := os.Chdir(dir); err != nil {
		t.Fatalf("chdir: %v", err)
	}
	t.Cleanup(func() {
		if err := os.Chdir(originalDir); err != nil {
			t.Fatalf("restore dir: %v", err)
		}
	})
}
