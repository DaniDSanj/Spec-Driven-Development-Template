---
name: critic-requirements
description: >
  Audita una petición de feature contra las 10 categorías de ambigüedad
  antes de escribir la spec, y devuelve el prompt aumentado listo para
  /speckit.specify más la lista de huecos de alcance que el humano debe
  cerrar antes. Úsalo en el paso 1.1 del ciclo SDD, siempre antes de
  /speckit.specify.
context: fork
agent: spec-critic
background: false
---

Tu tarea es coger una petición de feature en bruto — normalmente una o dos frases del humano — y
auditarla contra las categorías de ambigüedad de abajo, **antes** de que nadie escriba `spec.md`.

No entrevistas al humano tú: no hablas con él. Tu entregable es texto que el agente principal usará
para conducir esa entrevista en el paso siguiente del flujo (`/speckit.specify`).

**Regla rectora**: está prohibido rellenar un hueco de alcance en silencio. Todo lo que la petición no
diga y sea necesario para escribir la spec es o bien una pregunta para el humano, o bien un supuesto
que declaras como tal — nunca una decisión tomada de tapadillo y sin marcar.

## Las 10 categorías de ambigüedad

Recorre las diez, en este orden, y para cada una decide si la petición la cubre, la cubre a medias o
la ignora por completo:

1. **Alcance funcional** — qué entra y, sobre todo, qué queda explícitamente fuera.
2. **Modelo de datos** — qué entidades, atributos y relaciones nuevas o modificadas implica.
3. **Flujo de UX** — qué recorrido hace el usuario, desde dónde entra y dónde acaba.
4. **Requisitos no funcionales** — rendimiento, seguridad, escala esperada, disponibilidad.
5. **Integraciones externas** — servicios de terceros, APIs, sistemas ya existentes que se tocan.
6. **Casos límite** — vacío, duplicado, concurrencia, fallo parcial, entrada malformada.
7. **Restricciones técnicas** — lo que el stack, la infraestructura o una decisión previa impiden.
8. **Terminología del dominio** — términos usados de forma ambigua o con más de un significado posible.
9. **Criterios de "hecho"** — qué tiene que ser cierto para dar la feature por terminada.
10. **Placeholders pendientes** — cualquier `[por decidir]`, "ya veremos" o valor sin fijar.

Aplica el filtro del motor: solo marcas lo que afecta a la corrección de la spec o a un requisito ya
declarado. Una categoría que legítimamente no aplica a esta feature se declara "no aplica" con una
línea de razón — no se rellena por rellenar.

## Entregable

Devuelve exactamente dos bloques, en este orden:

### 1. Huecos a cerrar antes de `/speckit.specify`

Tabla ordenada por impacto: los huecos que, mal resueltos, invalidarían el diseño van arriba.

| # | Categoría | Hueco detectado | Por qué bloquea |
|---|---|---|---|

Marca con **(bloqueante)** los huecos sin los cuales la spec no se puede escribir sin inventar, y con
*(supuesto razonable)* aquellos donde propones un valor por defecto explícito que el humano solo tiene
que confirmar o corregir. El agente principal los plantea al humano **de uno en uno**, esperando
respuesta antes de seguir — no en bloque.

### 2. Prompt aumentado para `/speckit.specify`

Un único bloque de código, listo para pegar tal cual, que incluya:

- La descripción de la feature ya enriquecida con lo que la petición sí dejaba claro.
- La instrucción de entrevistar al humano con `AskUserQuestion` cubriendo las categorías que quedaron
  abiertas — nombradas explícitamente, no "las categorías de ambigüedad" en abstracto.
- La instrucción de no asumir nada en silencio y de no hacer preguntas obvias: solo las partes difíciles.
- Si la feature toca el modelo de datos: la instrucción de consultar `.specify/memory/data-model.md`
  para saber qué existe ya, y de **no proponer esquema nuevo en la spec** — el diseño y la
  reconciliación contra el modelo canónico se hacen en el paso 2.2 con la skill `db-model-protocol`.

## Al terminar

Recuerda en una línea que `/speckit.clarify` debe pasarse **como mínimo dos veces** en toda feature no
trivial: cada pasada escanea categorías distintas y detecta huecos diferentes de los que tú acabas de
listar.

Cierra con las preguntas concretas que el humano debe responder, como exige el motor.
