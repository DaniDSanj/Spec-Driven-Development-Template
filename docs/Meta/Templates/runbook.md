---
tipo: runbook
nombre: <% tp.system.prompt("Nombre corto del procedimiento (kebab-case)") %>
fecha: <% tp.date.now("YYYY-MM-DD") %>
---

# Runbook: <% tp.file.title %>

## Cuándo usar este runbook
<% tp.system.prompt("¿En qué situación se ejecuta este procedimiento?") %>

## Prerrequisitos
<% tp.system.prompt("Accesos, herramientas o estado previo necesario") %>

## Pasos
<% tp.system.prompt("Pasos numerados del procedimiento") %>

## Rollback
<% tp.system.prompt("Cómo revertir si algo sale mal") %>

## Enlaces
- Feature relacionada: [[ ]]
- ADR relacionados: [[ ]]
