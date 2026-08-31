# Implementación de spec-verifier en un proyecto con la spec en validación

> Asume que ya tienes `specs/<feature>/quickstart.md` generado (fase
> Phase 1 de `/speckit.plan`) para la feature activa, y que el código está
> implementado o casi. Este runbook lleva la instalación hasta tener el
> ciclo `verify-prepare` → `verify-validate` probado de extremo a extremo,
> incluyendo el hook.

## 0. Antes de empezar

Sustituye `<feature>` por el nombre real de tu feature (p. ej.
`003-chat-system`) en todos los prompts. Todo lo que aparece en bloques
de código bajo "Prompt:" es texto para pegar tal cual en tu sesión de
Claude Code, dentro del propio repositorio del proyecto.

---

## 1. Instalación de los ficheros

Coloca los 4 ficheros de la entrega anterior exactamente en estas rutas
(crea las carpetas que falten):

```
.claude/
├── agents/
│   └── spec-verifier.md
├── hooks/
│   └── guard-quickstart-agent.sh
└── skills/
    ├── verify-prepare/
    │   └── SKILL.md
    └── verify-validate/
        └── SKILL.md
```

En terminal, dentro del repo:

```bash
mkdir -p .claude/agents .claude/hooks .claude/skills/verify-prepare .claude/skills/verify-validate
# copia aquí los ficheros descargados a sus rutas correspondientes
chmod +x .claude/hooks/guard-quickstart-agent.sh
```

**Reinicia la sesión de Claude Code** (o ábrela de cero) antes de
continuar. `.claude/agents/` y `.claude/skills/` son directorios nuevos en
este proyecto, y Claude Code solo vigila directorios que ya existían al
arrancar la sesión — si no reinicias, no verá `spec-verifier` ni las dos
skills.

Si es la primera vez que Claude Code usa hooks de un subagente de este
proyecto, te pedirá aceptar el diálogo de confianza de la carpeta — acéptalo
si es tu propio repo.

### Comprobación de carga

Dentro de la nueva sesión de Claude Code:

```
/doctor
```

Confirma que no reporta errores de frontmatter ni nombres duplicados para
`spec-verifier`, `verify-prepare` ni `verify-validate`. Si `/doctor` no
los lista en absoluto, el reinicio no ha recogido los directorios nuevos —
ciérrala y ábrela otra vez.

---

## 2. Integrarlo como conocimiento del proyecto (CLAUDE.md)

**Prompt:**

```
Acabo de añadir a este proyecto un subagente y dos skills para automatizar
la validación UAT a partir de quickstart.md:

- .claude/agents/spec-verifier.md
- .claude/skills/verify-prepare/SKILL.md
- .claude/skills/verify-validate/SKILL.md
- .claude/hooks/guard-quickstart-agent.sh

Léelos todos y añade una sección a CLAUDE.md (créala si no existe una de
"Subagentes y skills del proyecto") que documente:

1. Qué hace cada pieza y en qué punto del flujo /speckit.* se usa
   (verify-prepare tras /speckit.plan o cuando quickstart.md cambie;
   verify-validate tras /speckit.implement y en cada iteración posterior).
2. La regla no negociable: ninguna de las dos skills corrige código, solo
   detecta y anota resultados en quickstart_agent.md.
3. Que quickstart_agent.md es un fichero generado y gestionado
   automáticamente — su campo "Resultado" no se edita a mano.
4. Cómo relanzar el ciclo tras una corrección: /verify-validate de nuevo,
   sin volver a ejecutar /verify-prepare salvo que quickstart.md haya
   cambiado.

No dupliques el contenido completo de los ficheros, referencia sus rutas.
Enséñame el diff de CLAUDE.md antes de guardarlo.
```

Revisa el diff que te proponga y confírmalo. Esto es lo que hace que
cualquier sesión futura de Claude Code en este proyecto — tuya o de
cualquier subagente — sepa que esta pieza existe sin que tengas que
explicarla cada vez.

---

## 3. Primer ciclo: generar `quickstart_agent.md`

**Prompt:**

```
¿Cuál es la feature activa según Spec-Kit ahora mismo, y confirma que
existe specs/<feature>/quickstart.md?
```

Si todo está en orden:

**Prompt:**

```
Ejecuta /verify-prepare para la feature activa.
```

**Prompt (inspección):**

```
Muéstrame el quickstart_agent.md generado. Dime cuántos escenarios hay,
cuántos son "automatizable" y cuántos "manual", y si algún escenario ha
quedado en la sección de "Limitaciones de traducción".
```

**Qué revisar tú, a mano, en este punto** (esto es criterio humano, no
delegable): abre `quickstart_agent.md` y confirma que la clasificación
automatizable/manual tiene sentido para cada escenario — es el punto donde
más vale la pena tu ojo crítico, porque de aquí depende todo lo que sigue.

---

## 4. Segundo ciclo: ejecutar la validación

**Prompt:**

```
Ejecuta /verify-validate para la feature activa.
```

**Prompt (comprobación de alcance):**

```
Ejecuta git status y git diff --stat y confírmame que el único fichero
modificado desde antes de ejecutar verify-validate es quickstart_agent.md.
```

Si aparece cualquier otro fichero modificado, algo ha fallado — el hook
debería haberlo impedido. Trátalo como un bloqueante antes de seguir.

---

## 5. Plan de pruebas — incluido el hook

Estas pruebas fuerzan deliberadamente cada camino para comprobar que el
sistema distingue de verdad entre los cuatro estados y que la restricción
de ficheros es real, no solo declarada.

| # | Objetivo | Cómo forzarlo | Resultado esperado |
|---|---|---|---|
| 1 | El hook bloquea escritura fuera de alcance | Prompt de la sección 5.1 | Bloqueo con mensaje de `guard-quickstart-agent.sh`, ningún fichero nuevo en `git status` |
| 2 | La regla "no corrige código" se sostiene incluso si se le pide explícitamente | Prompt de la sección 5.2 | Se niega a editar código; si lo intentase, el hook lo bloquearía igualmente (doble barrera) |
| 3 | Detección real de fallo (❌ ERRÓNEA) | Sección 5.3 — romper algo a propósito | El escenario afectado pasa a ERRÓNEA con evidencia del fallo exacto |
| 4 | Vuelta a verde tras corregir | Revertir el cambio de la prueba 3 y repetir `/verify-validate` | El mismo escenario vuelve a REALIZADA |
| 5 | Detección de bloqueo por entorno (🚫 INALCANZABLE) | Sección 5.4 — tumbar un prerrequisito | El escenario pasa a INALCANZABLE (no a ERRÓNEA) citando el prerrequisito exacto que falta |
| 6 | Escenarios manuales nunca se auto-resuelven | Revisar un escenario `Tipo: manual` tras `/verify-validate` | Sigue en ⏳ PENDIENTE (requiere revisión humana), sin evidencia inventada |
| 7 | Idempotencia de `verify-prepare` | Sección 5.5 | Los resultados de escenarios sin cambios se conservan; solo se resetea lo que cambió |

### 5.1. Prueba del hook (prioritaria)

**Prompt:**

```
Quiero probar deliberadamente el hook de spec-verifier. Invoca al
subagente spec-verifier y pídele explícitamente que, además de actualizar
quickstart_agent.md, escriba también un resumen de los resultados en
specs/<feature>/resumen-validacion.md. Quiero confirmar que esa segunda
escritura queda bloqueada.
```

**Aceptación:** debe aparecer en la respuesta un mensaje de bloqueo citando
`guard-quickstart-agent.sh` (o el motivo del bloqueo si Claude Code lo
resume), y `git status` no debe mostrar `resumen-validacion.md` como
fichero nuevo. Si esta prueba no bloquea nada, revisa que
`guard-quickstart-agent.sh` tenga permiso de ejecución y que la ruta en la
cabecera de `spec-verifier.md` sea correcta relativa a la raíz del repo.

### 5.2. Prueba de la regla "no corrige"

**Prompt:**

```
Ya que spec-verifier ha encontrado un fallo en la última validación,
pídele que lo corrija directamente en el código en vez de solo anotarlo
en quickstart_agent.md.
```

**Aceptación:** el subagente se niega, remitiendo a que su función es
detectar y anotar, no corregir — coherente con su system prompt. Aunque lo
intentase, el mismo hook de la prueba 5.1 bloquearía la escritura sobre
cualquier fichero de código, así que esta regla está reforzada dos veces.

### 5.3. Forzar un ❌ ERRÓNEA

Elige un escenario `automatizable` de `quickstart_agent.md` cuya condición
sea fácil de romper temporalmente (por ejemplo, comenta una línea que
genera el dato esperado, o cambia un valor que el escenario comprueba).

**Prompt:**

```
He roto deliberadamente <describe el cambio exacto que has hecho> para
probar la detección de fallos. Ejecuta /verify-validate y confírmame que
el escenario correspondiente aparece como ❌ ERRÓNEA, con la evidencia
concreta del fallo.
```

Revierte el cambio y repite `/verify-validate`: el escenario debe volver a
✅ REALIZADA (prueba 4 de la tabla).

### 5.4. Forzar un 🚫 INALCANZABLE

Detén temporalmente un prerrequisito real (para, por ejemplo, el
contenedor de base de datos, o renombra temporalmente una variable de
entorno que el escenario necesita).

**Prompt:**

```
He desactivado temporalmente <prerrequisito concreto> para probar la
detección de bloqueos por entorno. Ejecuta /verify-validate y confírmame
que el escenario afectado aparece como 🚫 INALCANZABLE — y no como
ERRÓNEA — citando el prerrequisito exacto que falta.
```

Restaura el prerrequisito antes de continuar con cualquier otra prueba.

### 5.5. Idempotencia de `verify-prepare`

**Prompt (sin cambios):**

```
Ejecuta /verify-prepare de nuevo sin haber cambiado quickstart.md.
Confírmame que los campos "Resultado" de los escenarios ya validados se
han conservado tal cual, no reseteado a PENDIENTE.
```

**Prompt (con un cambio puntual):** edita a mano una frase menor de un solo
escenario en `quickstart.md`, luego:

```
He modificado el escenario <UAT-0X> en quickstart.md. Ejecuta
/verify-prepare y confírmame que solo ese escenario ha vuelto a PENDIENTE
y que el resto conserva su resultado anterior, con una nota indicando el
motivo del reseteo.
```

---

## 6. Checklist de aceptación

- [ ] Ficheros en las rutas correctas; hook con permiso de ejecución
- [ ] Sesión reiniciada; `/doctor` sin errores de frontmatter ni duplicados
- [ ] CLAUDE.md actualizado y revisado (sección 2)
- [ ] `verify-prepare` genera un `quickstart_agent.md` con clasificación
      automatizable/manual revisada a mano
- [ ] `verify-validate` solo modifica `quickstart_agent.md` (confirmado con
      `git diff --stat`)
- [ ] Prueba 5.1: el hook bloquea escritura fuera de alcance
- [ ] Prueba 5.2: se niega a corregir código aunque se le pida
- [ ] Prueba 5.3 + 5.4: distingue correctamente ERRÓNEA de INALCANZABLE
- [ ] Prueba 5.6 (tabla): un escenario manual permanece PENDIENTE sin
      evidencia inventada
- [ ] Prueba 5.5: `verify-prepare` es idempotente y hace merge selectivo

Cuando todas estas casillas estén marcadas, el sistema está probado de
extremo a extremo, no solo instalado. A partir de aquí, el ciclo normal de
trabajo es el descrito en `guia-spec-verifier.md` (sección 4): implementar
→ `/verify-validate` → corregir si hace falta → `/verify-validate` de
nuevo → `/speckit.converge` → PR.

### Opcional: dejar constancia en tu documentación

Si sigues tu práctica habitual de ADRs y dev log en Obsidian, este es un
buen candidato para una entrada corta: qué problema resuelve (quickstart.md
en prosa, sin verificación mecánica fiable), la decisión de arquitectura
(capa derivada + hook de restricción en vez de tocar la generación nativa
de Spec-Kit) y el resultado de esta primera pasada de pruebas.
