<#
.SYNOPSIS
  Completa la puesta en marcha de un proyecto creado a partir de esta plantilla SDD (GitHub Template
  Repository), siguiendo el mismo orden de pasos que las secciones "Instalación de Spec-Kit" y
  "Configuración del harness" de README.md.

  Requiere PowerShell 7 o superior (`pwsh`). Windows PowerShell 5.1 no sirve: lee los ficheros .ps1
  sin BOM como ANSI, con lo que todos los acentos de este script se corromperían y acabarían escritos
  así en el perfil del proyecto.

.DESCRIPTION
  El repositorio ya nace con todo el harness en su sitio (.claude/context, .claude/skills,
  .claude/agents, .claude/hooks, .specify/memory, docs/, .github/workflows/ci.yml) porque se generó
  con "Use this template" / `gh repo create --template`. Este script solo se encarga de lo que
  todavía depende del proyecto concreto: ejecutar `specify init` y rellenar el perfil del proyecto
  (.claude/context/00_perfil_proyecto.md: nombre, descripción, versión de Python, motor de BD,
  visibilidad).

  La parte de GitHub (rama dev, branch protection, secret scanning con push protection, Dependabot
  alerts, private vulnerability reporting, exigencia de SHA en Actions, GitHub Project) vive en un
  script aparte, setup-github.ps1, porque tiene otros prerrequisitos y otro ciclo de vida: se
  reaplica cada vez que la configuración del repositorio se desincroniza, mientras que lo de aquí se
  hace una sola vez. Con -SetupGitHub, este script lo invoca por ti.

  Lo que la metodología exige que decida o revise un humano queda fuera a propósito: los campos del
  perfil sin default seguro (herramienta de migraciones, framework, cobertura objetivo, versión del
  motor), generar y revisar CLAUDE.md, instalar plugins de Obsidian, crear el GitHub Project y fijar
  el spending limit. El script deja todo eso listado en un checklist final.

.PARAMETER ProjectName
  Nombre del proyecto: rellena [NOMBRE_PROYECTO] en el perfil del proyecto. Si se usa -SetupGitHub,
  se usa también para nombrar el GitHub Project.

.PARAMETER ProjectDescription
  Descripción de una línea del proyecto: rellena [DESCRIPCIÓN_UNA_LÍNEA] en el perfil del proyecto.

.PARAMETER NonObviousCommands
  Comandos no evidentes (ej. cómo levantar la BD local). Rellena [COMANDOS_NO_OBVIOS] en el perfil
  del proyecto. Si se omite, se deja marcado como pendiente de completar a mano.

.PARAMETER PythonVersion
  Versión de Python a fijar en el perfil del proyecto. Sin default a propósito: el perfil declara como
  default "la última estable al iniciar el proyecto", y fijar aquí una versión concreta la
  contradiría en silencio cada vez que Python publica una release. Si se omite, el placeholder queda
  intacto y el checklist final lo recuerda como campo pendiente.

.PARAMETER DbEngine
  Motor de base de datos: PostgreSQL, SQLServer o Ninguno. Se fija en el perfil del proyecto (por
  defecto PostgreSQL, que ya es el default documentado).

.PARAMETER Visibility
  Visibilidad del repositorio: private o public. Se fija en el perfil del proyecto, de donde la lee
  la skill git-run-actions para razonar sobre el consumo de minutos de GitHub Actions. Nota: en repos
  privados sin GitHub Pro/Team la API de branch protection no está disponible, y secret scanning con
  push protection exige GitHub Secret Protection, así que -SetupGitHub dejará esos puntos como pasos
  manuales.

.PARAMETER SpecifyScriptType
  Tipo de scripts que instala Spec-Kit (sh, ps o py) — evita el selector interactivo de
  `specify init`. Por defecto ps, acorde al shell principal de este entorno.

.PARAMETER SetupGitHub
  Si se indica, invoca setup-github.ps1 (que debe estar junto a este script) para completar en el
  repositorio remoto ya existente lo que "Use this template" no hace por sí solo: rama dev, marcarla
  como rama por defecto, branch protection en dev y main, secret scanning con push protection,
  Dependabot alerts, private vulnerability reporting, exigir acciones fijadas por SHA y un GitHub
  Project. Ese script pide confirmación explícita antes de tocar nada remoto, y comprueba él mismo sus
  prerrequisitos (`gh` instalado y autenticado). Sin este parámetro, ejecutarlo queda como paso del
  checklist final.

.PARAMETER InstallGh
  Solo tiene efecto junto con -SetupGitHub: se pasa tal cual a setup-github.ps1, que instalará `gh`
  con winget si falta. La autenticación (`gh auth login`) sigue siendo manual por naturaleza (login
  por navegador).

.NOTES
  El script es idempotente por construcción: solo sustituye placeholders literales del perfil del
  proyecto, así que un campo ya personalizado a mano nunca se pisa al volver a ejecutarlo. Por eso
  ya no existe un parámetro -Force.

.EXAMPLE
  # Dentro del repo ya clonado (creado con "Use this template" o `gh repo create --template`):
  .\bootstrap.ps1 -ProjectName "mi-app" -ProjectDescription "API de gestión de pedidos" `
      -DbEngine PostgreSQL -Visibility private

.EXAMPLE
  .\bootstrap.ps1 -ProjectName "mi-app" -ProjectDescription "API de gestión de pedidos" `
      -SetupGitHub

.EXAMPLE
  .\bootstrap.ps1 -ProjectName "mi-app" -ProjectDescription "API de gestión de pedidos" `
      -SetupGitHub -InstallGh
#>

# Va DESPUÉS del bloque de ayuda a propósito: un #Requires por delante de él impide que `Get-Help
# .\bootstrap.ps1 -Full` reconozca la ayuda basada en comentarios y solo devuelva la sintaxis.
#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$ProjectDescription,

    [string]$NonObviousCommands = '',

    [string]$PythonVersion = '',

    [ValidateSet('PostgreSQL', 'SQLServer', 'Ninguno')]
    [string]$DbEngine = 'PostgreSQL',

    [ValidateSet('private', 'public')]
    [string]$Visibility = 'private',

    [ValidateSet('sh', 'ps', 'py')]
    [string]$SpecifyScriptType = 'ps',

    [switch]$SetupGitHub,

    [switch]$InstallGh
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

$script:ManualSteps = New-Object System.Collections.Generic.List[string]

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Message)
    Write-Host "  [omitido] $Message" -ForegroundColor DarkYellow
}

function Write-Note {
    param([string]$Message)
    Write-Host "  [aviso] $Message" -ForegroundColor Yellow
}

function Add-ManualStep {
    param([string]$Message)
    $script:ManualSteps.Add($Message) | Out-Null
}

function Test-Prereq {
    param([string]$Name, [bool]$Required)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Ok $Name
        return $true
    }
    if ($Required) {
        Write-Host "  [FALTA] $Name (obligatorio)" -ForegroundColor Red
    } else {
        Write-Note "$Name no encontrado (opcional, algunas funciones no estarán disponibles)"
    }
    return $false
}

# ---------------------------------------------------------------------------
# Validación inicial
# ---------------------------------------------------------------------------

$ProjectPath = (Get-Location).ProviderPath

if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.git'))) {
    throw "No se encuentra '.git' en $ProjectPath. Ejecuta este script desde la raíz del repositorio ya creado con 'Use this template' (o 'gh repo create --template') y clonado localmente."
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.claude\context'))) {
    throw "No se encuentra '.claude\context' en $ProjectPath. Este script solo funciona sobre un repositorio generado desde esta plantilla."
}

Write-Host "Proyecto: $ProjectPath"

# ---------------------------------------------------------------------------
# Paso 0 — Prerrequisitos de máquina
# ---------------------------------------------------------------------------

Write-Section 'Paso 0: prerrequisitos de máquina'

$hasGit = Test-Prereq 'git' $true
$hasUv = Test-Prereq 'uv' $true
$hasSpecify = Test-Prereq 'specify' $true
# bash y jq son obligatorios: los cuatro hooks de .claude/hooks/ se invocan con `bash` desde
# .claude/settings.json y leen su entrada JSON con `jq`. Además, los dos guards de PreToolUse son
# fail-closed, así que sin jq bloquean toda escritura en vez de dejarla pasar en silencio.
$hasBash = Test-Prereq 'bash' $true
$hasJq = Test-Prereq 'jq' $true
$hasClaude = Test-Prereq 'claude' $false

if (-not $hasClaude) {
    Add-ManualStep 'Instalar/autenticar Claude Code (claude) para poder generar y revisar CLAUDE.md'
}

if (-not ($hasGit -and $hasUv -and $hasSpecify -and $hasBash -and $hasJq)) {
    Write-Host ''
    Write-Host 'Faltan herramientas obligatorias. Instálalas y vuelve a ejecutar el script:' -ForegroundColor Red
    if (-not $hasUv) {
        Write-Host '  uv:      curl -LsSf https://astral.sh/uv/install.sh | sh   (o el instalador de uv para Windows)'
    }
    if (-not $hasSpecify) {
        Write-Host '  specify: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git'
    }
    if (-not $hasGit) {
        Write-Host '  git:     https://git-scm.com/downloads'
    }
    if (-not $hasBash) {
        Write-Host '  bash:    viene con Git for Windows (Git Bash). Reinstala git marcando esa opción, o usa WSL.'
    }
    if (-not $hasJq) {
        Write-Host '  jq:      winget install jqlang.jq  |  sudo apt install jq  |  brew install jq'
    }
    exit 1
}

if ($InstallGh -and -not $SetupGitHub) {
    Write-Note '-InstallGh no tiene efecto sin -SetupGitHub; se ignora'
}

# `gh`, su instalación con winget y su autenticación son prerrequisitos del Paso 5, que vive en
# setup-github.ps1: los comprueba él, no este script.

Write-Section 'specify check'
specify check

# ---------------------------------------------------------------------------
# Paso 1 — specify init (fusiona constitution.md junto a la memoria ya presente)
# ---------------------------------------------------------------------------

Write-Section 'Paso 1: specify init'

if (Test-Path -LiteralPath (Join-Path $ProjectPath '.specify\memory\constitution.md')) {
    Write-Skip '.specify/memory/constitution.md ya existe, no se repite specify init'
} else {
    try {
        specify init --here --integration claude --script $SpecifyScriptType --force
        Write-Ok 'specify init'
    } catch {
        Write-Host ''
        Write-Host 'specify init falló. La sintaxis de flags cambia entre versiones de Spec-Kit; revisa la ayuda:' -ForegroundColor Red
        specify init --help
        throw
    }
}

# ---------------------------------------------------------------------------
# Paso 2 — Perfil del proyecto
# ---------------------------------------------------------------------------

Write-Section 'Paso 2: perfil del proyecto'

$contextDest = Join-Path $ProjectPath '.claude\context'
$profilePath = Join-Path $contextDest '00_perfil_proyecto.md'

if (-not (Test-Path -LiteralPath $profilePath)) {
    Write-Note 'no se encuentra .claude/context/00_perfil_proyecto.md; el repo no se generó desde una versión actual de la plantilla'
    Add-ManualStep 'Crear a mano .claude/context/00_perfil_proyecto.md con los datos del proyecto'
} else {
    $content = Get-Content -LiteralPath $profilePath -Raw -Encoding UTF8

    $nonObvious = $NonObviousCommands
    if ([string]::IsNullOrWhiteSpace($nonObvious)) {
        $nonObvious = '[PENDIENTE - completar a mano]'
    }

    $visibilityEs = 'privado'
    if ($Visibility -eq 'public') { $visibilityEs = 'público' }

    $engineEs = $DbEngine
    if ($DbEngine -eq 'SQLServer') { $engineEs = 'SQL Server' }

    # Cada entrada: placeholder literal del fichero -> valor a escribir.
    $descPlaceholder = '[DESCRIPCI' + [char]0x00D3 + 'N_UNA_L' + [char]0x00CD + 'NEA]'
    $replacements = [ordered]@{
        '[NOMBRE_PROYECTO]'     = $ProjectName
        $descPlaceholder        = $ProjectDescription
        '[COMANDOS_NO_OBVIOS]'  = $nonObvious
        '[PostgreSQL]'          = $engineEs
        '[privado]'             = $visibilityEs
    }

    # La versión de Python solo se toca si se pasó -PythonVersion. Sin ella, el placeholder queda
    # intacto y se recuerda en el checklist final: el perfil declara como default "la última estable",
    # y escribir aquí una versión fija lo contradiría en silencio.
    if (-not [string]::IsNullOrWhiteSpace($PythonVersion)) {
        $replacements['[3.14.7]'] = $PythonVersion
    }

    $newContent = $content
    $applied = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($key in $replacements.Keys) {
        if ($newContent.Contains($key)) {
            $newContent = $newContent.Replace($key, $replacements[$key])
            $applied.Add("$key -> $($replacements[$key])") | Out-Null
        } else {
            $missing.Add($key) | Out-Null
        }
    }

    if ($newContent -ne $content) {
        Set-Content -LiteralPath $profilePath -Value $newContent -NoNewline -Encoding UTF8
        foreach ($a in $applied) { Write-Ok $a }
    }
    if ($missing.Count -gt 0) {
        Write-Skip "placeholders ya rellenos o ausentes: $($missing -join ', ')"
    }
}

Add-ManualStep 'Completar en .claude/context/00_perfil_proyecto.md los campos sin default: framework del proyecto, cobertura mínima de tests, versión del motor de BD y herramienta de migraciones'

if ([string]::IsNullOrWhiteSpace($PythonVersion)) {
    Add-ManualStep 'Fijar la versión de Python en .claude/context/00_perfil_proyecto.md (default declarado: la última estable en https://www.python.org/downloads/ al iniciar el proyecto), o relanzar el script con -PythonVersion'
}

# ---------------------------------------------------------------------------
# Paso 3 — Generación de CLAUDE.md
# ---------------------------------------------------------------------------

Write-Section 'Paso 3: generación de CLAUDE.md'

$claudeMdPromptSrc = Join-Path $ProjectPath '.claude\prompts\01_init_project.md'
if (Test-Path -LiteralPath $claudeMdPromptSrc) {
    Write-Ok 'prompt disponible en .claude/prompts/01_init_project.md (sin placeholders: lee los datos del perfil)'
} else {
    Write-Note 'no se encuentra .claude/prompts/01_init_project.md'
}
Add-ManualStep 'Abrir `claude` dentro del proyecto, pegar el bloque de prompt de .claude/prompts/01_init_project.md y revisar el CLAUDE.md generado (sobrescribe el CLAUDE.md de la plantilla) antes de darlo por bueno'

# ---------------------------------------------------------------------------
# Paso 4 — Obsidian
# ---------------------------------------------------------------------------

Write-Section 'Paso 4: Obsidian'

Add-ManualStep 'Abrir el vault de Obsidian en docs/ e instalar los plugins comunitarios: Dataview, Templater, obsidian-git, Kanban/Tasks, Excalidraw (ver docs/Meta/Setup.md)'

# ---------------------------------------------------------------------------
# Paso 5 — Completar en GitHub lo que "Use this template" no hace (solo con -SetupGitHub)
#
# La configuración de GitHub vive en su propio script, setup-github.ps1. Está separada a propósito:
# tiene otros prerrequisitos (solo git y gh, nada de uv/specify/bash/jq) y otro ciclo de vida —
# rellenar el perfil o ejecutar `specify init` se hace una vez, mientras que la configuración del
# repositorio se reaplica cada vez que se desincroniza. Aquí solo se delega, para que la puesta en
# marcha completa siga siendo un único comando.
# ---------------------------------------------------------------------------

Write-Section 'Paso 5: repositorio de GitHub'

$setupGitHubScript = Join-Path $PSScriptRoot 'setup-github.ps1'

if (-not $SetupGitHub) {
    Write-Skip '-SetupGitHub no indicado: no se toca nada en GitHub'
    Add-ManualStep "Configurar el repositorio en GitHub ejecutando: pwsh -File `"$setupGitHubScript`"  (rama dev, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project). Alternativa manual: el checklist de la seccion 2.5 (Configurar GitHub) del README.md"
} elseif (-not (Test-Path -LiteralPath $setupGitHubScript)) {
    Write-Note 'no se encuentra setup-github.ps1 junto a este script; el repo no se generó desde una versión actual de la plantilla'
    Add-ManualStep 'Completar a mano el checklist de la seccion 2.5 (Configurar GitHub) del README.md (rama dev, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project, spending limit)'
} else {
    # Los placeholders recién rellenados no se commitean ni se publican aquí: es una decisión humana,
    # y setup-github.ps1 solo configura el lado del servidor.
    Add-ManualStep 'Revisar, commitear y publicar los placeholders rellenados de .claude/context/00_perfil_proyecto.md y lo que haya añadido `specify init`'

    $ghArgs = @('-ProjectName', $ProjectName)
    if ($InstallGh) { $ghArgs += '-InstallGh' }

    & $setupGitHubScript @ghArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Note "setup-github.ps1 terminó con el código $LASTEXITCODE"
        Add-ManualStep 'Revisar el estado del repositorio en GitHub: setup-github.ps1 no terminó correctamente — ver la seccion 2.5 (Configurar GitHub) del README.md'
    }
}

Add-ManualStep 'Activar la red local de .githooks/ si la quieres (pre-commit: escaneo de secretos con gitleaks; pre-push: ruff/ty/pytest/pip-audit antes de cada push, ahorra minutos de Actions): git config core.hooksPath .githooks'
if (-not (Get-Command 'gitleaks' -ErrorAction SilentlyContinue)) {
    Add-ManualStep 'Instalar gitleaks para que el hook pre-commit escanee secretos (sin él, avisa y deja pasar): winget install Gitleaks.Gitleaks | brew install gitleaks'
}

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------

Write-Section 'Checklist final'

Write-Host 'Automatizado por el script:' -ForegroundColor Green
Write-Host '  - specify init (.specify/memory/constitution.md)'
Write-Host '  - datos del proyecto en .claude/context/00_perfil_proyecto.md'
if ($SetupGitHub) {
    Write-Host '  - la configuración de GitHub, delegada en setup-github.ps1 (su propio resumen va más arriba)'
}

Write-Host ''
Write-Host 'Pendiente de revisión/acción humana:' -ForegroundColor Yellow
foreach ($step in $script:ManualSteps) {
    Write-Host "  - $step"
}

Write-Host ''
Write-Host 'Cuando termines, dentro de una sesión de Claude Code en el proyecto ejecuta /context y /doctor para verificar.'

exit 0
