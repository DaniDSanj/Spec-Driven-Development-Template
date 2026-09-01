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
# `docker compose --env-file .env.dev`. `.env.example` se permite: es plantilla, no secreto.
#
# FAIL-CLOSED a propósito: si falta `jq` o el JSON de entrada no se puede interpretar, este hook
# BLOQUEA en vez de dejar pasar. Un PreToolUse que sale con un código distinto de 2 es un error no
# bloqueante para Claude Code — la acción se permitiría igualmente —, así que un guard que "falla
# hacia fuera" sería puramente decorativo justo cuando más falta hace.
#
# Es una red de seguridad, no un sandbox: ver SECURITY.md para sus límites conocidos.
set -uo pipefail

block() {
  echo "Escritura bloqueada: $1 requiere confirmación humana explícita (migraciones/secretos)." >&2
  exit 2   # exit code 2 = bloquea la acción
}

if ! command -v jq >/dev/null 2>&1; then
  echo "Guard de ficheros sensibles: no se encuentra 'jq', así que no se puede comprobar la ruta." >&2
  echo "Se bloquea por precaución. Instálalo y repite: winget install jqlang.jq (Windows) | sudo apt install jq | brew install jq" >&2
  exit 2
fi

INPUT="$(cat)"

if ! FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"; then
  echo "Guard de ficheros sensibles: no se pudo interpretar el JSON de entrada. Se bloquea por precaución." >&2
  exit 2
fi
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"

# Las rutas llegan con el separador nativo del sistema: en Windows, `H:\proyecto\migrations\001.py`.
# Se normalizan a `/` SOLO para comparar, nunca para ejecutar nada.
FILE_PATH_NORM="${FILE_PATH//\\//}"
COMMAND_NORM="${COMMAND//\\//}"

# --- Write / Edit -----------------------------------------------------------
if [[ -n "$FILE_PATH_NORM" ]]; then
  case "$FILE_PATH_NORM" in
    */migrations/*|migrations/*) block "$FILE_PATH" ;;
  esac

  BASENAME="${FILE_PATH_NORM##*/}"
  case "$BASENAME" in
    .env.example|.env.sample|.env.template) : ;;   # plantillas sin secretos: permitidas
    .env|.env.*|*.env)                       block "$FILE_PATH" ;;
  esac
fi

# --- Bash -------------------------------------------------------------------
if [[ -n "$COMMAND_NORM" ]]; then
  # Cualquier mención a un directorio de migraciones.
  if [[ "$COMMAND_NORM" == *"migrations/"* ]]; then
    block "el comando (toca migrations/)"
  fi

  # Herramientas de migración, con o sin la ruta escrita.
  if printf '%s' "$COMMAND_NORM" | grep -Eqi '(^|[[:space:]])(alembic|flyway|liquibase)([[:space:]]|$)|dotnet[[:space:]]+ef[[:space:]]+migrations|manage\.py[[:space:]]+migrate'; then
    block "el comando (herramienta de migraciones)"
  fi

  # .env solo como destino de escritura, y sin contar las plantillas .env.example/.sample/.template.
  if printf '%s' "$COMMAND_NORM" | grep -Eq '>>?[[:space:]]*[^[:space:]|;&]*\.env|(tee|cp|mv)[[:space:]]+[^|;&]*[[:space:]][^[:space:]|;&]*\.env|sed[[:space:]]+-i[^|;&]*\.env' \
     && ! printf '%s' "$COMMAND_NORM" | grep -Eq '\.env\.(example|sample|template)([[:space:]]|$)'; then
    block "el comando (escribe en un fichero .env)"
  fi
fi

exit 0
