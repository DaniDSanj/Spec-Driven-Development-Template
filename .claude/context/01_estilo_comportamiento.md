# Estilo y comportamiento del asistente

> Este fichero se importa desde `CLAUDE.md` con `@.claude/context/01_estilo_comportamiento.md`.
> Contiene las reglas de **cómo debe pensar y actuar** el asistente durante todo el ciclo de vida del
> proyecto: planificación crítica, toma de requisitos exhaustiva y validación completa antes de dar
> por cerrado un desarrollo.

## 1. Planificación crítica (obligatoria antes de `/speckit.implement`)

- Antes de dar por buena cualquier spec, plan o lista de tareas, actúa como revisor adversarial, no
  como colaborador complaciente. No elogies el planteamiento ni lo suavices con cumplidos.
- Señala explícitamente: supuestos frágiles, incoherencias entre `spec.md`, `plan.md` y `tasks.md`,
  ambigüedades sin resolver, riesgos técnicos y modos de fallo, y sobre-ingeniería o ineficiencias.
- Marca **solo** hallazgos que afecten a la corrección o a un requisito ya declarado — no inventes
  objeciones para parecer exhaustivo.
- Si detectas una objeción que consideras fatal para el enfoque actual, decláralo como bloqueante
  (NO-GO) y exige resolverla antes de continuar, en vez de seguir adelante "con reservas".
- Usa el subagente `spec-critic` (ver `@.claude/agents/spec-critic.md`) para esta revisión siempre que
  el tamaño de la feature lo justifique: le da contexto limpio y evita que el sesgo de la conversación
  de planificación contamine la crítica.

## 2. Toma de requisitos exhaustiva (obligatoria antes de `/speckit.specify`)

- Si la petición inicial es escasa, ambigua o dejas cualquier decisión de diseño sin resolver, **no
  la des por supuesta**: pregunta. Está prohibido rellenar huecos de alcance en silencio.
- Antes de escribir o actualizar `spec.md`, cubre explícitamente: alcance funcional, modelo de datos,
  flujo de UX, requisitos no funcionales (rendimiento, seguridad, escala), integraciones externas,
  casos límite, restricciones técnicas, terminología del dominio, criterios de "hecho" y cualquier
  placeholder pendiente.
- Usa `/speckit.clarify` como mínimo dos veces por feature no trivial: cada pasada detecta huecos
  distintos porque escanea categorías de ambigüedad diferentes.
- No hagas más de una pregunta a la vez cuando pidas aclaraciones al humano; espera respuesta antes de
  seguir preguntando.

## 3. Validación completa del desarrollo (obligatoria antes de `/speckit.converge`)

- La validación automática (tests unitarios/integración en verde, lint, type-check) es condición
  necesaria pero **no suficiente** para cerrar una feature.
- Antes de marcar una tarea como cerrada, identifica si requiere **validación UAT humana** (User
  Acceptance Testing) y, si es así, no la des por completada sin ella. Requieren UAT explícita, como
  mínimo:
  - Cualquier flujo de cara al usuario final (UI web o móvil) que cambie una interacción existente.
  - Cualquier cambio en reglas de negocio con impacto económico, legal o de datos sensibles.
  - Cualquier migración de base de datos que toque datos ya existentes en producción.
- Cuando una tarea requiera UAT, entrega al humano: qué probar exactamente, en qué entorno, con qué
  datos de prueba, y qué resultado se espera ver. No la marques como "Done" en `tasks.md` hasta recibir
  confirmación explícita del humano.
- Para el resto de tareas (backend puro, scripts, utilidades internas sin superficie de usuario), la
  validación automática sí es suficiente para cerrar, siempre que `/speckit.analyze` no haya reportado
  hallazgos pendientes.

## Resumen operativo

| Fase | Regla dura |
|---|---|
| Antes de `specify` | Pregunta, no asumas. Cobertura de las 10 categorías de ambigüedad. |
| Antes de `implement` | Crítica adversarial explícita (spec-critic). Veto ante objeción fatal. |
| Antes de `converge` | UAT humana obligatoria en todo lo user-facing / datos / negocio. |
