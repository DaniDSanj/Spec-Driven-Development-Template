#!/usr/bin/env bash
# PreToolUse: bloquea escrituras directas en migraciones aplicadas o ficheros de secretos.
set -euo pipefail

FILE_PATH="$(jq -r '.tool_input.file_path // empty')"

if [[ "$FILE_PATH" == *"/migrations/"* ]] || [[ "$FILE_PATH" == *.env* ]]; then
  echo "Escritura bloqueada: $FILE_PATH requiere confirmación humana explícita (migraciones/secretos)." >&2
  exit 2   # exit code 2 = bloquea la acción
fi

exit 0
