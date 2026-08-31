---
name: critic-verifications
description: >
  Audita el criterio de cierre de las tareas de la feature activa antes de
  converger: qué tareas exigen UAT humana, cuáles se han cerrado sin
  evidencia objetiva, y si la clasificación automatizable/manual de
  quickstart_agent.md es correcta. Úsalo en el paso 4.4 del ciclo SDD,
  después de /verify-validate y antes de /speckit.converge.
context: fork
agent: spec-critic
background: false
---

Tu tarea es auditar el **criterio de cierre** de las tareas de la feature activa. La validación
automática en verde (tests, lint, type-check) es condición necesaria pero **no suficiente** para dar una
feature por cerrada; tú compruebas lo que esa validación no cubre.

## Frontera con `spec-verifier` (no la cruces)

Las skills `verify-prepare` y `verify-validate` *ejecutan* escenarios y anotan su resultado en
`quickstart_agent.md`. Tú **no ejecutas nada y no escribes en ningún fichero**, tampoco en
`quickstart_agent.md`. Auditas que la *clasificación* y el *criterio de cierre* sean correctos, y
reportas. Por eso este paso va después de `/verify-validate` y antes de `/speckit.converge`.

## Qué exige UAT humana

Una tarea no se puede cerrar solo con validación automática si cae en alguno de estos tres casos:

- Cualquier flujo de cara al usuario final (UI web o móvil) que cambie una interacción existente.
- Cualquier cambio en reglas de negocio con impacto económico, legal o sobre datos sensibles.
- Cualquier migración de base de datos que toque datos ya existentes en producción.

Para el resto de tareas (backend puro, scripts, utilidades internas sin superficie de usuario) la
validación automática sí basta para cerrar, siempre que `/speckit.analyze` no haya dejado hallazgos
pendientes.

## Los tres puntos de auditoría

Lee `tasks.md` y `quickstart_agent.md` de la feature activa (y `spec.md`/`plan.md` para entender qué
toca cada tarea) y responde a los tres:

1. **Cobertura de UAT** — ¿toda tarea que cae en alguno de los tres casos de arriba está marcada como
   pendiente de UAT humana?
2. **Evidencia de cierre** — ¿alguna tarea se ha marcado como cerrada sin evidencia objetiva (test en
   verde, salida de comando, dato comprobado)? Una tarea cerrada "porque el código está escrito" es un
   hallazgo.
3. **Clasificación de escenarios** — ¿hay algún escenario marcado como `automatizable` en
   `quickstart_agent.md` que en realidad exige juicio humano (aspecto visual, tono, UX, criterio de
   negocio)? Y al revés: ¿alguno marcado `manual` que tiene una condición verificable de forma
   determinista y podría automatizarse?

## Entregable

Listado **completo** de tareas y escenarios que incumplen alguno de los tres puntos, no un resumen:

| # | Punto | Tarea / Escenario | Qué incumple | Acción requerida |
|---|---|---|---|---|

Si un punto se cumple íntegramente, dilo explícitamente en una línea en vez de omitirlo — el humano
necesita saber que se comprobó.

Cuando una tarea requiera UAT y no la tenga descrita, indica qué falta entregarle al humano: **qué
probar exactamente, en qué entorno, con qué datos de prueba y qué resultado se espera ver**.

## Al terminar

Cierra con las preguntas concretas que el humano debe responder antes de `/speckit.converge`, como
exige el motor. Recuerda en una línea la regla dura: ninguna tarea con UAT pendiente se marca como
"Done" en `tasks.md` sin confirmación explícita del humano.
