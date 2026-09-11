#!/usr/bin/env bash
# PreToolUse: bloquea escrituras directas en migraciones aplicadas o ficheros de secretos, y la
# lectura de ficheros de secretos por parte del asistente.
#
# Cubre tres superficies:
#   - Write/Edit  -> se mira `file_path`: ni migraciones ni `.env`.
#   - Read/Grep   -> se mira `file_path` (Read) o `path` (Grep): solo `.env`. Leer un `.env` mete el
#                    secreto en la conversación, y de ahí al proveedor del modelo y a los logs.
#                    Las migraciones sí se pueden leer.
#   - Bash        -> se mira `command`, porque si no cualquier `alembic revision`, `sed -i`,
#                    `echo >` o `cat .env` rodearía el hook y la red de seguridad sería decorativa.
#
# Compromiso deliberado: para `migrations/` se bloquea cualquier comando Bash que mencione la ruta,
# lectura incluida. Leer una migración se hace con las herramientas Read/Grep, que aquí no se
# bloquean para migraciones. Para `.env` en Bash se bloquean la escritura y los comandos de lectura
# habituales, pero no cualquier mención, para no romper usos legítimos como
# `docker compose --env-file .env.dev`. `.env.example`/`.sample`/`.template` se permiten siempre:
# son plantillas, no secretos.
#
# FAIL-CLOSED a propósito: si falta `jq` o el JSON de entrada no se puede interpretar, este hook
# BLOQUEA en vez de dejar pasar. Un PreToolUse que sale con un código distinto de 2 es un error no
# bloqueante para Claude Code — la acción se permitiría igualmente —, así que un guard que "falla
# hacia fuera" sería puramente decorativo justo cuando más falta hace.
#
# Es una red de seguridad, no un sandbox: ver SECURITY.md para sus límites conocidos.
set -uo pipefail

block() {
  echo "Acción bloqueada: $1 requiere confirmación humana explícita (migraciones/secretos)." >&2
  exit 2   # exit code 2 = bloquea la acción
}

if ! command -v jq >/dev/null 2>&1; then
  echo "Guard de ficheros sensibles: no se encuentra 'jq', así que no se puede comprobar la ruta." >&2
  echo "Se bloquea por precaución. Instálalo y repite: winget install jqlang.jq (Windows) | sudo apt install jq | brew install jq" >&2
  exit 2
fi

INPUT="$(cat)"

if ! TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"; then
  echo "Guard de ficheros sensibles: no se pudo interpretar el JSON de entrada. Se bloquea por precaución." >&2
  exit 2
fi
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"

# Las rutas llegan con el separador nativo del sistema: en Windows, `H:\proyecto\migrations\001.py`.
# Se normalizan a `/` SOLO para comparar, nunca para ejecutar nada.
FILE_PATH_NORM="${FILE_PATH//\\//}"
COMMAND_NORM="${COMMAND//\\//}"

# ¿Es un fichero de secretos? Las plantillas sin secretos no cuentan.
is_env_file() {
  local base="${1##*/}"
  case "$base" in
    .env.example|.env.sample|.env.template) return 1 ;;
    .env|.env.*|*.env)                       return 0 ;;
  esac
  return 1
}

# --- Write / Edit / Read / Grep ---------------------------------------------
if [[ -n "$FILE_PATH_NORM" ]]; then
  case "$TOOL_NAME" in
    Read|Grep)
      is_env_file "$FILE_PATH_NORM" && block "leer $FILE_PATH (contiene secretos; usa .env.example para ver qué variables hay)"
      ;;
    *)
      case "$FILE_PATH_NORM" in
        */migrations/*|migrations/*) block "$FILE_PATH" ;;
      esac
      is_env_file "$FILE_PATH_NORM" && block "$FILE_PATH"
      ;;
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

  # Las plantillas .env.example/.sample/.template no cuentan ni para escribir ni para leer.
  if ! printf '%s' "$COMMAND_NORM" | grep -Eq '\.env\.(example|sample|template)([[:space:]]|$)'; then
    # .env como destino de escritura.
    if printf '%s' "$COMMAND_NORM" | grep -Eq '>>?[[:space:]]*[^[:space:]|;&]*\.env|(tee|cp|mv)[[:space:]]+[^|;&]*[[:space:]][^[:space:]|;&]*\.env|sed[[:space:]]+-i[^|;&]*\.env'; then
      block "el comando (escribe en un fichero .env)"
    fi
    # .env como origen de lectura con los comandos habituales.
    if printf '%s' "$COMMAND_NORM" | grep -Eqi '(^|[[:space:];&|(])(cat|less|more|head|tail|type|get-content|gc|grep|rg|findstr|source)[[:space:]][^|;&]*\.env'; then
      block "el comando (lee un fichero .env)"
    fi
  fi
fi

exit 0
