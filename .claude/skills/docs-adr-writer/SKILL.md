---
name: docs-adr-writer
description: >
  Redacta un Architecture Decision Record en el vault de Obsidian del proyecto:
  ruta y numeración, formato Nygard, regla append-only con supersede, y el
  índice Dataview de docs/ADR/Overview.md. Úsalo en el paso 2.4 del ciclo SDD
  —el mismo día de la decisión, antes de /speckit-tasks— y en el 5.3 para
  cualquier decisión que quedara sin ADR.
context: fork
agent: docs-manager
background: false
---

Tu tarea es redactar **un** ADR como borrador, listo para que el humano lo revise antes de
commitearlo. No commitees tú.

## Antes de escribir: ¿esta decisión merece un ADR?

Sí merece ADR: elección de tecnología, librería o framework; modelo de datos; arquitectura de
módulos; estrategia de autenticación/autorización; y cualquier trade-off que un futuro mantenedor
podría cuestionar razonablemente.

No merece ADR: detalles de implementación de bajo nivel (por qué una función maneja un error de una
forma concreta) — eso se documenta en el propio código o en el mensaje de commit.

Si la decisión que te han pasado cae en el segundo grupo, dilo y no crees el fichero.

## Redacción

1. **Ruta y numeración**: `docs/ADR/records/ADR-XXXX-titulo-corto.md`, numeración correlativa de 4
   dígitos. Mira qué ADR existen ya antes de elegir el número; nunca reutilices uno.
2. **Formato obligatorio** (Nygard), con la plantilla Templater de `docs/Meta/Templates/adr.md`:

   - Frontmatter: `tipo: adr`, `id: ADR-XXXX`, `estado`, `fecha`, `supersede:`.
   - Cuerpo: **Título · Contexto · Decisión · Consecuencias**.
   - `estado`: `Propuesto` mientras se discute, `Aceptado` una vez tomada, `Superseded` cuando otro
     ADR la reemplaza.
3. **Contexto** describe la fuerza que motiva la decisión, no la decisión. **Consecuencias** dice qué
   se gana *y qué se sacrifica* — un ADR sin coste declarado está incompleto.
4. **Un ADR = una decisión.** Si te pasan dos, redacta dos ficheros y dilo.
5. **Append-only**: si esta decisión reemplaza a una anterior, crea el ADR nuevo con
   `supersede: [[ADR-00XX]]` en su frontmatter y en el antiguo cambia **solo** su `estado` a
   `Superseded`, añadiendo en el cuerpo `Superseded por [[ADR-00YY]]`. El campo `supersede:` se
   rellena únicamente en el ADR nuevo.
6. **Enlaces**: conecta con wikilinks la nota de spec de la feature, los issues implicados y
   cualquier ADR relacionado.

## Índice

Tras crear el ADR, comprueba que `docs/ADR/Overview.md` existe con el bloque `dataview` documentado
en `docs/Meta/Workflow.md`; créalo con ese bloque la primera vez que no exista. A partir de ahí la
tabla se regenera sola con cada ADR nuevo si el frontmatter YAML está bien formado — no requiere
edición manual adicional.

## Al terminar

Resume qué ADR creaste (ruta y título), qué ADR marcaste como `Superseded` si aplica, y pregunta lo
que te haya faltado para redactar el Contexto o las Consecuencias.
