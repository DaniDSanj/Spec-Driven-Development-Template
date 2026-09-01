# Modelo de Datos Canónico

> **Fuente de verdad del esquema del proyecto.** Lo lee y lo actualiza el subagente
> `database-manager` a través de las skills `db-model-protocol` (propone) y `db-model-integration`
> (aplica, solo tras aprobación humana explícita). Las convenciones de diseño —naming, campos de
> auditoría, política de índices— **no viven aquí**: están en la skill `db-model-conventions`.
>
> Lo que sigue es el **ejemplo que trae la plantilla**, para que se vea el formato esperado.
> Sustitúyelo por las entidades reales a medida que se creen, o vacía las secciones "Entidades" y
> "Changelog" si el proyecto aún no tiene ninguna tabla.

> Última actualización: [fecha] — actualizado por spec [NNN-nombre]

## Convenciones activas

Las generales están en la skill `db-model-conventions` y no se repiten aquí. Esta sección es solo para
decisiones de esquema **específicas de este proyecto** que se aparten de ellas o las concreten:

- [ninguna todavía — ej. "las tablas de auditoría histórica viven en el schema `audit`"]

## Entidades

### tabla: `clientes`

| Columna | Tipo | Constraints | Introducida en | Modificada en |
|---|---|---|---|---|
| `id` | SERIAL | PK | 001 | — |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | 001 | — |
| `estado` | VARCHAR(20) | NOT NULL | 001 | 006 (se amplían los valores permitidos de 3 a 5) |
| `segmento_id` | INTEGER | FK → `segmentos.id`, NULL, indexada | 009 | — |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT CURRENT_TIMESTAMP | 001 | — |
| `created_by` | INTEGER | FK → `usuarios.id`, NULL | 001 | — |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT CURRENT_TIMESTAMP, trigger BEFORE UPDATE | 001 | — |
| `updated_by` | INTEGER | FK → `usuarios.id`, NULL | 001 | — |
| `version` | INTEGER | NOT NULL DEFAULT 1, trigger BEFORE UPDATE | 001 | — |

**Índices:** `ux_clientes_email` (UNIQUE sobre `email`) · `ix_clientes_segmento_id` (FK, exigido por la
consulta de segmentación de la spec 009).

**Specs que dependen de esta tabla:** 001, 003, 006, 009

## Changelog

- **[009]** Añadida columna `segmento_id` a `clientes` (FK a `segmentos`, indexada). Afecta a las specs
  003 y 006 → readaptaciones aplicadas y aprobadas.
- **[006]** Ampliado el dominio de `estado` de 3 a 5 valores posibles. Sin impacto en el esquema de
  otras tablas.
