# CLAUDE.md

Este fichero da instrucciones a Claude Code (claude.ai/code) para trabajar con el código de esta plantilla.

## Qué es esta carpeta

Esta carpeta es una **GitHub Template Repository**: el mecanismo de puesta en marcha de un proyecto nuevo es el botón "Use this template" de GitHub (o `gh repo create <nombre> --template DaniDSanj/Spec-Driven-Development-Template --clone`), no clonar ni copiar ficheros a mano desde aquí. Es la plantilla de **Spec-Driven Development (SDD)** con un stack fijo: Claude Code + GitHub Spec-Kit, Python, PostgreSQL/SQL Server, Obsidian como documentación, GitHub como control de versiones. Aquí no hay nada que compilar, lintar ni testear.

El repo mezcla dos cosas en la misma raíz:
- **Documentación de la propia plantilla** (este `CLAUDE.md`, `README.md`, `bootstrap.ps1`, `bootstrap_example.md`, `CONTRIBUTING.md`, `SECURITY.md`): solo tiene sentido mientras se está *editando la plantilla* o poniendo en marcha un proyecto nuevo; es descartable en el proyecto downstream una vez completada la puesta en marcha.
- **La carga útil de andamiaje ya en su ruta final de destino** (`.claude/`, `.specify/memory/`, `docs/`, `.githooks/`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, `.gitignore`, `.gitattributes`, `.gitleaks.toml`, `LICENSE`): esto es lo que "Use this template" entrega intacto a cada proyecto nuevo, sin ningún paso de copia.

Punto de entrada para un humano que lea esta plantilla: [`README.md`](README.md).

## Tu rol aquí

Cuando se te pida cambiar esta plantilla, estás modificando la plantilla en sí (no un proyecto downstream). Se aplican dos objetivos innegociables a cada cambio:

- Cumplir con las convenciones de la metodología SDD ya documentadas en esta carpeta.
- Mantener la consistencia interna de todos los ficheros de esta plantilla: rutas, nombres de fichero y numeración están referenciados de forma cruzada desde varios documentos (ver Arquitectura más abajo), así que renombrar o reordenar algo en un sitio obliga a propagarlo a cada lugar donde se mencione.

Reglas de comportamiento (aplican a todo el trabajo en esta plantilla):
- Haz una evaluación crítica de los requerimientos — no ejecutes sin más la primera lectura.
- No resuelvas ambigüedades de forma unilateral. Pregunta, una pregunta cada vez; al preguntar, expón las alternativas junto con una recomendación.
- Para cambios no triviales, presenta un plan y espera confirmación antes de editar.
- Tras confirmar los cambios, haz una segunda pasada de consistencia sobre esta carpeta (referencias cruzadas, concordancia de rutas/numeración) antes de dar la tarea por cerrada.

## Arquitectura

Dentro de esta carpeta:

- `README.md` — la plantilla propiamente dicha, en un único documento con estas secciones secuenciales:
  1. Primeros pasos — índice y la tabla de qué contiene cada ruta que ya viene incluida en la raíz del repo al usar "Use this template".
  2. Instalación de Spec-Kit — ejecuta `specify init --here` en el repo ya creado desde la plantilla.
  3. Configuración del harness — la puesta en marcha ordenada y de una sola vez que debe seguir un proyecto nuevo (verificar que el harness ya está presente → rellenar placeholders → generar `CLAUDE.md` → Obsidian → GitHub). Los pasos dependen del orden.
  4. Instalación de skills, subagentes y hooks — tabla de decisión skill vs. subagente vs. hook vs. `CLAUDE.md`, qué hace cada skill/agente/hook ya incluido en `.claude/`, y cómo añadir herramientas nuevas más adelante.
  5. Estructura de la plantilla — tabla de referencia rápida de qué contiene cada ruta ya incluida al usar "Use this template", y qué ficheros de la plantilla (`README.md`, `bootstrap.ps1`, `bootstrap_example.md`, `CONTRIBUTING.md`, `SECURITY.md`) son descartables tras la puesta en marcha.
  6. Principio rector de toda la plantilla — por qué todo `CLAUDE.md` que produce esta plantilla se mantiene corto: un único import de valores más la tabla de enrutado a skills, en vez de convenciones en línea.
- `bootstrap.ps1` — script PowerShell que ejecuta de un tirón el equivalente a las secciones "Instalación de Spec-Kit" y "Configuración del harness" del README (`specify init`, placeholders mecánicos, prompt de `CLAUDE.md` y, opcionalmente con `-SetupGitHub`, rama `dev`/branch protection/secret scanning con push protection/Dependabot alerts/GitHub Project); se ejecuta dentro del repo del proyecto ya creado desde la plantilla, nunca dentro de esta plantilla.
- `bootstrap_example.md` — ejemplo de invocación de `bootstrap.ps1` con todos sus parámetros, listo para copiar, editar y pegar en PowerShell 7 (`pwsh`; el script declara `#Requires -Version 7.0`).
- `CONTRIBUTING.md` — cómo se contribuye a la plantilla, con la tabla de qué hay que propagar al renombrar algo (es la formalización de la regla de consistencia de "Tu rol aquí").
- `SECURITY.md` — qué ejecuta la plantilla en la máquina de quien la usa, los límites conocidos de los guards, las capas de escaneo de secretos, la cadena de suministro del CI, el análisis estático, qué hacer si se filtra un secreto y cómo reportar un fallo de seguridad en privado.

### La carga de andamiaje (ya en su ruta final)

A diferencia de un flujo de copia entre repos, estas rutas viven ya en la raíz de este mismo repositorio, en el sitio exacto donde las necesita un proyecto downstream — "Use this template" las entrega intactas:

| Ruta | Contenido |
|---|---|
| `.claude/context/00_perfil_proyecto.md` | Los valores concretos de cada proyecto (nombre, versión de Python, motor de BD, herramienta de migraciones, visibilidad…). **Único fichero de `.claude/context/`** y único import `@` del `CLAUDE.md` downstream; lo rellena `bootstrap.ps1` y se completa a mano |
| `.claude/skills/*` | Skills recomendadas (a nivel de proyecto; `~/.claude/skills/*` es la alternativa global — gana el de proyecto en caso de colisión de nombre) |
| `.claude/agents/*` | Subagentes recomendados |
| `.claude/hooks/*.sh` + `.claude/settings.json` | Hooks recomendados. Los dos guards de `PreToolUse` son **fail-closed** (sin `jq`, o si no pueden leer la ruta, bloquean) y normalizan el separador de ruta, para funcionar igual en Windows que en Unix |
| `.githooks/pre-commit`, `.githooks/pre-push` | Red local opcional (`git config core.hooksPath .githooks`): `pre-commit` escanea secretos en staging con `gitleaks` (sin `gitleaks` instalado, avisa y deja pasar; si `gitleaks` falla, bloquea); `pre-push` corre las cinco comprobaciones de Python del job `quality` del CI (ruff/ty/pytest/pip-audit) |
| `.gitleaks.toml` | Configuración de `gitleaks`: reglas por defecto más el allowlist de las plantillas `.env.example`/`.sample`/`.template` |
| `docs/` | El esqueleto del vault de Obsidian del proyecto (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/`). Quien escribe en él son las skills `docs-*` sobre el motor `docs-manager`; las convenciones de documentación ya no son un fichero de contexto |
| `.claude/prompts/*` | La biblioteca de prompts maestros del proyecto: `01_init_project.md` (generación única del `CLAUDE.md` real) y `02_spec_development.md` (el ciclo completo de una spec, de la petición al merge) |
| `.specify/memory/*` | Estado real del proyecto, nunca método: `data-model.md` (modelo de datos canónico, con changelog y qué specs dependen de cada tabla) y `db_ideas.md` (bandeja de entrada de ideas de tabla sin feature asignada — ningún paso del ciclo la lee; el boceto de una feature concreta vive en `specs/<feature>/db_ideas.md`). Nada de esta carpeta se importa en `CLAUDE.md`. `specify init` añade aquí `constitution.md`. El protocolo de cambio de esquema ya no vive aquí: es la skill `db-model-protocol` |
| `.github/workflows/ci.yml` | Workflow de CI, estático: escaneo de secretos con `gitleaks` sobre todo el historial (siempre) y ruff/ty/pytest/pip-audit (gateados por la existencia de `pyproject.toml` y `src/`). Token de solo lectura (`permissions: contents: read`) y acciones fijadas por SHA |
| `.github/dependabot.yml` | PRs mensuales de Dependabot hacia `dev`, agrupadas por ecosistema: GitHub Actions (mantiene al día los SHA de `ci.yml`) y dependencias `uv` |
| `.gitignore` | Escrito para este stack: secretos y credenciales, datos de BD (backups, dumps, SQLite), Python, entornos `uv` (pero **no** `uv.lock`), estado local de Obsidian y `settings.local.json` |
| `.gitattributes` | Normalización de finales de línea. `*.sh text eol=lf` es lo que impide que los hooks lleguen con CRLF al clonar en Windows y `bash` los rechace |
| `LICENSE` | MIT de la plantilla. En el proyecto downstream se sustituye, no se borra |

**Tensión aceptada**: al vivir `.claude/skills/`, `.claude/agents/` y `.claude/settings.json` en la raíz de este mismo repo, Claude Code los carga también mientras se edita la propia plantilla (no un proyecto Python real). Es un efecto colateral menor y aceptado a propósito — no hay mecanismo nativo de GitHub Template para excluir rutas al generar, y los hooks no tienen nada que ejecutar sobre ficheros Markdown.

**Sobrescritura intencionada de este `CLAUDE.md`**: en el flujo downstream, el paso "Generar CLAUDE.md" (prompt `.claude/prompts/01_init_project.md`) sobrescribe este fichero con el `CLAUDE.md` real del proyecto — para entonces el humano ya no necesita las meta-instrucciones de esta plantilla.

**Separación entre perfil y convenciones**: `00_perfil_proyecto.md` contiene solo *valores* de un proyecto concreto. Las *convenciones* —iguales en todos los proyectos— ya no son ficheros de contexto: son las skills de dominio de `.claude/skills/`, que se cargan bajo demanda. Cuando una convención necesita un valor, la skill remite al perfil en vez de declarar un placeholder propio — así `bootstrap.ps1` escribe en un único sitio y no hay doble fuente de verdad. Si añades un valor configurable nuevo, va al perfil, nunca al cuerpo de una skill.

La numeración de `.claude/context/` es un residuo histórico: la migración de convenciones a skills terminó y solo queda el `00`. Los números **no se reasignan** al retirar un fichero, así que la secuencia se quedó con huecos (falta `01`, retirado con `spec-critic`; falta `02`, retirado con `docs-manager` y las skills `docs-*`; falta `03`, retirado con las skills `dev-*`; falta `04`, retirado con `database-manager` y las skills `db-*`; falta `05`, retirado con las skills `git-*`), y así se queda para que las referencias históricas sigan siendo legibles. Si añades o quitas un fichero de contexto, actualiza los dos sitios que los enumeran: `README.md` y `.claude/prompts/01_init_project.md`.

### Principio rector de los `CLAUDE.md` downstream

Todo `CLAUDE.md` que produce esta plantilla (para proyectos destino y, por extensión, este mismo fichero) se mantiene corto a propósito. La sustancia vive fuera y solo se referencia, por dos vías distintas:

- **Los valores del proyecto**, con un único import `@.claude/context/00_perfil_proyecto.md`, acompañado de una frase de "cuándo es relevante consultarlo".
- **Las convenciones de método**, con la tabla de enrutado a skills (`/critic-*`, `/dev-python-*`, `/db-model-*`, `/docs-*`, `/git-*`): cada una se carga sola cuando su dominio es relevante, en vez de ocupar la ventana desde el primer turno.

Un `CLAUDE.md` sobrecargado hace que Claude ignore la mitad — no metas en línea nada que deba vivir en una skill o en un fichero enlazado.
