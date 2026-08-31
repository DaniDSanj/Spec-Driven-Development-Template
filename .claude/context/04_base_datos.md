# Diseño de base de datos

> Importado desde `CLAUDE.md` con `@.claude/context/04_base_datos.md`.
> Rellena `[ ]` con los valores reales del proyecto. Si un proyecto usa SQL Server en vez de
> PostgreSQL, marca la casilla correspondiente: la mayoría de reglas son comunes, las diferencias
> están señaladas explícitamente.
>
> **Si algún campo de este fichero sigue sin rellenar** al usarlo en un proyecto: los campos con
> default declarado (motor → PostgreSQL, PK → `id`, schemas → sin usar) se aplican tal cual y se
> mencionan en la respuesta; los campos sin default seguro porque dependen del stack del proyecto
> (p. ej. la herramienta de migraciones) deben preguntarse al usuario antes de generar o proponer
> nada relacionado — nunca asumirlos en silencio.

## Motor

- [ ] PostgreSQL `[versión]` — **motor por defecto**, úsalo salvo que el punto siguiente aplique.
- [ ] SQL Server `[versión]` — usar cuando `[justificar: integración con stack Microsoft existente,
      requisito del cliente, etc.]`.

## Convenciones de nombres

- Tablas: plural, `snake_case` → `users`, `order_items`.
- Columnas: singular, `snake_case` → `first_name`, `created_at`.
- Clave primaria:
  - [ ] `id` — **por defecto**, úsalo salvo que el punto siguiente aplique.
  - [ ] `[tabla]_id` — usar cuando `[justificar: explicitud en joins con varias FK a la misma
        tabla, convención ya existente en el proyecto, etc.]`.
- Clave foránea: `[tabla_referenciada_singular]_id` → `user_id`, `order_id`. Siempre indexada.
- [ ] Usar schemas (PostgreSQL) para namespacing por dominio — **por defecto: no** (todo en el
      schema por defecto, p. ej. `public`). Si se marca, ejemplo: `[ej. auth.users,
      billing.invoices]`.

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
columna no obvia con `COMMENT ON TABLE ...` / `COMMENT ON COLUMN ...`.

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
  escritura y almacenamiento.
- SQL Server: define explícitamente la clave clustered (debe ser *narrow, unique, static y
  ever-increasing* — normalmente la PK identity). Índices nonclustered en columnas de
  `WHERE`/`JOIN`/`ORDER BY`/`GROUP BY`.

## Ideas de base de datos aportadas por el humano

`.specify/memory/db_ideas.md` contiene borradores de tablas concretas (campos, tipos, claves, uso)
escritos directamente por el humano — útil para aterrizar detalles técnicos que no salen bien
explicando solo la funcionalidad. **No se consulta automáticamente**: solo se lee cuando el prompt de
`/speckit.plan` de la spec en curso lo referencia explícitamente (p. ej. señalando una tabla
concreta). Cuando así se referencia, **no es una fuente de verdad**: trátalo como punto de partida y
aplica sobre él las convenciones de esta misma sección (naming, campos de auditoría, índices, motor)
sin excepción, señalando explícitamente cualquier corrección que hagas sobre lo escrito por el
humano.

## Migraciones

- Herramienta: `[nombre de la herramienta del proyecto — p. ej. Alembic, Flyway, Liquibase, EF Core
  Migrations]`. Si este campo sigue sin rellenar, pregunta al usuario qué herramienta usa el
  proyecto antes de generar o proponer una migración — no asumas ninguna por defecto, depende del
  stack (lenguaje/framework) del proyecto. Toda migración se genera, se revisa a mano y se versiona
  en Git; nunca se aplican cambios de esquema directamente en la BD sin migración.
- Toda migración que afecte a datos ya existentes en producción requiere UAT humana explícita (ver
  `@.claude/context/01_estilo_comportamiento.md`) antes de aplicarse.

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
