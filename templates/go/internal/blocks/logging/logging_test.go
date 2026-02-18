package logging

import (
	"log/slog"
	"testing"

	"github.com/__ORG__/__REPO_NAME__/internal/blocks/config"
)

func TestNewReturnsLogger(t *testing.T) {
	cfg := &config.Config{
		AppEnv:   "dev",
		LogLevel: "info",
		AppName:  "test-app",
	}
	logger := New(cfg)
	if logger == nil {
		t.Fatal("expected non-nil logger")
	}
}

func TestParseLevelMapsCorrectly(t *testing.T) {
	tests := []struct {
		input string
		want  slog.Level
	}{
		{"debug", slog.LevelDebug},
		{"info", slog.LevelInfo},
		{"warn", slog.LevelWarn},
		{"error", slog.LevelError},
		{"unknown", slog.LevelInfo},
	}

	for _, tt := range tests {
		got := parseLevel(tt.input)
		if got != tt.want {
			t.Errorf("parseLevel(%q) = %v, want %v", tt.input, got, tt.want)
		}
	}
}
