---
name: git-run-actions
description: >
  Supervisa el CI de una PR: lee el estado del job quality de ci.yml,
  diagnostica el paso que falla y propone la corrección, sin tocar nunca el
  workflow. Incluye el coste de minutos de GitHub Actions según la visibilidad
  del repo y la red local pre-push. Úsalo en el paso 5.7 del ciclo SDD, tras
  abrir la PR hacia dev.
---

# Supervisar el CI de la PR

Esta skill es **plana**: no forkea. Diagnosticar un check en rojo y proponer la corrección exige ver
el código que se acaba de escribir; y la corrección la aplica el mismo hilo, que ya tiene el contexto
de la feature.

La PR no se puede mergear hasta que el job `quality` de `.github/workflows/ci.yml` esté en verde
(`required_status_checks`; en `dev`, además, con `strict: true`: la rama debe estar al día con `dev`.
Ver `git-update-repo`).

## Leer el estado

```bash
gh pr checks <N>                 # estado de todos los checks de la PR
gh run view --log-failed         # log solo de los pasos que han fallado
gh run view <run-id> --log       # log completo, si hace falta el contexto previo
```

## Diagnóstico por paso

El job `quality` corre seis comprobaciones en este orden: el escaneo de secretos (siempre) y las
cinco de Python (solo tras el gate). Identifica cuál falló antes de proponer nada — el log de un paso
posterior no aparece si uno anterior cortó.

| Paso | Qué falla | Corrección típica |
|---|---|---|
| `Secret scan (gitleaks)` | `gitleaks` ha encontrado un posible secreto en algún commit del historial (el log lo muestra redactado, con fichero, línea y commit) | **No es un fallo de CI, es un incidente**: detente y avisa al humano. El secreto ya está en GitHub, así que hay que rotarlo; sacarlo del último commit no basta. Si es un falso positivo, `gitleaks:allow` en la línea o una entrada en `.gitleaks.toml`, siempre con aprobación humana |
| `uv run ruff check src/` | Lint (imports sin usar, complejidad, reglas activas), incluidas las de seguridad `S*` | `uv run ruff check --fix src/` y revisar lo que no arregla solo. Un `S*` se corrige cambiando el código (ver `dev-python-coding`), no con `noqa` |
| `uv run ruff format --check src/` | Formato | `uv run ruff format src/` |
| `uv run ty check` | Tipado estático | Corregir la anotación; convenciones en `dev-python-coding` |
| `uv run pytest -q` | Tests | Es un fallo real de la feature: vuelve al paso 4.1, no relajes el test |
| `Dependency audit (pip-audit)` | Una dependencia de ejecución de `uv.lock` tiene una CVE conocida (el log da paquete, versión, ID y versión corregida). También falla si `uv.lock` no existe o no está al día con `pyproject.toml` (`--frozen`) | Actualizar a la versión corregida (`uv lock --upgrade-package <paquete>`) y volver a correr los tests. Si no hay versión corregida, es decisión del humano: excepción documentada (`--ignore-vuln <ID>` en el paso, con ADR) o sustituir la dependencia. Puede fallar en una PR que no tocó dependencias si la CVE es nueva: no es culpa de la feature, pero hay que resolverlo igual |

Reproduce siempre en local antes de pushear una corrección — cada intento a ciegas consume minutos de
Actions y un ciclo de espera.

## Límite duro: no se edita `ci.yml`

`.github/workflows/ci.yml` es **estático a propósito** y está gateado por la existencia de
`pyproject.toml` **y** de `src/` (el step `Check project is initialized`, que evita que el job falle
cuando el workflow ya está en el repo pero todavía no se ha ejecutado `uv init` ni existe el paquete).
Si el check `quality` sale verde habiendo ejecutado solo el escaneo de secretos (que va antes del
gate y corre siempre), es este gate: comprueba que el proyecto tiene ambas cosas antes de dar por
buena la ausencia de fallos. No lo regeneres ni lo parchees para
que un check pase: eso rompe la garantía de que el mismo workflow vale desde el primer commit del
proyecto, y convierte un fallo real en uno silenciado.

Si el workflow necesita cambiar de verdad (una variable de entorno nueva, un servicio de BD para los
tests de integración), eso es una decisión de proyecto: proponla al humano y documéntala, no la
apliques de paso mientras arreglas un check.

Añadir jobs nuevos (`release-please` o `git-cliff` para changelog automático desde Conventional
Commits) es legítimo cuando el proyecto lo justifica, y sigue siendo una decisión del humano.

La única edición recurrente de `ci.yml` que no es una decisión nueva es la que propone Dependabot
(`.github/dependabot.yml`): una PR mensual hacia `dev` que actualiza los SHA con los que se fijan las
acciones. Se revisa y se mergea como cualquier otra PR, tras pasar `quality`. Si el salto es de
versión mayor, lee las notas de la acción antes de aprobar. Al fijar una acción nueva, usa también su
SHA completo con la versión en un comentario, nunca un tag.

## Red local: `pre-push`

El hook local `.githooks/pre-push` corre las mismas comprobaciones de Python (`ruff`/`ty`/`pytest`/`pip-audit`) antes de
dejar pushear, así que el problema se detiene un paso antes, en la máquina y sin gastar minutos:

```bash
git config core.hooksPath .githooks
```

El mismo `core.hooksPath` activa también `.githooks/pre-commit`, que escanea secretos con `gitleaks`
antes de cada commit. Si lo bloquea, no se salta con `--no-verify`: se saca el secreto del commit.

## Coste de minutos de Actions

Lee **GitHub → Visibilidad del repositorio** en `@.claude/context/00_perfil_proyecto.md`.

| | Repo público | Repo privado |
|---|---|---|
| Minutos de Actions | Ilimitados (fair-use) | 2.000 min/mes (Linux-equivalent) en el plan Free |
| Multiplicador por OS | Linux 1x · Windows 2x · macOS 10x | ídem |

Si el repo es privado y el consumo se acerca a los 2.000 min/mes, tres palancas por orden de impacto:
reducir la matriz de sistemas operativos a solo Linux, activar caché de dependencias
(`actions/cache` o el caché nativo de `uv`), y agrupar jobs redundantes en uno.
