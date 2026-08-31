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

Antes de escribir nada, lee entero `@.claude/context/00_perfil_proyecto.md`, que contiene los datos
concretos de este proyecto. Es el único fichero de contexto que hay: las convenciones de método viven
en las skills de la tabla de enrutado de más abajo, que se cargan solas cuando su dominio es relevante.

Si en `00_perfil_proyecto.md` queda algún campo sin rellenar, aplica su "Regla de campos sin
rellenar": los campos con default lo usan y lo mencionas al final; los campos sin default seguro me
los preguntas antes de dar el CLAUDE.md por terminado.

Reglas de generación del CLAUDE.md:

1. NO copies el contenido del perfil dentro de CLAUDE.md. En su lugar, impórtalo con la sintaxis
   @.claude/context/00_perfil_proyecto.md, con una línea de una frase explicando cuándo es relevante
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
   de contexto, Reglas de conversación, Enrutado a skills, Estructura de ramas, Notas del entorno.
   La sección "Estructura de ramas" se limita a NOMBRAR las ramas (main desplegable, la rama de
   integración que diga el perfil, y feature/<id-speckit>-<slug>) y a remitir a /git-update-repo para
   las reglas. No copies ahí el modelo de branch protection ni el formato de los commits: eso vive en
   la skill, y duplicarlo crea dos fuentes de verdad que se desincronizan.
6. El resultado completo debe caber cómodamente en una pantalla y media — si al terminar supera eso,
   revisa qué puedes mover a un import en vez de dejarlo inline.

Además de los imports, copia inline en el CLAUDE.md estos dos bloques tal cual. No son convenciones de
dominio (esas viven en skills, que se cargan solas cuando hacen falta): el primero gobierna la
conversación contigo, que ningún subagente puede tener, y el segundo es lo que me permite delegar sin
llevar las convenciones cargadas de antemano.

## Reglas de conversación

- No rellenes huecos de alcance en silencio: lo que la petición no diga y sea necesario, se pregunta.
- Una pregunta cada vez, esperando respuesta antes de la siguiente.
- Ninguna tarea con UAT humana pendiente se marca como cerrada sin mi confirmación explícita.

## Enrutado a skills

| Cuando toque… | Invoca |
|---|---|
| Tomar requisitos antes de escribir una spec | `/critic-requirements` |
| Revisar spec/plan/tasks antes de implementar | `/critic-plan` |
| Auditar el criterio de cierre antes de converger | `/critic-verifications` |
| Escribir o modificar código Python | `/dev-python-coding` |
| Escribir o modificar tests | `/dev-python-testing` |
| Diseñar, revisar o modificar cualquier tabla o esquema | `/db-model-conventions` |
| Bocetar las tablas de una feature antes del plan | `/db-model-ideas` |
| Reconciliar un esquema contra el modelo de datos canónico | `/db-model-protocol` |
| Generar una migración, ya con el esquema aprobado | `/db-model-integration` |
| Escribir un ADR de una decisión arquitectónica | `/docs-adr-writer` |
| Sincronizar una nota del vault de Obsidian | `/docs-vault-sync` |
| Generar o actualizar el `CHANGELOG.md` | `/docs-changelog` |
| Documentar un procedimiento operativo nuevo | `/docs-runbook` |
| Auditar la consistencia antes de cerrar una feature | `/docs-consistency-check` |
| Crear la rama de una feature, o revisar la protección de ramas | `/git-update-repo` |
| Commitear, pushear y abrir la PR de cierre hacia `dev` | `/git-close-feature` |
| Comprobar o diagnosticar el CI de una PR | `/git-run-actions` |

Al terminar, muéstrame el CLAUDE.md generado y pregúntame si hay algún comando o convención local que
se te haya escapado antes de darlo por definitivo.
```

> La migración de `.claude/context/*.md` a skills de dominio está completa: las cinco familias
> (`critic-*`, `dev-*`, `db-model-*`, `docs-*`, `git-*`) son skills de carga bajo demanda, y el único
> fichero de contexto que queda —y por tanto el único import `@` del `CLAUDE.md`— es el perfil del
> proyecto, que contiene valores y no método.

## Revisión final

- Verifica que se cargó correctamente con `/context` dentro de Claude Code.
- Revisa manualmente el resultado una vez: es el único fichero que Claude lee siempre, así que merece
  una revisión humana antes de commitearlo.
