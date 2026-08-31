# Cómo trabajar con GitHub en este proyecto

> Importado desde `CLAUDE.md` con `@.claude/context/05_github.md`. Este fichero ya vive en su ruta
> final — viene incluido al crear el repo desde esta plantilla ("Use this template").

## Rama de trabajo

- Toda la rama de desarrollo activo se llama **`dev`**. Ninguna feature se desarrolla directamente
  sobre `main`.
- **Estrategia de ramas por feature**: `feature/<id-speckit>-<slug>` → se mergea a `dev` vía PR.
  - **Obligatoria siempre, sin excepción por trivialidad.** Ya no existe la opción de commitear
    directo sobre `dev` (ver "Branch protection" abajo): `dev` tiene `required_status_checks`
    (`quality` en verde) con `enforce_admins: true`, así que GitHub rechaza cualquier `git push`
    directo a `dev`, incluso del owner del repo — el commit recién creado nunca tiene todavía un
    check en verde porque el CI solo corre después de que el commit exista en GitHub. Toda feature,
    por pequeña que sea, necesita su propia rama y PR.
  - El cierre automático de issues en GitHub Projects depende del evento "Pull request merged" con
    `Closes #N` en la descripción de la PR — sin rama de feature no hay PR, y sin PR los issues
    quedan abiertos aunque el trabajo esté hecho, por muchos issues que haya generado
    `/speckit.taskstoissues`.
- El humano (tú) es quien solicita las Pull Requests de `dev` hacia `main` de forma manual — el
  asistente **no** abre PRs a `main` de forma autónoma. Las PRs `feature/*` → `dev` son distintas:
  el asistente debe **proponer activamente** abrir esa PR al terminar `/speckit.implement`, sin
  esperar a que se le pida.
- `main` se mantiene siempre desplegable; `dev` es la rama de integración.

## Branch protection (GitHub, no código)

- `dev` y `main` exigen `required_status_checks.contexts = ["quality"]` (el único job de
  `ci.yml`), `strict: true` (la rama debe estar actualizada con la base) y `enforce_admins: true`
  (nadie, ni el owner, puede saltárselo). `main` exige además 1 aprobación de PR humana
  (`required_approving_review_count: 1`).
- Sin estas reglas, una PR con el CI en rojo (p. ej. por una variable de entorno requerida ausente
  del workflow) puede mergearse igual si la rama no tiene ninguna regla de protección propia —
  `required_approving_review_count` no sustituye a `required_status_checks`, son comprobaciones
  independientes.
- Verificar/editar esta configuración vía `gh api repos/<owner>/<repo>/branches/<rama>/protection`
  (GET para leer, PUT para sobrescribir por completo — incluir siempre todos los campos que ya
  existían, no solo el que se cambia, o se pierden).
- Complementa un hook local de pre-push (`.githooks/pre-push`, activar con
  `git config core.hooksPath .githooks`) que corre las mismas comprobaciones (`ruff`/`ty`/`pytest`)
  antes de dejar pushear — detiene el problema un paso antes, en la máquina local.

## Cierre de una feature con issues (PR + `Closes #N`)

Cuando una feature tuvo Issues generados por `/speckit.taskstoissues`, la PR `feature/* → dev` que
cierra la feature debe incluir en su descripción `Closes #N` por cada issue que cubre (uno por
tarea, o agrupado si varias tareas comparten issue). Esto es lo único que dispara el cierre
automático de issues configurado en los Workflows de GitHub Projects (evento "Pull request
merged" → Status `Done`) — sin esto los issues quedan abiertos de forma indefinida pese a que el
trabajo esté terminado y mergeado.

**Formato obligatorio — repetir la palabra clave por cada issue, nunca una lista separada por
comas.** GitHub solo interpreta como cierre automático la referencia que sigue *inmediatamente* a
`Closes`/`Fixes`/`Resolves`; una lista como `Closes #47, #48, #49, ...` solo cierra la primera (o
las dos primeras, comportamiento inconsistente) — el resto queda como mención sin efecto. Correcto:

```text
Closes #47, Closes #48, Closes #49, Closes #50
```

## Repositorio público vs. privado

| | Repo público | Repo privado |
|---|---|---|
| Minutos de GitHub Actions | Ilimitados (fair-use) | 2.000 min/mes (Linux-equivalent) en el plan Free |
| Recomendación | Úsalo si el código no contiene datos/lógica sensible | Necesario si hay credenciales, lógica de negocio propietaria o requisito de confidencialidad |
| Multiplicador de minutos por OS | Linux 1x · Windows 2x · macOS 10x (aplica igual en ambos casos) | ídem |

Cuál es este proyecto: ver **GitHub → Visibilidad del repositorio** en
`@.claude/context/00_perfil_proyecto.md`. Si es privado y el consumo de Actions se acerca a
2.000 min/mes: reduce la matriz de sistemas operativos a solo Linux, activa caché de dependencias
(`actions/cache` o el cache nativo de `uv`), y agrupa jobs redundantes.

## Piezas gratuitas combinables y cómo se autogestionan

- **GitHub Issues**: se generan automáticamente desde `tasks.md` con `/speckit.taskstoissues` — no
  crear issues a mano si Spec-Kit ya los genera, para no duplicar la fuente de verdad.
- **GitHub Projects**: tablero (Kanban o roadmap) que agrupa los Issues generados; configúralo una vez
  por proyecto y deja que las automatizaciones nativas de Projects muevan las tarjetas según el estado
  del Issue/PR. Configuración manual vía web (una vez por proyecto):
  1. En el repo → pestaña **Projects** → **New project** → plantilla **Board** (Kanban).
  2. Vincular el repo si no se ha creado desde ahí: dentro del proyecto → **⋯** (menú superior) →
     **Settings** → **Manage access** no es necesario; el link repo↔proyecto se hace desde
     **⋯ → Settings → General → Linked repositories → Add repository**.
  3. Columnas: por defecto trae el campo **Status** con `Todo` / `In Progress` / `Done`. Edítalas
     desde el header de cada columna (**···** → *Rename*/*Delete*) o añade nuevas con **+ Add status**
     (p. ej. `Backlog`, `In Review`) si el flujo lo requiere.
  4. Automatizaciones nativas: dentro del proyecto → **⋯ → Workflows**, activar:
     - **Item added to project** → Status: `Todo`
     - **Item reopened** → Status: `Todo`
     - **Item closed** → Status: `Done`
     - **Pull request merged** → Status: `Done`
     - **Auto-add to project**: filtro `is:issue` (o `is:issue,pr`) sobre el repositorio, para que
       los issues generados por `/speckit.taskstoissues` entren solos al tablero sin añadirlos a mano.
- **GitHub Actions**: el workflow `.github/workflows/ci.yml` ya viene incluido en el repo (se creó
  con la plantilla, no hace falta generarlo a mano):

```yaml
name: CI
on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Check for pyproject.toml
        id: check
        run: echo "exists=$(test -f pyproject.toml && echo true || echo false)" >> "$GITHUB_OUTPUT"
      - uses: astral-sh/setup-uv@v5
        if: steps.check.outputs.exists == 'true'
      - run: uv sync
        if: steps.check.outputs.exists == 'true'
      - run: uv run ruff check src/
        if: steps.check.outputs.exists == 'true'
      - run: uv run ruff format --check src/
        if: steps.check.outputs.exists == 'true'
      - run: uv run ty check
        if: steps.check.outputs.exists == 'true'
      - run: uv run pytest -q
        if: steps.check.outputs.exists == 'true'
```

> El paso `Check for pyproject.toml` evita que el job falle si el `ci.yml` está presente antes de
> ejecutar `uv init` (arranque del proyecto). En cuanto exista `pyproject.toml` en el repo, los
> pasos de `uv` se ejecutan con normalidad — no hay que tocar el workflow ni recordar un orden.

  Añade jobs adicionales (`release-please` o `git-cliff` para changelog automático desde Conventional
  Commits) cuando el proyecto lo justifique.
- **GitHub Wiki**: no se usa como fuente de verdad de documentación (esa es el vault de Obsidian);
  solo se activa si necesitas una vista pública mínima sin dar acceso al vault completo.
- **GitHub Pages**: opcional, para publicar documentación estática (ej. exportando el vault con
  MkDocs) si el proyecto necesita un sitio de docs público.

## Checklist de puesta en marcha (una vez por repo)

- [ ] Crear el repo desde esta plantilla: botón "Use this template" en GitHub, o
      `gh repo create <nombre> --template <owner>/Spec-Driven-Development-Template --clone`
      (`público`/`privado` según la tabla de arriba). `.github/workflows/ci.yml` ya viene incluido.
- [ ] Crear rama `dev` desde `main` y marcarla como rama por defecto para nuevos PRs.
- [ ] Branch protection en `main`: requiere PR + CI en verde.
- [ ] Crear GitHub Project (Board/Kanban) vinculado al repo y activar sus Workflows (ver sección
      "Piezas gratuitas combinables").
- [ ] Configurar `Spending limit = $0` en `Settings → Billing` para evitar cargos accidentales de Actions.

`bootstrap.ps1 -SetupGitHub` automatiza (best-effort) los tres pasos intermedios sobre un repo ya
creado desde la plantilla.
