# spec-verifier — arquitectura de dos skills sobre un subagente

> Sustituye al diseño anterior de un único subagente `uat-validator`. Esta
> versión separa "traducir quickstart.md a algo ejecutable" de "ejecutar
> esas validaciones", y usa un hook para convertir la restricción de
> ficheros en una garantía técnica, no solo una instrucción.

## 1. Por qué esta forma y no un solo subagente monolítico

El problema de partida: `quickstart.md` es un artefacto de Spec-Kit escrito
en prosa para que lo siga un humano, no para que lo ejecute un agente sin
ambigüedad. En vez de tocar cómo Spec-Kit genera ese fichero (que forzaría
reescribir su propio prompt de `/speckit.plan`), se introduce una capa
derivada:

```
quickstart.md  --[verify-prepare]-->  quickstart_agent.md  --[verify-validate]-->  quickstart_agent.md (con resultados)
   (prosa,                                (estructurado,                              (mismo fichero,
   humano)                                 automatizable/manual)                       anotado in situ)
```

Las dos skills comparten el mismo subagente (`spec-verifier`) porque las
reglas de seguridad — nunca tocar código, nunca editar nada que no sea
`quickstart_agent.md`, nunca inventar un resultado — son idénticas en
ambos casos; lo único que cambia es el procedimiento concreto, y ese vive
en el cuerpo de cada skill.

## 2. Instalación

```
.claude/
├── agents/
│   └── spec-verifier.md          ← copiar aquí
├── hooks/
│   └── guard-quickstart-agent.sh ← copiar aquí, y dar permiso de ejecución
└── skills/
    ├── verify-prepare/
    │   └── SKILL.md              ← copiar aquí
    └── verify-validate/
        └── SKILL.md              ← copiar aquí
```

```bash
chmod +x .claude/hooks/guard-quickstart-agent.sh
```

Al ser subagente y skills de proyecto (`.claude/`), la primera vez que
Claude Code use el hook del subagente te pedirá aceptar el diálogo de
confianza de la carpeta del proyecto — es el mecanismo estándar por el que
Claude Code evita ejecutar hooks de un repositorio en el que aún no confías.

Si prefieres tenerlo disponible en todos tus proyectos SDD en vez de
repetir la instalación en cada repo, la alternativa es guardar estos
mismos ficheros en `~/.claude/agents/` y `~/.claude/skills/` — con la
salvedad de que la ruta del hook (`./.claude/hooks/...`) es relativa al
proyecto, así que en ese caso tendrías que copiar también el script del
hook a cada proyecto, o apuntar a una ruta absoluta fija en tu máquina.

## 3. Cómo funciona la restricción "solo puede tocar ese fichero"

`spec-verifier` tiene `Write` y `Edit` en su lista de herramientas —
necesarias para generar y anotar `quickstart_agent.md` — pero su cabecera
declara un hook `PreToolUse` que se dispara antes de cualquier `Write` o
`Edit`. El script comprueba el nombre del fichero objetivo; si no es
exactamente `quickstart_agent.md`, bloquea la operación con código de
salida 2 y el subagente recibe el motivo del bloqueo en vez de completar
la escritura. Esto es lo que hace que la restricción sea real y no solo
una petición en el system prompt: aunque el modelo "decidiera" saltársela,
la herramienta se niega a ejecutarse.

`Bash` sigue disponible para ambas skills (lo necesita `verify-validate`
para ejecutar los comandos de cada escenario). `verify-prepare` no lo
necesita, y su propio cuerpo se lo prohíbe explícitamente por instrucción
— es una restricción blanda, no reforzada por hook. Si en algún momento
quieres una garantía dura también aquí, la forma correcta es partir
`spec-verifier` en dos subagentes (`spec-verifier-prepare` sin `Bash`,
`spec-verifier-validate` con `Bash`) y apuntar cada skill a uno distinto
con su propio campo `agent:`. Para un proyecto solo no es imprescindible,
pero es la vía si algún día trabajas en equipo y quieres esa garantía
también reforzada mecánicamente.

## 4. Uso en el flujo SDD

```
/speckit.plan                    → genera quickstart.md
/verify-prepare                  → genera/actualiza quickstart_agent.md
/speckit.tasks → /speckit.implement
/verify-validate                 → ejecuta y anota resultados
  ├─ sin ERRÓNEA/INALCANZABLE → /speckit.converge → PR
  └─ con ERRÓNEA/INALCANZABLE → "revisa quickstart_agent.md y corrige
                                  el proyecto" → /verify-validate de nuevo
```

Ninguna de las dos skills corrige nada por su cuenta — ese paso lo pides tú
explícitamente a Claude en la conversación principal, en base a lo que
`quickstart_agent.md` refleja. Es un bucle deliberadamente manual en ese
punto: la skill detecta y documenta, tú decides cuándo y cómo corregir.

Si cambias `quickstart.md` (por ejemplo, tras un `/speckit.clarify` que
afecta a un escenario), vuelve a ejecutar `/verify-prepare` — conservará
los resultados de los escenarios que no hayan cambiado y solo reseteará a
`PENDIENTE` los afectados.

## 5. Ficheros de esta entrega

- `spec-verifier.md` → `.claude/agents/spec-verifier.md`
- `verify-prepare/SKILL.md` → `.claude/skills/verify-prepare/SKILL.md`
- `verify-validate/SKILL.md` → `.claude/skills/verify-validate/SKILL.md`
- `guard-quickstart-agent.sh` → `.claude/hooks/guard-quickstart-agent.sh`

Esta entrega sustituye a la anterior (`uat-validator.md`,
`quickstart-template.md`, `guia-subagente-validacion-uat.md`): la lógica
de esos ficheros — clasificación en estados, evidencia obligatoria,
separación entre validar y corregir — sigue siendo válida y está
incorporada aquí, ahora con la traducción automática de `quickstart.md` y
con la restricción de ficheros reforzada por hook en vez de solo por
instrucción.
