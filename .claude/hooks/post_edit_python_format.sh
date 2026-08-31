#!/usr/bin/env bash
# PostToolUse: formatea, lintea y type-checkea automáticamente cualquier .py que Claude acabe de editar.
set -euo pipefail

FILE_PATH="$(jq -r '.tool_input.file_path // empty')"

if [[ "$FILE_PATH" == *.py ]]; then
  uv run ruff format "$FILE_PATH" 2>/dev/null || true
  uv run ruff check --fix "$FILE_PATH" 2>/dev/null || true
  uv run ty check "$FILE_PATH" || true
fi

exit 0
