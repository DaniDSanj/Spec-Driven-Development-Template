---
name: docs-consistency-check
description: >
  Checklist de consistencia que se recorre antes de cerrar cualquier feature:
  docstrings y tipado, ADR de las decisiones tomadas, Conventional Commits con
  ID de feature, CHANGELOG.md, nota de vault enlazada y UAT humana confirmada.
  Audita, no redacta. Úsalo en el paso 5.5 del ciclo SDD, tras revisar los
  borradores de documentación y antes del commit de cierre.
---

# Checklist de consistencia antes de cerrar una feature

Esta skill es **plana**: no forkea. Dos de sus seis puntos no son verificables en contexto limpio —
los Conventional Commits requieren `git log` (el motor `docs-manager` no tiene `Bash` a propósito) y
la confirmación de UAT vive en la conversación con el humano, no en disco.

**Audita, no arregla.** Recorre los seis puntos, reporta el estado de cada uno con la evidencia
concreta que lo respalda, y para los que fallen indica a qué paso del ciclo hay que volver. No
redactes tú la documentación que falte: eso es trabajo de las skills `docs-*` del paso 5.3/5.4.

## Los seis puntos

| # | Punto | Cómo se comprueba |
|---|---|---|
| 1 | Docstrings Google-style en todo lo público y type hints completos | Revisar los `.py` tocados por la feature; convención en `dev-python-coding` |
| 2 | ADR creado o actualizado si hubo decisión arquitectónica | ¿Hay decisiones en `plan.md` sin ADR en `docs/ADR/records/`? Si falta alguno → `docs-adr-writer` |
| 3 | Los commits siguen Conventional Commits y referencian el ID de feature | `git log <base>..HEAD --no-merges`; convención en `git-update-repo` |
| 4 | `CHANGELOG.md` actualizado | ¿Tiene entradas del rango de esta feature? Si no → `docs-changelog` |
| 5 | Nota de la feature en el vault, enlazada con su(s) ADR y su Issue de GitHub | `docs/Specs/[feature].md` existe y sus wikilinks resuelven. Si no → `docs-vault-sync` |
| 6 | UAT humana confirmada si aplicaba | Lo audita en detalle la skill `critic-verifications` en el paso 4.4; aquí solo se confirma que ese paso se ejecutó y que no quedan escenarios `manual` en ⏳ PENDIENTE en `quickstart_agent.md` |

Añade un séptimo punto si la feature introdujo un procedimiento operativo nuevo: que exista su
runbook en `docs/Runbooks/` (si no → `docs-runbook`).

## Formato de salida

Una tabla con las columnas **Punto · Estado (✅/❌/N/A) · Evidencia · Acción**. Un punto no se marca
✅ sin evidencia concreta (ruta de fichero, hash de commit, línea). "Parece correcto" no es evidencia.

Cierra con el veredicto: **listo para cerrar** o **la lista de lo que falta**, en orden de
resolución. Si hay algún ❌, la feature no se cierra.
