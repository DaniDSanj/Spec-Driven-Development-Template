# Guía de Intalación de Skills, Subagentes y Hooks

## ¿Qué instalar?

Regla de decisión rápida para elegir el mecanismo correcto:

| Si necesitas... | Usa |
|---|---|
| Que algo se cumpla **siempre**, de forma determinista (formatear, testear, bloquear una escritura) | **Hook** |
| Conocimiento de dominio reutilizable que Claude carga **solo cuando hace falta** (una convención, un checklist) | **Skill** |
| Delegar una tarea a un contexto **limpio y aislado** (revisión adversarial, investigación) | **Subagente** |
| Una regla **siempre activa** y corta que guía el comportamiento general | `CLAUDE.md` / `context/*.md` |

## Documentación

### Skills 

Todas las skills son solo **recomendadaciones** para este stack en concreto y deberán almacenarse en `.claude/skills/`:

#### `db-schema-design`
Encapsula las convenciones de [**04_base_datos.md**](./files/context/04_base_datos.md) (naming, campos de auditoría, política de índices) para que el asistente las aplique al diseñar cualquier tabla nueva sin tener que repetírselas cada vez. Válida tanto para PostgreSQL como para SQL Server.

#### `adr-writer`
Sabe el formato exacto de ADR, dónde vive (`docs/ADR/records/`), y aplica la regla append-only + supersede automáticamente.

#### `obsidian-sync`
Sabe qué nota del vault actualizar tras cada evento de la tabla de disparo de [**02_documentacion_mantenibilidad.md**](./files/context/02_documentacion_mantenibilidad.md), y en qué formato (Dataview/wikilinks).

Puedes añadir más según crezca el proyecto (ej. `fastapi-endpoint-scaffold`, `pytest-fixtures`), pero empieza solo con estas tres — más skills de las que realmente usas solo añaden ruido a la carga inicial.

### Subagentes

Todas los subagentes son solo **recomendadaciones** para este stack en concreto y deberán almacenarse en `.claude/agents/`:

#### `spec-critic`
Revisor adversarial de spec/plan (usado en [**01_estilo_comportamiento.md**](./files/context/01_estilo_comportamiento.md), sección 1). Contexto limpio: solo ve `spec.md`/`plan.md`/`tasks.md`, no el histórico de la conversación de planificación.

#### `db-designer`
Propone y valida esquemas SQL contra las convenciones de [**04_base_datos.md**](./files/context/04_base_datos.md); se invoca durante `/speckit.plan` o `/speckit.implement` cuando la feature toca el modelo de datos.

#### `docs-updater`
Tras `/speckit.converge`, redacta el ADR/Changelog/nota de vault correspondientes según la tabla de disparo, y los deja listos para revisión humana antes de commitear.

#### `security-reviewer`
Revisa cambios que tocan superficies sensibles (autenticación, gestión de secretos/`.env`, migraciones, entradas no confiables) antes de `/speckit.converge`, buscando vulnerabilidades tipo OWASP Top 10. Complementa al hook `pre_edit_guard_sensitive.sh` (que bloquea la escritura) revisando la lógica una vez escrita.

### Hooks

Todas los hooks son solo **recomendadaciones** para este stack en concreto y deberán almacenarse en `.claude/settings.json`:

1. **PostToolUse en `Edit`/`Write` sobre `*.py`** → `ruff format` + `ruff check --fix` + `ty check` automáticos.
2. **Stop** → `uv run pytest -q`; si falla, Claude ve el resultado antes de dar la tarea por cerrada.
3. **PreToolUse en `Write`/`Edit` sobre `migrations/**` o `.env*`** → bloquea la escritura (no pide confirmación: el hook sale con código 2 y corta la acción), dado que son ficheros de alto riesgo (datos de producción / secretos). El humano decide manualmente si aplica el cambio por otra vía.

Los ficheros de ejemplo listos para copiar están en `./files/native/skills/`, `./files/native/agents/` y `./files/native/hooks/` de esta misma plantilla.

## ¿Cómo instalarlos?

### A nivel de proyecto
Todo quedará compartido dentro del proyecto, es decir, vía Git. Recomendado para todo lo específico de este stack.

```bash
cp -r ruta/a/plantilla/files/native/skills/*      .claude/skills/
cp -r ruta/a/plantilla/files/native/agents/*.md   .claude/agents/
cp ruta/a/plantilla/files/native/hooks/settings.json  .claude/settings.json
cp ruta/a/plantilla/files/native/hooks/*.sh       .claude/hooks/
chmod +x .claude/hooks/*.sh
git add .claude/ && git commit -m "chore: harness Claude Code (skills/agents/hooks)"
```

Al vivir dentro del repo, cualquier humano que clone el proyecto (o tú mismo en otra máquina) hereda automáticamente el mismo comportamiento del asistente — esto es parte de la mantenibilidad del punto 7 de la guía original.

### A nivel global
Aplica a todos tus proyectos con este stack, ej. convenciones Python/PostgreSQL que repites siempre.

```bash
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r ruta/a/plantilla/files/native/skills/db-schema-design ~/.claude/skills/
cp ruta/a/plantilla/files/native/agents/spec-critic.md ~/.claude/agents/
```

- Precedencia: si un skill/subagente con el mismo nombre existe tanto en `.claude/` (proyecto) como en `~/.claude/` (global), **gana el del proyecto**. Usa esto para tener una versión global genérica y sobreescribirla por proyecto solo cuando haga falta.
- Los hooks (`settings.json`) **no** se heredan por fusión automática entre global y proyecto en todas las versiones de Claude Code. Verifica con `/doctor` que los hooks esperados están activos tras clonar un proyecto nuevo.
