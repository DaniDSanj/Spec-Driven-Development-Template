---
name: verify-prepare
description: >
  Traduce el quickstart.md de la feature activa (prosa orientada a un
  humano) a un fichero estructurado quickstart_agent.md, marcando cada
  escenario como automatizable o manual. Úsalo en el paso 3.1 del ciclo SDD,
  tras el veredicto GO de /critic-plan, o cuando quickstart.md haya cambiado
  y quickstart_agent.md esté desactualizado o no exista.
context: fork
agent: spec-verifier
background: false
---

Tu tarea es traducir `specs/<feature>/quickstart.md` a
`specs/<feature>/quickstart_agent.md`, un formato estructurado y sin
ambigüedad que otra skill (`verify-validate`) pueda ejecutar sin tener que
interpretar prosa.

Se ejecuta **después** del GO de `critic-plan` (paso 2.8), no justo tras
`/speckit-plan`: traducir un `quickstart.md` que la crítica adversarial
todavía podría hacer cambiar sería trabajo desechable.

**No ejecutes ningún comando del proyecto en esta tarea.** Tu trabajo es
puramente de lectura y transformación de texto — ni siquiera para
"comprobar que existe algo". Si necesitas saber si un servicio o comando
existe, infiere lo que puedas del propio `quickstart.md` y de `spec.md`, y
si no es suficiente, dilo en el fichero de salida en vez de intentar
averiguarlo ejecutando algo.

## Pasos

1. Lee `specs/<feature>/quickstart.md`.
2. Lee `specs/<feature>/spec.md` (si existe) para mapear cada escenario con
   su requisito funcional (`FR-XXX`) o historia de usuario (`US-X`).
3. Para cada escenario o sección de validación identificable en el
   `quickstart.md`:
   - Extrae el prerrequisito, la acción/comando y el resultado esperado.
   - Reescribe el resultado esperado como condición verificable siempre
     que el texto original lo permita (código de salida, contenido exacto
     de salida, un dato comprobable). Si el texto original es
     irreductiblemente subjetivo (aspecto visual, tono, UX), no lo fuerces:
     marca el escenario como `manual`.
   - Clasifica el escenario: `automatizable` (tiene una condición
     verificable de forma determinista) o `manual` (requiere juicio
     humano).
4. Si `quickstart.md` no está estructurado en escenarios claros, haz tu
   mejor interpretación razonable y anota en el fichero de salida, en una
   sección `## Limitaciones de traducción`, qué partes no has podido
   mapear con confianza — no las inventes ni las fuerces a encajar.

## Fusión con una versión anterior (idempotencia)

Si `specs/<feature>/quickstart_agent.md` ya existe:

- Para cada escenario cuyo contenido (Dado/Cuando/Entonces) no haya
  cambiado respecto a la versión anterior, **conserva su `Resultado` y su
  evidencia tal cual estaban** — no los resetees a `PENDIENTE`.
- Para un escenario nuevo, o cuyo contenido sí ha cambiado, su `Resultado`
  pasa a `PENDIENTE` (con nota: "reseteado por cambios en quickstart.md").
- Para un escenario que existía y ha desaparecido de `quickstart.md`,
  elimínalo de `quickstart_agent.md` y menciónalo en una nota al inicio del
  fichero ("Escenario UAT-0X eliminado: ya no aparece en quickstart.md").
- Añade siempre una línea al inicio del fichero indicando si esta ejecución
  ha sido una traducción desde cero o una fusión, y qué ha cambiado.

## Formato de salida (`quickstart_agent.md`)

```markdown
# Quickstart Agent — <Feature>

> Generado por la skill `verify-prepare` a partir de `quickstart.md`.
> El campo "Resultado" de cada escenario lo gestiona la skill
> `verify-validate` — no lo edites a mano. Para cambiar un escenario,
> edita `quickstart.md` y vuelve a ejecutar `verify-prepare`.

- Última traducción: <fecha> (<desde cero | fusión — resumen de cambios>)
- Última validación: <fecha de la última ejecución de verify-validate | sin ejecutar>

## Resumen de la última ejecución

| Total | ✅ Realizadas | ❌ Erróneas | ⏳ Pendientes | 🚫 Inalcanzables |
|---|---|---|---|---|
| N | X | Y | Z | W |

## Escenarios

### UAT-01 — <nombre corto>
- Cubre: FR-00X
- Tipo: automatizable
- Dado: <estado inicial>
- Cuando:
  ```bash
  <comando exacto>
  ```
- Entonces (verificable):
  - Código de salida: `0`
  - Salida contiene: `"..."`
  - (u otra condición comprobable)
- Limpieza: <comando de teardown, si aplica>
- **Resultado**: ⏳ PENDIENTE
- Evidencia:
- Notas:

### UAT-02 — <nombre corto>
- Cubre: US-X
- Tipo: manual
- Descripción: <qué debe comprobar un humano y por qué no es automatizable>
- **Resultado**: ⏳ PENDIENTE (requiere revisión humana)
- Notas:
```

## Al terminar

Escribe el fichero con `Write` (o `Edit` si solo estás fusionando cambios
puntuales). Devuelve un resumen breve: cuántos escenarios se han traducido,
cuántos son `automatizable` frente a `manual`, y si ha habido fusión con una
versión anterior. No ejecutes `verify-validate` a continuación por tu
cuenta — eso lo decide quien te ha invocado.
