---
name: db-model-protocol
description: >
  Diseña el esquema de la feature activa y lo reconcilia contra el modelo de
  datos canónico en contexto limpio: reutilización antes que creación,
  análisis de impacto sobre las specs dependientes y propuesta en bloque a
  la espera de aprobación humana explícita. Entrega DDL y erDiagram, no
  aplica nada. Úsalo en el paso 2.2 del ciclo SDD, tras /speckit-plan,
  siempre que la feature toque el modelo de datos.
context: fork
agent: database-manager
background: false
---

Tu tarea es proponer el esquema de base de datos de la feature activa y **reconciliarlo contra el
modelo canónico** del proyecto, entregando una propuesta cerrada que el humano pueda aprobar o
rechazar. **No apliques nada**: la aprobación la recoge el hilo principal, y quien la ejecuta después
es la skill `db-model-integration`.

Trabajas en contexto limpio, sin el histórico de la conversación de planificación. Eso es deliberado:
lo que importa es lo que quedó escrito en `spec.md` y `plan.md`, no lo que se dijo por el camino.

## El protocolo, paso a paso

Recórrelo entero, en este orden:

1. **Lectura.** Lee `.specify/memory/data-model.md` **completo** antes de proponer cualquier
   estructura. No propongas nada apoyándote en un fragmento.
2. **Convenciones.** Ten cargada la skill `db-model-conventions` (naming, campos de auditoría, política
   de índices, anexo NoSQL) y los valores del perfil del proyecto. Se aplican sin excepción y por
   encima de cualquier otra fuente.
3. **Boceto humano.** Si el prompt que has recibido referencia explícitamente
   `specs/<feature>/db_ideas.md` (p. ej. señala una tabla o sección concreta), léelo y tómalo como
   punto de partida — es un borrador humano, no una fuente de verdad. Aplica sobre él las convenciones
   del paso 2 y **señala explícitamente cada punto que corrijas o completes**. Si el prompt no lo
   menciona, no lo consultes por tu cuenta.
4. **Reutilización.** Si ya existe una entidad o columna en el modelo canónico que cubre la necesidad,
   propón reutilizarla o extenderla en vez de crear una nueva, y justifica por qué. Si no es viable,
   justifica por qué no.
5. **Impacto.** Si la propuesta modifica una estructura existente:
   - Localiza todas las specs listadas en su columna "Specs que dependen de esta tabla".
   - Lee el `spec.md` y el `plan.md` de cada una.
   - Determina si su comportamiento actual sigue siendo válido.
   - Si no, redacta la readaptación concreta: qué cambia en su `plan.md`, en las queries afectadas, o
     en el pipeline/informe correspondiente.
   - Ante conflicto entre una spec antigua y la nueva necesidad, **la antigua se adapta a la nueva**.
     Nunca al revés, y nunca se deja la contradicción sin señalar.
6. **Índices.** Justifica cada índice propuesto contra una query real esperada de la feature. Si no
   puedes nombrar la consulta que lo necesita, no lo propongas.

## Entregable

Todo en un único bloque, para que el humano pueda aprobarlo o rechazarlo de una vez:

### 1. DDL completo

El `CREATE TABLE` / `ALTER TABLE` de cada estructura nueva o modificada, en la sintaxis del motor del
perfil, con los campos de auditoría, el trigger de `updated_at`/`version`, los índices y los
`COMMENT ON` de toda columna no obvia.

### 2. Diagrama

Un bloque Mermaid `erDiagram` con las entidades afectadas y sus relaciones.

### 3. Impacto sobre el modelo canónico

| Estructura | Acción | Specs que dependen | Readaptación propuesta |
|---|---|---|---|

Acción: `Nueva`, `Extendida`, `Modificada`, `Reutilizada sin cambios`. Si no se modifica ninguna
estructura existente, dilo explícitamente en una línea en vez de dejar la tabla vacía.

### 4. Notas

- Si algún dato de la feature encajaría mejor en `JSONB` o en un caché externo (Redis), dilo aquí
  según el anexo NoSQL de `db-model-conventions`.
- Si la feature requiere una migración sobre **datos ya existentes en producción**, márcalo
  explícitamente como punto que requiere **UAT humana** antes de aplicarse.
- Si la **herramienta de migraciones** del perfil sigue sin rellenar, dilo aquí: es un campo sin
  default seguro y hay que preguntarlo antes de llegar al paso 4.2.

## Al terminar

Cierra con las preguntas concretas que el humano debe responder, como exige el motor, y con la frase
explícita de que **nada se ha aplicado todavía** y de que hace falta su aprobación explícita para
continuar.
