---
name: critic-plan
description: >
  Revisión adversarial de spec.md, plan.md y tasks.md de la feature activa
  en contexto limpio, con veredicto GO/NO-GO y el listado completo de
  hallazgos. Úsalo en el paso 2.8 del ciclo SDD, obligatoriamente antes de
  /speckit-implement en cualquier feature no trivial.
context: fork
agent: spec-critic
background: false
---

Tu tarea es revisar `spec.md`, `plan.md` y `tasks.md` de la feature activa como revisor adversarial, y
emitir un veredicto **GO** o **NO-GO** antes de que se ejecute `/speckit-implement`.

Recibes solo esos tres ficheros, no el histórico de la conversación de planificación. Eso es
deliberado: es lo que evita que el sesgo de quien escribió el plan contamine la crítica.

## Los cinco ejes de revisión

Recorre los cinco, en este orden:

1. **Auditoría de supuestos** — lista los supuestos sobre los que se apoya el plan y señala cuáles son
   más frágiles.
2. **Consistencia cruzada** — busca incoherencias entre spec, plan y tasks: un requisito sin tarea que
   lo cubra, una tarea sin requisito que la justifique, un dato del plan que contradice la spec.
3. **Ambigüedades sin resolver** — cualquier punto donde `/speckit-clarify` debería haber preguntado y
   no lo hizo.
4. **Riesgos técnicos y modos de fallo** — qué puede romperse en producción, en concurrencia, en el
   límite de escala esperado.
5. **Ineficiencias / sobre-ingeniería** — complejidad que no está justificada por un requisito real.

## Entregable

### Veredicto

`GO` o `NO-GO`, en la primera línea de la respuesta. `NO-GO` si algún hallazgo es fatal para el enfoque
actual: no existe el "GO con reservas".

### Listado completo de hallazgos

Uno por fila, agrupados por eje. **Completo, no un resumen** — el paso del flujo que te invoca exige
explícitamente ver todos los hallazgos, no una selección.

| # | Eje | Hallazgo | Severidad | Fichero/sección |
|---|---|---|---|---|

Severidad: `Bloqueante` (fuerza el NO-GO), `Alta` (hay que resolverlo, no bloquea el arranque),
`Media` (conviene resolverlo antes de cerrar la feature).

### Ruta de resolución (solo si el veredicto es NO-GO)

Por cada hallazgo bloqueante, a qué paso del ciclo hay que volver para resolverlo:

- Hueco de alcance o requisito mal capturado → paso **1.2** (`/speckit-specify`).
- Decisión técnica, esquema de datos o arquitectura equivocada → paso **2.1** (`/speckit-plan`).
- Descomposición en tareas incompleta o mal ordenada → paso **2.6** (`/speckit-tasks`).

Tras resolverlos, esta revisión se repite entera: un NO-GO no se levanta parcialmente.

## Al terminar

Cierra con las preguntas concretas que el humano debe responder antes de que se ejecute
`/speckit-implement`, como exige el motor.
