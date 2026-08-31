---
name: docs-changelog
description: >
  Genera las entradas de CHANGELOG.md a partir de los Conventional Commits del
  rango de la feature, en formato Keep a Changelog 2.0.0, y las refleja en
  docs/Changelog/Changelog.md. Úsalo en el paso 5.4 del ciclo SDD, en el
  cierre — nunca a mano en mitad del desarrollo.
---

# Cómo se escribe el `CHANGELOG.md` en este proyecto

Esta skill es **plana**: no forkea a `docs-manager`. El motor de documentación no tiene `Bash` a
propósito (así no puede commitear), y generar el changelog exige leer el rango de commits con
`git log`. El hilo principal sí puede, y además es quien conoce el rango de la feature.

## Cuándo

En el **cierre** de la feature, después de `/speckit.converge` y con los commits ya hechos. Nunca a
mano en mitad del desarrollo: las entradas se derivan de los commits, no al revés.

## Formato

[Keep a Changelog](https://keepachangelog.com) 2.0.0. Bajo cada versión, solo las secciones que
tengan contenido, en este orden: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.

## Procedimiento

1. **Obtén el rango.** Los commits de la feature, típicamente `git log dev..HEAD --no-merges`. Si la
   rama base no es `dev` o el rango no está claro, pregúntalo antes de generar nada.
2. **Mapea cada Conventional Commit a su sección**:

   | Prefijo del commit | Sección |
   |---|---|
   | `feat` | `Added` |
   | `fix` | `Fixed` |
   | `refactor`, `perf`, `style` | `Changed` (solo si el cambio es visible para quien usa el proyecto) |
   | `deprecate` o commit que marca algo como obsoleto | `Deprecated` |
   | commit que elimina una capacidad | `Removed` |
   | cambio en autenticación, secretos, dependencias vulnerables | `Security` |
   | `docs`, `test`, `chore`, `ci` | **no entran** en el changelog |

3. **Redacta para quien usa el proyecto, no para quien lo programó.** Una entrada describe el cambio
   observable, no el fichero tocado. El ID de feature va entre paréntesis al final para trazabilidad.
4. **`BREAKING CHANGE:`**: refleja la ruptura bajo `Changed` o `Removed`, márcala explícitamente, y
   **comprueba que existe el ADR que la documenta**. Si no existe, dilo — es un hueco de la Fase 5,
   no algo que se arregle escribiendo mejor la entrada del changelog.
5. **Espejo en el vault**: replica las mismas entradas en `docs/Changelog/Changelog.md`, que es el
   espejo human-readable del `CHANGELOG.md` del repo.
6. **Déjalo como borrador.** No commitees: el humano revisa primero.

## Al terminar

Muestra las entradas generadas agrupadas por sección, di qué commits descartaste y por qué, y señala
cualquier commit que no siguiera Conventional Commits (es un incumplimiento de
`@.claude/context/05_github.md`, no algo que debas normalizar en silencio).
