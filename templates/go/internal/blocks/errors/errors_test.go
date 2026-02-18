package errors

import (
	"errors"
	"strings"
	"testing"
)

func TestConfigMissingErrorContainsKey(t *testing.T) {
	err := &ConfigMissingError{Key: "API_KEY"}
	if !strings.Contains(err.Error(), "API_KEY") {
		t.Errorf("expected error to contain key name, got: %s", err.Error())
	}
}

func TestConfigMissingErrorUnwraps(t *testing.T) {
	err := &ConfigMissingError{Key: "API_KEY"}
	if !errors.Is(err, ErrConfigMissing) {
		t.Error("expected ConfigMissingError to unwrap to ErrConfigMissing")
	}
}

func TestConfigInvalidErrorContainsReason(t *testing.T) {
	err := &ConfigInvalidError{Key: "PORT", Reason: "must be a number"}
	msg := err.Error()
	if !strings.Contains(msg, "PORT") || !strings.Contains(msg, "must be a number") {
		t.Errorf("expected error to contain key and reason, got: %s", msg)
	}
}

func TestConfigInvalidErrorUnwraps(t *testing.T) {
	err := &ConfigInvalidError{Key: "PORT", Reason: "must be a number"}
	if !errors.Is(err, ErrConfigInvalid) {
		t.Error("expected ConfigInvalidError to unwrap to ErrConfigInvalid")
	}
}
