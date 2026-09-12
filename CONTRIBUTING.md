# Contribuir a la plantilla

Este repositorio es una **GitHub Template Repository**. No hay nada que compilar, lintar ni testear: lo
que se mantiene es un conjunto de documentos y scripts que otro repositorio hereda intacto al pulsar
"Use this template".

Si lo que quieres es *usar* la plantilla, no contribuir a ella, el punto de entrada es
[`README.md`](README.md).

## La regla que más se incumple: propagar los renombrados

Rutas, nombres de fichero, nombres de skill y numeración de pasos están **referenciados de forma cruzada**
desde varios documentos a la vez. Renombrar o reordenar algo en un sitio obliga a propagarlo a todos.
Los sitios que casi siempre hay que tocar a la vez:

| Si cambias… | Actualiza también |
|---|---|
| Una skill de `.claude/skills/` | La tabla de enrutado de `.claude/prompts/01_init_project.md`, la sección "Skills" del `README.md` y el paso correspondiente de `.claude/prompts/02_spec_development.md` |
| Un subagente de `.claude/agents/` | La sección "Subagentes" del `README.md` y las skills que lo declaran en `agent:` |
| Un fichero de `.claude/context/` | El `README.md` y `.claude/prompts/01_init_project.md` (son los dos sitios que los enumeran). Los números **no se reasignan** al retirar un fichero |
| La numeración de un paso del ciclo | Las `description` de las skills implicadas (Claude las lee para decidir cuándo autoinvocarlas) y los enlaces internos de `02_spec_development.md` |
| Un placeholder de `00_perfil_proyecto.md` | El bloque `$replacements` de `bootstrap.ps1`, que sustituye literales |
| Una sección numerada del `README.md` | `bootstrap.ps1`, `setup-github.ps1` y la skill `git-update-repo` la citan por número ("la sección 2.5") |
| Un paso del job `quality` de `.github/workflows/ci.yml`, o la versión de `gitleaks` que fija | `SECURITY.md`, la tabla de diagnóstico de `git-run-actions`, la cabecera de `.githooks/pre-push` y las secciones 4 y 5 del `README.md` |
| El modelo de branch protection, o lo que activa `setup-github.ps1` | La skill `git-update-repo`, el checklist de la sección 2.5 del `README.md`, la ayuda de `setup-github.ps1` y la de `bootstrap.ps1`, y `bootstrap_example.md` |
| Un job de `.github/workflows/ci.yml` que sea *required status check* (añadirlo, renombrarlo o quitarlo) | El `$branchContexts` de `setup-github.ps1` (lo referencia por nombre de job), la tabla de branch protection de `git-update-repo`, el checklist de la sección 2.5 del `README.md` y la tabla de diagnóstico de `git-run-actions`. Ojo al orden al añadir uno: el job debe existir ya en la rama base antes de exigirlo, o toda PR queda bloqueada |

Antes de dar un cambio por cerrado, haz una pasada de consistencia sobre todo el repo. Dos comprobaciones
mecánicas que ayudan:

```bash
# Enlaces internos y relativos rotos en todos los .md
# Referencias a /skills y a subagentes que ya no existen
```

(No hay script: se hacen a mano o pidiéndoselo al asistente.)

## Estilo

- **Idioma**: castellano, en todo el repositorio.
- **Commits**: Conventional Commits, la misma convención que la plantilla impone a los proyectos que
  genera (`feat`, `fix`, `refactor`, `docs`, `chore`…). Ver la skill `git-update-repo`.
- **Ramas**: `main` es la rama que copia "Use this template" y debe estar siempre publicable. Cada
  cambio va en su propia rama, con PR a `dev`, y `dev` se integra en `main` con otra PR. Las dos ramas
  están protegidas: no se admite push directo (ver la skill `git-update-repo`).
- **Documentos**: se escriben para alguien que llega sin contexto. Si una regla necesita justificación,
  se justifica en línea; si un fichero solo tiene sentido con otro delante, se enlaza.

## Qué cambios encajan y cuáles no

**Encajan**: corregir inconsistencias entre documentos, mejorar la portabilidad de los hooks, ampliar una
convención existente, añadir una skill que cubra un hueco real del ciclo SDD.

**No encajan por defecto**: cambiar el stack fijo de la plantilla (Claude Code + Spec-Kit, Python,
PostgreSQL/SQL Server, Obsidian, GitHub) o añadir skills "por si acaso". Más skills de las que se usan
solo añaden ruido a la carga inicial del asistente; ese criterio es deliberado y está escrito en el
`README.md`.

## Seguridad

Activa la red local antes de empezar: `git config core.hooksPath .githooks`. El hook `pre-commit`
escanea secretos con `gitleaks` y `pre-push` corre las comprobaciones del CI. Qué protege cada capa
está en [`SECURITY.md`](SECURITY.md).

Los fallos de seguridad no van en un issue público: usa la vía privada que indica
[`SECURITY.md`](SECURITY.md).
