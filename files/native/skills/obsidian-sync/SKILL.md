---
name: obsidian-sync
description: Qué nota del vault de Obsidian actualizar y cuándo, tras cada evento relevante del ciclo SDD (plan generado, decisión tomada, feature cerrada). Úsalo al cierre de cada fase del ciclo SDD.
---

# Sincronización del vault tras eventos del ciclo SDD

Tabla de disparo (idéntica a la de `.claude/context/02_documentacion_mantenibilidad.md`, aplicada aquí de
forma operativa):

| Evento | Nota a crear/actualizar | Formato |
|---|---|---|
| `/speckit.plan` genera `data-model.md` | `docs/Data-Model/[feature]-ER.md` | Bloque ```mermaid erDiagram``` |
| Decisión arquitectónica tomada | ADR nuevo (usa skill `adr-writer`) | — |
| `/speckit.converge` → "Converged" | `docs/Changelog/Changelog.md` + `docs/Specs/[feature].md` | Keep a Changelog / espejo de spec.md |
| Cambio rompe compatibilidad | ADR nuevo (usa skill `adr-writer`) + `docs/Changelog/Changelog.md` | El ADR documenta el trade-off de ruptura; entrada en Changelog bajo `Changed`/`Removed`, referenciando `BREAKING CHANGE:` del commit |
| Feature introduce procedimiento operativo nuevo | `docs/Runbooks/[nombre].md` | Plantilla runbook |

Reglas:
- Antes de actualizar cualquier nota, comprueba que `docs/Meta/Overview.md` existe; si no, créalo con
  el contenido documentado en `docs/Meta/Workflow.md` (enlaces de navegación + tabla de actividad
  reciente) — es el punto de entrada del vault y debe existir desde la primera sincronización.
- Actualiza al cierre de cada fase, no de forma diferida.
- Todo enlace cruzado con wikilinks `[[ ]]` (Spec ↔ ADR ↔ Issue de GitHub ↔ Runbook).
- Si una nota ya existe, actualízala (no dupliques notas para la misma feature/decisión).
