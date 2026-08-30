# Instalación y Configuración de Spec-Kit

> **Atajo automatizado**: [**install.ps1**](./install.ps1) ejecuta por ti el equivalente al Caso A + Claude Code de este documento (`specify init --here --integration claude --script <sh|ps|py> --force`), además de los pasos de `03_Configuracion_Harness.md`. Sigue requiriendo que `git`, `uv` y `specify` ya estén instalados a mano (ver "Prerrequisitos" más abajo) — el script solo comprueba que existan y se detiene con instrucciones si faltan. Ejemplo listo para copiar y editar (con todos los parámetros) en [**install_example.md**](./install_example.md); documentación completa de cada parámetro con `Get-Help .\install.ps1 -Full`. Si necesitas crear la carpeta del proyecto, usar otro agente, o controlar cada paso a mano, sigue este documento.

## Prerrequisitos (una sola vez por máquina)

```bash
# uv (gestor de Python recomendado; también instala Python si falta)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instala el CLI de Spec-Kit como herramienta global de uv
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verifica prerrequisitos del sistema (git, versión de Python, agente detectado, etc.)
specify check
```

⚠️**IMPORTANTE**: Los nombres exactos de flags (`--ai`, `--integration`, etc.) han cambiado entre versiones de Spec-Kit. Antes de copiar los comandos de abajo literalmente, confírmalos con:

```bash
specify init --help
specify integration list
```

Elige tu situación respondiendo a estas dos preguntas independientes — combina la respuesta de la 1 con la de la 2 en un único comando `specify init`.

## 1. ¿Dónde inicializas?

### Caso A — Ya estás en la raíz del proyecto (carpeta vacía o con código existente)

```bash
cd mi-proyecto/
specify init --here --integration claude
```

Spec-Kit detecta que ya estás dentro de una carpeta y no crea un subdirectorio nuevo: coloca `.specify/`, `specs/` y los comandos del agente directamente aquí. Es el caso más habitual cuando ya tienes un repositorio Git iniciado o código heredado (brownfield).

### Caso B — Quieres que Spec-Kit cree la carpeta raíz del proyecto

```bash
specify init mi-proyecto --integration claude
cd mi-proyecto
git init # si no lo hace ya specify init automáticamente
```

Útil para proyectos 100% greenfield: partes de cero y Spec-Kit te entrega la estructura ya lista.

## 2. ¿Qué agente usas?

Los comandos de arriba ya incluyen `--integration claude`; este flag es el que decide qué agente instala Spec-Kit, y es independiente de la respuesta a la pregunta 1.

### Claude Code (`--integration claude`)

Esto instala los slash commands (`/speckit.constitution`, `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.checklist`, `/speckit.tasks`, `/speckit.analyze`, `/speckit.implement`, `/speckit.converge`, `/speckit.taskstoissues`) en `.claude/commands/`, de forma que Claude Code los reconoce automáticamente al abrir el proyecto. No necesitas configurar nada adicional: abre `claude` dentro de la carpeta y escribe `/speckit.` para ver el autocompletado.

### Cualquier otro asistente

Sustituye `--integration claude` por el agente que quieras, combinándolo con el comando de la pregunta 1 que te corresponda:

```bash
specify integration list # lista los agentes soportados por tu versión instalada

specify init --here --integration copilot # Caso A: carpeta ya existente
specify init mi-proyecto --integration cursor # Caso B: Spec-Kit crea la carpeta
```

Spec-Kit soporta más de 30 agentes con la misma mecánica (`--integration gemini`, `--integration codex`, etc.): cambia el destino de los comandos slash (`.cursor/commands/`, `.github/copilot/`, etc.) pero el flujo de fases (`constitution → specify → clarify → plan → checklist → tasks → analyze → implement → converge`) es idéntico. Si en el futuro alternas de agente en el mismo proyecto, puedes volver a ejecutar `specify init --here --integration <otro-agente>` para añadir los comandos del nuevo agente sin perder `.specify/` ni `specs/`.

## Verificación tras la instalación

```bash
ls .specify/memory/ # debe existir constitution.md (vacío hasta el primer /speckit.constitution)
ls specs/ # vacío hasta la primera feature
ls .claude/commands/ # (o la carpeta equivalente de tu agente)
```

Si algo falta, repite `specify check` — es idempotente y no rompe nada si vuelves a ejecutar `init`.
