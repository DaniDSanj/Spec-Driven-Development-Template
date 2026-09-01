#!/usr/bin/env bash
# PostToolUse: formatea, lintea y type-checkea automáticamente cualquier .py que Claude acabe de editar.
#
# Falla en abierto a propósito: es una comodidad, no una barrera. Si falta `jq` o `uv`, no se hace
# nada y la edición sigue su curso; lo que no puede pasar es que el hook rompa el flujo de trabajo.
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
command -v uv >/dev/null 2>&1 || exit 0

FILE_PATH="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"

if [[ "$FILE_PATH" == *.py ]]; then
  uv run ruff format "$FILE_PATH" 2>/dev/null || true
  uv run ruff check --fix "$FILE_PATH" 2>/dev/null || true
  uv run ty check "$FILE_PATH" || true
fi

exit 0
