# Convenciones de desarrollo en Python

> Importado desde `CLAUDE.md` con `@.claude/context/03_python.md`.
> Contiene solo **convenciones**, iguales en todos los proyectos con este stack. Los valores concretos
> de este proyecto (versión de Python, framework, cobertura objetivo) están en
> `@.claude/context/00_perfil_proyecto.md` — consúltalo allí y aplica su regla de campos sin rellenar.

## Versión y entorno

- Versión de Python: ver **Python → Versión** en `@.claude/context/00_perfil_proyecto.md`.
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

Cuál aplica a este proyecto: ver **Python → Tipo de proyecto y framework** en
`@.claude/context/00_perfil_proyecto.md`. Criterios para elegir, si aún está sin decidir:

- **Backend / API web** → **FastAPI** por defecto; **Django** si el proyecto necesita admin panel,
  ORM integrado y escala "enterprise" desde el inicio.
- **Frontend web** → React vía API separada, o Django templates.
- **Aplicación móvil en Python** → **BeeWare / Toga+Briefcase** si se necesita look&feel nativo real;
  **Kivy** (UI custom vía OpenGL) para apps gráficas/juegos o UI muy a medida; **Flet** (envuelve
  Flutter) para builds más ligeros y curva de entrada rápida si la UI es sencilla.

## Testing

- Framework: `pytest`. Estructura de tests en `tests/` reflejando `src/[paquete]/`.
- Cobertura mínima objetivo: ver **Python → Cobertura mínima objetivo** en
  `@.claude/context/00_perfil_proyecto.md`.
- Todo endpoint/función de negocio nuevo requiere al menos un test antes de que la tarea se marque
  como cerrada en `tasks.md` (coherente con el criterio de cierre que audita la skill
  `critic-verifications`).

## Gestión de dependencias

```bash
uv add <paquete>            # dependencia de producción
uv add --dev <paquete>      # dependencia de desarrollo
uv sync                     # instala desde el lockfile (uv.lock, versionado en git)
```

`uv.lock` se versiona siempre en Git — es lo que garantiza reproducibilidad exacta del entorno para
cualquier humano que retome el proyecto.
