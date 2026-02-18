package main

import (
	"fmt"
	"os"

	"github.com/__ORG__/__REPO_NAME__/internal/blocks/config"
	"github.com/__ORG__/__REPO_NAME__/internal/blocks/logging"
)

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("config load: %w", err)
	}

	logger := logging.New(cfg)

	logger.Info("lab_cli started",
		"app_name", cfg.AppName,
		"app_env", cfg.AppEnv,
	)

	logger.Info("all blocks initialized successfully")
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
