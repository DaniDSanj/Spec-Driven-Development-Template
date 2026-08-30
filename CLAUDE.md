# CLAUDE.md

Este fichero da instrucciones a Claude Code (claude.ai/code) para trabajar con el código de esta plantilla.

## Qué es esta carpeta

Esta carpeta es una **plantilla de arranque** alojada en un vault de Obsidian que sirve de repositorio maestro de plantillas para poner en marcha proyectos nuevos (cada plantilla cubre un stack y una metodología distintos; puede haber varias hermanas al mismo nivel). Esta en concreto es la plantilla de **Spec-Driven Development (SDD)** con un stack fijo: Claude Code + GitHub Spec-Kit, Python, PostgreSQL/SQL Server, Obsidian como documentación, GitHub como control de versiones. Aquí no hay nada que compilar, lintar ni testear: lo que entrega esta carpeta son guías en Markdown más un árbol `files/` de artefactos de andamiaje (ficheros de contexto, skills, subagentes, hooks, prompts, plantillas de Obsidian) que se copian a *otros* proyectos, los downstream.

Punto de entrada para un humano que lea esta plantilla: [`01_Guia_Uso_Plantilla.md`](01_Guia_Uso_Plantilla.md).

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

- **`00_Guias_Inicio/`** — lectura previa recomendada: cómo instalar/usar Claude Code (`01_Guia_Claude_Code.md`) y la guía completa de la metodología SDD con referencia de comandos de Spec-Kit y prompts maestros (`02_Guia_Spec_Driven_Development.md`).
- La plantilla propiamente dicha, dividida en cuatro guías secuenciales más una chuleta de comandos:
  1. `01_Guia_Uso_Plantilla.md` — índice y la tabla de mapeo de carpetas (ruta origen en esta plantilla → ruta destino en un proyecto downstream).
  2. `02_Instalacion_Spec_Kit.md` — instala Spec-Kit (CLI `specify`) en un proyecto destino.
  3. `03_Configuracion_Harness.md` — la puesta en marcha ordenada y de una sola vez que debe seguir un proyecto nuevo (ficheros de contexto → skills/agentes/hooks → generar `CLAUDE.md` → estructura del vault de Obsidian → configuración de GitHub). Los pasos dependen del orden.
  4. `04_Instalacion_Herramientas_Claude.md` — tabla de decisión skill vs. subagente vs. hook vs. `CLAUDE.md`, y qué hace cada skill/agente/hook recomendado en `files/native/`.
  5. `install_example.md` — ejemplo de invocación de `install.ps1` (el atajo automatizado) con todos sus parámetros, listo para copiar, editar y pegar en PowerShell.

### `files/` — la carga de andamiaje

Todo lo que hay bajo esta carpeta es contenido de plantilla inerte, que se copia tal cual al propio repositorio de un proyecto downstream (nunca lo ejecuta ni lo lee directamente Claude en *esta plantilla*, salvo cuando se está editando la plantilla). El mapeo de destino (también documentado en `01_Guia_Uso_Plantilla.md`):

| Origen en esta plantilla | Destino en el proyecto destino |
|---|---|
| `files/context/01_estilo_comportamiento.md` … `04_base_datos.md` | `.claude/context/01..04*.md`, importados en el `CLAUDE.md` del destino vía `@` |
| `files/github/01_github_workflow.md` | `.claude/context/05_github.md` |
| `files/native/skills/*` | `.claude/skills/*` (o `~/.claude/skills/*` si se reutiliza entre proyectos; a nivel de proyecto gana en caso de colisión de nombre) |
| `files/native/agents/*` | `.claude/agents/*` |
| `files/native/hooks/*` | `.claude/settings.json` + `.claude/hooks/*.sh` |
| `files/obsidian/*` | El propio vault de Obsidian del proyecto destino, bajo `docs/` |
| `files/prompts/*` | La biblioteca de prompts maestros del proyecto destino (también copiable a su vault) |
| `files/specify/*` | `.specify/memory/` del proyecto destino (la carpeta ya existe tras `specify init`, con `constitution.md` dentro): `data-model.md` (modelo de datos canónico, con changelog y qué specs dependen de cada tabla), `schema-change-protocol.md` (protocolo obligatorio que `/speckit.specify` y `/speckit.plan` invocan antes de crear o modificar cualquier estructura, ver `files/prompts/02_Desarrollo.md`) y `db_ideas.md` (borrador humano de tablas concretas — nunca se importa en `CLAUDE.md`, ni se lee por comprobación automática de existencia: solo se consulta cuando el prompt de `/speckit.plan` de una spec lo referencia explícitamente) |

La numeración en `context/` y en las guías de primer nivel es significativa y estructural: fija tanto el orden de lectura para humanos como el orden de import que exige `files/prompts/01_ClaudeMD.md` (el prompt que genera el `CLAUDE.md` de un proyecto *downstream*, distinto de este). Si añades, quitas o reordenas un fichero de contexto, actualiza todos los sitios que los enumeran: `01_Guia_Uso_Plantilla.md`, `03_Configuracion_Harness.md`, `04_Instalacion_Herramientas_Claude.md` y `files/prompts/01_ClaudeMD.md`.

### Principio rector de los `CLAUDE.md` downstream

Todo `CLAUDE.md` que produce esta plantilla (para proyectos destino y, por extensión, este mismo fichero) se mantiene corto a propósito: la sustancia vive en `context/*.md` y solo se trae vía imports `@`, cada uno con una frase de "cuándo es relevante consultarlo". Un `CLAUDE.md` sobrecargado hace que Claude ignore la mitad — no metas en línea nada que deba vivir en un fichero enlazado.
