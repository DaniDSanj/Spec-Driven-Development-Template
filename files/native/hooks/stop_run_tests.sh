#!/usr/bin/env bash
# Stop: antes de dar la tarea por cerrada, corre la suite de tests y devuelve el resultado a Claude.
set -uo pipefail

# Si el proyecto aun no tiene pyproject.toml (ver CLAUDE.md, fase de arranque) `uv run
# pytest` no encuentra el interprete/dependencias y falla con "program not found", lo cual no es
# un fallo de test real. Igual que el step "Check for pyproject.toml" de ci.yml, nos saltamos
# pytest hasta que el proyecto este inicializado.
if [[ ! -f "$CLAUDE_PROJECT_DIR/pyproject.toml" ]]; then
  exit 0
fi

uv run pytest -q
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
  echo "Los tests han fallado. No des la tarea por cerrada hasta corregirlos." >&2
  exit 2   # exit code 2 = bloquea y devuelve el mensaje a Claude como feedback
fi

exit 0
