---
name: docs-vault-sync
description: >
  Sincroniza el vault de Obsidian con el estado real de la feature: nota de
  spec, diagrama ER, espejo del changelog y enlaces cruzados con wikilinks.
  Úsalo en el paso 2.3 del ciclo SDD (cuando /speckit.plan generó
  data-model.md) y en el 5.3 al cerrar la feature.
context: fork
agent: docs-manager
background: false
---

Tu tarea es dejar el vault de `docs/` alineado con lo que la feature tiene escrito en `specs/`, como
borrador para revisión humana. No commitees.

## Qué nota toca cada evento

| Evento | Nota a crear/actualizar | Formato |
|---|---|---|
| `/speckit.plan` generó `data-model.md` | `docs/Data-Model/[feature]-ER.md` | Bloque ```mermaid erDiagram``` |
| `/speckit.specify` + `/speckit.clarify` cerrados | `docs/Specs/[feature].md` | Plantilla `docs/Meta/Templates/spec.md`, espejo de `specs/<feature>/spec.md` |
| `/speckit.converge` → "Converged" | `docs/Specs/[feature].md` + `docs/Changelog/Changelog.md` | Espejo de la spec / espejo human-readable de `CHANGELOG.md` |
| Decisión arquitectónica tomada | ADR nuevo → **usa la skill `docs-adr-writer`** | — |
| Cambio rompe compatibilidad | ADR (`docs-adr-writer`) + `docs/Changelog/Changelog.md` | El ADR documenta el trade-off; la entrada de changelog va bajo `Changed`/`Removed` referenciando el `BREAKING CHANGE:` del commit |
| Feature introduce un procedimiento operativo nuevo | `docs/Runbooks/[nombre].md` → **usa la skill `docs-runbook`** | — |

Las tres filas que delegan lo hacen a propósito: el formato de un ADR, de un runbook y del
`CHANGELOG.md` vive en su propia skill, para que no haya dos fuentes de verdad. Aquí solo se decide
**qué** hace falta tocar.

## Reglas

- El `erDiagram` de `docs/Data-Model/[feature]-ER.md` se genera a partir del `data-model.md` de la
  feature, no de memoria: si difieren, gana el fichero y lo señalas.
- La nota de spec es un **espejo navegable**, no una copia literal: resume el qué y el porqué, y
  enlaza a `specs/<feature>/spec.md` para el detalle.
- Actualiza al cierre de cada fase, no de forma diferida al final del proyecto.
- Todo enlace cruzado con wikilinks `[[ ]]` (Spec ↔ ADR ↔ Issue de GitHub ↔ Runbook), para que
  Dataview y el grafo de Obsidian naveguen la trazabilidad completa.
- Si la nota ya existe, actualízala; no crees una segunda nota para la misma feature.

## Al terminar

Resume qué notas creaste y cuáles actualizaste, y señala qué delegaciones quedan pendientes (ADR,
runbook, changelog) para que el hilo principal lance la skill que toque.
