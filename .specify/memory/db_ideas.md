# Ideas de base de datos — bandeja de entrada

> Vive en `.specify/memory/`, igual que `data-model.md`: nada de esta carpeta se importa en
> `CLAUDE.md`, así que este fichero puede crecer y cambiar tanto como haga falta sin inflar el
> contexto de conversaciones que no tocan BD.
>
> **Propósito**: aquí el humano apunta ideas de tabla que **todavía no pertenecen a ninguna feature**.
> Es una bandeja de entrada, no un catálogo: un sitio donde no perder una idea que llega antes de que
> exista la spec que la necesita.
>
> **Ningún paso del ciclo SDD lee este fichero.** Ningún agente comprueba si existe. En cuanto una
> feature recoge una idea de aquí, el contenido se **mueve** —se corta de este fichero y se pega en
> `specs/<feature>/db_ideas.md`—, nunca se copia. Así cada tabla tiene un único dueño en todo momento.
>
> **Dónde va el boceto de una feature concreta**: en `specs/<feature>/db_ideas.md`, con la skill
> `db-model-ideas` (paso 1.4 de `.claude/prompts/02_spec_development.md`). Es por feature a propósito:
> dos features en ramas paralelas no se pisan el fichero, y `/speckit-plan` no arrastra al contexto
> tablas ajenas.
>
> **Dónde vive el modelo ya aprobado**: en `.specify/memory/data-model.md`. Ese sí es transversal y sí
> es la fuente de verdad. Una feature que reutilice una tabla ya existente la lee ahí — no vuelve a
> bocetarla.

---

## Ideas sin feature asignada

<!-- Duplica el bloque de abajo por cada tabla que quieras apuntar. Al asignarla a una feature,
     CÓRTALO de aquí y pégalo en specs/<feature>/db_ideas.md. -->

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

No hace falta rellenar los campos de auditoría (`created_at`, `created_by`, `updated_at`,
`updated_by`, `version`): los añade `db-model-protocol` por convención en toda tabla transaccional.
