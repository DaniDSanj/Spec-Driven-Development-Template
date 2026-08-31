# Ciclo SDD — Fase 1 (Desarrollo)

Un prompt por comando. Ejecútalos en este orden para cada feature nueva.

## 0. `/speckit.constitution` (solo la primera vez del proyecto, o al cambiar principios)

```
/speckit.constitution

Establece los principios rectores de este proyecto: stack (Python [versión], PostgreSQL/SQL Server, Claude Code + Spec-Kit), disciplina de testing (TDD estricto en módulos de negocio, tests obligatorios antes de cerrar tarea), estilo de documentación (ver `@.claude/context/02_documentacion_mantenibilidad.md`), y cualquier restricción no negociable del proyecto (ej. no usar plataformas de pago).
```

## 1. `/speckit.specify` (usando elicitación exhaustiva)

```
/speckit.specify

Quiero construir: [descripción breve de la feature].

Antes de escribir la spec, entrevístame en detalle usando AskUserQuestion. Pregunta sobre alcance funcional, modelo de datos, flujo de UX, requisitos no funcionales (rendimiento, seguridad, escala), integraciones externas, casos límite, restricciones técnicas y terminología del dominio — cubre las categorías de `@.claude/context/01_estilo_comportamiento.md` sección 2. No hagas preguntas obvias; dig into las partes difíciles que quizá no he considerado. No asumas nada en silencio: si algo es ambiguo, pregunta antes de escribir spec.md.

Antes de definir cualquier estructura de datos, consulta .specify/memory/data-model.md y sigue el protocolo descrito en .specify/memory/schema-change-protocol.md para cualquier creación o modificación de esquema.
```

## 2. `/speckit.clarify` (mínimo dos pasadas en features no triviales)

```
/speckit.clarify
```

Repite una segunda vez tras resolver las primeras preguntas — cada pasada detecta ambigüedades distintas.

## 3. `/speckit.plan`

Si tienes ideas concretas de tablas/campos/tipos/claves para esta feature (más rápidas de dibujar que de explicar en prosa), apúntalas antes en `.specify/memory/db_ideas.md` — es un fichero transversal a todo el proyecto, no exclusivo de esta feature. `db-designer` **no lo lee por su cuenta**: solo lo consulta como borrador de partida (nunca como sustituto de las convenciones de `04_base_datos.md`) si tú lo referencias explícitamente en el propio prompt de `/speckit.plan`, como en el ejemplo de abajo.

```
/speckit.plan

Genera el plan técnico. Stack: [Python versión] con [FastAPI/Django/Kivy/BeeWare/Flet según aplique], [PostgreSQL/SQL Server]. 

Boceto de estructuras de datos necesarias para esta funcionalidad: 
[No hay ideas dentro de esta spec] | [Puedes encontrarlo en `@.specify/memory/db_ideas.md`]

Si la feature toca el modelo de datos, invoca al subagente db-designer para proponer el esquema siguiendo `@.claude/context/04_base_datos.md`. Reconcilia el boceto contra el modelo canónico en .specify/memory/data-model.md antes de aceptarlo como definitivo. Si detectas necesidad de modificar estructuras existentes, aplica el protocolo de .specify/memory/schema-change-protocol.md y preséntame la propuesta de impacto antes de continuar con el resto del plan.
```

## 4. `/speckit.checklist`

```
/speckit.checklist
```

## 5. `/speckit.tasks`

```
/speckit.tasks
```

## 6. `/speckit.analyze` (read-only, antes de tocar código)

```
/speckit.analyze
```

Si reporta hallazgos, resuélvelos (vuelve a `specify`/`plan`/`tasks` según corresponda) antes de continuar.

## 7. Revisión adversarial (obligatoria antes de implementar, ver `@.claude/context/01_estilo_comportamiento.md`)

```
Antes de implementar, usa el subagente spec-critic para revisar spec.md, plan.md y tasks.md de esta feature. Si reporta un NO-GO, resuélvelo antes de continuar. Muéstrame el listado completo de hallazgos, no solo un resumen.
```

## 8. `/speckit.taskstoissues` (features con más de ~5 tareas)

```
/speckit.taskstoissues
```

Ejecútalo **antes** de implementar, nunca después: es lo que da seguimiento en tiempo real a las tareas mientras se hacen, no un registro histórico de lo ya terminado. Si la feature es trivial y no genera issues (~5 tareas o menos), salta este paso y continúa en el 10 trabajando directamente sobre `dev`.

## 9. Crea la rama de feature (obligatoria si el paso anterior generó issues)

```
Crea la rama `feature/<id-speckit>-<slug>` a partir de `dev` y cámbiate a ella. Confírmame el nombre exacto de rama que has usado.
```

Referencia de lo que ejecutará el asistente (no lo lances tú a mano):

```bash
git checkout -b feature/<id-speckit>-<slug> dev
```

Si el paso 8 generó issues, esta rama es obligatoria — es lo que permite que el cierre de esos issues sea automático al mergear (ver `@.claude/context/05_github.md`). Si no hay issues asociados, este paso es opcional y puedes seguir trabajando sobre `dev`.

## 10. `/speckit.implement`

```
/speckit.implement

Implementa las tareas de esta feature. Para cada tarea que toque una superficie de usuario o datos de producción, señala explícitamente que requiere UAT humana antes de marcarla como cerrada (ver `@.claude/context/01_estilo_comportamiento.md` sección 3) y describe qué debo probar exactamente.
```

En cuanto las tareas y su UAT queden validadas, si trabajaste sobre `feature/*`, propón activamente —como parte del cierre de esta tarea, no como ocurrencia tardía— abrir la PR hacia `dev` con `Closes #N` por cada issue que resuelve.

Continúa con [**03_Cierre.md**](./03_Cierre.md) una vez implementado y validado.
