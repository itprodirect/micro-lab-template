// Package errors provides typed error values for all blocks.
package errors

import (
	"errors"
	"fmt"
)

// Sentinel errors for matching with errors.Is.
var (
	ErrConfigMissing = errors.New("config key missing")
	ErrConfigInvalid = errors.New("config key invalid")
	ErrLoggingInit   = errors.New("logging initialization failed")
)

// ConfigMissingError wraps ErrConfigMissing with the key name.
type ConfigMissingError struct {
	Key string
}

func (e *ConfigMissingError) Error() string {
	return fmt.Sprintf("config key missing: %s", e.Key)
}

func (e *ConfigMissingError) Unwrap() error {
	return ErrConfigMissing
}

// ConfigInvalidError wraps ErrConfigInvalid with key and reason.
type ConfigInvalidError struct {
	Key    string
	Reason string
}

func (e *ConfigInvalidError) Error() string {
	return fmt.Sprintf("config key invalid: %s — %s", e.Key, e.Reason)
}

func (e *ConfigInvalidError) Unwrap() error {
	return ErrConfigInvalid
}
