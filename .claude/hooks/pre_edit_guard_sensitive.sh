#!/usr/bin/env bash
# PreToolUse: bloquea escrituras directas en migraciones aplicadas o ficheros de secretos.
#
# Cubre dos superficies:
#   - Write/Edit  -> se mira `file_path`.
#   - Bash        -> se mira `command`, porque si no cualquier `alembic revision`,
#                    `sed -i` o `echo >` rodearía el hook y la red de seguridad sería decorativa.
#
# Compromiso deliberado: para `migrations/` se bloquea cualquier comando Bash que mencione la ruta,
# lectura incluida. Leer una migración se hace con las herramientas Read/Grep, que no pasan por aquí.
# Para `.env` se bloquea solo cuando es destino de escritura, para no romper usos legítimos como
# `docker compose --env-file .env.dev`.
set -euo pipefail

INPUT="$(cat)"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

block() {
  echo "Escritura bloqueada: $1 requiere confirmación humana explícita (migraciones/secretos)." >&2
  exit 2   # exit code 2 = bloquea la acción
}

# --- Write / Edit -----------------------------------------------------------
if [[ -n "$FILE_PATH" ]]; then
  if [[ "$FILE_PATH" == *"/migrations/"* ]] || [[ "$FILE_PATH" == *.env* ]]; then
    block "$FILE_PATH"
  fi
fi

# --- Bash -------------------------------------------------------------------
if [[ -n "$COMMAND" ]]; then
  # Cualquier mención a un directorio de migraciones.
  if [[ "$COMMAND" == *"migrations/"* ]]; then
    block "el comando (toca migrations/)"
  fi

  # Herramientas de migración, con o sin la ruta escrita.
  if printf '%s' "$COMMAND" | grep -Eqi '(^|[[:space:]])(alembic|flyway|liquibase)([[:space:]]|$)|dotnet[[:space:]]+ef[[:space:]]+migrations|manage\.py[[:space:]]+migrate'; then
    block "el comando (herramienta de migraciones)"
  fi

  # .env solo como destino de escritura.
  if printf '%s' "$COMMAND" | grep -Eq '>>?[[:space:]]*[^[:space:]|;&]*\.env|(tee|cp|mv)[[:space:]]+[^|;&]*[[:space:]][^[:space:]|;&]*\.env|sed[[:space:]]+-i[^|;&]*\.env'; then
    block "el comando (escribe en un fichero .env)"
  fi
fi

exit 0
