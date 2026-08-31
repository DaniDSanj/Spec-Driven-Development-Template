# CLAUDE.md

Este fichero da instrucciones a Claude Code (claude.ai/code) para trabajar con el código de esta plantilla.

## Qué es esta carpeta

Esta carpeta es una **GitHub Template Repository**: el mecanismo de puesta en marcha de un proyecto nuevo es el botón "Use this template" de GitHub (o `gh repo create <nombre> --template <owner>/Spec-Driven-Development-Template --clone`), no clonar ni copiar ficheros a mano desde aquí. Es la plantilla de **Spec-Driven Development (SDD)** con un stack fijo: Claude Code + GitHub Spec-Kit, Python, PostgreSQL/SQL Server, Obsidian como documentación, GitHub como control de versiones. Aquí no hay nada que compilar, lintar ni testear.

El repo mezcla dos cosas en la misma raíz:
- **Documentación de la propia plantilla** (este `CLAUDE.md`, `README.md`, `bootstrap.ps1`, `bootstrap_example.md`): solo tiene sentido mientras se está *editando la plantilla* o poniendo en marcha un proyecto nuevo; es descartable en el proyecto downstream una vez completada la puesta en marcha.
- **La carga útil de andamiaje ya en su ruta final de destino** (`.claude/`, `.specify/memory/`, `docs/`, `.github/workflows/ci.yml`): esto es lo que "Use this template" entrega intacto a cada proyecto nuevo, sin ningún paso de copia.

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
  5. Estructura de la plantilla — tabla de referencia rápida de qué contiene cada ruta ya incluida al usar "Use this template", y qué ficheros de la plantilla (`README.md`, `bootstrap.ps1`, `bootstrap_example.md`) son descartables tras la puesta en marcha.
  6. Principio rector de toda la plantilla — por qué todo `CLAUDE.md` que produce esta plantilla se mantiene corto y solo referencia `context/*.md` vía imports.
- `bootstrap.ps1` — script PowerShell que ejecuta de un tirón el equivalente a las secciones "Instalación de Spec-Kit" y "Configuración del harness" del README (`specify init`, placeholders mecánicos, prompt de `CLAUDE.md` y, opcionalmente con `-SetupGitHub`, rama `dev`/branch protection/GitHub Project); se ejecuta dentro del repo del proyecto ya creado desde la plantilla, nunca dentro de esta plantilla.
- `bootstrap_example.md` — ejemplo de invocación de `bootstrap.ps1` con todos sus parámetros, listo para copiar, editar y pegar en PowerShell.

### La carga de andamiaje (ya en su ruta final)

A diferencia de un flujo de copia entre repos, estas rutas viven ya en la raíz de este mismo repositorio, en el sitio exacto donde las necesita un proyecto downstream — "Use this template" las entrega intactas:

| Ruta | Contenido |
|---|---|
| `.claude/context/00_perfil_proyecto.md` | Los valores concretos de cada proyecto (nombre, versión de Python, motor de BD, herramienta de migraciones, visibilidad…). Único fichero de contexto que un proyecto downstream rellena; lo rellena `bootstrap.ps1` y se completa a mano |
| `.claude/context/02_documentacion_mantenibilidad.md` | Importado en el `CLAUDE.md` del proyecto vía `@` |
| `.claude/context/05_github.md` | Flujo de trabajo con GitHub, importado igual con `@` |
| `.claude/skills/*` | Skills recomendadas (a nivel de proyecto; `~/.claude/skills/*` es la alternativa global — gana el de proyecto en caso de colisión de nombre) |
| `.claude/agents/*` | Subagentes recomendados |
| `.claude/hooks/*.sh` + `.claude/settings.json` | Hooks recomendados |
| `docs/` | El esqueleto del vault de Obsidian del proyecto (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/`) |
| `.claude/prompts/*` | La biblioteca de prompts maestros del proyecto: `01_init_project.md` (generación única del `CLAUDE.md` real) y `02_spec_development.md` (el ciclo completo de una spec, de la petición al merge) |
| `.specify/memory/*` | Estado real del proyecto, nunca método: `data-model.md` (modelo de datos canónico, con changelog y qué specs dependen de cada tabla) y `db_ideas.md` (bandeja de entrada de ideas de tabla sin feature asignada — ningún paso del ciclo la lee; el boceto de una feature concreta vive en `specs/<feature>/db_ideas.md`). Nada de esta carpeta se importa en `CLAUDE.md`. `specify init` añade aquí `constitution.md`. El protocolo de cambio de esquema ya no vive aquí: es la skill `db-model-protocol` |
| `.github/workflows/ci.yml` | Workflow de CI (ruff/ty/pytest), estático y gateado por la existencia de `pyproject.toml` |

**Tensión aceptada**: al vivir `.claude/skills/`, `.claude/agents/` y `.claude/settings.json` en la raíz de este mismo repo, Claude Code los carga también mientras se edita la propia plantilla (no un proyecto Python real). Es un efecto colateral menor y aceptado a propósito — no hay mecanismo nativo de GitHub Template para excluir rutas al generar, y los hooks no tienen nada que ejecutar sobre ficheros Markdown.

**Sobrescritura intencionada de este `CLAUDE.md`**: en el flujo downstream, el paso "Generar CLAUDE.md" (prompt `.claude/prompts/01_init_project.md`) sobrescribe este fichero con el `CLAUDE.md` real del proyecto — para entonces el humano ya no necesita las meta-instrucciones de esta plantilla.

**Separación entre perfil y convenciones**: `00_perfil_proyecto.md` contiene solo *valores* de un proyecto concreto; los ficheros de contexto que quedan (`02`, `05`) contienen solo *convenciones*, iguales en todos los proyectos. Cuando una convención necesita un valor, remite al perfil en vez de declarar un placeholder propio — así `bootstrap.ps1` escribe en un único sitio y no hay doble fuente de verdad. Si añades un valor configurable nuevo, va al perfil, nunca a un fichero de convenciones.

La numeración en `.claude/context/` fija el orden de lectura para humanos y el orden de import que enumera `.claude/prompts/01_init_project.md` (el prompt que genera el `CLAUDE.md` de un proyecto *downstream*, distinto de este). Los números **no se reasignan** al retirar un fichero: la secuencia tiene huecos (falta `01`, retirado con `spec-critic`; falta `03`, retirado con las skills `dev-*`; falta `04`, retirado con `database-manager` y las skills `db-*`) y así se queda, para que las referencias históricas sigan siendo legibles. Si añades o quitas un fichero de contexto, actualiza todos los sitios que los enumeran: `README.md` y `.claude/prompts/01_init_project.md`.

### Principio rector de los `CLAUDE.md` downstream

Todo `CLAUDE.md` que produce esta plantilla (para proyectos destino y, por extensión, este mismo fichero) se mantiene corto a propósito: la sustancia vive en `.claude/context/*.md` y solo se trae vía imports `@`, cada uno con una frase de "cuándo es relevante consultarlo". Un `CLAUDE.md` sobrecargado hace que Claude ignore la mitad — no metas en línea nada que deba vivir en un fichero enlazado.
