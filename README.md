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
> ["Generar CLAUDE.md"](#23-generar-claudemd). Lo mismo aplica a `bootstrap.ps1`,
> `bootstrap_example.md` y `CONTRIBUTING.md`. `SECURITY.md` y `LICENSE` no se borran: se adaptan
> a tu proyecto.

## Índice

- [Primeros pasos](#primeros-pasos)
- [1. Instalación de Spec-Kit](#1-instalación-de-spec-kit)
- [2. Configuración del harness](#2-configuración-del-harness-una-vez-por-proyecto)
- [Instalación de skills, subagentes y hooks](#instalación-de-skills-subagentes-y-hooks)
- [Estructura de la plantilla](#estructura-de-la-plantilla)
- [Principio rector de toda la plantilla](#principio-rector-de-toda-la-plantilla)

## Primeros Pasos

Este repositorio es una **GitHub Template Repository**: no se clona ni se copia a mano, se usa como origen para generar un repositorio nuevo, que nace ya con todo el árbol de la plantilla (`.claude/`, `.specify/memory/`, `docs/`, `.githooks/`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, `.gitignore`, `.gitattributes`, `.gitleaks.toml`, `LICENSE`) en su ruta final. Para poder utilizar esta plantilla, sigue estas indicaciones:

0. Crea el repositorio del proyecto desde esta plantilla: botón **"Use this template"** en la página de este repo en GitHub, o `gh repo create <nombre> --template DaniDSanj/Spec-Driven-Development-Template --clone`. Clónalo localmente si no usaste `--clone`.
1. Ejecuta `specify init` en el repo ya creado siguiendo la sección [**Instalación de Spec-Kit**](#1-instalación-de-spec-kit).
2. Configura el *harness* del proyecto con la sección [**Configuración del harness**](#2-configuración-del-harness-una-vez-por-proyecto).
3. Cada vez que abras una feature/spec nueva sigue [**02_spec_development**](./.claude/prompts/02_spec_development.md) de arriba abajo: cubre el ciclo completo de la petición al merge (specify → plan → tasks → implementación → UAT → documentación → PR).
4. Cuando el proyecto lleve tiempo cerrado y vuelvas a él, entra por la **Fase 0 (Encuadre)** de ese mismo documento: reconstruye el contexto y clasifica la petición (corrección / mejora pequeña / funcionalidad nueva), y la clasificación te dice qué fases posteriores aplican.

> **Atajo automatizado**: los pasos 1 y 2 (incluyendo gran parte de lo que documenta la sección
> [Instalación de skills, subagentes y hooks](#instalación-de-skills-subagentes-y-hooks), referenciada
> desde dentro del paso 2) se pueden ejecutar de un tirón con [**bootstrap.ps1**](./bootstrap.ps1), un
> script PowerShell que se ejecuta **dentro del repo ya creado desde la plantilla** (paso 0) y rellena
> todo lo mecánico que todavía depende del proyecto concreto (`specify init`, placeholders de contexto
> y, opcionalmente, lo que "Use this template" no deja hecho en GitHub: rama `dev`, branch protection,
> secret scanning con push protection, Dependabot alerts, reporte privado de vulnerabilidades,
> exigencia de SHA en Actions, GitHub Project) y deja en un checklist final lo que exige revisión humana — generar y revisar
> `CLAUDE.md`, instalar plugins de Obsidian, fijar el spending limit. Las secciones de este README
> siguen siendo la referencia manual y el *fallback* si el script falla en algún punto. Ejemplo mínimo
> (ejecutado desde la raíz del repo del proyecto, no desde esta plantilla):
> ```powershell
> .\bootstrap.ps1 -ProjectName "mi-app" -ProjectDescription "Descripción de una línea" `
>     -DbEngine PostgreSQL -Visibility private
> ```
> Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md). Documentación completa de cada parámetro: `Get-Help .\bootstrap.ps1 -Full`.

## 1. Instalación de Spec-Kit

Esta sección asume que ya creaste el repositorio del proyecto a partir de la plantilla (botón "Use this template" en GitHub, o `gh repo create <nombre> --template DaniDSanj/Spec-Driven-Development-Template --clone`) y lo tienes clonado localmente — es decir, siempre estás en el **Caso A** de más abajo (carpeta ya existente).

> **Atajo automatizado**: [**bootstrap.ps1**](./bootstrap.ps1) ejecuta por ti el equivalente al Caso A + Claude Code de esta sección (`specify init --here --integration claude --script <sh|ps|py> --force`), además de los pasos de [Configuración del harness](#2-configuración-del-harness-una-vez-por-proyecto). Se ejecuta desde la raíz del repo del proyecto ya creado. Sigue requiriendo que `git`, `uv` y `specify` ya estén instalados a mano (ver "Prerrequisitos" más abajo) — el script solo comprueba que existan y se detiene con instrucciones si faltan. Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md); documentación completa de cada parámetro con `Get-Help .\bootstrap.ps1 -Full`. Si necesitas usar otro agente o controlar cada paso a mano, sigue esta sección.

### Prerrequisitos (una sola vez por máquina)

| Herramienta | Obligatoria | Para qué |
|---|---|---|
| `git` | Sí | Todo el flujo |
| `uv` | Sí | Gestor de Python y de entornos; lo usan los hooks y el CI |
| `specify` | Sí | El CLI de Spec-Kit |
| `bash` | Sí | `.claude/settings.json` invoca con `bash` los cuatro hooks de `.claude/hooks/`. En Windows viene con **Git Bash** (Git for Windows); en WSL/Linux/macOS ya está |
| `jq` | Sí | Los hooks leen su entrada JSON con `jq`. Los dos guards de `PreToolUse` son *fail-closed*: sin `jq` **bloquean toda escritura, lectura y comando** que pase por ellos en vez de dejarlos pasar en silencio |
| **Claude Code ≥ v2.1.218** | Sí | Las skills forkeadas de esta plantilla usan `background: false` en su frontmatter, que se introdujo en esa versión |
| `pwsh` (PowerShell 7+) | Solo para `bootstrap.ps1` | El script lo declara con `#Requires -Version 7.0`. Windows PowerShell 5.1 no vale |
| `gh` (GitHub CLI) | Solo para `bootstrap.ps1 -SetupGitHub` y la skill `git-run-actions` | Rama `dev`, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project y lectura del estado del CI |
| `gitleaks` | Solo para la red local `.githooks/pre-commit` | Escaneo de secretos antes de cada commit. Sin él, el hook avisa y deja pasar. `winget install Gitleaks.Gitleaks` · `brew install gitleaks` |

```bash
# uv (gestor de Python recomendado; también instala Python si falta)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instala el CLI de Spec-Kit como herramienta global de uv
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# jq (lo usan los cuatro hooks para leer el JSON de entrada)
winget install jqlang.jq        # Windows
sudo apt install jq             # Linux
brew install jq                 # macOS

# Verifica prerrequisitos del sistema (git, versión de Python, agente detectado, etc.)
specify check
```

⚠️ **IMPORTANTE — verificado contra Spec-Kit `0.14.2`.** Entre versiones de Spec-Kit han cambiado tanto los flags (`--ai` pasó a `--integration`) como **el nombre y la ubicación de los comandos**: hasta la 0.13 eran ficheros en `.claude/commands/` invocados como `/speckit.plan` (con punto); desde la 0.14 son *skills* en `.claude/skills/speckit-*/` invocadas como `/speckit-plan` (**con guion**). Toda esta plantilla usa la forma con guion.

Antes de copiar nada literalmente, confirma qué instaló tu versión:

```bash
specify --version
specify init --help
specify integration list
ls .claude/skills/          # tras el init: speckit-specify, speckit-plan, … (o .claude/commands/ en versiones antiguas)
```

Si tu versión usa la forma con punto, la traducción es mecánica: `/speckit-plan` → `/speckit.plan`, y así con todos.

Elige tu situación respondiendo a estas dos preguntas independientes — combina la respuesta de la 1 con la de la 2 en un único comando `specify init`.

### 1.1 ¿Dónde inicializas?

#### Caso A — Ya estás en la raíz del proyecto (el repo creado desde la plantilla)

```bash
cd mi-proyecto/
specify init --here --integration claude
```

Spec-Kit detecta que ya estás dentro de una carpeta y no crea un subdirectorio nuevo: coloca `.specify/`, `specs/` y los comandos del agente directamente aquí, junto a `.specify/memory/data-model.md` y `db_ideas.md` que ya trae la plantilla. Es el único caso relevante al usar esta plantilla, porque el repositorio (y por tanto la carpeta) ya existe desde que se creó con "Use this template".

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

Esto instala los diez comandos del ciclo (`/speckit-constitution`, `/speckit-specify`, `/speckit-clarify`, `/speckit-plan`, `/speckit-checklist`, `/speckit-tasks`, `/speckit-analyze`, `/speckit-implement`, `/speckit-converge`, `/speckit-taskstoissues`) como skills en **`.claude/skills/speckit-*/`**, junto a las que ya trae esta plantilla — no colisionan, los nombres son distintos. Claude Code los reconoce automáticamente al abrir el proyecto: no hay que configurar nada. Abre `claude` dentro de la carpeta y escribe `/speckit-` para ver el autocompletado.

> Al terminar, `specify init` sugiere "considera añadir `.claude/` a `.gitignore`". **En esta plantilla, no lo hagas**: `.claude/` es el harness compartido (skills, subagentes, hooks, perfil del proyecto) y tiene que viajar en el repo — es lo que hace que cualquiera que clone herede el mismo comportamiento del asistente. Lo que sí conviene ignorar es `.claude/settings.local.json`, que ya está en el `.gitignore` de la plantilla.

#### Cualquier otro asistente

Sustituye `--integration claude` por el agente que quieras, combinándolo con el comando de la pregunta 1.1 que te corresponda:

```bash
specify integration list # lista los agentes soportados por tu versión instalada

specify init --here --integration copilot # Caso A: carpeta ya existente
specify init mi-proyecto --integration cursor # Caso B: Spec-Kit crea la carpeta
```

Spec-Kit soporta más de 30 agentes con la misma mecánica (`--integration gemini`, `--integration codex`, etc.): cambia el destino de los comandos (`.cursor/`, `.github/copilot/`, etc.) pero el flujo de fases (`constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge`) es idéntico. Si en el futuro alternas de agente en el mismo proyecto, puedes volver a ejecutar `specify init --here --integration <otro-agente>` para añadir los comandos del nuevo agente sin perder `.specify/` ni `specs/`.

### 1.3 Verificación tras la instalación

```bash
ls .specify/memory/          # data-model.md, db_ideas.md (ya en la plantilla) + constitution.md (nuevo, vacío hasta el primer /speckit-constitution)
ls specs/                    # vacío hasta la primera feature
ls .claude/skills/           # las 19 de la plantilla + las 10 speckit-* recién instaladas
```

Si algo falta, repite `specify check` — es idempotente y no rompe nada si vuelves a ejecutar `init`.

## 2. Configuración del harness (una vez por proyecto)

Sigue paso a paso esta sección una vez que hayas creado el repositorio desde la plantilla ("Use this template") y completado la [**instalación del Spec Kit**](#1-instalación-de-spec-kit) (`specify init --here`). Verifica con `specify check` si se ha instalado correctamente.

⚠️**IMPORTANTE**: Sigue el orden, cada paso depende del anterior.

> **Atajo automatizado**: los pasos 1, 2 (placeholders) y 3 (prompt listo para pegar) se pueden ejecutar de un tirón con [**bootstrap.ps1**](./bootstrap.ps1), incluyendo lo que "Use this template" no deja hecho en GitHub si se usa `-SetupGitHub` (rama `dev`, branch protection, secret scanning con push protection, Dependabot alerts, reporte privado de vulnerabilidades, exigencia de SHA en Actions, GitHub Project). Ejemplo listo para copiar y editar (con todos los parámetros) en [**bootstrap_example.md**](./bootstrap_example.md); documentación completa de cada parámetro con `Get-Help .\bootstrap.ps1 -Full`. Lo que sigue aquí es la referencia manual y el *fallback* si el script falla en algún punto.

### 2.1 Verificar que el harness ya está presente

Al haber creado el repo con "Use this template", estas rutas ya existen — no hay nada que copiar:

```bash
ls .claude/context/       # 00_perfil_proyecto.md
ls .claude/skills/        # las 19 de la plantilla (critic-requirements, critic-plan, critic-verifications, dev-python-coding, dev-python-testing, db-model-conventions, db-model-ideas, db-model-protocol, db-model-integration, docs-adr-writer, docs-vault-sync, docs-changelog, docs-runbook, docs-consistency-check, git-update-repo, git-close-feature, git-run-actions, verify-prepare, verify-validate) + las 10 speckit-* que añadió specify init
ls .claude/agents/        # docs-manager.md, spec-critic.md, security-reviewer.md, database-manager.md, spec-verifier.md
ls .claude/hooks/         # *.sh + .claude/settings.json en la raíz de .claude/
ls .githooks/             # pre-commit, pre-push (red local opcional, ver más abajo)
ls .specify/memory/       # data-model.md, db_ideas.md (+ constitution.md tras specify init)
ls docs/                  # Specs/, ADR/records/, Data-Model/, Runbooks/, Changelog/, Meta/
ls .github/ .github/workflows/   # dependabot.yml, workflows/ci.yml
ls .gitignore .gitattributes .gitleaks.toml LICENSE
```

Si falta alguna, el repo no se creó correctamente desde la plantilla — vuelve a generarlo con "Use this template" en vez de copiar ficheros a mano.

No hace falta `chmod +x` sobre los hooks: `settings.json` los invoca como `bash "<ruta>"`, así que el bit de ejecución es irrelevante. Los finales de línea sí importan, y de eso se encarga `.gitattributes` (`*.sh text eol=lf`), para que `bash` no falle con `$'\r': command not found` al clonar en Windows.

Opcionalmente, activa la red local de `.githooks/`: `pre-commit` busca secretos con `gitleaks` en lo que está en staging **antes** de cada commit, y `pre-push` corre lint, formato, tipado, tests y la auditoría de CVEs de dependencias **antes** de cada `push` (ahorra minutos de GitHub Actions y un ciclo de espera):

```bash
git config core.hooksPath .githooks
```

### 2.2 Rellenar el perfil del proyecto

Todos los valores que cambian de un proyecto a otro viven en **un único fichero**,
[**00_perfil_proyecto.md**](./.claude/context/00_perfil_proyecto.md). Es también el **único** fichero
que queda en `.claude/context/`: las convenciones de método ya no son ficheros de contexto siempre
activos, sino skills que se cargan bajo demanda y que leen de aquí el valor que necesiten.

| Fichero | Descripción |
| --- | --- |
| [**00_perfil_proyecto.md**](./.claude/context/00_perfil_proyecto.md) | **El único que se rellena.** Nombre y descripción del proyecto, comandos no obvios, versión de Python, framework, cobertura objetivo, motor de BD y versión, convención de PK, uso de schemas, herramienta de migraciones, visibilidad del repo. `bootstrap.ps1` rellena la parte mecánica; el resto se completa a mano. |
| [**.specify/memory/data-model.md**](./.specify/memory/data-model.md) | Modelo de datos canónico del proyecto (entidades, changelog, qué specs dependen de cada tabla). Arranca con el ejemplo de la plantilla; sustitúyelo por las tablas reales a medida que se creen, o vacíalo si el proyecto aún no tiene ninguna. |

Cada campo del perfil declara si tiene *default* o no. Los que tienen default se aplican solos y el
asistente te lo menciona; los que **no** lo tienen (herramienta de migraciones, framework, cobertura
objetivo, versión del motor) el asistente te los preguntará antes de generar nada que dependa de
ellos, en vez de asumirlos en silencio.

`db_ideas.md` no requiere relleno inicial: es la bandeja de entrada donde apuntar ideas de tabla que aún no pertenecen a ninguna feature, y ningún paso del ciclo la lee. El boceto de una feature concreta vive en `specs/<feature>/db_ideas.md`, y el protocolo de cambio de esquema es hoy la skill `db-model-protocol` (ver [Estructura de la plantilla](#estructura-de-la-plantilla)).

### 2.3 Generar CLAUDE.md

Abre `claude` dentro del proyecto y pega el prompt de [**01_init_project**](./.claude/prompts/01_init_project.md) tal cual — no tiene placeholders que rellenar: lee los datos del proyecto de `00_perfil_proyecto.md`. Esto **sobrescribe** el `CLAUDE.md` que trae la plantilla (meta-instrucciones para editar la propia plantilla) con el `CLAUDE.md` real del proyecto — es intencionado. Revisa el resultado a mano antes de continuar.

### 2.4 Configurar Obsidian

1. Abre `docs/` como vault de Obsidian.
2. Sigue [**docs/Meta/Setup.md**](./docs/Meta/Setup.md) para instalar y configurar los plugins comunitarios (Dataview, Templater y obsidian-git son imprescindibles; Tasks, Excalidraw y DBML Visualizer, opcionales).
3. Revisa [**docs/Meta/Workflow.md**](./docs/Meta/Workflow.md) para el flujo de trabajo diario con el vault.
4. La estructura de carpetas (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/Templates/`) y las plantillas Templater ya vienen creadas — no hay nada que montar.

### 2.5 Configurar GitHub

Lo que "Use this template" **ya dejó hecho**: el repo, `.github/workflows/ci.yml` y todo el árbol de
`.claude/`. Lo que queda es configuración del lado de GitHub, una sola vez por repo. `bootstrap.ps1
-SetupGitHub` automatiza (best-effort) los siete primeros puntos:

- [ ] Crear la rama `dev` desde `main` y marcarla como rama por defecto para nuevos PRs.
- [ ] Branch protection en **`dev` y `main`**: `required_status_checks.contexts = ["quality"]`, `strict: true`, `enforce_admins: true`. Las reglas y el porqué de cada ajuste están en la skill `git-update-repo`.
- [ ] Secret scanning con **push protection** (`Settings → Advanced Security`): GitHub rechaza en el servidor un push que contenga un secreto reconocible, aunque nadie tenga activada la red local. Gratis en repos públicos; en privados exige GitHub Secret Protection (de pago), y sin él `bootstrap.ps1` lo deja como paso manual. Qué cubre cada capa del escaneo de secretos: [`SECURITY.md`](SECURITY.md).
- [ ] Dependabot alerts activadas (`Settings → Advanced Security`): avisan de vulnerabilidades conocidas en las dependencias. Las PRs mensuales de actualización (GitHub Actions y dependencias `uv`, hacia `dev`) ya las define `.github/dependabot.yml`, que viene en el repo.
- [ ] Private vulnerability reporting activado (`Settings → Advanced Security`): es el canal privado de **Security → Report a vulnerability** al que remite `SECURITY.md`. Gratis en cualquier repo.
- [ ] Exigir acciones fijadas por SHA (`Settings → Actions → General`): `ci.yml` ya fija sus acciones por SHA completo; esta opción hace fallar cualquier workflow que use una por tag. Gratis en cualquier repo.
- [ ] Crear un GitHub Project (Board/Kanban) vinculado al repo y activar sus Workflows nativas (abajo).
- [ ] Fijar `Spending limit = $0` en `Settings → Billing` para evitar cargos accidentales de Actions (no tiene API ni CLI: es manual).

#### Visibilidad del repositorio

Decisión que se toma al crear el repo (paso 0) y se anota en el perfil del proyecto:

| | Repo público | Repo privado |
|---|---|---|
| Minutos de GitHub Actions | Ilimitados (fair-use) | 2.000 min/mes (Linux-equivalent) en el plan Free |
| Cuándo | El código no contiene datos ni lógica sensible | Hay credenciales, lógica de negocio propietaria o requisito de confidencialidad |

Qué hacer si el repo es privado y el consumo se acerca al límite lo cubre la skill `git-run-actions`.

#### GitHub Project: pasos web (una vez por proyecto)

El tablero agrupa los Issues que genera `/speckit-taskstoissues` — no crees issues a mano si Spec-Kit
ya los genera, para no duplicar la fuente de verdad.

1. En el repo → pestaña **Projects** → **New project** → plantilla **Board** (Kanban).
2. Vincular el repo: dentro del proyecto → **⋯ → Settings → General → Linked repositories → Add repository**.
3. Columnas: por defecto trae el campo **Status** con `Todo` / `In Progress` / `Done`. Edítalas desde el header de cada columna (**···** → *Rename*/*Delete*) o añade nuevas con **+ Add status** (p. ej. `Backlog`, `In Review`) si el flujo lo requiere.
4. Automatizaciones nativas: dentro del proyecto → **⋯ → Workflows**, activar:
   - **Item added to project** → Status: `Todo`
   - **Item reopened** → Status: `Todo`
   - **Item closed** → Status: `Done`
   - **Pull request merged** → Status: `Done`
   - **Auto-add to project**: filtro `is:issue` (o `is:issue,pr`) sobre el repositorio, para que los issues generados por `/speckit-taskstoissues` entren solos al tablero.

El Workflow "Pull request merged" es el que cierra los issues, y solo se dispara con `Closes #N` en la
descripción de la PR (ver la skill `git-close-feature`).

#### Lo que esta plantilla no usa

- **GitHub Wiki**: no es la fuente de verdad de la documentación (esa es el vault de Obsidian). Actívala solo si necesitas una vista pública mínima sin dar acceso al vault completo.
- **GitHub Pages**: opcional, para publicar documentación estática (ej. exportando el vault con MkDocs) si el proyecto necesita un sitio de docs público.

### 2.6 Verificación final

```bash
/context # dentro de Claude Code: confirma que CLAUDE.md y sus imports se cargaron
/doctor # confirma que hooks y skills están activos
```

- [ ] `specify check` en verde.
- [ ] `bash`, `jq` y `uv` en el `PATH` (sin `jq` los guards bloquean toda escritura, lectura y comando: son *fail-closed*).
- [ ] `.claude/context/00_perfil_proyecto.md` sin placeholders `[ ]` pendientes. **Es el único fichero
      del repo que hay que rellenar**: ni `docs/Meta/`, ni las skills, ni los prompts llevan placeholders.
- [ ] `.specify/memory/data-model.md` con las entidades reales, o vaciado si el proyecto aún no tiene
      ninguna tabla — lo que trae la plantilla es un ejemplo. (`db_ideas.md` es una bandeja de entrada
      vacía y mantiene los corchetes de plantilla a propósito: no cuenta para este punto.)
- [ ] `CLAUDE.md` generado y revisado a mano (sobrescribe el de la plantilla).
- [ ] Vault de Obsidian con los plugins comunitarios instalados.
- [ ] Repo GitHub con rama `dev`, CI y branch protection en `dev` y `main` configurados; secret scanning con push protection si el plan lo permite; Dependabot alerts, reporte privado de vulnerabilidades y SHA obligatorio en Actions.
- [ ] *(opcional)* Red local activada (`pre-commit` con `gitleaks` + `pre-push`): `git config core.hooksPath .githooks`.
- [ ] Documentación de la plantilla retirada o sustituida: `README.md`, `bootstrap.ps1`,
      `bootstrap_example.md` y `CONTRIBUTING.md`. `SECURITY.md` **se conserva y se adapta**: describe
      los hooks, las capas de seguridad y el procedimiento ante un secreto filtrado, y remiten a él
      los hooks del repo; revisa al menos su sección "Reportar un problema". `LICENSE` **revísalo**:
      hereda la MIT de la plantilla y probablemente quieras otra para tu proyecto.

Con esto, el harness está listo y puedes empezar el primer ciclo SDD con [**02_spec_development**](./.claude/prompts/02_spec_development.md) (proyecto nuevo: entra directamente por el paso 1.0 y sáltate la Fase 0).

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

##### `critic-requirements`
Audita una petición de feature contra las 10 categorías de ambigüedad **antes** de escribir la spec, y devuelve el prompt aumentado listo para pegar en `/speckit-specify` más la lista de huecos de alcance que hay que cerrar primero, ordenada por impacto. Se usa en el paso 1.1 del ciclo. Se apoya en el subagente `spec-critic`.

##### `critic-plan`
Revisión adversarial de `spec.md`/`plan.md`/`tasks.md` en contexto limpio, con los cinco ejes (supuestos, consistencia cruzada, ambigüedades, riesgos y modos de fallo, sobre-ingeniería). Devuelve el listado completo de hallazgos y un veredicto GO/NO-GO; ante NO-GO indica a qué paso del ciclo hay que volver. Se usa en el paso 2.8, obligatoriamente antes de `/speckit-implement`. Se apoya en el subagente `spec-critic`.

##### `critic-verifications`
Audita el criterio de cierre antes de converger: qué tareas exigen UAT humana, cuáles se han cerrado sin evidencia objetiva, y si la clasificación `automatizable`/`manual` de `quickstart_agent.md` es correcta. No ejecuta ni escribe nada — esa es la frontera con `verify-validate`. Se usa en el paso 4.4. Se apoya en el subagente `spec-critic`.

##### `dev-python-coding`
Convenciones de escritura de código Python (gestión con `uv`, layout `src/`, tipado estático con genéricos built-in y PEP 695, Pydantic v2, ruff + `ty`, docstrings Google style, criterios de elección de framework). Lee la versión de Python y el framework del perfil del proyecto. Se carga en el paso 4.1, justo antes de `/speckit-implement`, y en cualquier edición de un `.py` fuera del ciclo. **Es una skill plana**: no forkea a ningún subagente, porque el código se escribe en el hilo principal, que es el que tiene `spec.md`/`plan.md`/`tasks.md` y el bucle de corrección del paso 4.3.

##### `dev-python-testing`
Convenciones de testing (pytest, `tests/` como espejo de `src/[paquete]/`, mockeo obligatorio de conexiones a BD y de todo lo externo, cobertura mínima del perfil) y la regla dura de que ningún endpoint o función de negocio se cierra en `tasks.md` sin al menos un test. Se carga junto a `dev-python-coding` en el paso 4.1, y es plana por el mismo motivo.

##### `db-model-conventions`
Convenciones de esquema (motor, naming, campos de auditoría obligatorios con su trigger, política de índices, regla de migraciones y anexo de cuándo introducir NoSQL), válidas tanto para PostgreSQL como para SQL Server. Lee del perfil del proyecto el motor, la versión, la convención de PK, el uso de schemas y la herramienta de migraciones. Se carga en el paso 2.1, justo antes de `/speckit-plan`, y sigue en contexto para el 4.1. **Es una skill plana**: `/speckit-plan` es un comando de Spec-Kit cuyo interior no controlamos y es él quien genera `data-model.md`, así que la única forma determinista de que lo genere bien es tener las convenciones puestas cuando arranca.

##### `db-model-ideas`
Recoge el boceto humano de tablas de la feature en `specs/<feature>/db_ideas.md`, con la plantilla de bloque por tabla y la regla de que es un punto de partida, nunca una fuente de verdad. Se usa en el paso 1.4. El boceto es por feature a propósito: dos features en ramas paralelas no se pisan el fichero, y `/speckit-plan` no arrastra al contexto tablas ajenas. También plana.

##### `db-model-protocol`
Diseña el esquema de la feature y lo reconcilia contra el modelo canónico en contexto limpio: reutilización antes que creación, análisis de impacto sobre cada spec dependiente, y prioridad de la spec nueva sobre la antigua. Entrega DDL, `erDiagram` Mermaid y la tabla de specs afectadas, y **no aplica nada** — espera aprobación humana explícita. Se usa en el paso 2.2. Se apoya en el subagente `database-manager`.

##### `db-model-integration`
Tras la aprobación explícita del esquema, entrega el comando exacto de la herramienta de migraciones y el DDL revisado —**nunca escribe el fichero de migración**, que el hook bloquea a propósito— y actualiza `.specify/memory/data-model.md` (entidad + changelog), el `data-model.md` local de la spec y las readaptaciones aprobadas. Se usa en el paso 4.2. Se apoya en el subagente `database-manager`.

##### `docs-adr-writer`
Redacta un ADR: ruta y numeración correlativa en `docs/ADR/records/`, formato Nygard (Contexto · Decisión · Consecuencias), regla append-only con `supersede:` en el ADR nuevo, criterio de qué decisión merece ADR y cuál no, y el índice Dataview de `docs/ADR/Overview.md`. Se usa en el paso 2.4 —el mismo día de la decisión, antes de `/speckit-tasks`— y en el 5.3 para lo que quedara suelto. Se apoya en el subagente `docs-manager`.

##### `docs-vault-sync`
Decide **qué** nota del vault toca cada evento del ciclo (`data-model.md` → `docs/Data-Model/[feature]-ER.md`; converge → `docs/Specs/[feature].md` y el espejo del changelog), con `docs/Meta/Overview.md` como precondición y wikilinks cruzados Spec ↔ ADR ↔ Issue ↔ Runbook. El formato de ADR, runbook y changelog lo delega en sus skills, para que no haya dos fuentes de verdad. Se usa en los pasos 2.3 y 5.3. Se apoya en el subagente `docs-manager`.

##### `docs-changelog`
Genera las entradas de `CHANGELOG.md` a partir de los Conventional Commits del rango de la feature, en formato Keep a Changelog 2.0.0, con la tabla de mapeo prefijo → sección y el tratamiento de `BREAKING CHANGE:` (que además exige comprobar que existe el ADR que lo documenta). Se usa en el paso 5.4. **Es una skill plana**: `docs-manager` no tiene `Bash` a propósito —así no puede commitear— y leer el rango con `git log` es justo lo que esta tarea necesita.

##### `docs-runbook`
Redacta un runbook en `docs/Runbooks/` cuando la feature introduce un procedimiento operativo nuevo (deploy especial, rollback, migración con ventana de mantenimiento). Plantilla `docs/Meta/Templates/runbook.md` y la regla dura de que un runbook sin rollback está incompleto. Se usa en el paso 5.3, invocada desde el resultado de `docs-vault-sync`. Se apoya en el subagente `docs-manager`.

##### `docs-consistency-check`
El checklist de seis puntos que se recorre antes de cerrar cualquier feature: docstrings y type hints, ADR si hubo decisión, Conventional Commits con ID de feature, `CHANGELOG.md`, nota de vault enlazada con su ADR e Issue, y UAT humana confirmada. **Audita con evidencia concreta, no redacta**; si algún punto sale ❌, se vuelve al 5.3/5.4. Se usa en el paso 5.5. También plana: necesita `git log`, y un auditor no debe llevar permisos de escritura.

##### `git-update-repo`
Convenciones de Git y GitHub: modelo de ramas (`main` desplegable, `dev` de integración, `feature/<id-speckit>-<slug>`), la regla de que la rama de feature es obligatoria sin excepción por trivialidad con sus dos razones, el modelo de branch protection de `dev` y `main` con el comando `gh api .../protection` (y el aviso de que `PUT` sobrescribe el objeto entero), y el formato de los mensajes de commit (Conventional Commits con el ID de feature en el scope, que es lo que consume `docs-changelog`). Se carga en el paso 3.3 y sigue en contexto hasta el 5.6. **Es una skill plana**: son convenciones que necesita puestas el hilo que crea la rama y redacta los commits.

##### `git-close-feature`
El cierre en GitHub: commit, `push` de la rama y PR hacia `dev` con un **`Closes #N` repetido por cada issue** (nunca una lista con comas — GitHub solo cierra la referencia inmediatamente posterior a `Closes`), y la frontera dura de que el asistente propone activamente la PR `feature/* → dev` pero **nunca** abre la PR `dev → main`, que es del humano igual que el merge. Se usa en el paso 5.6. También plana: redactar el commit y el cuerpo de la PR exige saber qué se implementó y qué issues cubre, justo lo que un contexto limpio no tiene, y `push`/`gh pr create` son acciones irreversibles hacia fuera.

##### `git-run-actions`
Supervisión del CI de la PR: leer el estado del check `quality` (`gh pr checks`, `gh run view --log-failed`), diagnosticar cuál de los cuatro pasos del job falla (`ruff check` / `ruff format --check` / `ty check` / `pytest`) y proponer la corrección, más el coste de minutos de Actions según la visibilidad del repo y la red local `.githooks/pre-push`. **No edita `ci.yml`**: es estático y gateado por `pyproject.toml` + `src/` a propósito, y parchearlo para que un check pase silencia un fallo real. Se usa en el paso 5.7. Plana: diagnosticar el rojo exige ver el código recién escrito, y la corrección la aplica el mismo hilo.

##### `verify-prepare`
Traduce `specs/<feature>/quickstart.md` (prosa) a `specs/<feature>/quickstart_agent.md`, un formato estructurado que clasifica cada escenario como `automatizable` o `manual` y lo mapea a su `FR-XXX`/`US-X` de `spec.md`. Se usa tras el GO del subagente `spec-critic`, o cuando `quickstart.md` cambia y `quickstart_agent.md` queda desactualizado (fusión idempotente: conserva el resultado de los escenarios sin cambios). Se apoya en el subagente `spec-verifier`.

##### `verify-validate`
Ejecuta los escenarios `automatizable` de `quickstart_agent.md` de la feature activa y anota en ese mismo fichero el resultado de cada uno (✅ REALIZADA / ❌ ERRÓNEA / ⏳ PENDIENTE / 🚫 INALCANZABLE), con evidencia objetiva. Nunca corrige el proyecto ni edita otro fichero. Se usa tras `/speckit-implement`, y de nuevo tras cada corrección, hasta que no queden ERRÓNEAS ni INALCANZABLES. Se apoya en el subagente `spec-verifier`.

Puedes añadir más según crezca el proyecto (ej. `fastapi-endpoint-scaffold`, `pytest-fixtures`), pero empieza solo con estas — más skills de las que realmente usas solo añaden ruido a la carga inicial.

#### Subagentes

Todos los subagentes son solo **recomendaciones** para este stack en concreto y ya vienen incluidos en `.claude/agents/` al crear el repo desde esta plantilla — no hay que instalarlos:

##### `spec-critic`
Motor de crítica compartido por las skills `critic-requirements`, `critic-plan` y `critic-verifications`. Contexto limpio: solo ve los ficheros de la feature, no el histórico de la conversación de planificación. Es read-only por construcción (`tools: Read, Grep, Glob`): observa y reporta, nunca escribe ni corrige lo que encuentra roto.

##### `database-manager`
Motor de base de datos compartido por las skills `db-model-protocol` y `db-model-integration`. Contexto limpio: ve el modelo canónico y los ficheros de la feature, no el histórico de la conversación de planificación. No tiene `Bash` ni `Write` (`tools: Read, Grep, Glob, Edit`): no escribe migraciones ni las aplica, y no modifica el modelo canónico sin aprobación humana explícita y previa.

##### `docs-manager`
Motor de documentación compartido por las skills `docs-adr-writer`, `docs-vault-sync` y `docs-runbook`. Contexto limpio: ve los ficheros de la feature y el vault, no el histórico de la conversación. No tiene `Bash` (`tools: Read, Grep, Glob, Write, Edit`): escribe borradores pero no commitea, no edita un ADR ya aceptado y no inventa contenido que no esté en `spec.md`/`plan.md`/los commits.

##### `security-reviewer`
Revisa cambios que tocan superficies sensibles (autenticación, gestión de secretos/`.env`, migraciones, entradas no confiables) antes de `/speckit-converge`, buscando vulnerabilidades tipo OWASP Top 10. Complementa al hook `pre_edit_guard_sensitive.sh` (que bloquea la escritura, y la lectura de `.env`) revisando la lógica una vez escrita.

##### `spec-verifier`
Motor de ejecución compartido por las skills `verify-prepare` y `verify-validate`. Nunca corrige código de producción, configuración ni tests, y nunca inventa un resultado sin evidencia objetiva; solo puede escribir `quickstart_agent.md` de la feature activa, restricción reforzada por el hook `guard-quickstart-agent.sh` (declarado en su propio frontmatter, no en `.claude/settings.json`, porque solo debe aplicar a sus escrituras, no a toda la sesión).

#### Hooks

Todos los hooks son solo **recomendaciones** para este stack en concreto y ya vienen incluidos en `.claude/settings.json` al crear el repo desde esta plantilla — no hay que instalarlos:

1. **PostToolUse en `Edit`/`Write` sobre `*.py`** → `ruff format` + `ruff check --fix` + `ty check` automáticos. Falla en abierto: si faltan `jq` o `uv`, no hace nada y la edición sigue. Es una comodidad, no una barrera.
2. **Stop** → `uv run pytest -q`; si falla, Claude ve el resultado antes de dar la tarea por cerrada. Gateado por `pyproject.toml` + `src/`, igual que el CI, y con protección de bucle (`stop_hook_active`) para que unos tests que no se consiguen arreglar no reenganchen la sesión indefinidamente.
3. **PreToolUse en `Write`/`Edit`/`Read`/`Grep`/`Bash` sobre `migrations/**` o ficheros `.env`** → bloquea la escritura de ambos y la lectura de `.env` (no pide confirmación: el hook sale con código 2 y corta la acción), dado que son ficheros de alto riesgo (datos de producción / secretos). Leer un `.env` también es una fuga: su contenido entra en la conversación y sale de la máquina. El humano decide manualmente si aplica el cambio por otra vía. Cubre `Bash` además de las herramientas de ficheros porque si no, un `alembic revision`, un `sed -i`, un `echo >` o un `cat .env` lo rodearían y la red de seguridad sería decorativa. Tres compromisos deliberados: para `migrations/` bloquea cualquier comando `Bash` que mencione la ruta, lectura incluida (leer una migración se hace con `Read`/`Grep`, que el hook deja pasar para migraciones); para `.env` en `Bash` bloquea la escritura y los comandos de lectura habituales (`cat`, `head`, `grep`, `Get-Content`, `source`…), pero no cualquier mención, para no romper usos legítimos como `docker compose --env-file`; y deja pasar siempre `.env.example`/`.sample`/`.template`, que son plantillas sin secretos.
4. **PreToolUse en `Write`/`Edit`, scopeado al subagente `spec-verifier`** (declarado en `.claude/agents/spec-verifier.md`, no en la lista de arriba) → bloquea cualquier escritura suya que no sea `quickstart_agent.md` de la feature activa.

Los dos guards (3 y 4) son **fail-closed**: si falta `jq` o si el JSON de entrada no se puede interpretar, **bloquean** (el 4, además, si no llega `file_path`). Un `PreToolUse` que sale con un código distinto de 2 es, para Claude Code, un error *no bloqueante*: la acción se permitiría igualmente. Un guard que "falla hacia fuera" sería decorativo justo cuando más falta hace. El precio es que sin `jq` no se puede escribir nada — por eso es prerrequisito obligatorio, y por eso `bootstrap.ps1` se detiene si falta.

Los dos comparan rutas **normalizando el separador**, así que funcionan igual con `H:\proyecto\migrations\001.py` que con `/proyecto/migrations/001.py`. Sus límites conocidos están en [`SECURITY.md`](SECURITY.md): son una red de seguridad, no un sandbox.

Fuera de `.claude/`, la plantilla trae además dos hooks de Git en **`.githooks/`** (opcionales, se activan juntos con `git config core.hooksPath .githooks`):

- **`pre-commit`**: escanea con `gitleaks` lo que está en staging y aborta el commit si encuentra un posible secreto. Usa las reglas por defecto de gitleaks más las excepciones de `.gitleaks.toml` (las plantillas `.env.example`/`.sample`/`.template`). Si `gitleaks` no está instalado, avisa y deja pasar; si está instalado pero falla (p. ej. `.gitleaks.toml` mal escrito), bloquea.
- **`pre-push`**: corre las cinco comprobaciones de Python del job `quality` del CI (ruff, formato, ty, pytest y la auditoría de CVEs de dependencias con `pip-audit`) antes de cada `push`, para no gastar minutos de Actions en un fallo detectable en local. El otro paso de `quality`, el escaneo de secretos, lo cubre `pre-commit`.

El job `quality` repite el escaneo de `gitleaks` en el CI sobre **todo el historial** del repo, en cada PR y cada push a `dev`, esté o no activada la red local. Ese paso corre antes del gate de `pyproject.toml`/`src/`, así que protege desde el primer commit del proyecto. Usa la misma `.gitleaks.toml` que el hook local.

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

Al vivir dentro del repo, cualquier humano que clone el proyecto (o tú mismo en otra máquina) hereda automáticamente el mismo comportamiento del asistente — es el mismo objetivo de mantenibilidad que persiguen las skills `docs-*`: que cualquier desarrollo pueda retomarlo un humano que no participó en la conversación con la IA.

#### A nivel global
Aplica a todos tus proyectos con este stack, ej. convenciones Python/PostgreSQL que repites siempre. Puedes promover una skill/subagente ya presente en un proyecto concreto (incluido este):

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r .claude/skills/db-model-conventions ~/.claude/skills/
cp .claude/agents/spec-critic.md ~/.claude/agents/
```

- Precedencia: si un skill/subagente con el mismo nombre existe tanto en `.claude/` (proyecto) como en `~/.claude/` (global), **gana el del proyecto**. Usa esto para tener una versión global genérica y sobreescribirla por proyecto solo cuando haga falta.
- Los hooks (`settings.json`) **no** se heredan por fusión automática entre global y proyecto en todas las versiones de Claude Code. Verifica con `/doctor` que los hooks esperados están activos tras clonar un proyecto nuevo.

## Estructura de la plantilla

Al usar "Use this template", el repo nuevo nace con estas rutas ya en su sitio (nada que copiar):

| Ruta | Contenido |
| --- | --- |
| `.claude/context/00_perfil_proyecto.md` | Los valores concretos de este proyecto (versión de Python, motor de BD, herramienta de migraciones, visibilidad…). **El único fichero de `.claude/context/`**, y el único import `@` del `CLAUDE.md`. Ninguna convención vive ya aquí: las de código Python, base de datos, documentación y Git son las skills `dev-python-*`, `db-model-*`, `docs-*` y `git-*` |
| `.specify/memory/data-model.md`, `db_ideas.md` | Estado real del proyecto, nunca método: el modelo de datos canónico, y la bandeja de entrada de ideas de tabla sin feature asignada (que ningún paso del ciclo lee — el boceto de una feature vive en `specs/<feature>/db_ideas.md`). Nada de esta carpeta se importa en `CLAUDE.md`. `specify init` añade aquí además `constitution.md` |
| `.claude/skills/*` | Skills recomendadas (`critic-requirements`, `critic-plan`, `critic-verifications`, `dev-python-coding`, `dev-python-testing`, `db-model-conventions`, `db-model-ideas`, `db-model-protocol`, `db-model-integration`, `docs-adr-writer`, `docs-vault-sync`, `docs-changelog`, `docs-runbook`, `docs-consistency-check`, `git-update-repo`, `git-close-feature`, `git-run-actions`, `verify-prepare`, `verify-validate`) |
| `.claude/agents/*` | Subagentes recomendados (`spec-critic`, `database-manager`, `docs-manager`, `security-reviewer`, `spec-verifier`) |
| `.claude/hooks/*.sh` + `.claude/settings.json` | Hooks recomendados (formateo post-edición, tests en Stop, guard de ficheros sensibles, guard de escritura de `spec-verifier` scopeado en su propio agente) |
| `.claude/prompts/*.md` | Biblioteca de prompts maestros: `01_init_project.md` (generación única del `CLAUDE.md` real) y `02_spec_development.md` (ciclo completo de una spec, con Fase 0 de encuadre para retomar el proyecto) |
| `docs/` | Esqueleto del vault de Obsidian (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Meta/` con las guías de setup/workflow y las plantillas de nota) |
| `.githooks/pre-commit`, `.githooks/pre-push` | Red local opcional: `pre-commit` escanea secretos con `gitleaks` antes de cada commit; `pre-push` corre las comprobaciones de Python del CI (ruff/ty/pytest/pip-audit) antes de cada `push`. Se activan con `git config core.hooksPath .githooks` |
| `.gitleaks.toml` | Configuración de `gitleaks`: reglas por defecto más el allowlist de las plantillas `.env.example`/`.sample`/`.template` |
| `.github/workflows/ci.yml` | Workflow de CI: escaneo de secretos con `gitleaks` sobre todo el historial (siempre) y ruff/ty/pytest/pip-audit (gateados por la existencia de `pyproject.toml` y `src/`). Token de solo lectura (`permissions: contents: read`) y acciones fijadas por SHA completo, no por tag |
| `.github/dependabot.yml` | Como mucho una PR mensual de Dependabot por ecosistema, hacia `dev`: GitHub Actions (mantiene al día los SHA de `ci.yml`) y dependencias `uv`. Pasan el mismo check `quality` y se mergean tras revisión humana |
| `.gitignore` | Escrito para este stack: secretos (`.env*`, claves y certificados, `.pgpass`, `credentials.json`), datos de BD (backups `.bak`, dumps, `.mdf`/`.ldf`, SQLite), Python, entornos `uv` (pero **no** `uv.lock`, que se versiona), estado local de Obsidian y `settings.local.json` de Claude Code |
| `.gitattributes` | Normalización de finales de línea. `*.sh text eol=lf` es lo que evita que los hooks lleguen con CRLF al clonar en Windows y `bash` falle con `$'\r': command not found` |
| `LICENSE` | MIT. **Revísalo en tu proyecto**: se hereda la licencia de la plantilla, que probablemente no sea la que quieres |

Este `README.md`, `bootstrap.ps1`, `bootstrap_example.md` y `CONTRIBUTING.md` son documentación **de la propia plantilla** (no de tu proyecto): puedes borrarlos del repo del proyecto una vez completada la puesta en marcha, o dejarlos como referencia. `SECURITY.md` no se borra: describe lo que el repo ejecuta, sus capas de seguridad y qué hacer si se filtra un secreto, y remiten a él `.githooks/pre-commit` y `pre_edit_guard_sensitive.sh`; se adapta al proyecto (como mínimo, "Reportar un problema"). `LICENSE` tampoco se borra, se sustituye por la que corresponda a tu proyecto.

## Principio rector de toda la plantilla

`CLAUDE.md` se mantiene deliberadamente corto. La sustancia vive fuera de él y solo se referencia: los valores del proyecto, con un único import (`@.claude/context/00_perfil_proyecto.md`); todas las convenciones de método, con la tabla de enrutado a skills (`/critic-*`, `/dev-python-*`, `/db-model-*`, `/docs-*`, `/git-*`). Esto evita que un `CLAUDE.md` sobrecargado haga que Claude ignore la mitad de las reglas: una skill se carga sola cuando su dominio es relevante, en vez de ocupar la ventana desde el primer turno.
