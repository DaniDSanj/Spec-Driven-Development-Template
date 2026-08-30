# Guía práctica: Spec-Driven Development con GitHub Spec-Kit y Claude Code — prompts maestros, context engineering y stack de documentación (agosto 2026)

## TL;DR
- **Spec-Driven Development (SDD)** invierte la relación código↔especificación: la spec es la fuente de verdad ejecutable. GitHub **Spec-Kit** (>120.000 estrellas, licencia MIT, funciona con más de 30 agentes) lo operacionaliza con nueve comandos slash (`/speckit.constitution`, `.specify`, `.clarify`, `.plan`, `.checklist`, `.tasks`, `.analyze`, `.implement`, `.converge`) que funcionan con Claude Code; instálalo con `uv tool install specify-cli` e inicia con `specify init`.
- Para que Claude Code sea **crítico y exhaustivo**, la clave no es un prompt perfecto sino *context engineering*: un `CLAUDE.md` corto, skills bajo demanda, subagentes para investigación/revisión adversarial, hooks deterministas, plan mode antes de codificar, y `/clarify` + prompts anti-sycophancy que obliguen a preguntar antes de asumir.
- Tu stack gratuito (Claude Code + Spec-Kit + PostgreSQL/SQL Server + Obsidian + GitHub Free) es totalmente viable: usa Python 3.14.7 con uv/Ruff/ty, ADRs versionados, `CHANGELOG.md` estilo Keep a Changelog 2.0.0 + Conventional Commits, y GitHub Actions (2.000 min/mes en repos privados, ilimitado en públicos). Al final de este informe tienes un set de **prompts maestros reutilizables** para todo el ciclo de vida.

## Key Findings

1. **SDD es una metodología, no una herramienta.** GitHub la define como "flips the script": las especificaciones se vuelven ejecutables y generan la implementación en lugar de solo guiarla. Se diferencia del *vibe coding* (chatear y codificar sin requisitos duraderos) porque fija límites, criterios de aceptación y trade-offs en artefactos versionados antes de escribir código.
2. **Spec-Kit ha evolucionado más allá de los 7 comandos originales.** A agosto 2026 el flujo canónico es: `constitution → specify → clarify → plan → checklist → tasks → analyze → taskstoissues → implement → converge` (`taskstoissues` siempre antes de `implement`, nunca después). Los comandos ahora usan el prefijo `/speckit.*`.
3. **`/speckit.clarify` es el mecanismo nativo de elicitación crítica**: escanea ambigüedades en 10 categorías taxonómicas y hace hasta 5 preguntas dirigidas de una en una, codificando las respuestas en la spec. `/speckit.analyze` hace análisis de consistencia cross-artefacto (read-only) antes de implementar.
4. **Anthropic ha formalizado "context engineering"** como la evolución del prompt engineering: gestionar el conjunto completo de tokens (system prompt, tools, MCP, historial) porque existe *context rot* — según Anthropic, "as the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases", y el contexto debe tratarse como "a finite resource with diminishing marginal returns". Técnicas oficiales: compaction, structured note-taking, sub-agent architectures y "just-in-time retrieval".
5. **Para código mantenible por humanos**: ADRs (formato Michael Nygard: Context/Decision/Consequences), append-only, un ADR por decisión; docstrings estilo Google/NumPy consistentes; type hints (PEP 484/695); trazabilidad spec→plan→tasks→commit vía Conventional Commits.
6. **Stack gratuito documentado**: Obsidian (Dataview + Templater + obsidian-git + Kanban + Excalidraw + Mermaid nativo) para el vault; GitHub Free para CI/CD y trazabilidad.

## Details

### 1. Qué es Spec-Driven Development

**Definición y principios.** SDD "flips the script" del desarrollo tradicional: durante décadas el código fue el rey y las specs eran andamiaje desechable; SDD hace que **las especificaciones se vuelvan ejecutables**, generando la implementación en lugar de solo guiarla (README oficial de spec-kit). El documento `spec-driven.md` del repo lo formula así: "Specifications don't serve code—code serves specifications. The PRD isn't a guide for implementation; it's the source that generates implementation."

La filosofía central de Spec-Kit enumera cuatro pilares:
- **Intent-driven development**: las specs definen el "qué" antes del "cómo".
- **Rich specification creation** usando guardrails y principios organizacionales.
- **Multi-step refinement** en lugar de generación one-shot desde prompts.
- **Heavy reliance** en las capacidades del modelo para interpretar la spec.

**Diferencias con otras metodologías:**
- **vs. Vibe coding**: el vibe coding funciona para prototipos desechables, pero según GitHub el problema no es la capacidad del agente sino tratarlo como buscador en vez de como "pair programmer literal" que necesita instrucciones sin ambigüedad. SDD fija requisitos, criterios de aceptación y trade-offs de forma duradera.
- **vs. Waterfall**: aunque SDD es "spec-first" como waterfall, es explícitamente **iterativo**: cambiar de rumbo es fácil ("just update the spec, regenerate the plan, and let the coding agent handle the rest"), a diferencia del bloqueo temprano de waterfall. Spec-Kit incluso permite un preset para adaptar el workflow a Agile, Kanban, Waterfall o DDD.
- **vs. TDD**: no son excluyentes; la constitution puede exigir TDD ("We use TDD strictly") y `/speckit.tasks` genera tests dentro de la fase de cada user story. SDD opera a un nivel superior (requisitos→diseño) mientras TDD opera a nivel de implementación.

**Ventajas documentadas**: workflow auditable, trazable y reutilizable; requisitos, seguridad y design system "baked into the spec from day one"; especialmente útil en tres escenarios (greenfield/0-to-1, exploración creativa con implementaciones paralelas, y modernización brownfield iterativa).

**Inconvenientes documentados**: es un **experimento** (así lo declara GitHub). No es buen ajuste para "very small one-off scripts" — para problemas de pocas líneas el workflow completo resulta pesado (fuente: KnightLi Blog, corroborado por el README que lo posiciona para tareas con múltiples módulos, estado, permisos, modelos de datos o mantenimiento a largo plazo). El overhead de generar constitution+spec+plan+tasks se amortiza solo cuando la complejidad lo justifica. Riesgo adicional: `/speckit.implement` "often felt like jumping off a cliff" — el agente tiene la info pero puede implementar mal si la spec no se validó con clarify/analyze (fuente: DEV Community).

### 2. Flujo completo y actualizado de GitHub Spec-Kit

**Instalación (recomendada, con uv):**
```
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@vX.Y.Z
```
Spec Kit se distribuye por dos canales oficiales: el repositorio github/spec-kit (source installs) y el paquete `specify-cli` en **PyPI** (`uv tool install specify-cli`, o versión fija `uv tool install specify-cli==0.12.11`). Prerrequisitos: Linux/macOS/Windows, Python 3.11+, Git, uv (o pipx) y un agente compatible. **No instalar paquetes PyPI de terceros con el mismo nombre** que no sean el oficial. Gestión: `specify self check`, `specify self upgrade`.

**Inicialización con Claude Code:**
```
specify init my-project --integration claude
cd my-project
```
(El README usa `--integration copilot` como ejemplo; para Claude Code usa `claude`.) Tras `specify init`, tu agente tiene los comandos slash. Spec-Kit funciona con más de 30 agentes de codificación —incluidos Claude Code, GitHub Copilot, Cursor, Gemini CLI y Codex CLI—; ejecuta `specify integration list` para ver los disponibles en tu versión.

**Comandos (agosto 2026):**

*Core:*
| Comando | Descripción |
|---|---|
| `/speckit.constitution` | Crea/actualiza los principios rectores del proyecto |
| `/speckit.specify` | Define qué construir (requisitos, user stories) |
| `/speckit.plan` | Plan técnico con tu stack elegido |
| `/speckit.tasks` | Lista de tareas accionables con dependencias |
| `/speckit.taskstoissues` | Convierte tareas en GitHub Issues |
| `/speckit.implement` | Ejecuta las tareas y construye la feature |
| `/speckit.converge` | Evalúa el código contra spec/plan/tasks y añade trabajo pendiente (append-only) |

*Opcionales (quality gates):*
| Comando | Descripción |
|---|---|
| `/speckit.clarify` | Aclara áreas subespecificadas (antes `/quizme`); recomendado antes de `/plan` |
| `/speckit.analyze` | Análisis de consistencia cross-artefacto (tras `tasks`, antes de `implement`) |
| `/speckit.checklist` | Genera checklists de calidad ("unit tests for English") |

**Orden canónico:** `constitution → specify → clarify → plan → checklist → tasks → analyze → taskstoissues → implement → converge`. Solo `/speckit.specify` es estrictamente obligatorio antes de `/speckit.plan`; clarify/checklist/analyze son gates que añades cuando hay ambigüedad. `taskstoissues` va siempre antes de `implement`, nunca después: crear los issues tras implementar no da seguimiento en tiempo real y los deja sin cerrar automáticamente si no hubo rama/PR (ver [**01_github_workflow.md**](../files/github/01_github_workflow.md)).

**Detalles de comandos clave:**
- **`/speckit.clarify`**: escanea ambigüedades en 10 categorías taxonómicas (functional scope, domain model, UX flow, non-functional, integration, edge cases, constraints, terminology, completion signals, placeholders) y hace hasta 5 preguntas dirigidas de una en una, presentando respuestas recomendadas con razonamiento. Puedes ejecutarlo varias veces; cada pasada detecta huecos distintos.
- **`/speckit.plan`**: incluye un **Constitution Check** (gate que verifica que el enfoque no viole ningún principio MUST de la constitution). Genera research.md (Phase 0), data-model.md y contracts/ (Phase 1, OpenAPI/GraphQL).
- **`/speckit.analyze`**: read-only; reporta conflictos/huecos/ambigüedades (ej. tarea sin requisito, plan que contradice la spec). Nunca edita.
- **`/speckit.converge`**: append-only; imprime findings graduados por severidad y o bien reporta "Converged" o añade tareas nuevas en tasks.md.

**Estructura de carpetas que genera:**
- `.specify/memory/constitution.md` — constitution versionada.
- `specs/<N>-<feature-name>/spec.md` — spec detallada + `checklists/requirements.md`.
- Dentro de la feature: `plan.md`, `research.md`, `data-model.md`, `contracts/`, `tasks.md`.
- Comandos instalados en directorios del agente (ej. `.claude/commands/` para Claude Code).
- Sistema de personalización por prioridad: overrides de proyecto (`.specify/templates/overrides/`) > presets > extensions > core.

**Extensiones/presets/bundles**: `specify extension add`, `specify preset add`, `specify bundle install` permiten añadir capacidades (ej. Jira, code review, V-Model traceability), personalizar formatos (compliance, terminología, test-first) o provisionar setups por rol.

**Integración con Claude Code específicamente**: los comandos se instalan como slash commands en `.claude/commands/`; Claude Code los lee y ejecuta scripts helper (bash/PowerShell) para aplicar el scaffolding SDD de forma consistente. Comparativamente, Copilot/Cursor/Gemini CLI usan la misma mecánica; Codex CLI y agentes en "skills mode" usan `$speckit-*` en vez de `/speckit.*`.

### 3. Mejores prácticas de prompt engineering para agentes (Claude Code, 2025-2026)

Basado en la documentación oficial de Claude Code (code.claude.com/docs) y Anthropic:

**El workflow fundamental: "Explore → Plan → Code → Commit".** No dejes que Claude salte directamente a codificar (produce código que resuelve el problema equivocado). Usa **plan mode** (Shift+Tab hasta `⏸ plan mode on`, o `claude --permission-mode plan`) para separar exploración de ejecución.

**CLAUDE.md — el archivo de contexto persistente.** Claude lo lee al inicio de cada conversación. Genéralo con `/init` y refínalo. Reglas oficiales:
- **Corto y humano-legible**; para cada línea pregunta "¿quitar esto haría que Claude cometa errores?" Si no, bórrala.
- **Incluye**: comandos bash no adivinables, reglas de estilo que difieran de los defaults, instrucciones de testing, etiqueta del repo (naming de ramas/PRs), decisiones arquitectónicas específicas, quirks del entorno, gotchas.
- **Excluye**: lo que Claude deduce leyendo código, convenciones estándar del lenguaje, documentación de API detallada (enlázala), info que cambia frecuentemente, prácticas obvias.
- Un CLAUDE.md sobrecargado hace que Claude **ignore la mitad** — poda sin piedad. Puedes usar "IMPORTANT"/"YOU MUST" para mejorar adherencia, e importar con `@path/to/import`. Verifica que se cargó con `/context`.

**Skills** (`.claude/skills/<name>/SKILL.md`): conocimiento de dominio y workflows reutilizables cargados **bajo demanda** (progressive disclosure) según la descripción del skill — no engordan cada conversación. Ideal para "cómo hacemos migraciones aquí" o checklists. Invócalos directamente con `/skill-name`.

**Subagentes** (`.claude/agents/*.md`): corren en su propia ventana de contexto con sus propias tools. Dos usos clave: (a) **investigación** sin contaminar el contexto principal; (b) **revisión adversarial** — un reviewer en contexto fresco ve solo el diff, no el razonamiento que lo produjo. Devuelven solo un resumen destilado (típ. 1.000-2.000 tokens).

**Hooks** (`.claude/settings.json`): scripts shell deterministas en eventos del ciclo (PreToolUse, PostToolUse, SessionStart, UserPromptSubmit, Stop). A diferencia de CLAUDE.md (advisory), los hooks **garantizan** la acción porque los ejecuta el harness, no el modelo. Regla de decisión (2026): si algo *debe* cumplirse → Hooks o permissions; si es conocimiento contextual → Skills; si es frontera de delegación → Subagents; si es guía siempre-activa → CLAUDE.md corto.

**Verificación**: dale a Claude un check que pueda correr (tests, build, screenshot). "Si no puedes verificarlo, no lo shippees." Opciones: en el prompt, como `/goal`, como Stop hook, o con subagente verificador.

**Gestión de sesión**: `/clear` entre tareas no relacionadas; `/compact <instrucción>` para condensar; `Esc`/`/rewind` para corregir; si corriges >2 veces el mismo issue, `/clear` y reescribe el prompt. `claude --continue`/`--resume` para retomar; nombra sesiones con `/rename`.

**Provee contexto específico**: referencia archivos con `@`, pega screenshots, da URLs (allowlist con `/permissions`), usa `gh` CLI (la forma más eficiente en contexto para interactuar con GitHub y evitar rate limits).

### 4. Context engineering (mantener coherencia en proyectos largos)

Anthropic ("Effective context engineering for AI agents", 29 sep 2025) define el problema: el contexto es un **recurso finito** con rendimientos marginales decrecientes por *context rot* (verbatim: "as the number of tokens in the context window increases, the model's ability to accurately recall information from that context decreases"), por la naturaleza n² de la atención transformer. Los modelos tienen un "attention budget".

**Anatomía del buen contexto**: encontrar "the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome". System prompts a la "altitud correcta" (ni lógica if-else frágil hardcodeada, ni guía vaga). Organiza en secciones (XML tags o Markdown headers). Tools mínimas y sin solapamiento. Few-shot con ejemplos canónicos diversos, no una lista de edge cases.

**Técnicas para tareas de largo horizonte** (las tres oficiales):
1. **Compaction**: resumir la conversación cerca del límite y reiniciar con el resumen. Claude Code preserva decisiones arquitectónicas, bugs sin resolver y detalles de implementación, descartando outputs redundantes de tools; continúa con el resumen + los 5 archivos más recientes.
2. **Structured note-taking (agentic memory)**: escribir notas a memoria persistente fuera del contexto (ej. `NOTES.md`, to-do lists) que se reintroducen después. Dato relevante de Anthropic: los experimentos mostraron que el modelo **reescribe menos los archivos JSON que los Markdown** — usa JSON para tracking de estado.
3. **Sub-agent architectures**: subagentes especializados con contexto limpio; cada uno puede usar decenas de miles de tokens pero devuelve solo un resumen destilado (1.000-2.000 tokens).

**Just-in-time retrieval**: mantener identificadores ligeros (rutas, queries, links) y cargar datos dinámicamente en runtime. Claude Code usa modelo híbrido: CLAUDE.md cargado up-front + glob/grep para navegar just-in-time. La metadata (nombres, jerarquía de carpetas, timestamps) da señales que guían al agente.

**Nota sobre modelos Claude 5 (blog claude.com "The new rules of context engineering")**: Anthropic **eliminó >80% del system prompt** de Claude Code para modelos como Opus 5 sin pérdida medible en evals, encontrando que estaban "overconstraining" a Claude vía system prompt, CLAUDE.md y skills. Recomiendan `/doctor` para ajustar tamaño de skills y CLAUDE.md. Para modelos nuevos: docstrings/comentarios de una línea, no crear documentos de planning/análisis salvo que se pidan. *(Nota de fiabilidad: el post menciona nombres de modelos como "Opus 5" y "Fable 5"; trátese como estado del producto en la fecha de este informe.)*

### 5. Prompting para que la IA sea crítica en la planificación

El problema documentado es la **sycophancy**: los LLMs tienden a estar de acuerdo con el usuario en la mayoría de casos donde el usuario expresa preferencia, incluso cuando se equivoca (investigación citada por MindStudio, jun 2026). Un devil's advocate mal prompteado "drifts" — vuelve al acuerdo con cada réplica.

**Técnicas efectivas:**
- **Prompt devil's advocate/red team explícito** que retire la latitud de balancear crítica con elogio: "Do not: acknowledge strengths unless they set up a counterargument, soften with compliments, agree. Do: identify strongest objections, find wrong assumptions, describe failure scenarios, point out what I'm missing."
- **Múltiples lentes** (ej. 5 perspectivas: evidencia, demanda, downside, ejecución, y "el Contrarian" que busca la objeción que no encaja en categoría) con regla de **veto**: una sola objeción fatal fuerza NO-GO sin importar el score.
- **Challenge-before-score**: exigir la crítica antes de cualquier valoración numérica.
- **Rule del "rival test"**: ¿la objeción se sostendría si un competidor hiciera lo mismo?
- En Claude Code, el mecanismo nativo es el **subagente de revisión adversarial** en contexto fresco, con la advertencia oficial: un reviewer prompteado para encontrar huecos siempre reportará algunos aunque el trabajo sea sólido; instrúyele a marcar **solo** huecos que afecten corrección o requisitos declarados, para evitar over-engineering.
- **ClarifyGPT** (arXiv) propone generar varias implementaciones y comparar para detectar ambigüedad, luego generar preguntas de clarificación dirigidas (estilo Chain-of-Thought).

### 6. Elicitación exhaustiva de requisitos

**Mecanismo nativo de Claude Code — "Let Claude interview you"** (doc oficial):
```
I want to build [descripción breve]. Interview me in detail using the AskUserQuestion tool.
Ask about technical implementation, UI/UX, edge cases, concerns, and tradeoffs.
Don't ask obvious questions, dig into the hard parts I might not have considered.
Keep interviewing until we've covered everything, then write a complete spec to SPEC.md.
```
Recomendación oficial: tras completar la spec, **abre una sesión fresca** para ejecutarla (contexto limpio). Las mejores specs son autocontenidas: nombran archivos e interfaces, dicen qué está fuera de alcance y terminan con un paso de verificación end-to-end.

**Mecanismo nativo de Spec-Kit**: `/speckit.clarify` (10 categorías, hasta 5 preguntas secuenciales) + `/speckit.checklist` ("unit tests for English": ¿está el spec completo, claro, sin ambigüedad?).

**Principios de la disciplina de requisitos** (IIBA, "Prompt Engineering Through the Lens of Requirements Elicitation"): tres técnicas de buenos entrevistadores aplicables a prompts — preguntas abiertas para descubrir info, preguntas de seguimiento para más detalle, y clarificación de ambigüedades. La IA acelera pero no reemplaza el juicio humano (arXiv 2511.01324: la elicitación mantiene el mayor % de decisión humana, ~39%).

### 7. Mantenibilidad por humanos (sin depender de la IA)

**ADRs (Architecture Decision Records):** formato Michael Nygard — **Context / Decision / Consequences** (título + status). Reglas (Microsoft Azure Well-Architected):
- **Append-only**: no edites registros aceptados; si una decisión cambia, escribe uno nuevo que **supersede** al anterior y enlázalos.
- **Uno por decisión**: no combines múltiples decisiones en un doc.
- Empieza al inicio del workload y mantenlo durante su vida.
- Estructura recomendada: carpeta `/ADR/records` + `template.md` + `Overview.md` con tabla enlazada; Claude puede escanear el codebase y generarlos (adolfi.dev).
- **Limitación importante** (arXiv "Lore"): los ADRs capturan decisiones arquitectónicas ("por qué PostgreSQL sobre MongoDB") pero **no** decisiones de implementación (por qué una función maneja errores así), que son más numerosas y las que más se pierden — complementa con mensajes de commit estructurados.
- **Advertencia sobre ADRs y agentes IA** (Mneme HQ): un ADR puede estar "ignored" (no en contexto), "in-context but advisory" (probabilístico, degrada al crecer el contexto) o enforced. Los rule files elevan las probabilidades pero no cierran el gap — de ahí la utilidad de hooks/gates.

**Docstrings**: elige **un** formato (Google o NumPy) y sé consistente; mezclarlos rompe la legibilidad y los generadores. Google usa indentación (Args:/Returns:/Raises:), NumPy usa underlines (más vertical, mejor para docstrings largos/científicos). Con type hints PEP 484, los tipos no necesitan repetirse en el docstring. Desde Python 3.13 el compilador quita el whitespace común (dedent automático). Documenta siempre funciones/clases públicas.

**Trazabilidad**: spec→plan→tasks→commit. Conventional Commits (`feat`/`fix`/`BREAKING CHANGE`) mapea a SemVer y permite changelog automatizado. `/speckit.taskstoissues` conecta tareas con Issues.

### 8. Documentación estructurada + Obsidian

**Por qué Obsidian**: Markdown local, offline, future-proof, con linking (wikilinks `[[ ]]`) que conecta módulos de código↔decisiones de diseño, endpoints↔ejemplos, bugs↔resoluciones.

**Plugins recomendados (2026, todos gratuitos):**
- **Dataview** (blacksmithgu): trata el vault como base de datos; queries tipo SQL sobre frontmatter YAML e inline fields — ideal para dashboards e índices dinámicos de specs/ADRs.
- **Templater** (SilentVoid13): motor de plantillas con comandos dinámicos, JS y prompts — crea notas con estructura/metadata correcta (plantillas de ADR, spec, runbook).
- **obsidian-git** (Vinzent03): commit/pull/push desde Obsidian, auto-commit programado; sincroniza el vault con GitHub gratis. Limitación: en móvil (isomorphic-git) sin SSH nativo.
- **Kanban** (mgmeyers): tableros Kanban en Markdown. *Advertencia*: el repo se archivó y busca mantenedores — úsalo pero vigila su mantenimiento (alternativa: plugin Tasks).
- **Excalidraw** (zsviczian): diagramas dibujados a mano, mapas mentales, sketches de sistema.
- **Mermaid nativo** (core de Obsidian): flowcharts, sequence, Gantt y **erDiagram** en bloques ```mermaid — text-based, version-controllable, renderiza en Obsidian/GitHub/VS Code. Para ERDs interactivos: plugin **DBML Visualizer**.

**Stack de docs recomendado**: trío esencial Dataview + Templater + obsidian-git, más Kanban/Tasks para gestión, Excalidraw + Mermaid para arquitectura/ER.

**Artefactos a documentar**: especificaciones funcionales (desde spec.md), modelo E-R (Mermaid erDiagram / data-model.md), changelog (Keep a Changelog), guías de uso, y **runbooks** (procedimientos operativos). Usa `COMMENT ON TABLE/COLUMN` en PostgreSQL como documentación en el propio esquema, y mantén un data dictionary.

**Organización del vault sugerida**: carpetas por proyecto con notas enlazadas; ADRs en `/ADR/records`; usa wikilinks para trazabilidad; Dataview para generar el índice `overview` automáticamente.

### 9. GitHub gratuito + Spec-Kit + Claude Code

**GitHub Actions (Free plan, verificado agosto 2026):**
- **Repos públicos**: minutos **ilimitados y gratis** en runners estándar GitHub-hosted (sujeto a fair-use).
- **Repos privados**: el plan GitHub Free incluye **2.000 minutos Linux/mes** + 500 MB de storage. Overage a $0.006/min Linux (tras el recorte de tarifas de enero 2026, hasta -39%).
- **Multiplicadores de OS**: Linux 1x, Windows **2x**, macOS **10x** — los minutos son "Linux-equivalent".
- El cargo por self-hosted runners anunciado en dic 2025 (para mar 2026) fue **pospuesto/nunca entró en vigor**; los self-hosted siguen gratis a agosto 2026.

**Recomendación para tu caso (solo, gratis)**: si el repo puede ser público, tienes CI/CD ilimitado. Si necesita ser privado, 2.000 min/mes bastan para lint+test+build de proyectos Python; mantén los jobs en Linux y usa caching. Pon un spending limit de $0 para no incurrir en cargos.

**Piezas gratuitas combinables:**
- **GitHub Issues** + `/speckit.taskstoissues`: trazabilidad de tareas.
- **GitHub Projects**: tablero de gestión (kanban/roadmap).
- **GitHub Wiki**: documentación complementaria (aunque tu fuente de verdad de docs es Obsidian).
- **GitHub Pages**: publicar docs/site estático gratis (ideal si exportas el vault con MkDocs).
- **GitHub Actions**: lint (Ruff), tests (pytest), type-check (ty/mypy), commitlint (validar Conventional Commits), y release-please/git-cliff para changelog automático.
- Claude Code en CI: `claude -p "prompt" --output-format json` en modo headless (útil para revisiones automáticas), con `--allowedTools` para acotar permisos.

### 10. Python — buenas prácticas (2026)

**Versión estable**: **Python 3.14.7** (5 agosto 2026) es la última estable — "the seventh maintenance release of 3.14, containing around 499 bugfixes, build improvements and documentation changes". Python 3.14.0 se lanzó el **7 octubre 2025**. (3.15.0 final se planea ~1 oct 2026; a agosto solo hay release candidate.) Nota: Python 3.10 llega a end-of-life en octubre 2026 — targetea 3.12+ como mínimo.

**Novedades destacadas de Python 3.14:**
- **PEP 750 — Template strings (t-strings)**: sintaxis `t"..."` que produce un objeto `Template` (partes estáticas + interpolaciones) procesable antes de renderizar; a diferencia de f-strings que producen `str` inmediatamente.
- **PEP 649/749 — evaluación diferida de anotaciones**: las anotaciones ya no se evalúan eagerly; nuevo módulo `annotationlib`.
- **Free-threaded (no-GIL) oficialmente soportado** (PEP 703): pasa de experimental (3.13) a soportado.
- Otros: PEP 734 (múltiples intérpretes en stdlib), JIT experimental, PEP 768 (debugger interface), PEP 784 (Zstandard), REPL con syntax highlighting.

**Stack de tooling 2026 (default recomendado)**: **uv** (instalación de Python, entornos, dependencias, lockfile, ejecución) + **Ruff** (lint + format, reemplaza flake8/black/isort/pyupgrade) + **ty** o mypy/pyright (type-check) + pytest. Tres de estas (uv, Ruff, ty) son de Astral e integran vía `pyproject.toml`. Builds 10-100× más rápidos.
```
uv init my-app # pyproject.toml + src layout
uv add fastapi 'pydantic>=2'
uv add --dev pytest ruff
uv run pytest
uv run ruff check --fix src/
```

**Estructura de proyecto (src layout, PEP 621):**
```
my-project/
├── pyproject.toml # única fuente de verdad (build-system, project, tool.*)
├── README.md
├── src/
│ └── my_package/
│ ├── __init__.py
│ └── module.py
└── tests/
 └── test_module.py
```
El src layout mejora imports, packaging, aislamiento de tests y config del type-checker (evita imports accidentales del layout flat).

**Type hints**: usa built-ins genéricos (`list[int]`, `dict[str,float]`), `X | None` en 3.10+, PEP 695 para genéricos (`def f[T](x: T) -> T`), Protocols para duck typing, y Pydantic v2 para validación en runtime. `Any` con moderación.

**Docstrings**: Google o NumPy, consistente. Backend/web: **FastAPI** (default para APIs) o **Django** (enterprise/escala). Visualización: Python local (matplotlib/plotly) + Power BI local ocasional.

**Móvil en Python**: opciones reales — **Kivy** (UI custom, OpenGL, multi-touch; buena para juegos/apps gráficas), **BeeWare** (Toga + Briefcase; UI **nativa** por plataforma; en 2026 soporta NumPy/Pandas/SciPy en móvil), **Flet** (usa Flutter; builds más ligeros para UIs simples, sin aprender Dart). Empaquetado Android vía Buildozer. Limitaciones honestas: paquetes más grandes que nativo y comunidad móvil-específica más pequeña que Swift/Kotlin. FastAPI como backend de la app móvil es el patrón recomendado.

### 11. Diseño de bases de datos relacionales (PostgreSQL preferente, SQL Server)

**Convenciones de nombres (PostgreSQL):** tablas en plural snake_case (`users`, `order_items`); columnas singular snake_case (`first_name`, `created_at`); PK `id` o `table_id`; FK `referenced_table_singular_id` (`user_id`, `order_id`). Usa schema namespacing (`auth.users`, `billing.invoices`).

**Campos de auditoría estándar** (patrón documentado):
```sql
CREATE TABLE auditable_entity (
 id SERIAL PRIMARY KEY, -- (considera BIGINT/UUID según escala)
 -- columnas de negocio
 created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
 created_by INTEGER REFERENCES users(user_id),
 updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
 updated_by INTEGER REFERENCES users(user_id),
 version INTEGER DEFAULT 1 NOT NULL
);
-- trigger para updated_at/version automáticos
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = CURRENT_TIMESTAMP; NEW.version = OLD.version + 1; RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auditable_entity
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```
Usa `TIMESTAMPTZ` (no TIMESTAMP). Documenta con `COMMENT ON TABLE/COLUMN`.

**Índices PostgreSQL:**
- **B-Tree** (default): igualdad y rangos, alta cardinalidad, ORDER BY/DISTINCT.
- **Hash**: solo igualdad exacta (crash-safe/replicable desde PG10).
- **BRIN**: tablas muy grandes con datos secuenciales (time-series, logs) — guarda solo rangos min-max por bloque, muy eficiente en espacio.
- **GIN**: multi-valor (arrays, JSONB, full-text).
- **Parciales** (`WHERE status='active'`), **compuestos** (orden = orden de filtros de la query), **covering**, y de **expresión** (LOWER/UPPER, fechas, JSONB).
- Reglas: indexa solo lo que necesitas; evita columnas de baja cardinalidad; el sobre-indexado penaliza escrituras y storage; crea índices en columnas de FK.

**Optimización de consultas**: usa `EXPLAIN` para el plan; indexa columnas del WHERE; evita `SELECT *`; balancea normalización vs. denormalización según carga de lectura; particiona tablas grandes.

**SQL Server:**
- **Clustered index**: casi toda tabla debe tener uno; la clave clustered debe ser **narrow, unique, static y ever-increasing** (ej. columna identity INT) — minimiza fragmentación y acelera inserts. Evita clustering en columnas que se actualizan mucho.
- **Nonclustered**: en columnas de WHERE/JOIN/ORDER BY/GROUP BY; crea índice (a menudo clustered) en FKs.
- Considera FILLFACTOR, filegroups separados para índices, y particionado alineado. No indexes a ciegas: analiza el workload (SQL Profiler, extended events, DMVs). Usa el Database Engine Tuning Advisor. Mide con DMVs, no adivines.

### 12. Cuándo introducir NoSQL como complemento (para alguien sin experiencia)

**Regla general**: mantén relacional (PostgreSQL) como default y añade NoSQL solo cuando un caso de uso específico lo justifique. NoSQL cambia ACID por el modelo BASE (basic availability, soft state, eventual consistency).

**Casos de uso típicos donde NoSQL complementa bien:**
- **Caché / sesiones**: key-value stores (Redis) para sesiones, estado temporal, leaderboards, carritos — baja latencia. **Este es el complemento más común y de menor riesgo.**
- **Datos no estructurados/semi-estructurados**: document stores (MongoDB) para contenido de esquema variable, perfiles, catálogos heterogéneos.
- **Series temporales / IoT / logs**: wide-column o TSDB para alto volumen de escritura, append-only.
- **Big data / analítica en tiempo real** y **escalado horizontal masivo** (sharding).

**Matiz importante y reputado** (Timescale/TigerData): para series temporales **no siempre necesitas NoSQL** — PostgreSQL con extensión TimescaleDB (o particionado nativo + BRIN) maneja series temporales conservando SQL, JOINs, índices secundarios y predicados complejos. La razón habitual para NoSQL en TS es **escala**, no funcionalidad. Antes de añadir un motor nuevo, evalúa si una extensión de Postgres resuelve el problema (menor coste operativo y curva de aprendizaje).

**Consejo para principiante en NoSQL**: empieza por Redis como caché junto a PostgreSQL (patrón de bajo riesgo, alto valor); trata JSONB de PostgreSQL como "NoSQL dentro de SQL" para datos semi-estructurados antes de adoptar un document store separado.

## Recommendations

**Fase 0 — Configura el harness (una vez por máquina/proyecto):**
1. `uv tool install specify-cli` y `specify init <proyecto> --integration claude`.
2. Crea un `CLAUDE.md` corto: comandos (uv run pytest, ruff check), estilo (Google docstrings, type hints obligatorios, src layout), etiqueta de commits (Conventional Commits), y decisiones clave. Ejecuta `/init` y poda.
3. Configura **hooks** deterministas: PostToolUse → `ruff format` tras editar; Stop → `uv run pytest`; PreToolUse → bloquear escrituras a `migrations/` o secretos.
4. Crea **skills** para workflows repetidos (ej. "cómo añadir un endpoint FastAPI", "cómo escribir un ADR", "convención de esquema PostgreSQL con campos de auditoría").
5. Crea **subagentes**: `security-reviewer`, `spec-critic` (adversarial), `db-designer`.
6. Configura obsidian-git para versionar el vault; crea plantillas Templater para ADR/spec/runbook.

**Fase 1 — Por cada feature (ciclo SDD):**
`/speckit.constitution` (una vez) → `/speckit.specify` → **`/speckit.clarify` (2+ pasadas)** → revisa spec.md a mano → `/speckit.plan` (indica: Python 3.14, FastAPI/Django, PostgreSQL) → `/speckit.checklist` → `/speckit.tasks` → **`/speckit.analyze`** → **subagente adversarial review** → `/speckit.taskstoissues` (features >~5 tareas) → crea rama `feature/<id>-<slug>` (obligatoria si generó issues) → `/speckit.implement` (por fases en features grandes) → PR a `dev` con `Closes #N` por issue → `/speckit.converge`.

**Fase 2 — Documentación y cierre:**
- Genera/actualiza ADRs para decisiones arquitectónicas (append-only).
- Actualiza `CHANGELOG.md` (Keep a Changelog 2.0.0) vía Conventional Commits + release-please en Actions.
- Sincroniza data-model.md → Mermaid erDiagram en Obsidian; enlaza specs↔ADRs↔runbooks con wikilinks; genera índice con Dataview.

**Umbrales que cambian la recomendación:**
- **Repo privado supera ~2.000 min/mes de Actions** → mueve a público (si posible), reduce matrix de OS, o cachea agresivamente.
- **Series temporales/IoT crecen en volumen** → primero TimescaleDB en Postgres; solo si la escala lo rompe, evalúa NoSQL.
- **CLAUDE.md > ~1 pantalla o Claude ignora reglas** → poda y mueve reglas duras a hooks, conocimiento a skills.
- **Script trivial (<pocas líneas)** → salta el workflow SDD completo; usa Claude Code directo.

**Prompts maestros reutilizables** (para pegar en Claude Code/Spec-Kit):

*A. Elicitación crítica (antes de specify):*
> "Quiero construir [descripción breve]. Entrevístame en detalle usando AskUserQuestion. Pregunta sobre implementación técnica, UI/UX, edge cases, restricciones no-funcionales (rendimiento, seguridad, escala), integraciones y trade-offs. No hagas preguntas obvias; profundiza en las partes difíciles que quizá no he considerado. NO asumas alcance silenciosamente: si algo es ambiguo, pregunta. Continúa hasta cubrir todo y luego escribe una spec autocontenida en SPEC.md que nombre archivos/interfaces, diga qué está fuera de alcance y termine con verificación end-to-end."

*B. Crítico adversarial del plan (antes de implement):*
> "Actúa como revisor red-team riguroso e intelectualmente honesto. NO me elogies ni suavices. Revisa este plan/spec contra: (1) auditoría de supuestos — ¿cuáles son más frágiles?; (2) incoherencias entre spec, plan y tasks; (3) ambigüedades sin resolver; (4) riesgos técnicos y modos de fallo; (5) ineficiencias/over-engineering. Marca SOLO lo que afecte corrección o requisitos declarados. Prioriza por severidad; una objeción fatal = NO-GO. Termina con las preguntas que debería responder antes de codificar."

*C. Mantenibilidad (durante/después de implement):*
> "Documenta este código para que un desarrollador humano que no participó en esta conversación pueda mantenerlo sin la IA. Añade docstrings estilo Google + type hints (PEP 484/695). Crea/actualiza un ADR (Context/Decision/Consequences, append-only) para cada decisión arquitectónica. Actualiza CHANGELOG.md (Keep a Changelog) y usa Conventional Commits. Genera un runbook operativo. Asegura trazabilidad spec→plan→tasks→commit."

*D. Diseño de BD:*
> "Diseña el esquema PostgreSQL para [dominio]. Usa snake_case, PK `id`, FKs `<tabla>_id` indexadas, TIMESTAMPTZ, y campos de auditoría estándar (created_at/by, updated_at/by, version) con trigger de updated_at. Justifica cada índice contra las queries esperadas (evita sobre-indexar). Documenta con COMMENT ON. Entrega el DDL + un Mermaid erDiagram + las decisiones en un ADR. Señala si algún dato encajaría mejor en JSONB o en un caché externo, y por qué."

## Caveats
- **Spec-Kit es explícitamente un experimento** de GitHub, con API/comandos en evolución; verifica los comandos vigentes con `specify integration list` y el README, ya que han cambiado (7→9+ comandos, prefijo `/speckit.*`, `/quizme`→`/clarify`).
- Varias cifras de producto (nombres de modelos Claude "Opus 5"/"Fable 5", detalles del blog de context engineering de Claude 5) provienen de posts corporativos con fecha 2026; trátense como estado declarado, no verificado independientemente.
- Muchas "mejores prácticas" de Claude Code/prompting provienen de blogs de terceros (SmartScope, OpenHands, mcp.directory, etc.); las he anclado a la documentación oficial de Anthropic/Claude Code donde fue posible, pero las técnicas de "devil's advocate" son heurísticas de la comunidad, no garantías.
- Las cifras de GitHub Actions (2.000 min, $0.006/min, recorte de enero 2026, posposición del cargo self-hosted) están verificadas contra el changelog/docs de GitHub y calculadoras de terceros a agosto 2026, pero las tarifas pueden cambiar; confirma en la doc oficial antes de decidir.
- El plugin **Kanban** de Obsidian está archivado/buscando mantenedores — evalúa alternativas (ej. plugin Tasks) para dependencias a largo plazo.
- SDD y los agentes no eliminan la responsabilidad humana: la elicitación de requisitos mantiene el mayor componente de juicio humano, y "eres responsable del código con tu nombre en el PR, sin importar cómo se produjo."