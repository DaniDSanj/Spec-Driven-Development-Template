#!/usr/bin/env bash
# Stop: antes de dar la tarea por cerrada, corre la suite de tests y devuelve el resultado a Claude.
#
# A diferencia de los dos guards de PreToolUse, este hook falla EN ABIERTO a propósito: si no puede
# comprobar algo, deja que la sesión termine. Aquí "bloquear" (exit 2) significa "no pares, sigue
# trabajando", así que un fallo del propio hook que bloqueara dejaría la sesión en bucle.
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

INPUT="$(cat)"

# Protección de bucle: si ya venimos de un Stop bloqueado por este mismo hook, no lo repetimos.
# Sin esto, unos tests que Claude no consigue arreglar reenganchan la sesión indefinidamente.
if command -v jq >/dev/null 2>&1; then
  STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)"
  if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    exit 0
  fi
fi

# Si el proyecto aun no esta inicializado (sin pyproject.toml o sin src/), `uv run pytest` no
# encuentra el interprete/dependencias y falla con "program not found", lo cual no es un fallo de
# test real. Mismo criterio que el step "Check project is initialized" de .github/workflows/ci.yml.
if [[ ! -f "$PROJECT_DIR/pyproject.toml" ]] || [[ ! -d "$PROJECT_DIR/src" ]]; then
  exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "No se encuentra 'uv', así que no se han podido correr los tests." >&2
  exit 0
fi

uv run pytest -q
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
  echo "Los tests han fallado. No des la tarea por cerrada hasta corregirlos." >&2
  exit 2   # exit code 2 = bloquea y devuelve el mensaje a Claude como feedback
fi

exit 0
