# Mantenimiento futuro — reabrir el proyecto

## Cuándo usarlo

Cada vez que retomes un proyecto ya cerrado (días, semanas o meses después) para pedir una corrección,
una mejora pequeña o una funcionalidad nueva.

## Prompt

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
- FUNCIONALIDAD NUEVA → ciclo SDD completo desde /speckit.constitution (si hay que revisar principios) o directamente /speckit.specify, siguiendo `@.claude/prompts/02_Desarrollo.md` y `@.claude/prompts/03_Cierre.md` igual que en el desarrollo original.

No empieces a implementar nada hasta que confirmes conmigo la categoría elegida.
```

## Nota

Esta clasificación existe para que el asistente no trate cada "arréglame esto" como una feature nueva
completa (sobrecoste innecesario) ni una funcionalidad nueva como un simple fix (falta de spec/plan
adecuados). El resto de reglas del proyecto (`@.claude/context/01_estilo_comportamiento.md`,
`@.claude/context/02_documentacion_mantenibilidad.md`) se siguen aplicando sin excepción en cualquiera de los
tres casos.
