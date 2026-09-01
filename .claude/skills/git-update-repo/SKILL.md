---
name: git-update-repo
description: >
  Convenciones de Git y GitHub de este proyecto: modelo de ramas, la regla de
  que toda feature necesita su propia rama sin excepción, el modelo de branch
  protection de dev y main, y el formato de los mensajes de commit
  (Conventional Commits con el ID de feature). Úsalo en el paso 3.3 del ciclo
  SDD, al crear la rama de la feature, y de nuevo en el 5.6 al redactar los
  mensajes de commit.
---

# Ramas y mensajes de commit

Esta skill es **plana**: no forkea. Lo que contiene son convenciones que el hilo principal necesita
tener puestas mientras trabaja — quien crea la rama y redacta los commits es él, con el contexto de
la feature delante. Los valores concretos (nombre de la rama de integración, visibilidad del repo)
están en `@.claude/context/00_perfil_proyecto.md`, bloque **GitHub**.

## Modelo de ramas

| Rama | Rol |
|---|---|
| `main` | Siempre desplegable. Nunca se desarrolla sobre ella. |
| `dev` | Rama de integración y rama por defecto de los PRs (valor en el perfil). |
| `feature/<id-speckit>-<slug>` | Una por feature. Se mergea a `dev` vía PR y se borra después. |

El `<id-speckit>` es el identificador que genera `/speckit-specify` (`003`, `004`…) y el `<slug>` la
versión corta del nombre de la feature: `feature/003-checkout-stock`.

```bash
git checkout -b feature/<id-speckit>-<slug> dev
```

## La rama de feature es obligatoria, sin excepción por trivialidad

No existe la opción de commitear directo sobre `dev`, ni para un cambio de una línea. Dos razones
independientes, cada una suficiente por sí sola:

1. **GitHub lo rechaza.** `dev` tiene `required_status_checks` (`quality` en verde) con
   `enforce_admins: true`, así que el push directo falla incluso siendo owner del repo: el commit
   recién creado nunca tiene todavía un check en verde, porque el CI solo corre después de que el
   commit exista en GitHub.
2. **Sin PR no se cierran los issues.** El cierre automático en GitHub Projects depende del evento
   "Pull request merged" con `Closes #N` en la descripción de la PR. Sin rama no hay PR, y sin PR los
   issues que generó `/speckit-taskstoissues` quedan abiertos indefinidamente aunque el trabajo esté
   hecho y mergeado.

## Branch protection

Modelo objetivo, idéntico en `dev` y en `main`:

| Ajuste | Valor | Por qué |
|---|---|---|
| `required_status_checks.contexts` | `["quality"]` | El único job de `.github/workflows/ci.yml` |
| `required_status_checks.strict` | `true` | La rama debe estar actualizada con la base antes de mergear |
| `enforce_admins` | `true` | Nadie, ni el owner, se lo salta |
| `required_pull_request_reviews.required_approving_review_count` | `0` | PR obligatoria, pero sin aprobación de terceros: en un repo de una sola persona nadie puede aprobar la PR y `main` quedaría bloqueado. Súbelo a `1` en cuanto el proyecto tenga un segundo revisor. |

`required_approving_review_count` **no sustituye** a `required_status_checks`: son comprobaciones
independientes, y sin la segunda una PR con el CI en rojo se puede mergear igual.

Leer y escribir la configuración:

```bash
gh api repos/<owner>/<repo>/branches/<rama>/protection                       # leer
gh api --method PUT repos/<owner>/<repo>/branches/<rama>/protection --input -  # escribir
```

**`PUT` sobrescribe el objeto entero.** Incluye siempre todos los campos que ya existían, no solo el
que cambias, o se pierden. Lee primero con `GET`, modifica, y envía el objeto completo.

`bootstrap.ps1 -SetupGitHub` aplica este modelo a las dos ramas en la puesta en marcha (best-effort:
branch protection no suele estar disponible en repos privados sin GitHub Pro/Team). Si falló ahí, el
checklist de puesta en marcha del `README.md` lo deja como paso manual.

## Mensajes de commit

**Conventional Commits**, con el identificador de la feature de Spec-Kit en el scope:

```text
feat(003-checkout): añade validación de stock antes de confirmar pedido
```

| Prefijo | Cuándo |
|---|---|
| `feat` | Funcionalidad nueva visible para el usuario |
| `fix` | Corrección de un comportamiento roto |
| `refactor` | Cambio interno sin efecto observable |
| `docs` | Documentación (vault, ADR, README, changelog) |
| `test` | Tests, sin tocar producción |
| `chore` | Dependencias, configuración, andamiaje |

Un cambio incompatible añade `BREAKING CHANGE: <qué rompe>` en el footer del commit, no en el
asunto. Esto mapea a SemVer (`feat` → minor, `fix` → patch, `BREAKING CHANGE` → major).

No es cosmético: los mensajes de commit del rango de la feature son **la entrada** que consume
`docs-changelog` en el paso 5.4 para generar `CHANGELOG.md`. Un commit sin prefijo se convierte en
una entrada que hay que escribir a mano, o en una que falta.

## Trazabilidad de extremo a extremo

`/speckit-taskstoissues` conecta cada tarea de `tasks.md` con un Issue de GitHub. No lo omitas en
features de más de ~5 tareas: es la pieza que permite seguir el estado desde GitHub Projects y la que
da los números de issue que `git-close-feature` necesita para la PR.

Con esto la cadena **spec → plan → tasks → issue → commit → PR** queda navegable sin depender de la
conversación con el asistente.

**Siguiente en el ciclo**: al cerrar la feature, el commit, el push y la PR los cubre
`git-close-feature` (paso 5.6).
