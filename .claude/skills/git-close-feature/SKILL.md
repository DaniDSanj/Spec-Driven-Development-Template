---
name: git-close-feature
description: >
  Cierra la feature en GitHub: commit, push de la rama y PR hacia dev con un
  Closes #N repetido por cada issue que resuelve. Incluye la frontera dura de
  que el asistente propone la PR feature/* → dev pero nunca abre la PR dev →
  main. Úsalo en el paso 5.6 del ciclo SDD, tras el checklist de consistencia.
disable-model-invocation: true
---

# Cierre de la feature: commit, push y PR hacia `dev`

Esta skill es **plana**: no forkea. Redactar el mensaje de commit y el cuerpo de la PR exige saber
**qué** se ha implementado y **qué issues** cubre — justo lo que un contexto limpio no tiene. Y son
acciones irreversibles hacia fuera (`push`, `gh pr create`): las ejecuta el hilo que ha acompañado la
feature, no un fork sin memoria de ella.

Y es **de invocación manual** (`disable-model-invocation: true`): por ese mismo carácter irreversible,
el asistente no puede lanzarla por su cuenta al ver el código "terminado". La propone —eso sí, de forma
activa, como exige el paso 4.5 del ciclo— y la disparas tú escribiendo `/git-close-feature`.

El **formato** de los mensajes de commit no se repite aquí: está en `git-update-repo` (Conventional
Commits con el ID de feature en el scope).

## Secuencia

```bash
git add .
git commit -m "feat(<id-feature>): <resumen>"
git push origin feature/<id-speckit>-<slug>
gh pr create --base dev --head feature/<id-speckit>-<slug> \
  --title "feat(<id-feature>): <resumen>" \
  --body "Closes #47, Closes #48, Closes #49"
```

Si la feature necesita más de un commit, agrúpalos por unidad lógica (implementación, tests,
documentación) en vez de en un único commit gigante — `docs-changelog` los lee uno a uno.

Con la red local activada (`git config core.hooksPath .githooks`), el `commit` pasa por
`.githooks/pre-commit`, que escanea secretos con `gitleaks` y puede abortarlo, y el `push` por
`.githooks/pre-push`, que corre las comprobaciones del CI. Un bloqueo de `pre-commit` **no** se salta
con `--no-verify`: se saca el secreto del commit y, si ya estuvo publicado en algún sitio, se rota
(procedimiento en `SECURITY.md`).

## `Closes #N`: repetido por issue, nunca una lista

**Formato obligatorio.** GitHub solo interpreta como cierre automático la referencia que sigue
*inmediatamente* a `Closes`/`Fixes`/`Resolves`. Una lista separada por comas cierra solo el primer
issue (a veces los dos primeros, el comportamiento es inconsistente) y el resto queda como mención
sin efecto.

```text
❌ Closes #47, #48, #49, #50
✅ Closes #47, Closes #48, Closes #49, Closes #50
```

Un `Closes #N` por cada issue que la feature cubre (uno por tarea, o agrupado si varias tareas
compartían issue). Es lo único que dispara el Workflow "Pull request merged" → Status `Done` del
GitHub Project; sin ello los issues quedan abiertos pese a que el trabajo esté mergeado.

Los números de issue salen de `/speckit-taskstoissues` (paso 3.2). Si no los tienes a mano:
`gh issue list --search "<id-feature>" --state open`.

## Frontera dura

- **La PR `feature/* → dev` la propone el asistente activamente** al terminar la implementación, sin
  esperar a que se le pida. No la dejes para más tarde: es lo que cierra los issues.
- **La PR `dev → main` la abre siempre el humano.** El asistente no la crea de forma autónoma bajo
  ninguna circunstancia.
- **El merge lo hace siempre el humano**, también en `feature/* → dev`, y solo con el check `quality`
  en verde (paso 5.7, `git-run-actions`).

Al terminar, confirma al humano el número de PR resultante.
