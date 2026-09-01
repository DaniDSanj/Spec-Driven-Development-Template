#!/usr/bin/env bash
# .claude/hooks/guard-quickstart-agent.sh
#
# Bloquea cualquier Write o Edit del subagente spec-verifier que no vaya
# dirigido a un fichero llamado exactamente "quickstart_agent.md".
# Recibe el input del hook por stdin (JSON) y sale con código 2 para
# bloquear la operación, o 0 para permitirla.
#
# Se declara en el frontmatter de .claude/agents/spec-verifier.md, no en
# .claude/settings.json: solo debe aplicar a las escrituras de ese subagente,
# no a toda la sesión.
#
# FAIL-CLOSED a propósito: si falta `jq`, si el JSON no se puede interpretar o
# si no llega `file_path`, se bloquea. Un PreToolUse que sale con un código
# distinto de 2 deja pasar la acción, así que "no he podido comprobarlo" tiene
# que significar "no" y no "adelante".
set -uo pipefail

deny() {
  echo "Bloqueado: spec-verifier solo tiene permiso de escritura sobre quickstart_agent.md. $1" >&2
  exit 2
}

if ! command -v jq >/dev/null 2>&1; then
  deny "No se encuentra 'jq' para comprobar la ruta; instálalo (winget install jqlang.jq | sudo apt install jq | brew install jq)."
fi

INPUT="$(cat)"

if ! FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"; then
  deny "No se pudo interpretar el JSON de entrada del hook."
fi

if [ -z "$FILE_PATH" ]; then
  deny "La operación no declara 'file_path', así que no se puede verificar el destino."
fi

# Las rutas llegan con el separador nativo del sistema: en Windows,
# `H:\proyecto\specs\001-x\quickstart_agent.md`. Se normalizan a `/` solo para
# extraer el nombre de fichero — `basename` sobre una ruta con `\` devolvería la
# ruta entera y este guard bloquearía absolutamente todo.
FILE_PATH_NORM="${FILE_PATH//\\//}"
BASENAME="${FILE_PATH_NORM##*/}"

if [ "$BASENAME" != "quickstart_agent.md" ]; then
  deny "Intento sobre: $FILE_PATH"
fi

exit 0
