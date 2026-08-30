---
name: adr-writer
description: Formato y proceso para crear Architecture Decision Records (ADR) en el vault de Obsidian de este proyecto. Úsalo cada vez que se tome una decisión arquitectónica que un futuro mantenedor podría cuestionar razonablemente.
---

# Cómo escribir un ADR en este proyecto

1. Ubicación: `docs/ADR/records/ADR-XXXX-titulo-corto.md` (numeración correlativa de 4 dígitos).
2. Formato obligatorio: Título · Estado (`Propuesto`/`Aceptado`/`Superseded`) · Contexto · Decisión ·
   Consecuencias. Usa la plantilla Templater de `docs/Meta/Templates/adr.md`.
3. **Append-only**: nunca edites un ADR con estado `Aceptado`. Si la decisión cambia, crea un ADR
   nuevo, márcalo `Aceptado` y rellena su campo de frontmatter `supersede: [[ADR-00XX]]` apuntando
   al ADR que reemplaza. En el ADR antiguo, cambia únicamente su `estado` a `Superseded` y añade en
   el cuerpo el wikilink `Superseded por [[ADR-00YY]]` (el frontmatter `supersede:` solo se rellena
   en el ADR nuevo, no en el antiguo).
4. Un ADR = una decisión. No documentes dos decisiones distintas en el mismo fichero.
5. Sí crea ADR para: elección de librería/framework, modelo de datos, arquitectura de módulos,
   estrategia de auth, cualquier trade-off relevante.
   No crees ADR para: detalles de implementación de una función concreta (eso va en el código/commit).
6. Tras crear el ADR, asegúrate de que `docs/ADR/Overview.md` existe con el bloque `dataview`
   documentado en `docs/Meta/Workflow.md` (créalo con ese bloque la primera vez que no exista). A
   partir de ahí la tabla se regenera sola con cada ADR nuevo si el frontmatter YAML está bien
   formado — no requiere edición manual adicional.
