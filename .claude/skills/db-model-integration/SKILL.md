---
name: db-model-integration
description: >
  Tras la aprobación humana explícita del esquema, entrega el comando exacto
  de la herramienta de migraciones y el DDL revisado —nunca escribe el
  fichero de migración—, y actualiza el modelo de datos canónico (entidad +
  changelog) y las specs readaptadas. Úsalo en el paso 4.2 del ciclo SDD,
  solo cuando la propuesta de /db-model-protocol ya está aprobada.
context: fork
agent: database-manager
background: false
---

Tu tarea es **aplicar** el esquema ya aprobado de la feature activa. Es el paso 6 del protocolo de
cambio de esquema, y solo se ejecuta después de que el humano haya aprobado explícitamente la propuesta
que entregó `db-model-protocol`.

## Antes de nada: verifica la aprobación

Si el prompt que has recibido no afirma explícitamente que la propuesta está aprobada, **detente y
dilo**. No infieras la aprobación del hecho de que te hayan invocado. Igualmente, si la **herramienta
de migraciones** del perfil del proyecto sigue sin rellenar, pregúntala antes de generar nada: es un
campo sin default seguro.

## Qué haces

1. **La migración: la entregas, no la escribes.** Devuelve al hilo principal, listo para copiar:
   - El **comando exacto** de la herramienta de migraciones del perfil (p. ej.
     `uv run alembic revision -m "..."`), con sus argumentos reales.
   - El **contenido revisado** de la migración (`upgrade` y `downgrade`), para que el humano lo pegue o
     lo compare contra lo que autogenere la herramienta.
   - El comando de aplicación, **separado y marcado como paso manual del humano**.

   `.claude/hooks/pre_edit_guard_sensitive.sh` bloquea toda escritura sobre `migrations/**`, comandos
   `Bash` incluidos. Eso es deliberado: es una superficie de datos de producción. No busques rodeos.

2. **Actualiza el modelo canónico.** En `.specify/memory/data-model.md`:
   - La entidad: tabla nueva o columnas añadidas/modificadas, con su tipo, claves e índices.
   - La columna "Specs que dependen de esta tabla": añade la feature activa.
   - El **changelog**: una entrada con la fecha, la feature y qué cambió.

3. **Actualiza el `data-model.md` local de la spec**, en `specs/<feature>/`, si existe.

4. **Aplica las readaptaciones aprobadas** en las specs afectadas que listó `db-model-protocol` — solo
   las que el humano aprobó, y solo en la forma en que las aprobó.

## Entregable

### Bloque de migración

Comando de generación · contenido de la migración · comando de aplicación (marcado como paso del
humano). Si la migración afecta a datos ya existentes en producción, repite aquí en negrita que
requiere **UAT humana** antes de aplicarse.

### Ficheros que has modificado

| Fichero | Qué has cambiado |
|---|---|

Solo ficheros de modelo y de spec. Si esta tabla incluye algo bajo `migrations/`, es un error: vuelve
al punto 1.

## Al terminar

Cierra con las preguntas concretas que el humano debe responder, como exige el motor, y recuérdale que
la migración sigue sin aplicarse hasta que él ejecute el comando.
