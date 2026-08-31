---
name: docs-runbook
description: >
  Redacta un runbook en docs/Runbooks/ cuando la feature introduce un
  procedimiento operativo nuevo (deploy especial, rollback, migración manual,
  respuesta a incidente). Úsalo en el paso 5.3 del ciclo SDD, al cerrar la
  feature.
context: fork
agent: docs-manager
background: false
---

Tu tarea es redactar un runbook como borrador para revisión humana. No commitees.

## Cuándo se dispara

La feature introduce un **procedimiento operativo nuevo** que alguien tendrá que ejecutar a mano
alguna vez: un deploy con pasos especiales, un rollback, una migración que requiere ventana de
mantenimiento, la respuesta a un incidente previsible.

No merece runbook lo que ya está automatizado y no requiere intervención humana (lo que hace el CI,
lo que hace un script de un solo comando ya documentado en el `CLAUDE.md`).

Si el procedimiento que te han pasado no cumple lo anterior, dilo y no crees el fichero.

## Redacción

Ruta: `docs/Runbooks/[nombre-kebab-case].md`. Plantilla: `docs/Meta/Templates/runbook.md`, con
frontmatter `tipo: runbook`, `nombre`, `fecha` y estas secciones:

1. **Cuándo usar este runbook** — la situación que lo dispara, en una o dos frases. Si quien lo lee
   no puede decidir en 10 segundos si le aplica, está mal escrito.
2. **Prerrequisitos** — accesos, herramientas y estado previo necesario. Concreto: qué permiso, en
   qué entorno.
3. **Pasos** — numerados, uno por acción, con el comando exacto donde lo haya. Cada paso dice cómo se
   comprueba que salió bien.
4. **Rollback** — cómo revertir si algo falla. **Un runbook sin rollback está incompleto**: si el
   procedimiento no es reversible, dilo explícitamente y marca a partir de qué paso deja de serlo.
5. **Enlaces** — wikilinks a la feature relacionada y a los ADR que justifican el procedimiento.

Escríbelo para alguien que lo ejecuta a las 3 de la mañana sin contexto previo: nada de "como es
obvio", nada de pasos implícitos.

## Al terminar

Resume qué runbook creaste y pregunta lo que te haya faltado — especialmente el rollback y los
prerrequisitos de acceso, que casi nunca están escritos en `spec.md` ni en `plan.md`.
