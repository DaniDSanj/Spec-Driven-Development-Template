---
name: db-model-conventions
description: >
  Convenciones de diseño de esquema de base de datos de este proyecto:
  naming, campos de auditoría obligatorios, política de índices, regla de
  migraciones y cuándo introducir NoSQL. Válidas tanto para PostgreSQL como
  para SQL Server. Úsalo antes de diseñar, revisar o modificar cualquier
  tabla o modelo de datos — en el paso 2.1 del ciclo SDD junto a
  /speckit-plan, y en cualquier trabajo de esquema fuera del ciclo.
---

# Convenciones de esquema de base de datos

Los **valores** concretos de este proyecto (motor y versión, convención de PK, uso de schemas,
herramienta de migraciones) están en `.claude/context/00_perfil_proyecto.md`. Aplica su **regla de
campos sin rellenar**: si el campo tiene default declarado y sigue vacío, úsalo y menciónalo en tu
respuesta; si no tiene default seguro, pregunta antes de generar nada que dependa de él.

Este fichero contiene solo convenciones, comunes a PostgreSQL y SQL Server salvo donde se señala la
diferencia explícitamente. Las skills hermanas del dominio:

| Skill | Cuándo |
|---|---|
| `db-model-ideas` | Bocetar tablas de una feature antes del plan |
| `db-model-protocol` | Reconciliar el esquema propuesto contra el modelo canónico y analizar impacto |
| `db-model-integration` | Generar la migración y actualizar el modelo canónico, tras aprobación |

## Motor

Cuál usa este proyecto: ver **Base de datos → Motor** en el perfil. PostgreSQL es el motor por defecto;
SQL Server solo con justificación.

## Convenciones de nombres

- Tablas: plural, `snake_case` → `users`, `order_items`.
- Columnas: singular, `snake_case` → `first_name`, `created_at`.
- Clave primaria: ver **Base de datos → Convención de clave primaria** en el perfil (`id` por defecto).
- Clave foránea: `[tabla_referenciada_singular]_id` → `user_id`, `order_id`. Siempre indexada.
- Schemas (PostgreSQL) para namespacing por dominio: ver **Base de datos → Uso de schemas** en el
  perfil (por defecto no se usan).

## Campos de auditoría (obligatorios en toda tabla transaccional)

```sql
-- PostgreSQL
CREATE TABLE [nombre_tabla] (
  id SERIAL PRIMARY KEY,                 -- o BIGINT/UUID si se espera alta cardinalidad/distribución
  -- columnas de negocio --
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by INTEGER REFERENCES users(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_by INTEGER REFERENCES users(id),
  version INTEGER NOT NULL DEFAULT 1
);

CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  NEW.version = OLD.version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON [nombre_tabla]
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

```sql
-- SQL Server (equivalente)
CREATE TABLE [nombre_tabla] (
  id INT IDENTITY(1,1) PRIMARY KEY,
  -- columnas de negocio --
  created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  created_by INT NULL FOREIGN KEY REFERENCES users(id),
  updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  updated_by INT NULL FOREIGN KEY REFERENCES users(id),
  version INT NOT NULL DEFAULT 1
);
-- version/updated_at vía trigger AFTER UPDATE, equivalente al de PostgreSQL.
```

Usa siempre `TIMESTAMPTZ` en PostgreSQL (no `TIMESTAMP` sin zona horaria). Documenta cada tabla y
columna no obvia con `COMMENT ON TABLE ...` / `COMMENT ON COLUMN ...` (o `sp_addextendedproperty` en
SQL Server).

## Índices

- Toda FK lleva índice.
- Tipo por defecto: **B-Tree**. Casos especiales:
  - **GIN** → columnas `JSONB`, arrays, full-text search.
  - **BRIN** → tablas muy grandes con datos secuenciales (logs, series temporales) — mucho más
    ligero en espacio que B-Tree para este patrón.
  - **Parcial** (`WHERE status = 'active'`) → cuando las consultas filtran casi siempre por un
    subconjunto pequeño y estable.
- No indexar columnas de baja cardinalidad (ej. un booleano) salvo como parte de un índice compuesto.
- Antes de añadir un índice, justifícalo contra una query real esperada — el sobre-indexado penaliza
  escritura y almacenamiento. Si no puedes nombrar la consulta que lo necesita, no lo propongas.
- SQL Server: define explícitamente la clave clustered (debe ser *narrow, unique, static y
  ever-increasing* — normalmente la PK identity). Índices nonclustered en columnas de
  `WHERE`/`JOIN`/`ORDER BY`/`GROUP BY`.

## Migraciones

- Herramienta: ver **Base de datos → Herramienta de migraciones** en el perfil. Es un campo **sin
  default seguro**: si sigue sin rellenar, pregunta al usuario qué herramienta usa el proyecto antes de
  generar o proponer una migración.
- Toda migración se genera, se revisa a mano y se versiona en Git; nunca se aplican cambios de esquema
  directamente en la BD sin migración, ni con un `ALTER TABLE` suelto.
- Toda migración que afecte a datos ya existentes en producción requiere UAT humana explícita antes de
  aplicarse (la skill `critic-verifications` audita que esté señalada como tal).
- El fichero de migración **no lo escribe el asistente**: `.claude/hooks/pre_edit_guard_sensitive.sh`
  bloquea toda escritura sobre `migrations/**`. La skill `db-model-integration` entrega el comando
  exacto y el DDL revisado, y lo ejecuta el humano.

---

## Anexo — Cuándo introducir NoSQL como complemento

Regla general: PostgreSQL/SQL Server siguen siendo el motor por defecto. Añade un motor NoSQL solo
para un caso de uso puntual y bien delimitado, nunca como sustituto general:

| Necesidad | Opción recomendada | Nota |
|---|---|---|
| Caché / sesiones / rate limiting | **Redis** | El complemento de menor riesgo y mayor valor; empieza por aquí si necesitas NoSQL |
| Datos semi-estructurados de esquema variable | Primero `JSONB` en PostgreSQL; solo pasa a document store (MongoDB) si el volumen/escala lo exige |
| Series temporales / IoT / logs de alto volumen | Primero `TimescaleDB` (extensión de PostgreSQL) — conserva SQL, joins e índices; NoSQL solo si la escala rompe esto |
| Escalado horizontal masivo / sharding | Evaluar según carga real medida, no por anticipación |

No introduzcas un motor NoSQL nuevo sin antes comprobar si `JSONB` o una extensión de PostgreSQL
resuelve el problema — reduce coste operativo y curva de aprendizaje.
