# Convenciones de desarrollo en Python

> Importado desde `CLAUDE.md` con `@.claude/context/03_python.md`.
> Rellena los campos entre `[ ]` con los valores reales del proyecto antes de empezar a codificar; si
> no se rellenan, el asistente debe usar los valores por defecto indicados entre paréntesis.

## Versión y entorno

- Versión de Python: `[3.14.7]` (recomendado: la última estable en https://www.python.org/downloads/ en
  el momento de iniciar el proyecto).
- Gestor de paquetes y entornos: **uv** — no usar pip/venv/poetry salvo justificación explícita.
- Layout de proyecto: **src layout** (PEP 621), obligatorio salvo scripts de un solo fichero:

```
[nombre-proyecto]/
├── pyproject.toml
├── README.md
├── src/
│   └── [paquete]/
│       ├── __init__.py
│       └── ...
└── tests/
    └── test_*.py
```

## Herramientas de calidad (obligatorias, vía `pyproject.toml`)

| Herramienta | Uso | Comando habitual |
|---|---|---|
| Ruff | Lint + formato (sustituye a flake8/black/isort) | `uv run ruff check --fix src/` / `uv run ruff format src/` |
| ty (o mypy/pyright si el proyecto ya los usaba) | Type-checking estático | `uv run ty check` |
| pytest | Tests | `uv run pytest -q` |

- `Ruff` y el type-checker corren automáticamente vía hook `PostToolUse` (ver
  `.claude/hooks/`) — no hace falta invocarlos manualmente tras cada edición.

## Tipado

- Type hints obligatorios en toda función/método público. Usa genéricos built-in (`list[int]`,
  `dict[str, float]`), `X | None` en vez de `Optional[X]`, y PEP 695 (`def f[T](x: T) -> T`) para
  genéricos declarados por el usuario.
- `Any` solo con comentario justificando por qué no se puede tipar mejor.
- Modelos de datos/validación runtime: **Pydantic v2** por defecto.

## Docstrings

- Formato: Google style (ver `@.claude/context/02_documentacion_mantenibilidad.md`). Un único estilo en todo el repo.

## Framework según tipo de proyecto

Marca cuál aplica a este proyecto (puede haber más de uno si hay backend + móvil):

- [ ] **Backend / API web** → `[FastAPI]` (por defecto) o `[Django]` si el proyecto necesita admin
      panel, ORM integrado y escala "enterprise" desde el inicio.
- [ ] **Frontend web** → `[especificar: React vía API separada / Django templates / otro]`
- [ ] **Aplicación móvil en Python** → elegir una:
  - `[BeeWare / Toga+Briefcase]`: UI nativa por plataforma, mejor si se necesita look&feel nativo real.
  - `[Kivy]`: UI custom vía OpenGL, mejor para apps gráficas/juegos o UI muy a medida.
  - `[Flet]`: envuelve Flutter, builds más ligeros y curva de entrada más rápida si la UI es sencilla.

## Testing

- Framework: `pytest`. Estructura de tests en `tests/` reflejando `src/[paquete]/`.
- Cobertura mínima objetivo: `[definir, ej. 80% en módulos de negocio]`.
- Todo endpoint/función de negocio nuevo requiere al menos un test antes de que la tarea se marque
  como cerrada en `tasks.md` (coherente con la regla de validación de `01_estilo_comportamiento.md`).

## Gestión de dependencias

```bash
uv add <paquete>            # dependencia de producción
uv add --dev <paquete>      # dependencia de desarrollo
uv sync                     # instala desde el lockfile (uv.lock, versionado en git)
```

`uv.lock` se versiona siempre en Git — es lo que garantiza reproducibilidad exacta del entorno para
cualquier humano que retome el proyecto.
