# Ideas de base de datos (borrador humano)

> Vive en `.specify/memory/`, igual que `data-model.md` y `schema-change-protocol.md`: nada de esta
> carpeta se importa en `CLAUDE.md`, así que este fichero puede crecer y cambiar tanto como haga
> falta sin inflar el contexto de conversaciones que no tocan BD.
>
> **Propósito**: aquí el humano apunta ideas concretas de modelo de datos — tablas, campos, tipos,
> claves, relaciones, consultas esperadas — que a veces son más rápidas de dibujar que de explicar
> en prosa dentro de una spec funcional. Es **transversal**: una misma tabla puede nacer aquí antes
> de saber a qué feature pertenece, o servir a varias features a la vez.
>
> **Único uso**: este fichero **no se consulta automáticamente**. Ningún agente comprueba si existe
> ni lo lee por defecto. Se usa exclusivamente cuando el humano lo **referencia explícitamente
> dentro del prompt de `/speckit.plan`** de la spec en la que quiere usarlo (p. ej. "ver
> `db_ideas.md`, tabla `orders`") — ver `files/prompts/02_Desarrollo.md`. Si el prompt de esa spec no
> lo menciona, el asistente no lo consulta.
>
> **Cómo lo trata el asistente cuando sí se referencia**: este fichero es un **punto de partida, no
> una fuente de verdad**. El subagente `db-designer` (u otro subagente que diseñe/revise esquema)
> debe leer la parte referenciada, tomar las ideas relevantes para la tarea en curso, y **aplicar
> sobre ellas las convenciones de `.claude/context/04_base_datos.md` sin excepción** — naming, campos
> de auditoría, política de índices, motor en uso. Si algo aquí escrito choca con esas convenciones
> (un nombre de tabla en singular, un tipo de dato distinto al recomendado, una PK sin indexar, un
> campo de auditoría que falta...), el asistente debe **señalarlo explícitamente en su respuesta** y
> proponer la versión corregida — nunca copiar la idea tal cual sin pasarla por las convenciones del
> proyecto.

---

## Estado del catálogo

<!-- Notas libres de contexto general: qué features han aportado ideas, qué queda pendiente de
     revisar, enlaces a specs relacionadas, etc. -->

---

## Plantilla de entrada (duplica este bloque por cada tabla)

### `[nombre_tabla]`

- **Features relacionadas**: `[feature-a, feature-b, ... o "transversal" si aplica a todo el proyecto]`
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
- **Estado**: `[ ] Propuesta humana` · `[ ] Revisada por db-designer` · `[ ] Incorporada a migración`

<!-- Duplica el bloque anterior para cada tabla nueva que quieras aportar. -->
