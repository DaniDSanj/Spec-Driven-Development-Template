---
tipo: spec
feature: <% tp.system.prompt("Nombre corto de la feature (kebab-case)") %>
estado: En desarrollo
fecha: <% tp.date.now("YYYY-MM-DD") %>
---

# Spec: <% tp.file.title %>

> Espejo human-readable de `specs/<% tp.file.title %>/spec.md`. Se actualiza tras `/speckit.specify` +
> `/speckit.clarify`; no sustituye al fichero fuente que gestiona Spec-Kit.

## Resumen
<% tp.system.prompt("Descripción breve de la feature") %>

## Alcance funcional
<% tp.system.prompt("¿Qué incluye y qué queda explícitamente fuera de alcance?") %>

## Criterios de aceptación
<% tp.system.prompt("Lista de criterios de aceptación") %>

## Enlaces
- Spec fuente: `specs/<% tp.file.title %>/spec.md`
- ADR relacionados: [[ ]]
- Issues de GitHub: [[ ]]
