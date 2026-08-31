#!/bin/bash
# .claude/hooks/guard-quickstart-agent.sh
#
# Bloquea cualquier Write o Edit del subagente spec-verifier que no vaya
# dirigido a un fichero llamado exactamente "quickstart_agent.md".
# Recibe el input del hook por stdin (JSON) y sale con código 2 para
# bloquear la operación, o 0 para permitirla.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Si la herramienta no lleva file_path (no debería pasar con Write/Edit),
# no bloqueamos por precaución de no romper el flujo por un formato
# inesperado — pero esto no debería ocurrir en la práctica.
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

BASENAME=$(basename "$FILE_PATH")

if [ "$BASENAME" != "quickstart_agent.md" ]; then
  echo "Bloqueado: spec-verifier solo tiene permiso de escritura sobre quickstart_agent.md. Intento sobre: $FILE_PATH" >&2
  exit 2
fi

exit 0
