# Configuración del vault de Obsidian

> Esta nota (`docs/Meta/Setup.md`) documenta cómo está montado el vault de este proyecto, para que un
> humano nuevo pueda replicarlo sin preguntar. El "cómo documentamos aquí" está en
> [`Workflow.md`](Workflow.md).

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

No hace falta un plugin de tablero Kanban: el seguimiento de tareas vive en GitHub Projects, alimentado
por los Issues que genera `/speckit-taskstoissues`.

## Instalación

1. `Settings → Community plugins → Browse` → busca cada plugin de la tabla → `Install` → `Enable`.
2. Configura **obsidian-git**:
   - `Settings → obsidian-git → Vault backup interval`: **30** (minutos). Súbelo o bájalo si tu ritmo
     de escritura en el vault es muy distinto.
   - Activa `Commit message` con plantilla, ej. `vault: sync {{date}}`.
3. Configura **Templater**:
   - `Settings → Templater → Template folder location` → `Meta/Templates/`.
   - **No crees nada ahí**: `adr.md`, `spec.md` y `runbook.md` ya vienen en esa carpeta desde que el
     repo se creó con la plantilla. Su contenido está documentado en
     [`Workflow.md`](Workflow.md#plantillas-templater).
4. Configura **Dataview**:
   - `Settings → Dataview → Enable JavaScript Queries` (opcional, solo si vas a usar `dataviewjs`).

## El vault vive dentro del repo del código

Esta plantilla monta el vault como `docs/` **dentro del mismo repositorio que el código**: un único
`git push` sincroniza código y documentación, y cualquiera que clone el proyecto hereda la
documentación completa sin permisos adicionales. Es lo que asumen las skills `docs-*` al escribir
rutas como `docs/ADR/records/`.

La alternativa —un repositorio separado solo para el vault— tiene sentido si el vault se comparte
entre varios proyectos o si necesitas controlar el acceso a la documentación de forma independiente
del código. Si te vas por ahí, es un cambio de estructura que afecta a todas las skills `docs-*`:
documéntalo en un ADR y ajusta las rutas. En ese caso el remoto se añade así:

```bash
cd /ruta/al/vault
git init
git remote add origin git@github.com:<usuario>/<proyecto>-docs.git
```
