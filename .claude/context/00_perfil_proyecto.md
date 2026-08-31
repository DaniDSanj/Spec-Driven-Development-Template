# Perfil del proyecto

> Importado desde `CLAUDE.md` con `@.claude/context/00_perfil_proyecto.md`.
>
> Este fichero contiene **solo los valores concretos de este proyecto** — nada de convenciones ni de
> método. Las convenciones viven en las skills de cada subagente; aquí solo están los datos que
> cambian de un proyecto a otro y que esas skills necesitan leer.
>
> Lo rellena `bootstrap.ps1` en la puesta en marcha, y se completa a mano lo que el script no puede
> decidir. Es el único fichero de `.claude/context/` que un proyecto nuevo necesita editar.

## Regla de campos sin rellenar

Aplica a todo este fichero, sin excepción:

- Campo **con default declarado** (marcado *(default)* en la tabla): si sigue sin rellenar, aplica el
  default y **menciónalo en tu respuesta** — no lo des por confirmado en silencio.
- Campo **sin default seguro** (marcado *(sin default)*): si sigue sin rellenar, **pregunta al humano
  antes de generar o proponer nada que dependa de él**. Nunca lo asumas. Depende del stack concreto
  del proyecto y equivocarse produce trabajo que hay que tirar.

## Proyecto

| Campo | Valor |
|---|---|
| Nombre | `[NOMBRE_PROYECTO]` |
| Descripción (una línea) | `[DESCRIPCIÓN_UNA_LÍNEA]` |
| Comandos no obvios | `[COMANDOS_NO_OBVIOS]` *(ej. cómo levantar la BD local, cómo correr un seed de datos)* |

## Python

| Campo | Valor |
|---|---|
| Versión | `[3.14.7]` *(default: la última estable en https://www.python.org/downloads/ al iniciar el proyecto)* |
| Tipo de proyecto y framework | `[backend: FastAPI (default) o Django \| frontend: React vía API separada / Django templates \| móvil: BeeWare+Toga / Kivy / Flet]` *(sin default — puede haber más de uno si hay backend + móvil)* |
| Cobertura mínima objetivo | `[ej. 80% en módulos de negocio]` *(sin default)* |

## Base de datos

| Campo | Valor |
|---|---|
| Motor | `[PostgreSQL]` *(default: PostgreSQL; SQL Server solo con justificación — integración con stack Microsoft existente, requisito del cliente)* |
| Versión del motor | `[versión]` *(sin default)* |
| Convención de clave primaria | `[id]` *(default: `id`; `[tabla]_id` solo con justificación — explicitud en joins con varias FK a la misma tabla, convención ya existente)* |
| Uso de schemas para namespacing | `[no]` *(default: no — todo en el schema por defecto, p. ej. `public`. Si sí, indicar ejemplo: `auth.users`, `billing.invoices`)* |
| Herramienta de migraciones | `[Alembic / Flyway / Liquibase / EF Core Migrations]` *(sin default — depende del lenguaje y framework)* |

## GitHub

| Campo | Valor |
|---|---|
| Visibilidad del repositorio | `[privado]` *(default: privado. Público = minutos de Actions ilimitados en fair-use; privado = 2.000 min/mes en el plan Free)* |
| Rama de integración | `dev` *(default y convención fija de esta plantilla; `main` se mantiene siempre desplegable)* |
