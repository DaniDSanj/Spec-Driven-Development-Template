# Ciclo SDD — Fase 2 (Cierre)

## 1. `/speckit.converge`

```
/speckit.converge
```

Si no reporta "Converged" sino trabajo pendiente, vuelve a `/speckit.tasks`/`/speckit.implement` para resolverlo antes de continuar.

## 2. Validación UAT pendiente (si aplicó)

```
Repasa las tareas de esta feature que quedaron marcadas como pendientes de UAT humana. Para cada una, recuérdame qué debo probar y en qué entorno. No las marques como cerradas en tasks.md hasta que confirme explícitamente cada una.
```

Espera tu confirmación explícita por cada punto antes de continuar.

## 3. Cierre de documentación

```
Esta feature ha convergido y su UAT (si aplicaba) está confirmada. Usa el subagente docs-updater para:

1. Determinar, según la tabla de disparo de `@.claude/context/02_documentacion_mantenibilidad.md`, qué artefactos de documentación faltan (ADR, entrada de CHANGELOG.md, nota de vault, runbook).
2. Redactar cada uno como borrador, siguiendo el formato de las skills adr-writer y obsidian-sync.
3. Generar las entradas de CHANGELOG.md a partir de los commits Conventional Commits de esta feature, agrupadas en Added/Changed/Deprecated/Removed/Fixed/Security.
4. Presentarme un resumen de qué se creó o actualizó, sin hacer commit todavía.
```

## 4. Revisión y commit

- Revisa a mano los borradores generados (ADR, changelog, notas de vault).
- Confirma que el checklist de consistencia de `@.claude/context/02_documentacion_mantenibilidad.md` (sección 6) está completo.
- Si la feature ha tocado código sensible (autenticación, secretos/`.env`, migraciones, entradas no confiables), usa el subagente `security-reviewer` antes de continuar y resuelve cualquier hallazgo bloqueante.
- Pide al asistente que commitee siguiendo Conventional Commits, referenciando el ID de la feature:

```
Commitea los cambios de esta feature siguiendo Conventional Commits, referenciando el ID de la feature en el mensaje.
```

Referencia de lo que ejecutará el asistente:

```bash
git add .
git commit -m "feat(<id-feature>): <resumen>"
```

- Si trabajaste sobre `feature/<id-speckit>-<slug>` (obligatorio si la feature generó issues, ver `@.claude/context/05_github.md`): pide al asistente que empuje la rama y abra la PR hacia `dev` — no lo dejes para después, es lo que dispara el cierre automático de los issues al mergear (`@.claude/context/05_github.md` permite al asistente abrir PRs de `feature/*` a `dev` cuando se le pide explícitamente, a diferencia de la PR `dev → main`):

```
Empuja la rama `feature/<id-speckit>-<slug>` y abre una PR hacia `dev` que incluya `Closes #N` por cada issue que esta feature resuelve. Confírmame el número de PR resultante.
```

Referencia de lo que ejecutará el asistente:

```bash
git push origin feature/<id-speckit>-<slug>
gh pr create --base dev --head feature/<id-speckit>-<slug> --title "feat(<id-feature>): <resumen>" --body "Closes #N, Closes #M"
```

- Si la feature era trivial y no usó rama de feature (sin issues asociados), pide al asistente que empuje directo a `dev`:

```
Empuja los commits de esta feature directamente a `dev`.
```

Referencia de lo que ejecutará el asistente:

```bash
git push origin dev
```

- Abre tú mismo (el humano) la PR de `dev` a `main` cuando corresponda — el asistente no lo hace de forma autónoma (ver `@.claude/context/05_github.md`).

Con esto la feature queda cerrada y trazada de extremo a extremo: spec → plan → tasks → issues → implementación → UAT → ADR/changelog/vault → commit → PR con `Closes #N` → (el humano mergea) → Issue cerrado automáticamente.
