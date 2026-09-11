---
name: dev-python-coding
description: >
  Convenciones de escritura de código Python de este proyecto: gestión con
  uv, layout src/, tipado estático, Pydantic v2, ruff + ty, docstrings
  Google style y elección de framework. Úsalo antes de escribir o modificar
  cualquier fichero .py — en el paso 4.1 del ciclo SDD junto a
  /speckit-implement, y en cualquier edición de código fuera del ciclo.
---

# Convenciones de código Python

Los **valores** concretos de este proyecto (versión de Python, framework, cobertura) están en
`.claude/context/00_perfil_proyecto.md`. Aplica su **regla de campos sin rellenar**: si el campo tiene
default declarado y sigue vacío, úsalo y menciónalo en tu respuesta; si no tiene default seguro,
pregunta antes de generar nada que dependa de él.

Los tests tienen su propia skill: `dev-python-testing`.

## Versión y entorno

- Versión de Python: ver **Python → Versión** en el perfil del proyecto.
- Gestor de paquetes y entornos: **uv**. No uses pip/venv/poetry/pipenv salvo justificación explícita
  y declarada en la respuesta.
- Layout de proyecto: **src layout**, obligatorio salvo scripts de un solo fichero. Evita que los
  tests importen el paquete desde el directorio de trabajo en vez de desde el instalado, que es la
  causa clásica de "en local pasa y en CI no". Los metadatos van en `pyproject.toml` (PEP 621):

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

## Gestión de dependencias

```bash
uv add <paquete>            # dependencia de producción
uv add --dev <paquete>      # dependencia de desarrollo
uv sync                     # instala desde el lockfile (uv.lock, versionado en git)
```

`uv.lock` se versiona siempre en Git — es lo que garantiza reproducibilidad exacta del entorno para
cualquier humano que retome el proyecto.

## Herramientas de calidad (obligatorias, vía `pyproject.toml`)

| Herramienta | Uso | Comando habitual |
|---|---|---|
| Ruff | Lint + formato (sustituye a flake8/black/isort) | `uv run ruff check --fix src/` / `uv run ruff format src/` |
| ty (o mypy/pyright si el proyecto ya los usaba) | Type-checking estático | `uv run ty check` |

### Reglas de seguridad de Ruff (obligatorias)

Además de las reglas por defecto, activa el grupo `S` (port de *bandit*) en `pyproject.toml`:

```toml
[tool.ruff.lint]
extend-select = ["S"]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]   # pytest usa assert
```

Detecta, entre otros: SQL construido con f-strings o concatenación (`S608`), `subprocess` con
`shell=True` (`S602`), contraseñas en el código (`S105`/`S106`), `pickle`/`yaml.load` sobre datos no
confiables (`S301`/`S506`) y peticiones HTTP sin `timeout` (`S113`). La corrección es cambiar el
código — consultas parametrizadas, lista de argumentos en vez de `shell=True`, secretos desde el
entorno —, no silenciar la regla. Un `# noqa: S<código>` solo vale para un falso positivo real y lleva
al lado el porqué.

Ruff y el type-checker corren automáticamente vía el hook `PostToolUse`
(`.claude/hooks/post_edit_python_format.sh`) — **no los invoques a mano tras cada edición**. Lo que sí
debes hacer es leer lo que el hook reporte y corregirlo antes de dar la tarea por escrita.

## Tipado

- Type hints obligatorios en toda función/método público.
- Usa genéricos built-in (`list[int]`, `dict[str, float]`), `X | None` en vez de `Optional[X]`, y
  PEP 695 (`def f[T](x: T) -> T`) para genéricos declarados por ti.
- `Any` solo con un comentario justificando por qué no se puede tipar mejor. Sin ese comentario, no lo
  uses.
- Modelos de datos y validación en runtime: **Pydantic v2** por defecto.

## Docstrings y comentarios

- Formato único en todo el repo: **Google style** (`Args:`, `Returns:`, `Raises:`). No lo mezcles con
  NumPy style.
- Toda función, clase y módulo público lleva docstring. Con type hints activos, no repitas el tipo
  dentro del docstring: descríbelo solo si aporta un matiz que el tipo no capta.
- Comentarios inline solo para explicar el **por qué**, nunca el **qué** — el código ya dice el qué.

## Framework según tipo de proyecto

Cuál aplica: ver **Python → Tipo de proyecto y framework** en el perfil del proyecto. Es un campo
**sin default seguro**: si sigue sin rellenar, pregunta antes de andamiar nada. Criterios para elegir,
si aún está sin decidir:

- **Backend / API web** → **FastAPI** por defecto; **Django** si el proyecto necesita admin panel, ORM
  integrado y escala "enterprise" desde el inicio.
- **Frontend web** → React vía API separada, o Django templates.
- **Aplicación móvil en Python** → **BeeWare / Toga+Briefcase** si se necesita look&feel nativo real;
  **Kivy** (UI custom vía OpenGL) para apps gráficas/juegos o UI muy a medida; **Flet** (envuelve
  Flutter) para builds más ligeros y curva de entrada rápida si la UI es sencilla.
