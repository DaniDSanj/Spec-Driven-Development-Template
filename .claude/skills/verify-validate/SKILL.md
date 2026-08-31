---
name: verify-validate
description: >
  Ejecuta las validaciones automatizables descritas en quickstart_agent.md
  para la feature activa y anota el resultado de cada una (REALIZADA,
  ERRÓNEA, PENDIENTE, INALCANZABLE) directamente en ese fichero. Muestra
  además un resumen por consola. No corrige el proyecto ni edita ningún
  otro fichero. Úsalo después de /speckit.implement, y de nuevo tras cada
  corrección, hasta que no queden ERRÓNEAS ni INALCANZABLES.
context: fork
agent: spec-verifier
background: false
---

Tu tarea es ejecutar, uno por uno, los escenarios `automatizable` descritos
en `specs/<feature>/quickstart_agent.md`, anotar el resultado de cada uno
directamente en ese fichero, y devolver un resumen.

Si `specs/<feature>/quickstart_agent.md` no existe, no lo generes tú: dilo
explícitamente y termina indicando que hay que ejecutar `verify-prepare`
primero.

## Definición de los cuatro estados — sin término medio

- **✅ REALIZADA**: se ha ejecutado el escenario y el resultado observado
  coincide con el "Entonces" documentado, con evidencia objetiva adjunta.
- **❌ ERRÓNEA**: se ha ejecutado el escenario y el resultado observado NO
  coincide con el "Entonces" documentado. Documenta la diferencia exacta.
- **⏳ PENDIENTE**: el escenario es de tipo `manual` (siempre queda
  pendiente de revisión humana, tú nunca lo resuelves), o es
  `automatizable` pero no ha llegado a ejecutarse en esta pasada (por
  ejemplo, por una parada temprana deliberada — explica el motivo si es
  así).
- **🚫 INALCANZABLE**: el escenario es `automatizable`, has intentado
  ejecutarlo, pero un prerrequisito no disponible te lo ha impedido
  (servicio caído, variable de entorno ausente, credencial no disponible,
  dependencia no instalada). Indica exactamente qué prerrequisito falta.

Nunca marques `REALIZADA` por ausencia de errores visibles: verifica
activamente la condición positiva. Nunca marques `ERRÓNEA` por prudencia
si en realidad no has podido comprobar nada — en ese caso es
`INALCANZABLE`.

## Pasos, por cada escenario `automatizable`

1. Comprueba el prerrequisito documentado. Si no se cumple y no hay un
   comando de setup en el propio escenario que lo resuelva, márcalo
   `INALCANZABLE` con el motivo exacto y pasa al siguiente.
2. Ejecuta el comando exactamente como está escrito en "Cuando". No lo
   modifiques ni lo "mejores" — si está roto o desactualizado, eso es en
   sí mismo un hallazgo (repórtalo como `ERRÓNEA` con esa explicación).
3. Captura salida estándar, salida de error y código de salida.
4. Compara contra el "Entonces" del escenario. Clasifica según la
   definición de arriba.
5. Ejecuta el comando de "Limpieza" si existe, incluso si el escenario ha
   fallado.
6. Actualiza el campo `Resultado`, `Evidencia` y `Notas` de ese escenario
   en `quickstart_agent.md` (con `Edit`, sustituyendo solo ese bloque).

Los escenarios `manual` no se ejecutan: se dejan como `⏳ PENDIENTE
(requiere revisión humana)` sin tocar nada más de ellos.

## Al terminar

1. Actualiza la sección `## Resumen de la última ejecución` de
   `quickstart_agent.md` (la tabla con los totales) y la fecha de "Última
   validación".
2. Imprime en la conversación un resumen con esta forma:

```
Validación de <feature> — <fecha>

Total: N | ✅ Realizadas: X | ❌ Erróneas: Y | ⏳ Pendientes: Z | 🚫 Inalcanzables: W

❌ Erróneas:
  - UAT-0X: <motivo en una línea>

🚫 Inalcanzables:
  - UAT-0Y: <prerrequisito que falta>

⏳ Pendientes (revisión manual):
  - UAT-0Z: <qué debe comprobar un humano>
```

3. Si hay `ERRÓNEA` o `INALCANZABLE`, termina con una línea explícita como:
   "Hay N puntos sin resolver en quickstart_agent.md. Pide a Claude que los
   revise y corrija el proyecto en base a lo reflejado allí, y vuelve a
   ejecutar /verify-validate cuando termine." No los corrijas tú.

Solo has escrito en `quickstart_agent.md` en todo el proceso — ningún otro
fichero.
