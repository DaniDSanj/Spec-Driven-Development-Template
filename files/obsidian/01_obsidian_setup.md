# Configuración del vault de Obsidian

> Guarda esta nota como `@docs/Meta/Setup.md` dentro del propio vault. Documenta cómo está montado el
> vault de este proyecto, para que un humano nuevo pueda replicarlo sin preguntarte a ti.

## Plugins community necesarios (todos gratuitos)

| Plugin | Función | Imprescindible |
|---|---|---|
| **Dataview** | Trata el vault como base de datos; queries tipo SQL sobre frontmatter YAML | Sí |
| **Templater** | Motor de plantillas con comandos dinámicos — genera notas con estructura correcta | Sí |
| **obsidian-git** | Commit/pull/push del vault contra GitHub, auto-commit programado | Sí |
| **Tasks** | Gestión de tareas con checkboxes enlazables a `tasks.md` de Spec-Kit | Recomendado |
| **Excalidraw** | Diagramas a mano alzada, sketches de arquitectura | Opcional |
| **DBML Visualizer** | ERDs interactivos a partir de DBML | Opcional (Mermaid nativo cubre el caso básico) |

Mermaid (diagramas de flujo, secuencia, Gantt, `erDiagram`) viene integrado en el núcleo de Obsidian:
no requiere plugin.

## Instalación

1. `Settings → Community plugins → Browse` → busca cada plugin de la tabla → `Install` → `Enable`.
2. Configura **obsidian-git**:
   - `Settings → obsidian-git → Vault backup interval`: `[ej. 30 minutos]`.
   - Activa `Commit message` con plantilla, ej. `vault: sync {{date}}`.
   - Si el vault vive en un repo separado del código, añade el remoto:
     ```bash
     cd /ruta/al/vault
     git init
     git remote add origin git@github.com:[usuario]/[proyecto]-docs.git
     ```
3. Configura **Templater**:
   - `Settings → Templater → Template folder location` → `Meta/Templates/`.
   - Crea ahí las plantillas de ADR, spec, runbook (ver `02_obsidian_workflow.md` para su contenido).
4. Configura **Dataview**:
   - `Settings → Dataview → Enable JavaScript Queries` (opcional, solo si vas a usar `dataviewjs`).

## Decisión: ¿vault dentro del repo del código o repo separado?

- **Dentro del mismo repo** (`docs/` en la raíz): más simple, un único `git push` sincroniza código y
  documentación, ideal para proyecto en solitario. **Recomendado por defecto.**
- **Repo separado**: útil solo si el vault se comparte entre varios proyectos o si quieres controlar
  permisos de acceso a la documentación de forma independiente del código.

Este proyecto usa: `[dentro del repo / repo separado — indicar cuál]`.
