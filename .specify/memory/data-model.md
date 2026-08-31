# Modelo de Datos Canónico

> Última actualización: [fecha] — actualizado por spec [NNN-nombre]

## Convenciones activas
- Toda tabla con necesidad de auditoría usa TIMESTAMPTZ + trigger BEFORE UPDATE (ver constitution.md)
- [otras convenciones ya fijadas]

## Entidades

### tabla: clientes
| Columna | Tipo | Constraints | Introducida en | Modificada en |
|---|---|---|---|---|
| id | BIGINT | PK | 001 | — |
| email | VARCHAR(255) | UNIQUE, NOT NULL | 001 | — |
| estado | VARCHAR(20) | NOT NULL | 001 | 006 (se amplían valores permitidos) |

**Specs que dependen de esta tabla:** 001, 003, 006, 009

## Changelog
- [009] Añadida columna `segmento_id` a `clientes` (FK a `segmentos`). Afecta a specs 003, 006 → ver adaptaciones aplicadas.
- [006] Ampliado el dominio de `estado` de 3 a 5 valores posibles.