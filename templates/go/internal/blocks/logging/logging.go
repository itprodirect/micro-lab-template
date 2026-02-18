// Package logging provides structured logging using the slog standard library.
package logging

import (
	"log/slog"
	"os"

	"github.com/__ORG__/__REPO_NAME__/internal/blocks/config"
)

// New creates a structured logger based on the provided config.
// In dev mode, it uses text output. Otherwise, JSON output.
func New(cfg *config.Config) *slog.Logger {
	var handler slog.Handler

	level := parseLevel(cfg.LogLevel)

	opts := &slog.HandlerOptions{Level: level}

	if cfg.AppEnv == "dev" {
		handler = slog.NewTextHandler(os.Stderr, opts)
	} else {
		handler = slog.NewJSONHandler(os.Stderr, opts)
	}

	return slog.New(handler).With("app", cfg.AppName)
}

func parseLevel(s string) slog.Level {
	switch s {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
