# Ciclo SDD — Desarrollo de una spec

Documento único del ciclo de vida de una feature, de la petición al merge. Se lee de arriba abajo:
un prompt por paso, en este orden.

- **Proyecto nuevo, primera feature** → empieza en el paso [1.0](#10--speckitconstitution-solo-la-primera-vez).
- **Proyecto ya cerrado que retomas** (días, semanas o meses después) → empieza en la
  [Fase 0](#fase-0--encuadre-solo-al-retomar-un-proyecto), que decide qué fases de abajo aplican.
- Los pasos marcados *(si …)* son condicionales: si la condición no se cumple, sáltalos.
- Cada paso termina con **Siguiente:**, para que los saltos condicionales sean navegables.

| Fase | Qué cubre |
|---|---|
| [0 — Encuadre](#fase-0--encuadre-solo-al-retomar-un-proyecto) | Reconstruir contexto y clasificar la petición |
| [1 — Especificación](#fase-1--especificación) | `constitution` · `critic-requirements` · `specify` · `clarify` |
| [2 — Plan](#fase-2--plan) | `plan` · esquema de datos · `tasks` · `critic-plan` |
| [3 — Preparación](#fase-3--preparación-de-la-ejecución) | `verify-prepare` · issues · rama de feature |
| [4 — Implementación](#fase-4--implementación) | `dev-python-*` + `implement` · migración · `verify-validate` · `critic-verifications` · UAT |
| [5 — Cierre](#fase-5--cierre) | `converge` · seguridad · documentación · commit y PR |

---

## Fase 0 — Encuadre (solo al retomar un proyecto)

Sáltate esta fase entera si estás en un proyecto nuevo o continuando un ciclo ya en marcha.

### 0.1 — Reconstruir el contexto y clasificar la petición

```
Vamos a retomar este proyecto. Antes de proponer nada, reconstruye el contexto:

1. Lee CLAUDE.md y todos sus imports en `@.claude/context/`.
2. Lee el CHANGELOG.md completo para entender qué se ha entregado hasta ahora.
3. Lee los ADR más recientes en el vault (`@docs/ADR/records/`, ordenados por fecha) para entender las decisiones arquitectónicas vigentes.
4. Revisa el estado de specs/ y GitHub Issues abiertos para ver si hay trabajo a medias.

Lo que quiero ahora es: [descripción de la petición].

Clasifica la petición en una de estas categorías y dime cuál elegiste, con tu razonamiento:

- CORRECCIÓN (bug en algo ya existente, sin cambio de alcance) → no requiere un ciclo SDD completo; basta con un fix directo + test de regresión + entrada de CHANGELOG.md en Fixed.
- MEJORA PEQUEÑA (ajuste menor sobre una feature existente, sin nuevo modelo de datos ni nueva superficie de usuario) → ciclo SDD ligero: specify + clarify + implement directamente, sin plan completo si el plan existente de la feature original sigue siendo válido.
- FUNCIONALIDAD NUEVA → ciclo SDD completo desde /speckit.constitution (si hay que revisar principios) o directamente /speckit.specify.

No empieces a implementar nada hasta que confirmes conmigo la categoría elegida.
```

Esta clasificación existe para que el asistente no trate cada "arréglame esto" como una feature nueva
completa (sobrecoste innecesario) ni una funcionalidad nueva como un simple fix (falta de spec/plan
adecuados). El resto de reglas del proyecto se siguen aplicando sin excepción en cualquiera de los
tres casos.

### 0.2 — Ruta según la categoría confirmada

| Categoría | Fases que se ejecutan |
|---|---|
| **CORRECCIÓN** | Salta las Fases 1 y 2. Entra en [3.3](#33--crear-la-rama-de-feature) (rama), luego [4.1](#41--speckitimplement) con el fix + test de regresión, y cierra por la [Fase 5](#fase-5--cierre) (la entrada de changelog va bajo `Fixed`). |
| **MEJORA PEQUEÑA** | [Fase 1](#fase-1--especificación) completa. En la Fase 2, si el plan original de la feature sigue siendo válido, salta de [2.1](#21--speckitplan) directo a [2.6](#26--speckittasks). Luego Fases 3, 4 y 5 normales. |
| **FUNCIONALIDAD NUEVA** | Ciclo completo desde [1.0](#10--speckitconstitution-solo-la-primera-vez). |

**Siguiente:** el paso que indique la tabla según la categoría confirmada.

---

## Fase 1 — Especificación

### 1.0 — `/speckit.constitution` (solo la primera vez)

Solo en la primera feature del proyecto, o al cambiar los principios rectores.

```
/speckit.constitution

Establece los principios rectores de este proyecto: stack (Python [versión], PostgreSQL/SQL Server, Claude Code + Spec-Kit), disciplina de testing (TDD estricto en módulos de negocio, tests obligatorios antes de cerrar tarea), estilo de documentación (ver `@.claude/context/02_documentacion_mantenibilidad.md`), y cualquier restricción no negociable del proyecto (ej. no usar plataformas de pago).
```

**Siguiente:** [1.1](#11--critic-requirements).

### 1.1 — `/critic-requirements`

```
Ejecuta la skill /critic-requirements sobre esta petición: [descripción breve de la feature].
```

Audita la petición contra las 10 categorías de ambigüedad y devuelve dos cosas: la lista de huecos de
alcance a cerrar (ordenada por impacto) y el **prompt aumentado** listo para pegar en el paso
siguiente. Los huecos marcados *(bloqueante)* se resuelven **antes** de pasar a 1.2, preguntando de
una pregunta cada vez. No se rellena ningún hueco de alcance en silencio.

**Siguiente:** [1.2](#12--speckitspecify), con los bloqueantes ya resueltos.

### 1.2 — `/speckit.specify`

Pega el prompt aumentado que devolvió [1.1](#11--critic-requirements) detrás del comando. Si no
ejecutaste 1.1, esta es la plantilla mínima equivalente:

```
/speckit.specify

Quiero construir: [descripción breve de la feature].

Antes de escribir la spec, entrevístame en detalle usando AskUserQuestion sobre las categorías que quedaron abiertas: [las que liste 1.1]. No hagas preguntas obvias; dig into las partes difíciles que quizá no he considerado. No asumas nada en silencio: si algo es ambiguo, pregunta antes de escribir spec.md, y de una pregunta cada vez.

Antes de definir cualquier estructura de datos, consulta .specify/memory/data-model.md y sigue el protocolo descrito en .specify/memory/schema-change-protocol.md para cualquier creación o modificación de esquema.
```

**Siguiente:** [1.3](#13--speckitclarify-mínimo-dos-pasadas).

### 1.3 — `/speckit.clarify` (mínimo dos pasadas)

```
/speckit.clarify
```

Repite una segunda vez tras resolver las primeras preguntas — cada pasada detecta ambigüedades
distintas porque escanea categorías diferentes.

**Siguiente:** [1.4](#14--si-la-feature-toca-el-modelo-de-datos-boceto-de-tablas) si la feature toca datos; si no, [2.1](#21--speckitplan).

### 1.4 — *(si la feature toca el modelo de datos)* Boceto de tablas

Si tienes ideas concretas de tablas/campos/tipos/claves para esta feature (más rápidas de dibujar que
de explicar en prosa), apúntalas antes en `.specify/memory/db_ideas.md` — es un fichero transversal a
todo el proyecto, no exclusivo de esta feature. El subagente que diseña el esquema **no lo lee por su
cuenta**: solo lo consulta como borrador de partida (nunca como sustituto de las convenciones de
`@.claude/context/04_base_datos.md`) si tú lo referencias explícitamente en el propio prompt del paso
[2.1](#21--speckitplan).

**Siguiente:** [2.1](#21--speckitplan).

---

## Fase 2 — Plan

### 2.1 — `/speckit.plan`

```
/speckit.plan

Genera el plan técnico. Stack: [Python versión] con [FastAPI/Django/Kivy/BeeWare/Flet según aplique], [PostgreSQL/SQL Server]. 

Boceto de estructuras de datos necesarias para esta funcionalidad: 
[No hay ideas dentro de esta spec] | [Puedes encontrarlo en `@.specify/memory/db_ideas.md`]

Si la feature toca el modelo de datos, invoca al subagente db-designer para proponer el esquema siguiendo `@.claude/context/04_base_datos.md`. Reconcilia el boceto contra el modelo canónico en .specify/memory/data-model.md antes de aceptarlo como definitivo. Si detectas necesidad de modificar estructuras existentes, aplica el protocolo de .specify/memory/schema-change-protocol.md y preséntame la propuesta de impacto antes de continuar con el resto del plan.
```

**Siguiente:** [2.2](#22--si-la-feature-toca-el-modelo-de-datos-propuesta-de-esquema-e-impacto) si toca datos; si no, [2.4](#24--si-hubo-decisión-arquitectónica-adr).

### 2.2 — *(si la feature toca el modelo de datos)* Propuesta de esquema e impacto

El subagente entrega DDL completo, bloque Mermaid `erDiagram` y la lista de specs afectadas por
cualquier modificación de una estructura existente. **Espera tu aprobación explícita** antes de que
se aplique nada sobre el modelo canónico: ante conflicto entre una spec antigua y la nueva necesidad,
la antigua se adapta a la nueva, nunca al revés.

**Siguiente:** [2.3](#23--si-el-plan-generó-data-modelmd-sincronizar-el-vault).

### 2.3 — *(si el plan generó `data-model.md`)* Sincronizar el vault

Primer disparo de la tabla de `@.claude/context/02_documentacion_mantenibilidad.md` sección 5.

```
El plan de esta feature ha generado data-model.md. Usa el subagente docs-updater para sincronizar el erDiagram Mermaid en la nota de arquitectura del vault (`docs/Data-Model/[feature]-ER.md`), siguiendo el formato de la skill obsidian-sync. Déjalo como borrador, sin commitear.
```

**Siguiente:** [2.4](#24--si-hubo-decisión-arquitectónica-adr).

### 2.4 — *(si hubo decisión arquitectónica)* ADR

Segundo disparo de la tabla de la sección 5: un ADR se escribe **el mismo día de la decisión y antes
de continuar con `tasks`**, no en el cierre. Aplica a elección de tecnología/librería, modelo de
datos, arquitectura de módulos, estrategia de autenticación/autorización, o cualquier trade-off que un
futuro mantenedor podría cuestionar razonablemente.

```
En el plan de esta feature se ha tomado una decisión arquitectónica: [cuál]. Usa el subagente docs-updater para redactar el ADR correspondiente siguiendo la skill adr-writer. Déjalo como borrador, sin commitear.
```

**Siguiente:** [2.5](#25--speckitchecklist).

### 2.5 — `/speckit.checklist`

```
/speckit.checklist
```

**Siguiente:** [2.6](#26--speckittasks).

### 2.6 — `/speckit.tasks`

```
/speckit.tasks
```

**Siguiente:** [2.7](#27--speckitanalyze-read-only).

### 2.7 — `/speckit.analyze` (read-only)

```
/speckit.analyze
```

Si reporta hallazgos, resuélvelos (vuelve a [1.2](#12--speckitspecify), [2.1](#21--speckitplan) o
[2.6](#26--speckittasks) según corresponda) antes de continuar.

**Siguiente:** [2.8](#28--critic-plan-obligatorio).

### 2.8 — `/critic-plan` (obligatorio)

Obligatorio antes de implementar, en cualquier feature no trivial.

```
Ejecuta la skill /critic-plan para la feature activa.
```

Revisa `spec.md`, `plan.md` y `tasks.md` en contexto limpio (solo esos tres ficheros, no el histórico
de la conversación de planificación) y devuelve el listado completo de hallazgos más un veredicto
**GO/NO-GO**. Ante un **NO-GO** no se sigue "con reservas": se resuelve la objeción volviendo al paso
que indique la ruta de resolución ([1.2](#12--speckitspecify), [2.1](#21--speckitplan) o
[2.6](#26--speckittasks)) y se repite esta revisión entera.

**Siguiente:** [3.1](#31--verify-prepare), solo con un GO.

---

## Fase 3 — Preparación de la ejecución

### 3.1 — `/verify-prepare`

```
Ejecuta la skill /verify-prepare para la feature activa.
```

Traduce `specs/<feature>/quickstart.md` (generado en el paso [2.1](#21--speckitplan)) a
`specs/<feature>/quickstart_agent.md`, clasificando cada escenario como `automatizable` o `manual`.
Se ejecuta después del GO de [2.8](#28--critic-plan-obligatorio) a propósito — traducir un
`quickstart.md` que la crítica adversarial todavía podría hacer cambiar sería trabajo desechable. Si ya existía una versión previa de
`quickstart_agent.md`, la fusión es idempotente: conserva el resultado de los escenarios sin cambios.

**Siguiente:** [3.2](#32--speckittaskstoissues).

### 3.2 — `/speckit.taskstoissues`

Features con más de ~5 tareas.

```
/speckit.taskstoissues
```

Ejecútalo **antes** de implementar, nunca después: es lo que da seguimiento en tiempo real a las
tareas mientras se hacen, no un registro histórico de lo ya terminado.

**Siguiente:** [3.3](#33--crear-la-rama-de-feature).

### 3.3 — Crear la rama de feature

Obligatoria **siempre, sin excepción por trivialidad** (ver `@.claude/context/05_github.md`): `dev`
tiene `required_status_checks` con `enforce_admins: true`, así que GitHub rechaza cualquier push
directo, incluso del owner del repo.

```
Crea la rama `feature/<id-speckit>-<slug>` a partir de `dev` y cámbiate a ella. Confírmame el nombre exacto de rama que has usado.
```

Referencia de lo que ejecutará el asistente (no lo lances tú a mano):

```bash
git checkout -b feature/<id-speckit>-<slug> dev
```

**Siguiente:** [4.1](#41--speckitimplement).

---

## Fase 4 — Implementación

### 4.1 — `/speckit.implement`

```
Carga las skills /dev-python-coding y /dev-python-testing, y a continuación ejecuta /speckit.implement.

Implementa las tareas de esta feature aplicando esas convenciones. Para cada tarea que toque una superficie de usuario o datos de producción, señala explícitamente que requiere UAT humana antes de marcarla como cerrada y describe qué debo probar exactamente.
```

Las dos skills se cargan **antes** de `/speckit.implement`, no dentro: `/speckit.implement` es un
comando de Spec-Kit cuyo interior no controlamos, así que la única forma determinista de que escriba
con las convenciones puestas es tenerlas ya en contexto cuando arranca. Son skills planas a propósito
—no forkean a ningún subagente— porque el código se escribe en este mismo hilo, que es el que tiene
`spec.md`, `plan.md`, `tasks.md` y el bucle de corrección del paso
[4.3](#43--verify-validate-repite-tras-cada-corrección).

**Siguiente:** [4.2](#42--si-la-feature-incluye-una-migración-aplicarla) si hay migración; si no, [4.3](#43--verify-validate-repite-tras-cada-corrección).

### 4.2 — *(si la feature incluye una migración)* Aplicarla

Toda migración se genera, se revisa a mano y se versiona en Git; nunca se aplican cambios de esquema
directamente en la BD. Si la migración afecta a **datos ya existentes en producción**, requiere UAT
humana explícita antes de aplicarse.

```
Genera la migración de esta feature con la herramienta de migraciones del proyecto (ver `@.claude/context/04_base_datos.md`) y muéstramela para revisión. No la apliques hasta que te lo confirme explícitamente. Tras la aprobación, actualiza `.specify/memory/data-model.md` (entidad + changelog).
```

**Siguiente:** [4.3](#43--verify-validate-repite-tras-cada-corrección).

### 4.3 — `/verify-validate` (repite tras cada corrección)

```
Ejecuta la skill /verify-validate para la feature activa.
```

Ejecuta los escenarios `automatizable` de `quickstart_agent.md` y anota el resultado de cada uno
(✅ REALIZADA / ❌ ERRÓNEA / ⏳ PENDIENTE / 🚫 INALCANZABLE) directamente en ese fichero, sin corregir
nada por su cuenta. Si reporta `ERRÓNEA` o `INALCANZABLE`, corrige el código según lo anotado y repite
este paso — **no avances mientras queden puntos sin resolver de este tipo**. Los escenarios `manual`
quedan `PENDIENTE` a propósito: se confirman en el paso [4.5](#45--uat-manual).

**Siguiente:** [4.4](#44--critic-verifications).

### 4.4 — `/critic-verifications`

La validación automática en verde es condición necesaria pero **no suficiente** para cerrar una feature.

```
Ejecuta la skill /critic-verifications para la feature activa.
```

Audita tres cosas y devuelve el listado completo de lo que incumple alguna: que toda tarea con
superficie de usuario, regla de negocio con impacto económico/legal/de datos sensibles o migración
sobre datos de producción esté marcada como pendiente de UAT humana; que ninguna tarea se haya cerrado
sin evidencia objetiva; y que la clasificación `automatizable`/`manual` de `quickstart_agent.md` sea
correcta. No ejecuta ni corrige nada — a diferencia de [4.3](#43--verify-validate-repite-tras-cada-corrección),
que sí ejecuta escenarios y escribe en `quickstart_agent.md`.

**Siguiente:** [4.5](#45--uat-manual).

### 4.5 — UAT manual

```
Repasa los escenarios Tipo: manual que sigan en ⏳ PENDIENTE en specs/<feature>/quickstart_agent.md (los automatizable ya quedaron resueltos por /verify-validate). Para cada uno, recuérdame qué debo probar y en qué entorno. No los marques como cerrados hasta que confirme explícitamente cada uno.
```

Espera tu confirmación explícita **por cada punto** antes de continuar.

En cuanto las tareas y su UAT (automática y manual) queden validadas, el asistente debe proponer
activamente —como parte del cierre de esta tarea, no como ocurrencia tardía— abrir la PR hacia `dev`
con `Closes #N` por cada issue que resuelve (paso [5.6](#56--commit-push-y-pr-hacia-dev)).

**Siguiente:** [5.1](#51--speckitconverge).

---

## Fase 5 — Cierre

### 5.1 — `/speckit.converge`

```
/speckit.converge
```

Si no reporta "Converged" sino trabajo pendiente, vuelve a [2.6](#26--speckittasks) o
[4.1](#41--speckitimplement) para resolverlo antes de continuar.

**Siguiente:** [5.2](#52--si-tocó-superficie-sensible-revisión-de-seguridad).

### 5.2 — *(si tocó superficie sensible)* Revisión de seguridad

Aplica si la feature tocó autenticación, secretos/`.env`, migraciones o entradas no confiables.

```
Usa el subagente security-reviewer sobre los cambios de esta feature. Resuelve cualquier hallazgo Bloqueante o Alto antes de continuar con el cierre.
```

**Siguiente:** [5.3](#53--cierre-de-documentación).

### 5.3 — Cierre de documentación

```
Esta feature ha convergido y su UAT (si aplicaba) está confirmada. Usa el subagente docs-updater para:

1. Determinar, según la tabla de disparo de `@.claude/context/02_documentacion_mantenibilidad.md`, qué artefactos de documentación faltan (ADR, nota de vault, runbook).
2. Redactar cada uno como borrador, siguiendo el formato de las skills adr-writer y obsidian-sync.
3. Presentarme un resumen de qué se creó o actualizó, sin hacer commit todavía.
```

Los ADR de decisiones tomadas durante el plan ya se escribieron en el paso
[2.4](#24--si-hubo-decisión-arquitectónica-adr); aquí solo se cubre lo que falte.

**Siguiente:** [5.4](#54--changelog).

### 5.4 — Changelog

El `CHANGELOG.md` se actualiza **en el cierre**, nunca a mano en mitad del desarrollo: se genera a
partir de los Conventional Commits del rango de la feature.

```
Usa el subagente docs-updater para generar las entradas de CHANGELOG.md a partir de los commits Conventional Commits de esta feature, agrupadas en Added/Changed/Deprecated/Removed/Fixed/Security según el formato Keep a Changelog 2.0.0. Si algún commit lleva `BREAKING CHANGE:`, refleja la ruptura bajo `Changed`/`Removed` y comprueba que existe el ADR que la documenta. Déjalo como borrador, sin commitear.
```

**Siguiente:** [5.5](#55--revisión-humana-y-checklist-de-consistencia).

### 5.5 — Revisión humana y checklist de consistencia

- Revisa a mano los borradores generados (ADR, changelog, notas de vault).
- Confirma que el checklist de consistencia de
  `@.claude/context/02_documentacion_mantenibilidad.md` (sección 6) está completo: docstrings y type
  hints, ADR si hubo decisión, Conventional Commits con ID de feature, `CHANGELOG.md` actualizado,
  nota de la feature enlazada con su ADR e Issue, y UAT humana confirmada si aplicaba.

**Siguiente:** [5.6](#56--commit-push-y-pr-hacia-dev).

### 5.6 — Commit, push y PR hacia `dev`

```
Commitea los cambios de esta feature siguiendo Conventional Commits, referenciando el ID de la feature en el mensaje.
```

Referencia de lo que ejecutará el asistente:

```bash
git add .
git commit -m "feat(<id-feature>): <resumen>"
```

Después, la PR hacia `dev` — no la dejes para más tarde: es lo que dispara el cierre automático de los
issues al mergear. `@.claude/context/05_github.md` permite al asistente abrir PRs de `feature/*` a
`dev` cuando se le pide explícitamente, a diferencia de la PR `dev → main`.

```
Empuja la rama `feature/<id-speckit>-<slug>` y abre una PR hacia `dev` que incluya `Closes #N` por cada issue que esta feature resuelve. Confírmame el número de PR resultante.
```

Referencia de lo que ejecutará el asistente:

```bash
git push origin feature/<id-speckit>-<slug>
gh pr create --base dev --head feature/<id-speckit>-<slug> --title "feat(<id-feature>): <resumen>" --body "Closes #N, Closes #M"
```

**Formato obligatorio**: repite la palabra clave por cada issue (`Closes #47, Closes #48`), nunca una
lista separada por comas — GitHub solo cierra la referencia que sigue inmediatamente a `Closes`.

**Siguiente:** [5.7](#57--supervisar-el-ci-de-la-pr).

### 5.7 — Supervisar el CI de la PR

La PR no se puede mergear hasta que el job `quality` de `.github/workflows/ci.yml` esté en verde
(`required_status_checks` con `strict: true`).

```
Comprueba el estado del check `quality` en la PR #N. Si está en rojo, muéstrame el log del paso que falla y propón la corrección.
```

**Siguiente:** [5.8](#58--merge-y-cierre).

### 5.8 — Merge y cierre

- Mergea tú mismo la PR `feature/* → dev` una vez el CI esté en verde.
- Abre tú mismo (el humano) la PR de `dev` a `main` cuando corresponda — el asistente **no** lo hace
  de forma autónoma (ver `@.claude/context/05_github.md`).

Con esto la feature queda cerrada y trazada de extremo a extremo: spec → plan → tasks → issues →
implementación → UAT → ADR/changelog/vault → commit → PR con `Closes #N` → (el humano mergea) →
Issue cerrado automáticamente.
