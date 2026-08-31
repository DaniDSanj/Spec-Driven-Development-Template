# Plantilla Spec-Driven Development (SDD)

Esta carpeta es una **plantilla de arranque** para iniciar cualquier proyecto nuevo bajo Spec-Driven Development (SDD) con tu stack habitual, el cual está formado por las siguientes tecnologías:

- **Asistente**: Claude Code + Spec-Kit
- **Desarrollo**: Python
- **Bases de Datos**: PostgreSQL/SQL Server
- **Documentación**: Obsidian
- **Control de Versiones**: GitHub

> **Este `README.md` es documentación de la propia plantilla, no de tu proyecto.** Una vez completada
> la puesta en marcha (todos los pasos de este documento), puedes borrarlo o sustituirlo por el README
> real de tu proyecto — igual que `CLAUDE.md` se sobrescribe intencionadamente en el paso
> ["Generar CLAUDE.md"](#3-generar-claudemd).

## Índice

1. [Primeros pasos](#primeros-pasos)
2. [Instalación de Spec-Kit](#1-instalación-de-spec-kit)
3. [Configuración del harness](#2-configuración-del-harness-una-vez-por-proyecto)
4. [Instalación de skills, subagentes y hooks](#instalación-de-skills-subagentes-y-hooks)
5. [Estructura de la plantilla](#estructura-de-la-plantilla)
6. [Principio rector de toda la plantilla](#principio-rector-de-toda-la-plantilla)

## Primeros Pasos

Este repositorio es una **GitHub Template Repository**: no se clona ni se copia a mano, se usa como origen para generar un repositorio nuevo, que nace ya con todo el árbol de la plantilla (`.claude/`, `.specify/memory/`, `docs/`, `.github/workflows/ci.yml`) en su ruta final. Para poder utilizar esta plantilla, sigue estas indicaciones:

0. Crea el repositorio del proyecto desde esta plantilla: botón **"Use this template"** en la página de este repo en GitHub, o `gh repo create <nombre> --template <owner>/Spec-Driven-Development-Template --clone`. Clónalo localmente si no usaste `--clone`.
1. Ejecuta `specify init` en el repo ya creado siguiendo la sección [**Instalación de Spec-Kit**](#1-instalación-de-spec-kit).
2. Configura el *harness* del proyecto con la sección [**Configuración del harness**](#2-configuración-del-harness-una-vez-por-proyecto).
3. Cada vez que abras una feature/spec nueva usa los prompts de [**02_Desarrollo**](./.claude/prompts/02_Desarrollo.md) y [**03_Cierre**](./.claude/prompts/03_Cierre.md).
4. Cuando el proyecto lleve tiempo cerrado y vuelvas a él, usa [**04_Mantenimiento**](./.claude/prompts/04_Mantenimiento.md) para retomarlo y abrir nuevos desarrollos.

> **Atajo automatizado**: los pasos 1 y 2 (incluyendo gran parte de lo que documenta la sección
> [Instalación de skills, subagentes y hooks](#instalación-de-skills-subagentes-y-hooks), referenciada
> desde dentro del paso 2) se pueden ejecutar de un tirón con [**bootstrap.ps1**](./bootstrap.ps1), un
> script PowerShell que se ejecuta **dentro del repo ya creado desde la plantilla** (paso 0) y rellena
> todo lo mecánico que todavía depende del proyecto concreto (`specify init`, placeholders de contexto
> y, opcionalmente, lo que "Use this template" no deja hecho en GitHub: rama `dev`, branch protection,
> GitHub Project) y deja en un checklist final lo que exige revisión humana — generar y revisar
> `CLAUDE.md`, instalar plugins de Obsidian, fijar el spending limit. Las secciones de este README
> siguen siendo la referencia manual y el *fallback* si el script falla en algún punto. Ejemplo mínimo
> (ejecutado desde la raíz del repo del proyecto, no desde esta plantilla):
> ```powershell
> .\bootstrap.ps1 -ProjectName "mi-app" -ProjectDescription "Descripción de una línea" `
>     -DbEngine PostgreSQL -Visibility private
> ```
> Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md). Documentación completa de cada parámetro: `Get-Help .\bootstrap.ps1 -Full`.

## 1. Instalación de Spec-Kit

Esta sección asume que ya creaste el repositorio del proyecto a partir de la plantilla (botón "Use this template" en GitHub, o `gh repo create <nombre> --template <owner>/Spec-Driven-Development-Template --clone`) y lo tienes clonado localmente — es decir, siempre estás en el **Caso A** de más abajo (carpeta ya existente).

> **Atajo automatizado**: [**bootstrap.ps1**](./bootstrap.ps1) ejecuta por ti el equivalente al Caso A + Claude Code de esta sección (`specify init --here --integration claude --script <sh|ps|py> --force`), además de los pasos de [Configuración del harness](#2-configuración-del-harness-una-vez-por-proyecto). Se ejecuta desde la raíz del repo del proyecto ya creado. Sigue requiriendo que `git`, `uv` y `specify` ya estén instalados a mano (ver "Prerrequisitos" más abajo) — el script solo comprueba que existan y se detiene con instrucciones si faltan. Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md); documentación completa de cada parámetro con `Get-Help .\bootstrap.ps1 -Full`. Si necesitas usar otro agente o controlar cada paso a mano, sigue esta sección.

### Prerrequisitos (una sola vez por máquina)

```bash
# uv (gestor de Python recomendado; también instala Python si falta)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instala el CLI de Spec-Kit como herramienta global de uv
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verifica prerrequisitos del sistema (git, versión de Python, agente detectado, etc.)
specify check
```

⚠️**IMPORTANTE**: Los nombres exactos de flags (`--ai`, `--integration`, etc.) han cambiado entre versiones de Spec-Kit. Antes de copiar los comandos de abajo literalmente, confírmalos con:

```bash
specify init --help
specify integration list
```

Elige tu situación respondiendo a estas dos preguntas independientes — combina la respuesta de la 1 con la de la 2 en un único comando `specify init`.

### 1.1 ¿Dónde inicializas?

#### Caso A — Ya estás en la raíz del proyecto (el repo creado desde la plantilla)

```bash
cd mi-proyecto/
specify init --here --integration claude
```

Spec-Kit detecta que ya estás dentro de una carpeta y no crea un subdirectorio nuevo: coloca `.specify/`, `specs/` y los comandos del agente directamente aquí, junto a `.specify/memory/data-model.md`, `schema-change-protocol.md` y `db_ideas.md` que ya trae la plantilla. Es el único caso relevante al usar esta plantilla, porque el repositorio (y por tanto la carpeta) ya existe desde que se creó con "Use this template".

#### Caso B — Spec-Kit crea la carpeta raíz del proyecto (no aplica con esta plantilla)

```bash
specify init mi-proyecto --integration claude
cd mi-proyecto
git init # si no lo hace ya specify init automáticamente
```

Documentado por completitud (es la referencia genérica de Spec-Kit para proyectos 100% greenfield sin plantilla previa), pero no es el flujo de esta plantilla: aquí el repositorio ya nace con `.claude/`, `.specify/memory/` y `docs/` en su sitio, así que siempre se usa el Caso A.

### 1.2 ¿Qué agente usas?

Los comandos de arriba ya incluyen `--integration claude`; este flag es el que decide qué agente instala Spec-Kit, y es independiente de la respuesta a la pregunta 1.1.

#### Claude Code (`--integration claude`)

Esto instala los slash commands (`/speckit.constitution`, `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.checklist`, `/speckit.tasks`, `/speckit.analyze`, `/speckit.implement`, `/speckit.converge`, `/speckit.taskstoissues`) en `.claude/commands/`, de forma que Claude Code los reconoce automáticamente al abrir el proyecto. No necesitas configurar nada adicional: abre `claude` dentro de la carpeta y escribe `/speckit.` para ver el autocompletado.

#### Cualquier otro asistente

Sustituye `--integration claude` por el agente que quieras, combinándolo con el comando de la pregunta 1.1 que te corresponda:

```bash
specify integration list # lista los agentes soportados por tu versión instalada

specify init --here --integration copilot # Caso A: carpeta ya existente
specify init mi-proyecto --integration cursor # Caso B: Spec-Kit crea la carpeta
```

Spec-Kit soporta más de 30 agentes con la misma mecánica (`--integration gemini`, `--integration codex`, etc.): cambia el destino de los comandos slash (`.cursor/commands/`, `.github/copilot/`, etc.) pero el flujo de fases (`constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge`) es idéntico. Si en el futuro alternas de agente en el mismo proyecto, puedes volver a ejecutar `specify init --here --integration <otro-agente>` para añadir los comandos del nuevo agente sin perder `.specify/` ni `specs/`.

### 1.3 Verificación tras la instalación

```bash
ls .specify/memory/ # data-model.md, schema-change-protocol.md, db_ideas.md (ya en la plantilla) + constitution.md (nuevo, vacío hasta el primer /speckit.constitution)
ls specs/ # vacío hasta la primera feature
ls .claude/commands/ # (o la carpeta equivalente de tu agente)
```

Si algo falta, repite `specify check` — es idempotente y no rompe nada si vuelves a ejecutar `init`.

## 2. Configuración del harness (una vez por proyecto)

Sigue paso a paso esta sección una vez que hayas creado el repositorio desde la plantilla ("Use this template") y completado la [**instalación del Spec Kit**](#1-instalación-de-spec-kit) (`specify init --here`). Verifica con `specify check` si se ha instalado correctamente.

⚠️**IMPORTANTE**: Sigue el orden, cada paso depende del anterior.

> **Atajo automatizado**: los pasos 1, 2 (placeholders) y 3 (prompt listo para pegar) se pueden ejecutar de un tirón con [**bootstrap.ps1**](./bootstrap.ps1), incluyendo lo que "Use this template" no deja hecho en GitHub si se usa `-SetupGitHub` (rama `dev`, branch protection, GitHub Project). Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md); documentación completa de cada parámetro con `Get-Help .\bootstrap.ps1 -Full`. Lo que sigue aquí es la referencia manual y el *fallback* si el script falla en algún punto.

### 2.1 Verificar que el harness ya está presente

Al haber creado el repo con "Use this template", estas rutas ya existen — no hay nada que copiar:

```bash
ls .claude/context/       # 01_estilo_comportamiento.md .. 05_github.md
ls .claude/skills/        # adr-writer, db-schema-design, obsidian-sync
ls .claude/agents/        # docs-updater.md, spec-critic.md, security-reviewer.md, db-designer.md
ls .claude/hooks/         # *.sh + .claude/settings.json en la raíz de .claude/
ls .specify/memory/       # data-model.md, schema-change-protocol.md, db_ideas.md (+ constitution.md tras specify init)
ls docs/                  # Specs/, ADR/records/, Data-Model/, Runbooks/, Changelog/, Meta/
ls .github/workflows/     # ci.yml
```

Si falta alguna, el repo no se creó correctamente desde la plantilla — vuelve a generarlo con "Use this template" en vez de copiar ficheros a mano.

Verifica que `jq` está instalado en tu sistema (lo usan los scripts de hooks para leer el JSON de entrada):
```bash
winget install jqlang.jq        # Para Windows
sudo apt install jq             # Para Linux
brew install jq                 # Para MacOS
```

En sistemas Unix, asegúrate de que los hooks son ejecutables (Windows no lo necesita):
```bash
chmod +x .claude/hooks/*.sh
```

### 2.2 Rellenar los placeholders con los datos reales del proyecto

Ve rellenando manualmente los campos `[ ]` de cada fichero con los datos reales del proyecto:

| Fichero | Descripción |
| --- | --- |
| [**01_estilo_comportamiento.md**](./.claude/context/01_estilo_comportamiento.md) | Normalmente no requiere cambios, son reglas de comportamiento genéricas y ya aplicables tal cual. |
| [**02_documentacion_mantenibilidad.md**](./.claude/context/02_documentacion_mantenibilidad.md) | Normalmente tampoco requiere cambios. |
| [**03_python.md**](./.claude/context/03_python.md) | Rellena versión de Python, framework backend/móvil, criterios de cobertura. |
| [**04_base_datos.md**](./.claude/context/04_base_datos.md) | Rellena motor (PostgreSQL/SQL Server), schemas, decisión sobre NoSQL si aplica. |
| [**05_github.md**](./.claude/context/05_github.md) | Rellena [público/privado] y confirma el nombre de la rama de trabajo (dev por defecto). |
| [**.specify/memory/data-model.md**](./.specify/memory/data-model.md) | Modelo de datos canónico del proyecto (entidades, changelog, qué specs dependen de cada tabla). Arranca con el ejemplo de la plantilla; sustitúyelo por las tablas reales a medida que se creen, o vacíalo si el proyecto aún no tiene ninguna. |

`schema-change-protocol.md` y `db_ideas.md` no requieren relleno inicial: el primero es el protocolo obligatorio que `/speckit.specify` y `/speckit.plan` invocan antes de crear o modificar cualquier estructura; el segundo es un borrador humano de tablas concretas que solo se consulta cuando el prompt de `/speckit.plan` de una spec lo referencia explícitamente (ver [Estructura de la plantilla](#estructura-de-la-plantilla)).

### 2.3 Generar CLAUDE.md

Abre `claude` dentro del proyecto y pega el prompt de [**01_ClaudeMD**](./.claude/prompts/01_ClaudeMD.md), ya con sus placeholders rellenos. Esto **sobrescribe** el `CLAUDE.md` que trae la plantilla (meta-instrucciones para editar la propia plantilla) con el `CLAUDE.md` real del proyecto — es intencionado. Revisa el resultado a mano antes de continuar.

### 2.4 Configurar Obsidian

1. Abre `docs/` como vault de Obsidian.
2. Sigue [**docs/Meta/Setup.md**](./docs/Meta/Setup.md) para instalar y configurar los plugins comunitarios (Dataview, Templater, obsidian-git, Kanban/Tasks, Excalidraw).
3. Revisa [**docs/Meta/Workflow.md**](./docs/Meta/Workflow.md) para el flujo de trabajo diario con el vault.
4. La estructura de carpetas (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/Templates/`) y las plantillas Templater ya vienen creadas — no hay nada que montar.

### 2.5 Configurar GitHub

Sigue el checklist de puesta en marcha al final de [**05_github.md**](./.claude/context/05_github.md) (rama `dev`, branch protection en `main`, GitHub Project, spending limit a $0 — el repo y `.github/workflows/ci.yml` ya existen desde el paso 0 de "Use this template").

### 2.6 Verificación final

```bash
/context # dentro de Claude Code: confirma que CLAUDE.md y sus imports se cargaron
/doctor # confirma que hooks y skills están activos
```

- [ ] `specify check` en verde.
- [ ] `.claude/context/01_*.md` a `05_github.md` sin placeholders `[ ]` pendientes.
- [ ] `.specify/memory/data-model.md` y `.specify/memory/schema-change-protocol.md` presentes
      (`db_ideas.md` es opcional y mantiene corchetes de plantilla a propósito, no cuenta para este
      punto).
- [ ] `CLAUDE.md` generado y revisado a mano (sobrescribe el de la plantilla).
- [ ] Vault de Obsidian con los plugins comunitarios instalados.
- [ ] Repo GitHub con rama `dev`, CI y branch protection configurados.

Con esto, el harness está listo y puedes empezar el primer ciclo SDD con [**02_Desarrollo**](./.claude/prompts/02_Desarrollo.md).

## Instalación de skills, subagentes y hooks

### ¿Qué instalar?

Regla de decisión rápida para elegir el mecanismo correcto:

| Si necesitas... | Usa |
|---|---|
| Que algo se cumpla **siempre**, de forma determinista (formatear, testear, bloquear una escritura) | **Hook** |
| Conocimiento de dominio reutilizable que Claude carga **solo cuando hace falta** (una convención, un checklist) | **Skill** |
| Delegar una tarea a un contexto **limpio y aislado** (revisión adversarial, investigación) | **Subagente** |
| Una regla **siempre activa** y corta que guía el comportamiento general | `CLAUDE.md` / `context/*.md` |

### Documentación

#### Skills

Todas las skills son solo **recomendaciones** para este stack en concreto y ya vienen incluidas en `.claude/skills/` al crear el repo desde esta plantilla — no hay que instalarlas:

##### `db-schema-design`
Encapsula las convenciones de [**04_base_datos.md**](./.claude/context/04_base_datos.md) (naming, campos de auditoría, política de índices) para que el asistente las aplique al diseñar cualquier tabla nueva sin tener que repetírselas cada vez. Válida tanto para PostgreSQL como para SQL Server.

##### `adr-writer`
Sabe el formato exacto de ADR, dónde vive (`docs/ADR/records/`), y aplica la regla append-only + supersede automáticamente.

##### `obsidian-sync`
Sabe qué nota del vault actualizar tras cada evento de la tabla de disparo de [**02_documentacion_mantenibilidad.md**](./.claude/context/02_documentacion_mantenibilidad.md), y en qué formato (Dataview/wikilinks).

Puedes añadir más según crezca el proyecto (ej. `fastapi-endpoint-scaffold`, `pytest-fixtures`), pero empieza solo con estas tres — más skills de las que realmente usas solo añaden ruido a la carga inicial.

#### Subagentes

Todos los subagentes son solo **recomendaciones** para este stack en concreto y ya vienen incluidos en `.claude/agents/` al crear el repo desde esta plantilla — no hay que instalarlos:

##### `spec-critic`
Revisor adversarial de spec/plan (usado en [**01_estilo_comportamiento.md**](./.claude/context/01_estilo_comportamiento.md), sección 1). Contexto limpio: solo ve `spec.md`/`plan.md`/`tasks.md`, no el histórico de la conversación de planificación.

##### `db-designer`
Propone y valida esquemas SQL contra las convenciones de [**04_base_datos.md**](./.claude/context/04_base_datos.md); se invoca durante `/speckit.plan` o `/speckit.implement` cuando la feature toca el modelo de datos.

##### `docs-updater`
Tras `/speckit.converge`, redacta el ADR/Changelog/nota de vault correspondientes según la tabla de disparo, y los deja listos para revisión humana antes de commitear.

##### `security-reviewer`
Revisa cambios que tocan superficies sensibles (autenticación, gestión de secretos/`.env`, migraciones, entradas no confiables) antes de `/speckit.converge`, buscando vulnerabilidades tipo OWASP Top 10. Complementa al hook `pre_edit_guard_sensitive.sh` (que bloquea la escritura) revisando la lógica una vez escrita.

#### Hooks

Todos los hooks son solo **recomendaciones** para este stack en concreto y ya vienen incluidos en `.claude/settings.json` al crear el repo desde esta plantilla — no hay que instalarlos:

1. **PostToolUse en `Edit`/`Write` sobre `*.py`** → `ruff format` + `ruff check --fix` + `ty check` automáticos.
2. **Stop** → `uv run pytest -q`; si falla, Claude ve el resultado antes de dar la tarea por cerrada.
3. **PreToolUse en `Write`/`Edit` sobre `migrations/**` o `.env*`** → bloquea la escritura (no pide confirmación: el hook sale con código 2 y corta la acción), dado que son ficheros de alto riesgo (datos de producción / secretos). El humano decide manualmente si aplica el cambio por otra vía.

En sistemas Unix, verifica que son ejecutables (Windows no lo necesita): `chmod +x .claude/hooks/*.sh`.

### ¿Cómo añadir herramientas nuevas más adelante?

Lo de arriba ya está en el repo desde el principio. Esta sección aplica cuando el proyecto necesita algo que **no** viene en la plantilla (una skill nueva escrita a mano, una traída de otro proyecto, etc.):

#### A nivel de proyecto
Todo quedará compartido dentro del proyecto, es decir, vía Git. Recomendado para todo lo específico de este stack.

```bash
cp -r ruta/al/origen/mi-skill-nueva   .claude/skills/
cp ruta/al/origen/mi-agente-nuevo.md  .claude/agents/
# añade el hook nuevo a mano dentro de .claude/settings.json (no lo sobrescribas)
git add .claude/ && git commit -m "chore: añadir <herramienta> al harness"
```

Al vivir dentro del repo, cualquier humano que clone el proyecto (o tú mismo en otra máquina) hereda automáticamente el mismo comportamiento del asistente — esto es parte de la mantenibilidad documentada en `.claude/context/02_documentacion_mantenibilidad.md`.

#### A nivel global
Aplica a todos tus proyectos con este stack, ej. convenciones Python/PostgreSQL que repites siempre. Puedes promover una skill/subagente ya presente en un proyecto concreto (incluido este):

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r .claude/skills/db-schema-design ~/.claude/skills/
cp .claude/agents/spec-critic.md ~/.claude/agents/
```

- Precedencia: si un skill/subagente con el mismo nombre existe tanto en `.claude/` (proyecto) como en `~/.claude/` (global), **gana el del proyecto**. Usa esto para tener una versión global genérica y sobreescribirla por proyecto solo cuando haga falta.
- Los hooks (`settings.json`) **no** se heredan por fusión automática entre global y proyecto en todas las versiones de Claude Code. Verifica con `/doctor` que los hooks esperados están activos tras clonar un proyecto nuevo.

## Estructura de la plantilla

Al usar "Use this template", el repo nuevo nace con estas rutas ya en su sitio (nada que copiar):

| Ruta | Contenido |
| --- | --- |
| `.claude/context/01..04_*.md` | Convenciones de estilo, documentación, Python y base de datos — referenciadas desde `CLAUDE.md` con `@` |
| `.claude/context/05_github.md` | Flujo de trabajo con GitHub (ramas, branch protection, Issues/Projects) — referenciado con `@` |
| `.specify/memory/data-model.md`, `schema-change-protocol.md`, `db_ideas.md` | Modelo de datos canónico y protocolo de cambio de esquema que usan `/speckit.specify` y `/speckit.plan`; `db_ideas.md` (borrador humano de tablas concretas) solo se consulta cuando el prompt de `/speckit.plan` de una spec lo referencia explícitamente. Nada de esta carpeta se importa en `CLAUDE.md`. `specify init` añade aquí además `constitution.md` |
| `.claude/skills/*` | Skills recomendadas (`db-schema-design`, `adr-writer`, `obsidian-sync`) |
| `.claude/agents/*` | Subagentes recomendados (`spec-critic`, `db-designer`, `docs-updater`, `security-reviewer`) |
| `.claude/hooks/*.sh` + `.claude/settings.json` | Hooks recomendados (formateo post-edición, tests en Stop, guard de ficheros sensibles) |
| `.claude/prompts/*.md` | Biblioteca de prompts maestros: `01_ClaudeMD.md` (generación única del `CLAUDE.md` real), `02_Desarrollo.md`, `03_Cierre.md`, `04_Mantenimiento.md` |
| `docs/` | Esqueleto del vault de Obsidian (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/` con las guías de setup/workflow y las plantillas de nota) |
| `.github/workflows/ci.yml` | Workflow de CI (ruff/ty/pytest), gateado por la existencia de `pyproject.toml` |

Este `README.md`, `bootstrap.ps1` y `bootstrap_example.md` son documentación **de la propia plantilla** (no de tu proyecto): puedes borrarlos del repo del proyecto una vez completada la puesta en marcha, o dejarlos como referencia.

## Principio rector de toda la plantilla

`CLAUDE.md` se mantiene deliberadamente corto. Toda la sustancia vive en `context/*.md`, y `CLAUDE.md` solo la referencia con imports (`@.claude/context/01_estilo_comportamiento.md`, etc.). Esto evita que un `CLAUDE.md` sobrecargado haga que Claude ignore la mitad de las reglas. Cada fichero de contexto se activa solo cuando es relevante para la tarea en curso.
