# Cómo trabajar con Obsidian en este proyecto

> Guarda esta nota como `@docs/Meta/Workflow.md`. Es la referencia de "cómo documentamos aquí" — el
> asistente la lee (vía `@.claude/context/02_documentacion_mantenibilidad.md`) para saber cuándo y qué escribir
> en el vault.

## Estructura de carpetas del vault

```
docs/
├── Meta/
│   ├── Setup.md                # este documento de configuración
│   ├── Workflow.md             # este documento
│   ├── Templates/              # plantillas Templater
│   └── Overview.md             # dashboard generado con Dataview (índice de todo lo demás)
├── Prompts/                    # carpeta de prompts maestros. 
├── Specs/                      # una nota por feature, espejo de specs/<feature>/spec.md
├── ADR/
│   ├── records/                # ADR-0001.md, ADR-0002.md...
│   └── Overview.md             # tabla Dataview con todos los ADR (estado, fecha, enlaces)
├── Data-Model/
│   └── [feature]-ER.md         # una nota por feature; erDiagram Mermaid sincronizado con el
│                                # data-model.md que /speckit.plan genera para esa feature
├── Runbooks/                   # procedimientos operativos (deploy, rollback, incidentes)
└── Changelog/
    └── Changelog.md            # espejo human-readable de CHANGELOG.md del repo
```

## Artefactos a documentar y cuándo

| Artefacto | Se crea/actualiza en | Plantilla |
|---|---|---|
| Nota de Spec | Tras `/speckit.specify` + `/speckit.clarify` | `@docs/Meta/Templates/spec.md` |
| ADR | Al tomar una decisión arquitectónica (ver regla en `@.claude/context/02_documentacion_mantenibilidad.md`) | `@docs/Meta/Templates/adr.md` |
| Diagrama ER | Tras `/speckit.plan` (cuando genera `data-model.md`) | Bloque ` ```mermaid erDiagram ` |
| Runbook | Al cerrar una feature que introduce un procedimiento operativo nuevo (deploy especial, rollback, migración) | `@docs/Meta/Templates/runbook.md` |
| Changelog | En la Fase 2 (cierre) de cada ciclo SDD | Espejo de `CHANGELOG.md` |
| Dashboard (`docs/Meta/Overview.md`) | Bajo demanda, la primera vez que `obsidian-sync` actualiza el vault y el fichero todavía no existe | Query Dataview de esta misma nota (sección más abajo) |

## Plantillas Templater

Los 3 ficheros (`adr.md`, `spec.md`, `runbook.md`) ya viven en `docs/Meta/Templates/`
desde que el repo se creó con esta plantilla — no hay que copiarlos. Ejemplo del
contenido de `@docs/Meta/Templates/adr.md`:

```markdown
---
tipo: adr
id: ADR-<% tp.system.prompt("Número, ej. 0007") %>
estado: Propuesto
fecha: <% tp.date.now("YYYY-MM-DD") %>
supersede: 
---

# ADR-<% tp.file.title %>: <% tp.system.prompt("Título de la decisión") %>

## Contexto
<% tp.system.prompt("¿Qué problema o fuerza motiva esta decisión?") %>

## Decisión
<% tp.system.prompt("¿Qué se decide hacer?") %>

## Consecuencias
<% tp.system.prompt("¿Qué se gana y qué se sacrifica con esta decisión?") %>
```

## Query Dataview para `@docs/Meta/Overview.md`

Punto de entrada del vault: enlaces de navegación a cada sección más una tabla de actividad reciente.
Usa los campos `tipo`/`fecha`/`estado` que ya llevan las plantillas de `adr.md`, `spec.md` y
`runbook.md` (sección "Plantillas Templater" de arriba) — no requiere metadatos nuevos. A diferencia
de `Setup.md`/`Workflow.md`, **no** se crea en el scaffolding inicial: la skill `obsidian-sync` lo crea
bajo demanda la primera vez que actualiza el vault y comprueba que el fichero no existe todavía (ver
`@.claude/skills/obsidian-sync/SKILL.md`).

`Specs/`, `Data-Model/` y `Runbooks/` no tienen una nota-índice de nombre fijo (son carpetas con una
nota por feature/procedimiento), así que se listan con una query Dataview en vez de un wikilink — un
wikilink a un nombre que no existe como nota se vería roto en Obsidian. `ADR/Overview.md` y
`Changelog/Changelog.md` sí son notas reales, así que esas dos secciones enlazan directamente.

````markdown
# Overview

## Specs
```dataview
TABLE estado, fecha FROM "Specs" SORT fecha DESC
```

## ADR
[[ADR/Overview]] — tabla completa de ADRs (estado, fecha, supersede).

## Data-Model
```dataview
LIST FROM "Data-Model" SORT file.mtime DESC
```

## Runbooks
```dataview
TABLE fecha FROM "Runbooks" SORT fecha DESC
```

## Changelog
[[Changelog]]

## Actividad reciente
```dataview
TABLE tipo, fecha
FROM "Specs" OR "ADR/records" OR "Runbooks"
SORT file.mtime DESC
LIMIT 10
```
````

## Query Dataview para `@docs/ADR/Overview.md`

````markdown
```dataview
TABLE estado, fecha, supersede
FROM "ADR/records"
SORT fecha DESC
```
````

## Regla de actualización

- La documentación se actualiza **al cierre de cada fase relevante del ciclo SDD**, no de forma diferida al final del proyecto. Ver la tabla de disparo en `@.claude/context/02_documentacion_mantenibilidad.md`.
- Todo enlace cruzado (Spec ↔ ADR ↔ Issue de GitHub ↔ Runbook) se hace con wikilinks `[[ ]]` para que Dataview y el grafo de Obsidian puedan navegar la trazabilidad completa del proyecto.
