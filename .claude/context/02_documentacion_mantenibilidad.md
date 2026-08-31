# Documentación, mantenibilidad y trazabilidad

> Importado desde `CLAUDE.md` con `@.claude/context/02_documentacion_mantenibilidad.md`.
> Objetivo: que cualquier desarrollo pueda ser retomado por un humano que no participó en la
> conversación con la IA, sin depender del asistente para entender "por qué" se hizo algo.

## 1. ADRs (Architecture Decision Records)

- Ubicación: vault de Obsidian, carpeta `@docs/ADR/records/` (ver `@docs/Meta/Workflow.md`).
- Formato obligatorio (Nygard): **Título · Estado · Contexto · Decisión · Consecuencias**.
- **Append-only**: nunca edites un ADR aceptado. Si una decisión cambia, crea un ADR nuevo que
  referencia y marca como "Superseded" al anterior (enlaza con wikilink `[[ADR-00XX]]`).
- Un ADR = una decisión. No mezcles varias decisiones en el mismo documento.
- Crea un ADR cuando la decisión afecte a: elección de tecnología/librería, modelo de datos,
  arquitectura de módulos, estrategia de autenticación/autorización, o cualquier trade-off que un
  futuro mantenedor podría cuestionar razonablemente.
- **No** crees un ADR para decisiones de implementación de bajo nivel (por qué una función maneja un
  error de una forma concreta) — eso se documenta en el propio código o en el commit, no en un ADR.

## 2. Docstrings y comentarios

- Formato único en todo el proyecto: **Google style** (`Args:`, `Returns:`, `Raises:`). No mezclar con
  NumPy style.
- Toda función/clase/módulo público lleva docstring. Con type hints (PEP 484/695) activos, no repitas
  el tipo dentro del docstring: descríbelo solo si aporta matiz que el tipo no capta.
- Comentarios inline solo para explicar el "por qué", nunca el "qué" (el código ya dice el qué).

## 3. Trazabilidad spec → plan → tasks → commit

- Cada commit referencia el identificador de la feature de Spec-Kit, ej.:
  `feat(003-checkout): añade validación de stock antes de confirmar pedido`
- Usa **Conventional Commits** (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`,
  `BREAKING CHANGE:` en el footer cuando aplique). Esto permite generar `CHANGELOG.md` de forma
  automática y mapea a SemVer.
- `/speckit.taskstoissues` conecta cada tarea de `tasks.md` con un Issue de GitHub: no lo omitas en
  features con más de ~5 tareas, es la pieza que permite seguir el estado desde GitHub Projects.

## 4. Changelog

- Formato: [Keep a Changelog](https://keepachangelog.com) 2.0.0 — secciones `Added / Changed /
  Deprecated / Removed / Fixed / Security` bajo cada versión.
- Se actualiza en la **Fase 2 (cierre)** de cada ciclo SDD, nunca a mano en mitad del desarrollo:
  genera las entradas a partir de los Conventional Commits del rango de la feature.

## 5. Cuándo actualizar la documentación (regla de disparo)

| Evento | Acción obligatoria |
|---|---|
| `/speckit.plan` genera `data-model.md` | Sincronizar `erDiagram` Mermaid en la nota de arquitectura del vault |
| Decisión arquitectónica tomada | ADR nuevo, mismo día, antes de continuar con `tasks` |
| `/speckit.converge` reporta "Converged" | Actualizar `CHANGELOG.md` + nota de la feature en el vault |
| Cambio rompe compatibilidad | ADR + `BREAKING CHANGE:` en commit + entrada en Changelog bajo `Changed`/`Removed` |

## 6. Consistencia del proyecto (checklist rápido antes de cerrar cualquier feature)

- [ ] Docstrings Google-style en todo lo público, type hints completos.
- [ ] ADR creado/actualizado si hubo decisión arquitectónica.
- [ ] Commits siguen Conventional Commits y referencian el ID de feature.
- [ ] `CHANGELOG.md` actualizado.
- [ ] Nota de la feature en el vault enlazada con su(s) ADR(s) y su Issue de GitHub.
- [ ] UAT humana confirmada si aplicaba (lo audita la skill `critic-verifications`).
