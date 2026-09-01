# Seguridad

## Qué ejecuta esta plantilla en tu máquina

Antes de usarla, conviene que sepas exactamente qué se ejecuta y cuándo. Esta plantilla **no es código
pasivo**: al abrir Claude Code en un repositorio creado a partir de ella, `.claude/settings.json`
registra hooks que se ejecutan automáticamente sobre tu máquina.

| Cuándo | Qué se ejecuta | Fichero |
|---|---|---|
| Tras cada `Edit`/`Write` sobre un `.py` | `uv run ruff format` · `ruff check --fix` · `ty check` | `.claude/hooks/post_edit_python_format.sh` |
| Cuando Claude termina de responder | `uv run pytest -q` | `.claude/hooks/stop_run_tests.sh` |
| Antes de cada `Edit`/`Write`/`Bash` | Comprobación de ruta; puede bloquear la acción | `.claude/hooks/pre_edit_guard_sensitive.sh` |
| Antes de cada `Edit`/`Write` del subagente `spec-verifier` | Comprobación de ruta; puede bloquear la acción | `.claude/hooks/guard-quickstart-agent.sh` |

Además, `.githooks/pre-push` (si lo activas con `git config core.hooksPath .githooks`) corre lint,
formato, tipado y tests antes de cada `push`.

Todos son scripts de shell cortos y legibles. **Léelos antes de confiar en ellos**, igual que harías con
cualquier repositorio que configure hooks. Es exactamente el mismo consejo que da la documentación de
Claude Code sobre skills y hooks de proyecto.

## Qué protegen los guards y qué no

`pre_edit_guard_sensitive.sh` bloquea escrituras sobre `migrations/**` y ficheros `.env`, incluidas las
que intentarían rodearlo vía `Bash` (`alembic`, `flyway`, `liquibase`, `dotnet ef migrations`,
`manage.py migrate`, `sed -i`, redirecciones a `.env`).

Es una **red de seguridad, no un sandbox**. Está pensada para evitar que el asistente toque por descuido
superficies de datos de producción o de secretos; no está pensada para contener a un atacante con
capacidad de ejecutar comandos arbitrarios en tu máquina. Los límites conocidos:

- Solo cubre las herramientas `Write`, `Edit` y `Bash`. Un MCP server con capacidad de escritura no pasa
  por él.
- Compara rutas por patrón, no resuelve symlinks ni rutas relativas exóticas.
- Si `jq` no está instalado, el hook **bloquea** en vez de dejar pasar (fail-closed) — pero eso significa
  que sin `jq` el harness no funciona en absoluto. Es intencionado.

## Reportar un problema

Si encuentras un fallo de seguridad en la plantilla —un guard que se puede rodear trivialmente, un hook
que ejecuta algo inesperado, una instrucción que induce a commitear secretos— **no abras un issue
público**. Usa el formulario privado de GitHub: pestaña **Security → Report a vulnerability** de este
repositorio.

Para cualquier otro fallo (documentación, inconsistencias, bugs de `bootstrap.ps1`), un issue normal es
lo correcto.

## Lo que esta plantilla no cubre

Los proyectos generados a partir de ella heredan el andamiaje, no una auditoría. El `.gitignore` incluye
`.env` y claves, y el subagente `security-reviewer` revisa las superficies sensibles de cada feature
antes del cierre — pero la seguridad del proyecto final es responsabilidad de quien lo escribe.
