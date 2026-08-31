---
name: db-model-ideas
description: >
  Recoge el boceto humano de tablas de una feature en
  specs/<feature>/db_ideas.md, con la plantilla de bloque por tabla y la
  regla de que es un punto de partida, nunca una fuente de verdad. Úsalo en
  el paso 1.4 del ciclo SDD, cuando la feature toca el modelo de datos y
  tienes ideas concretas de tablas más rápidas de dibujar que de explicar.
---

# Boceto de tablas de una feature

Sirve para que el humano deje por escrito ideas concretas de modelo de datos —tablas, campos, tipos,
claves, relaciones, consultas esperadas— que a veces son más rápidas de dibujar que de explicar en
prosa dentro de una spec funcional.

## Dónde vive y por qué

El boceto va en **`specs/<feature>/db_ideas.md`**, junto al resto de artefactos de la feature. Es por
feature a propósito:

- Dos features en curso en ramas paralelas no se pisan el fichero ni chocan al mergear.
- Cuando el paso [2.1](../../prompts/02_spec_development.md) referencia el boceto, `/speckit.plan` lee
  solo las tablas de esta feature, no el catálogo entero del proyecto.
- El fichero muere con la feature: en cuanto el esquema se aprueba, la fuente de verdad pasa a ser
  `.specify/memory/data-model.md`, que sí es transversal. Una feature posterior que reutilice una
  tabla la lee ya diseñada en el modelo canónico, no vuelve a bocetarla aquí.

## La bandeja de entrada

`.specify/memory/db_ideas.md` es una **bandeja de entrada** para ideas de tabla que nacen antes de
saber a qué feature pertenecen. **Ningún paso del ciclo la lee nunca.** Cuando una feature recoge una
idea de ahí, el contenido se **mueve** —se corta de la bandeja y se pega en `specs/<feature>/db_ideas.md`—,
nunca se copia. Así cada tabla tiene un único dueño en todo momento y no hay doble fuente de verdad.

## Cómo lo trata el asistente

Este fichero **no se consulta automáticamente**. Se usa exclusivamente cuando el humano lo referencia
explícitamente dentro del prompt de `/speckit.plan` (p. ej. "ver `db_ideas.md`, tabla `orders`"). Si el
prompt no lo menciona, no lo consultes.

Cuando sí se referencia, es un **punto de partida, no una fuente de verdad**: aplica sobre él las
convenciones de `db-model-conventions` sin excepción —naming, campos de auditoría, política de índices,
motor en uso— y **señala explícitamente cualquier corrección** que hagas sobre lo escrito por el humano
(un nombre de tabla en singular, un tipo distinto al recomendado, una FK sin indexar, un campo de
auditoría que falta…). Nunca copies la idea tal cual sin pasarla por las convenciones del proyecto.

## Plantilla de bloque (duplica uno por tabla)

```markdown
### `[nombre_tabla]`

- **Uso / consultas esperadas**: `[para qué sirve esta tabla, qué consultas se esperan sobre ella]`
- **Campos**:

  | Campo | Tipo | Nullable | Notas |
  |---|---|---|---|
  | `[campo]` | `[tipo]` | `[sí/no]` | `[uso, valores válidos, etc.]` |

- **Claves**:
  - PK: `[campo o composición]`
  - FK: `[campo] → [tabla_referenciada].[columna]`
- **Relaciones**: `[1:N, N:M, etc. y con qué otras tablas]`
- **Notas libres / dudas para el asistente**: `[cualquier duda técnica, alternativa que dudas, etc.]`
```

No hace falta rellenar los campos de auditoría (`created_at`, `created_by`, `updated_at`, `updated_by`,
`version`): los añade `db-model-protocol` por convención en toda tabla transaccional.
