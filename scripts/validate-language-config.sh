#!/usr/bin/env bash
# Validate config/languages.json structure and referenced template paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

CONFIG_PATH="${1:-$REPO_ROOT/config/languages.json}"

[[ -f "$CONFIG_PATH" ]] || die "Language manifest not found: $CONFIG_PATH"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  die "python3 or python is required to validate language manifest"
fi

info "Validating language manifest: $CONFIG_PATH"

"$PYTHON_BIN" - "$CONFIG_PATH" "$REPO_ROOT" <<'PY'
import json
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])

errors = []

try:
    payload = json.loads(config_path.read_text(encoding="utf-8"))
except Exception as exc:  # noqa: BLE001
    print(f"[ERROR] Failed to parse JSON: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(payload, dict):
    errors.append("Top-level JSON must be an object")

version = payload.get("version") if isinstance(payload, dict) else None
if not isinstance(version, int) or version < 1:
    errors.append("`version` must be an integer >= 1")

languages = payload.get("languages") if isinstance(payload, dict) else None
if not isinstance(languages, list) or not languages:
    errors.append("`languages` must be a non-empty array")

required_lang_keys = {"id", "template_dir", "toolchains", "commands"}
required_commands = {"format_check", "lint", "test", "run"}
ids = set()

if isinstance(languages, list):
    for idx, lang in enumerate(languages):
        prefix = f"languages[{idx}]"

        if not isinstance(lang, dict):
            errors.append(f"{prefix} must be an object")
            continue

        missing_keys = sorted(required_lang_keys - set(lang.keys()))
        if missing_keys:
            errors.append(f"{prefix} missing keys: {missing_keys}")
            continue

        lang_id = lang.get("id")
        if not isinstance(lang_id, str) or not lang_id.strip():
            errors.append(f"{prefix}.id must be a non-empty string")
        elif lang_id in ids:
            errors.append(f"Duplicate language id: {lang_id}")
        else:
            ids.add(lang_id)

        template_dir = lang.get("template_dir")
        if not isinstance(template_dir, str) or not template_dir.strip():
            errors.append(f"{prefix}.template_dir must be a non-empty string")
        else:
            template_path = repo_root / template_dir
            if not template_path.is_dir():
                errors.append(f"{prefix}.template_dir does not exist: {template_dir}")

        toolchains = lang.get("toolchains")
        if not isinstance(toolchains, list) or not toolchains:
            errors.append(f"{prefix}.toolchains must be a non-empty array")
        elif any(not isinstance(x, str) or not x.strip() for x in toolchains):
            errors.append(f"{prefix}.toolchains entries must be non-empty strings")

        commands = lang.get("commands")
        if not isinstance(commands, dict):
            errors.append(f"{prefix}.commands must be an object")
        else:
            missing_cmds = sorted(required_commands - set(commands.keys()))
            if missing_cmds:
                errors.append(f"{prefix}.commands missing keys: {missing_cmds}")
            for cmd_key in required_commands:
                cmd_val = commands.get(cmd_key)
                if cmd_key in commands and (not isinstance(cmd_val, str) or not cmd_val.strip()):
                    errors.append(f"{prefix}.commands.{cmd_key} must be a non-empty string")

if errors:
    for err in errors:
        print(f"[ERROR] {err}", file=sys.stderr)
    sys.exit(1)

print(f"[INFO] Language manifest valid: {config_path}")
PY

info "Language manifest validation passed"