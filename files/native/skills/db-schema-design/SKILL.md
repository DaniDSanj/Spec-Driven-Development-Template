---
name: db-schema-design
description: Convenciones de diseño de esquema de base de datos de este proyecto (naming, campos de auditoría, política de índices), válidas tanto para PostgreSQL como para SQL Server. Úsalo cada vez que diseñes, revises o modifiques una tabla, migración o modelo de datos.
---

# Convenciones de esquema de base de datos

Al diseñar o revisar cualquier tabla:

1. **Naming**: tabla en plural `snake_case`; columnas en singular `snake_case`; FK como
   `<tabla_referenciada_singular>_id`.
2. **Campos de auditoría obligatorios** en toda tabla transaccional: `created_at`, `created_by`,
   `updated_at`, `updated_by`, `version` (`TIMESTAMPTZ`/`DATETIME2`, nunca un tipo sin zona
   horaria). Genera también el trigger de `updated_at`/`version` — ver plantilla completa en
   `.claude/context/04_base_datos.md` del proyecto.
3. **Índices**: toda FK indexada. B-Tree por defecto; GIN para JSONB/arrays/full-text (PostgreSQL);
   BRIN para tablas grandes con datos secuenciales. Nunca añadas un índice sin poder nombrar la
   query que lo necesita.
4. **Documentación en el propio esquema**: `COMMENT ON TABLE` / `COMMENT ON COLUMN` (o el
   equivalente `sp_addextendedproperty` en SQL Server) en cualquier columna cuyo propósito no sea
   obvio por el nombre.
5. **Migraciones**: siempre mediante la herramienta de migraciones versionada del proyecto (ver
   `.claude/context/04_base_datos.md`); si ese fichero no la especifica, pregunta al usuario antes
   de asumir una — nunca `ALTER TABLE` manual sin migración versionada.

Este proyecto usa PostgreSQL o SQL Server según lo indicado en `.claude/context/04_base_datos.md`
— consulta ese fichero para la sintaxis concreta de cada motor (`SERIAL`/`IDENTITY`,
`TIMESTAMPTZ`/`CURRENT_TIMESTAMP` vs `DATETIME2`/`SYSUTCDATETIME()`) y para la herramienta de
migraciones configurada en este proyecto.
