# Configuración del Harness (una vez por proyecto)

Sigue paso a paso este documento una vez que hayas completado la [**instalación del Spec Kit**](02_Instalacion_Spec_Kit.md) (caso A, B, C o D según tu situación). Verifica con `specify check` si se ha instalado correctamente. 

⚠️**IMPORTANTE**: Sigue el orden, cada paso depende del anterior.

> **Atajo automatizado**: los pasos 1, 2 y 4 completos, más parte de los pasos 3 y 5 (deja preparado el prompt de `CLAUDE.md` listo para pegar, y genera `ci.yml` — además del repo remoto si se usa `-SetupGitHub`), se pueden ejecutar de un tirón con [**install.ps1**](./install.ps1). Ejemplo listo para copiar y editar (con todos los parámetros) en [**install_example.md**](./install_example.md); documentación completa de cada parámetro con `Get-Help .\install.ps1 -Full`. Lo que sigue aquí es la referencia manual y el *fallback* si el script falla en algún punto.

## 1. Configurar Contexto

### Carpeta `Context`

Ejecuta el siguiente script para copiar los ficheros de la plantilla:
```bash
mkdir -p .claude/context
cp ruta/a/plantilla/files/context/*.md .claude/context/
```

Ve a la la ruta del proyecto `.claude/context/` y rellena manualmente los campos `[ ]` de cada fichero copiado con los datos reales del proyecto:

| Fichero | Descripción |
| --- | --- |
| [**01_estilo_comportamiento.md**](./files/context/01_estilo_comportamiento.md) | Normalmente no requiere cambios, son reglas de comportamiento genéricas y ya aplicables tal cual. |
| [**02_documentacion_mantenibilidad.md**](./files/context/02_documentacion_mantenibilidad.md) | Normalmente tampoco requiere cambios. |
| [**03_python.md**](./files/context/03_python.md) | Rellena versión de Python, framework backend/móvil, criterios de cobertura. |
| [**04_base_datos.md**](./files/context/04_base_datos.md) | Rellena motor (PostgreSQL/SQL Server), schemas, decisión sobre NoSQL si aplica. |

### Carpeta `Github`

Ejecuta el siguiente script para copiar los ficheros de la plantilla:
```bash
cp ruta/a/plantilla/files/github/01_github_workflow.md .claude/context/05_github.md
```

Ve a la ruta del proyecto `.claude/context/05_github.md` y rellena manualmente los campos `[ ]` con los datos reales del proyecto:

| Fichero | Descripción |
| --- | --- |
| [**01_github_workflow.md**](./files/github/01_github_workflow.md) | Rellena [público/privado] y confirma el nombre de la rama de trabajo (dev por defecto). |

### Carpeta `.specify/memory`

Ejecuta el siguiente script para copiar los ficheros de la plantilla (la carpeta `.specify/memory/`
ya existe tras `specify init`, con `constitution.md` dentro — ver [**02_Instalacion_Spec_Kit**](02_Instalacion_Spec_Kit.md)):
```bash
cp ruta/a/plantilla/files/specify/*.md .specify/memory/
```

| Fichero | Descripción |
| --- | --- |
| [**data-model.md**](./files/specify/data-model.md) | Modelo de datos canónico del proyecto (entidades, changelog, qué specs dependen de cada tabla). Arranca con el ejemplo de la plantilla; sustitúyelo por las tablas reales a medida que se creen, o vacíalo si el proyecto aún no tiene ninguna. |
| [**schema-change-protocol.md**](./files/specify/schema-change-protocol.md) | Protocolo obligatorio (lectura → reutilización → impacto → prioridad → propuesta al humano → aplicación) que `/speckit.specify` y `/speckit.plan` invocan automáticamente antes de tocar el modelo de datos (ver [**02_Desarrollo**](./files/prompts/02_Desarrollo.md)). No requiere rellenar ningún campo. |
| [**db_ideas.md**](./files/specify/db_ideas.md) | Borrador opcional de tablas concretas que el humano rellena cuando le hace falta — no se importa en `CLAUDE.md` ni se lee por comprobación automática de existencia: solo se consulta cuando el prompt de `/speckit.plan` de una spec lo referencia explícitamente (ver [**02_Desarrollo**](./files/prompts/02_Desarrollo.md)). Su sección "Plantilla de entrada" mantiene los corchetes `[ ]` a propósito (se duplica por cada tabla nueva, no se rellena y desaparece). |

## 2. Instalar skills, subagentes y hooks

Sigue el documento [**04_Instalacion_Herramientas_Claude.md**](04_Instalacion_Herramientas_Claude.md) para saber cómo instalarlos correctamente según las necesidades del proyecto.

Verifica que `jq` está instalado en tu sistema (lo usan los scripts de hooks para leer el JSON de entrada):
```bash
winget install jqlang.jq        # Para Windows
sudo apt install jq             # Para Linux
brew install jq                 # Para MacOS
```

Tras ello, y para instalar todos los skills, subagentes y hooks, ejecuta los siguientes comandos:
```bash
mkdir -p .claude/agents/
mkdir -p .claude/hooks/
mkdir -p .claude/skills/

cp -r ruta/a/plantilla/files/native/skills/* .claude/skills/
cp -r ruta/a/plantilla/files/native/agents/*.md .claude/agents/
cp ruta/a/plantilla/files/native/hooks/settings.json .claude/settings.json
cp ruta/a/plantilla/files/native/hooks/*.sh .claude/hooks/

chmod +x .claude/hooks/*.sh
git add .claude/ && git commit -m "chore: harness Claude Code (skills/agents/hooks)"
```

## 3. Generar CLAUDE.md

Abre `claude` dentro del proyecto y pega el prompt de [**01_ClaudeMD**](./files/prompts/01_ClaudeMD.md), ya con sus placeholders rellenos. Revisa el resultado a mano antes de continuar.

## 4. Configurar Obsidian

1. Crea (o abre) el vault del proyecto.
2. Sigue `./files/obsidian/01_obsidian_setup.md` para instalar y configurar los plugins, y cópialo
   como `docs/Meta/Setup.md` dentro del propio vault.
3. Copia `./files/obsidian/02_obsidian_workflow.md` como `docs/Meta/Workflow.md` dentro del propio vault.
4. Crea la estructura de carpetas (`Specs/`, `ADR/records/`, `Data-Model/`, `Runbooks/`, `Changelog/`, `Prompts/`)
 y las plantillas Templater descritas en ese mismo fichero.
5. Copia la biblioteca de prompts maestros (`./files/prompts/*.md`) a `docs/Prompts/` para tenerlos
   accesibles desde el propio vault.

Estos pasos puedes llevarlos a cabo ejecutando estos comandos:

```bash
mkdir -p docs/Meta/Templates/
mkdir -p docs/Specs/
mkdir -p docs/ADR/records/
mkdir -p docs/Data-Model/
mkdir -p docs/Runbooks/
mkdir -p docs/Changelog/
mkdir -p docs/Prompts/

cp ruta/a/plantilla/files/obsidian/01_obsidian_setup.md docs/Meta/Setup.md
cp ruta/a/plantilla/files/obsidian/02_obsidian_workflow.md docs/Meta/Workflow.md
cp ruta/a/plantilla/files/obsidian/templates/*.md docs/Meta/Templates/
cp ruta/a/plantilla/files/prompts/*.md docs/Prompts/

touch docs/Specs/.gitkeep docs/ADR/records/.gitkeep docs/Data-Model/.gitkeep docs/Runbooks/.gitkeep docs/Changelog/.gitkeep
```

En PowerShell, en lugar de `touch` usa:
```powershell
New-Item ./docs/Specs/.gitkeep -ItemType File
New-Item ./docs/ADR/records/.gitkeep -ItemType File
New-Item ./docs/Data-Model/.gitkeep -ItemType File
New-Item ./docs/Runbooks/.gitkeep -ItemType File
New-Item ./docs/Changelog/.gitkeep -ItemType File
```

## 5. Configurar GitHub

Sigue el checklist de puesta en marcha al final de [**01_github_workflow.md**](./files/github/01_github_workflow.md) (crear repo, rama `dev`, branch protection en `main`, `.github/workflows/ci.yml`, GitHub Project, spending limit a $0).

## 6. Verificación final

```bash
/context # dentro de Claude Code: confirma que CLAUDE.md y sus imports se cargaron
/doctor # confirma que hooks y skills están activos
```

- [ ] `specify check` en verde.
- [ ] `.claude/context/01_*.md` a `05_github.md` presentes y sin placeholders `[ ]` pendientes.
- [ ] `.specify/memory/data-model.md` y `.specify/memory/schema-change-protocol.md` presentes
      (`db_ideas.md` es opcional y mantiene corchetes de plantilla a propósito, no cuenta para este
      punto).
- [ ] `.claude/skills/`, `.claude/agents/`, `.claude/settings.json` presentes.
- [ ] `CLAUDE.md` generado y revisado a mano.
- [ ] Vault de Obsidian con la estructura de carpetas y plantillas creada.
- [ ] Repo GitHub con rama `dev`, CI y branch protection configurados.

Con esto, el harness está listo y puedes empezar el primer ciclo SDD con [**02_Desarrollo**](./files/prompts/02_Desarrollo.md).
