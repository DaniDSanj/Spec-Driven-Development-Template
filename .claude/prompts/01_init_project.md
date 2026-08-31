# Generación del `CLAUDE.md` del proyecto

Se ejecuta **una sola vez**, al arrancar un proyecto nuevo, **después** de haber rellenado
`.claude/context/00_perfil_proyecto.md` con los datos reales del proyecto (`bootstrap.ps1` rellena la
parte mecánica; el resto se completa a mano).

El prompt no lleva placeholders: los datos del proyecto los lee Claude del perfil. Cópialo y pégalo
tal cual dentro de una sesión de `claude` abierta en la raíz del proyecto.

> Al ejecutarse, este prompt **sobrescribe** el `CLAUDE.md` que trae la plantilla (que contiene
> meta-instrucciones para editar la plantilla misma) con el `CLAUDE.md` real del proyecto. Esa
> sobrescritura es intencionada.

## Prompt

```
Vas a generar el fichero CLAUDE.md de la raíz de este proyecto.

Antes de escribir nada, lee estos ficheros completos:
- `@.claude/context/00_perfil_proyecto.md` — los datos concretos de este proyecto
- `@.claude/context/01_estilo_comportamiento.md`
- `@.claude/context/02_documentacion_mantenibilidad.md`
- `@.claude/context/03_python.md`
- `@.claude/context/04_base_datos.md`
- `@.claude/context/05_github.md`

Si en `00_perfil_proyecto.md` queda algún campo sin rellenar, aplica su "Regla de campos sin
rellenar": los campos con default lo usan y lo mencionas al final; los campos sin default seguro me
los preguntas antes de dar el CLAUDE.md por terminado.

Reglas de generación del CLAUDE.md:

1. NO copies el contenido de esos ficheros dentro de CLAUDE.md. En su lugar, impórtalos con la
   sintaxis @ruta/al/fichero.md, cada uno con una línea de una frase explicando cuándo es relevante
   consultarlo.
2. Incluye en el propio CLAUDE.md (sin necesidad de import) solo lo que cumple TODOS estos criterios:
   comandos bash que yo no adivinaría solo, convenciones que difieran de los defaults del lenguaje o
   framework, la estructura de ramas de Git, y cualquier "gotcha" del entorno local de este proyecto
   concreto.
3. NO incluyas: nada que ya se deduzca leyendo el código, documentación de API que ya está en otro
   sitio, prácticas obvias del lenguaje, ni nada que cambie con frecuencia.
4. Para cada línea que escribas, aplica el test: "si quito esto, ¿cometerías un error evitable?". Si
   la respuesta es no, no la incluyas.
5. Estructura el fichero en secciones cortas con encabezados Markdown: Descripción, Comandos, Imports
   de contexto, Estructura de ramas, Notas del entorno.
6. El resultado completo debe caber cómodamente en una pantalla y media — si al terminar supera eso,
   revisa qué puedes mover a un import en vez de dejarlo inline.

Al terminar, muéstrame el CLAUDE.md generado y pregúntame si hay algún comando o convención local que
se te haya escapado antes de darlo por definitivo.
```

## Revisión final

- Verifica que se cargó correctamente con `/context` dentro de Claude Code.
- Revisa manualmente el resultado una vez: es el único fichero que Claude lee siempre, así que merece
  una revisión humana antes de commitearlo.
