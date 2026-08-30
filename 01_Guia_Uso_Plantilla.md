# Plantilla Spec-Driven Development (SDD)

Esta carpeta es una **plantilla de arranque** para iniciar cualquier proyecto nuevo bajo Spec-Driven Development (SDD) con tu stack habitual, el cual está formado por las siguientes tecnologías:

- **Asistente**: Claude Code + Spec-Kit
- **Desarrollo**: Python
- **Bases de Datos**: PostgreSQL/SQL Server
- **Documentación**: Obsidian
- **Control de Versiones**: GitHub

## Primeros Pasos

Si es tu primera vez con Claude Code, lee antes [**01_Guia_Claude_Code**](00_Guias_Inicio/01_Guia_Claude_Code.md) — esta plantilla asume que ya conoces conceptos como Plan Mode, hooks, skills, subagentes y permisos.

Para poder utilizar esta plantilla, sigue estas indicaciones:

1. Instala Spec-Kit en el proyecto siguiendo el documento [**02_Instalacion_Spec_Kit**](02_Instalacion_Spec_Kit.md).
2. Configura el *harness* del proyecto con [**03_Configuracion_Harness**](03_Configuracion_Harness.md).
3. Cada vez que abras una feature/spec nueva usa los prompts de [**02_Desarrollo**](./files/prompts/02_Desarrollo.md) y [**03_Cierre**](./files/prompts/03_Cierre.md).
4. Cuando el proyecto lleve tiempo cerrado y vuelvas a él, usa [**04_Mantenimiento**](./files/prompts/04_Mantenimiento.md) para retomarlo y abrir nuevos desarrollos.

> **Atajo automatizado**: los pasos 1 y 2 (incluyendo gran parte de lo que documenta `04_Instalacion_Herramientas_Claude`, referenciado desde dentro del paso 2) se pueden ejecutar de un tirón con [**install.ps1**](./install.ps1), un script PowerShell que copia y rellena todo lo mecánico (contexto, memoria de Spec-Kit, skills, subagentes, hooks, estructura de Obsidian, `ci.yml` y, opcionalmente, el repositorio de GitHub) y deja en un checklist final lo que exige revisión humana — generar y revisar `CLAUDE.md`, instalar plugins de Obsidian, crear el GitHub Project y fijar el spending limit. Las guías 02-05 siguen siendo la referencia manual y el *fallback* si el script falla en algún punto. Ejemplo mínimo:
> ```powershell
> .\install.ps1 -ProjectPath "D:\Proyectos\mi-app" -ProjectName "mi-app" `
>     -ProjectDescription "Descripción de una línea" -DbEngine PostgreSQL -Visibility private
> ```
> Ejemplo listo para copiar y editar (con todos los parámetros) en [**install_example.md**](./install_example.md). Documentación completa de cada parámetro: `Get-Help .\install.ps1 -Full`.

## Mapa de Carpetas
Las carpetas ubicadas en [`files`](./files/) se referencian con ubicaciones reales en el proyecto que estés realizando:

| Carpeta Actual | Carpeta Destino |
| --- | --- |
| `context/*.md` | `.claude/context/*.md`, referenciados desde `CLAUDE.md` con `@` |
| `specify/*.md` | `.specify/memory/*.md` — modelo de datos canónico (`data-model.md`), protocolo de cambio de esquema (`schema-change-protocol.md`) que usan `/speckit.specify` y `/speckit.plan`, y `db_ideas.md` (borrador humano de tablas concretas, solo se consulta cuando el prompt de `/speckit.plan` de una spec lo referencia explícitamente); nada de esta carpeta se importa en `CLAUDE.md` |
| `native/skills/*` | `.claude/skills/*` (o `~/.claude/skills/*` si es transversal a todos tus proyectos) |
| `native/agents/*` | `.claude/agents/*` (o `~/.claude/agents/*`) |
| `native/hooks/*` | `.claude/settings.json` + scripts en `.claude/hooks/` |
| `obsidian/*` | Notas de configuración dentro de tu vault de Obsidian (carpeta `docs/`) |
| `github/01_github_workflow.md` | `.claude/context/05_github.md`, referenciado desde `CLAUDE.md` con `@` (ese mismo fichero indica, en su checklist final, cómo generar los ficheros reales en `.github/workflows/`) |
| `prompts/*` | Tu biblioteca de prompts maestros (puedes guardarla también como notas en Obsidian) |

## Más Información

La guía completa acerca de cómo usar Claude Code con SDD está disponible [**aquí**](00_Guias_Inicio/02_Guia_Spec_Driven_Development.md).

## Principio rector de toda la plantilla

`CLAUDE.md` se mantiene deliberadamente corto. Toda la sustancia vive en `context/*.md`, y `CLAUDE.md` solo la referencia con imports (`@.claude/context/01_estilo_comportamiento.md`, etc.). Esto evita el problema descrito en la guía original: un `CLAUDE.md` sobrecargado hace que Claude ignore la mitad de las reglas. Cada fichero de contexto se activa solo cuando es relevante para la tarea en curso.
