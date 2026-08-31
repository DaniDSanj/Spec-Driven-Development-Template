---
tipo: adr
id: ADR-<% tp.system.prompt("Número, ej. 0007") %>
estado: Propuesto
fecha: <% tp.date.now("YYYY-MM-DD") %>
supersede: 
---

# ADR-<% tp.file.title %>: <% tp.system.prompt("Título de la decisión") %>

## Contexto
<% tp.system.prompt("¿Qué problema o fuerza motiva esta decisión?") %>

## Decisión
<% tp.system.prompt("¿Qué se decide hacer?") %>

## Consecuencias
<% tp.system.prompt("¿Qué se gana y qué se sacrifica con esta decisión?") %>
