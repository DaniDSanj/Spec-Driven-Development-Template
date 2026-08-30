# Fichero de Generación de `CLAUDE.md`

Una vez, al arrancar un proyecto nuevo (Fase 0), **después** de haber copiado y rellenado los ficheros de `context/` (01 a 04) y `github/01_github_workflow.md` con los datos reales del proyecto. El prompt le pide a Claude que lea esos ficheros ya rellenos y genere un `CLAUDE.md` corto que los referencie, en vez de repetir su contenido.

## Prompt

Rellena estos datos:

- `[NOMBRE_PROYECTO]`
- `[DESCRIPCIÓN_UNA_LÍNEA]`
- `[COMANDOS_NO_OBVIOS]` (ej. cómo levantar la BD local, cómo correr un seed de datos)
- Confirma que `context/01..04` y `github/01_github_workflow.md` ya están copiados dentro de `.claude/context/` (o la ruta que uses) y rellenos.

```
Vas a generar el fichero CLAUDE.md de la raíz de este proyecto.

Contexto del proyecto:
- Nombre: [NOMBRE_PROYECTO]
- Descripción en una línea: [DESCRIPCIÓN_UNA_LÍNEA]
- Comandos no evidentes que necesitarás repetidamente: [COMANDOS_NO_OBVIOS]

Antes de escribir nada, lee estos ficheros completos:
- `@.claude/context/01_estilo_comportamiento.md`
- `@.claude/context/02_documentacion_mantenibilidad.md`
- `@.claude/context/03_python.md`
- `@.claude/context/04_base_datos.md`
- `@.claude/context/05_github.md`

Reglas de generación del CLAUDE.md:

1. NO copies el contenido de esos ficheros dentro de CLAUDE.md. En su lugar, impórtalos con la sintaxis @ruta/al/fichero.md, cada uno con una línea de una frase explicando cuándo es relevante consultarlo.
2. Incluye en el propio CLAUDE.md (sin necesidad de import) solo lo que cumple TODOS estos criterios: comandos bash que yo no adivinaría solos, convenciones que difieran de los defaults del lenguaje/ framework, la estructura de ramas de Git (rama dev, ver github workflow), y cualquier "gotcha" del entorno local de este proyecto concreto.
3. NO incluyas: nada que ya se deduzca leyendo el código, documentación de API que ya está en otro sitio, prácticas obvias del lenguaje, ni nada que cambie con frecuencia.
4. Para cada línea que escribas, aplica el test: "si quito esto, ¿cometerías un error evitable?". Si la respuesta es no, no la incluyas.
5. Estructura el fichero en secciones cortas con encabezados Markdown: Descripción, Comandos, Imports de contexto, Estructura de ramas, Notas del entorno.
6. El resultado completo debe caber cómodamente en una pantalla y media — si al terminar supera eso, revisa qué puedes mover a un import en vez de dejarlo inline.

Al terminar, muéstrame el CLAUDE.md generado y pregúntame si hay algún comando o convención local que se te haya escapado antes de darlo por definitivo.
```

## Revisión Final

- Verifica que se cargó correctamente con `/context` dentro de Claude Code.
- Revisa manualmente el resultado una vez: es el único fichero que Claude lee siempre, así que merece
  una revisión humana antes de commitearlo.
