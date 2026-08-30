<#
.SYNOPSIS
  Instala automáticamente el harness de la plantilla SDD (Claude Code + Spec-Kit + Obsidian) en un
  proyecto destino, siguiendo el mismo orden de pasos que 02_Instalacion_Spec_Kit.md y
  03_Configuracion_Harness.md.

.DESCRIPTION
  Automatiza todo lo mecánico del proceso descrito en la plantilla: copiar ficheros de contexto,
  skills, subagentes, hooks, memoria de Spec-Kit, estructura de Obsidian y (opcionalmente) crear el
  repositorio de GitHub con rama dev, CI y branch protection.

  Lo que la metodología exige que decida o revise un humano queda fuera a propósito: rellenar
  convenciones que dependen del stack (motor de migraciones, convención de PK, uso de schemas),
  generar y revisar CLAUDE.md, instalar plugins de Obsidian, crear el GitHub Project y fijar el
  spending limit. El script deja todo eso listado en un checklist final.

.PARAMETER TemplatePath
  Raíz de este repositorio (la plantilla). Por defecto, la carpeta padre de donde vive este script.

.PARAMETER ProjectPath
  Carpeta del proyecto destino. Se crea si no existe.

.PARAMETER ProjectName
  Nombre del proyecto: rellena [NOMBRE_PROYECTO] en el prompt de CLAUDE.md y da nombre al repo de
  GitHub si se usa -SetupGitHub.

.PARAMETER ProjectDescription
  Descripción de una línea del proyecto: rellena [DESCRIPCIÓN_UNA_LÍNEA].

.PARAMETER NonObviousCommands
  Comandos no evidentes (ej. cómo levantar la BD local). Rellena [COMANDOS_NO_OBVIOS]. Si se omite,
  se deja marcado como pendiente de completar a mano.

.PARAMETER PythonVersion
  Versión de Python a fijar en context/03_python.md (por defecto 3.12).

.PARAMETER DbEngine
  Motor de base de datos: PostgreSQL, SQLServer o Ninguno. Marca la casilla correspondiente en
  context/04_base_datos.md (por defecto PostgreSQL, que ya es el default documentado).

.PARAMETER Visibility
  Visibilidad del repositorio: private o public. Rellena context/05_github.md y, si se usa
  -SetupGitHub, decide el flag de `gh repo create`.

.PARAMETER SpecifyScriptType
  Tipo de scripts que instala Spec-Kit (sh, ps o py) — evita el selector interactivo de
  `specify init`. Por defecto ps, acorde al shell principal de este entorno.

.PARAMETER SetupGitHub
  Si se indica, además de generar .github/workflows/ci.yml (que siempre se genera), intenta crear el
  repositorio remoto con `gh`, la rama dev, branch protection en main y un GitHub Project. Requiere
  `gh` ya instalado y autenticado (`gh auth login` es un paso manual, con login por navegador, que
  este script no automatiza). Pide confirmación explícita antes de tocar nada remoto.

.PARAMETER GitHubOwner
  Owner/organización de GitHub bajo el que crear el repo (solo con -SetupGitHub). Si se omite, se usa
  la cuenta autenticada en `gh`.

.PARAMETER InstallGh
  Solo tiene efecto junto con -SetupGitHub. Si falta `gh` (GitHub CLI), lo instala con winget antes de
  continuar, igual que este script ya asume que tú instalaste `uv`/`specify` de antemano — aquí, bajo
  petición explícita, lo hace el propio script. La autenticación (`gh auth login`) sigue siendo manual
  por naturaleza (login por navegador): si tras instalar `gh` no está autenticado, el script se detiene
  con instrucciones en vez de continuar.

.PARAMETER SkipObsidian
  Omite el montaje de la estructura del vault de Obsidian (docs/).

.PARAMETER Force
  Sobrescribe ficheros/carpetas ya existentes en el destino. Sin este flag, el script nunca pisa nada
  que ya exista — es seguro volver a ejecutarlo sobre un proyecto ya iniciado.

.EXAMPLE
  .\install.ps1 -ProjectPath "D:\Proyectos\mi-app" -ProjectName "mi-app" `
      -ProjectDescription "API de gestión de pedidos" -DbEngine PostgreSQL -Visibility private

.EXAMPLE
  .\install.ps1 -ProjectPath "D:\Proyectos\mi-app" -ProjectName "mi-app" `
      -ProjectDescription "API de gestión de pedidos" -SetupGitHub -GitHubOwner "mi-org"

.EXAMPLE
  .\install.ps1 -ProjectPath "D:\Proyectos\mi-app" -ProjectName "mi-app" `
      -ProjectDescription "API de gestión de pedidos" -SetupGitHub -InstallGh
#>
[CmdletBinding()]
param(
    [string]$TemplatePath = (Split-Path -Parent $PSScriptRoot),

    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [Parameter(Mandatory = $true)]
    [string]$ProjectDescription,

    [string]$NonObviousCommands = '',

    [string]$PythonVersion = '3.12',

    [ValidateSet('PostgreSQL', 'SQLServer', 'Ninguno')]
    [string]$DbEngine = 'PostgreSQL',

    [ValidateSet('private', 'public')]
    [string]$Visibility = 'private',

    [ValidateSet('sh', 'ps', 'py')]
    [string]$SpecifyScriptType = 'ps',

    [switch]$SetupGitHub,

    [string]$GitHubOwner = '',

    [switch]$InstallGh,

    [switch]$SkipObsidian,

    [switch]$Force
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

function Write-Warn2 {
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
        Write-Warn2 "$Name no encontrado (opcional, algunas funciones no estarán disponibles)"
    }
    return $false
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Copy-TemplateFile {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestPath
    )
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Warn2 "no existe en la plantilla: $SourcePath"
        return
    }
    if ((Test-Path -LiteralPath $DestPath) -and (-not $Force)) {
        Write-Skip $DestPath
        return
    }
    Ensure-Dir (Split-Path -Parent $DestPath)
    Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
    Write-Ok $DestPath
}

function Copy-TemplateDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$DestPath
    )
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Warn2 "no existe en la plantilla: $SourcePath"
        return
    }
    if ((Test-Path -LiteralPath $DestPath) -and (-not $Force)) {
        Write-Skip $DestPath
        return
    }
    Ensure-Dir (Split-Path -Parent $DestPath)
    Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Recurse -Force
    Write-Ok $DestPath
}

function Copy-TemplateFilesInDir {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$DestDir,
        [string]$Filter = '*.md'
    )
    if (-not (Test-Path -LiteralPath $SourceDir)) {
        Write-Warn2 "no existe en la plantilla: $SourceDir"
        return
    }
    Ensure-Dir $DestDir
    Get-ChildItem -LiteralPath $SourceDir -Filter $Filter -File | ForEach-Object {
        Copy-TemplateFile -SourcePath $_.FullName -DestPath (Join-Path $DestDir $_.Name)
    }
}

# ---------------------------------------------------------------------------
# Validación inicial
# ---------------------------------------------------------------------------

$TemplatePath = (Resolve-Path -LiteralPath $TemplatePath).ProviderPath
$FilesPath = Join-Path $TemplatePath 'Plantilla_Spec-Driven-Development\files'

if (-not (Test-Path -LiteralPath $FilesPath)) {
    throw "No se encuentra '$FilesPath'. Revisa -TemplatePath: debe apuntar a la raíz del repositorio de la plantilla."
}

if (-not (Test-Path -LiteralPath $ProjectPath)) {
    Ensure-Dir $ProjectPath
}
$ProjectPath = (Resolve-Path -LiteralPath $ProjectPath).ProviderPath

if ($ProjectPath -ieq $TemplatePath) {
    throw "ProjectPath no puede ser la misma carpeta que TemplatePath."
}

Write-Host "Plantilla: $TemplatePath"
Write-Host "Proyecto destino: $ProjectPath"

# ---------------------------------------------------------------------------
# Paso 0 — Prerrequisitos de máquina
# ---------------------------------------------------------------------------

Write-Section 'Paso 0: prerrequisitos de máquina'

$hasGit = Test-Prereq 'git' $true
$hasUv = Test-Prereq 'uv' $true
$hasSpecify = Test-Prereq 'specify' $true
$hasJq = Test-Prereq 'jq' $false
$hasClaude = Test-Prereq 'claude' $false

if (-not $hasJq) {
    Add-ManualStep 'Instalar jq (usado por los hooks de .claude/hooks/*.sh): winget install jqlang.jq'
}
if (-not $hasClaude) {
    Add-ManualStep 'Instalar/autenticar Claude Code (claude) para poder generar y revisar CLAUDE.md'
}

if (-not ($hasGit -and $hasUv -and $hasSpecify)) {
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
    exit 1
}

if ($InstallGh -and -not $SetupGitHub) {
    Write-Warn2 '-InstallGh no tiene efecto sin -SetupGitHub; se ignora'
}

$hasGh = $false
if ($SetupGitHub) {
    $hasGh = Test-Prereq 'gh' $true

    if ((-not $hasGh) -and $InstallGh) {
        Write-Section 'Instalando GitHub CLI (gh)'
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host 'No se encontró winget para instalar gh automáticamente. Instálalo tú: https://cli.github.com/' -ForegroundColor Red
            exit 1
        }
        winget install --id GitHub.cli --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Host "winget install de GitHub.cli devolvió el código $LASTEXITCODE" -ForegroundColor Red
            exit 1
        }
        # Refresca el PATH de esta sesión con el valor ya actualizado en el registro, para no
        # depender de abrir una terminal nueva (winget no propaga el PATH al proceso que lo invocó).
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = $machinePath + ';' + $userPath
        $hasGh = Test-Prereq 'gh' $true
    }

    if (-not $hasGh) {
        Write-Host ''
        Write-Host 'Se pidió -SetupGitHub pero falta gh (GitHub CLI).' -ForegroundColor Red
        Write-Host '  Instálalo tú (https://cli.github.com/) o relanza el script añadiendo -InstallGh.'
        exit 1
    }

    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host 'gh no está autenticado. Ejecuta `gh auth login` (requiere navegador) y vuelve a lanzar el script con -SetupGitHub.' -ForegroundColor Red
        exit 1
    }
    Write-Ok 'gh autenticado'
}

Write-Section 'specify check'
specify check

# ---------------------------------------------------------------------------
# Paso 1 — specify init en destino
# ---------------------------------------------------------------------------

Write-Section 'Paso 1: specify init'

Push-Location $ProjectPath
try {
    if (Test-Path -LiteralPath (Join-Path $ProjectPath '.specify')) {
        Write-Skip '.specify ya existe, no se repite specify init'
    } else {
        try {
            specify init --here --integration claude --script $SpecifyScriptType --force
        } catch {
            Write-Host ''
            Write-Host 'specify init falló. La sintaxis de flags cambia entre versiones de Spec-Kit; revisa la ayuda:' -ForegroundColor Red
            specify init --help
            throw
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.git'))) {
        git init | Out-Null
        Write-Ok 'git init'
    } else {
        Write-Skip 'ya es un repositorio git'
    }
} finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# Paso 2 — Contexto (.claude/context, .specify/memory)
# ---------------------------------------------------------------------------

Write-Section 'Paso 2: contexto (.claude/context, .specify/memory)'

$contextDest = Join-Path $ProjectPath '.claude\context'
Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'context') -DestDir $contextDest -Filter '*.md'

$githubDest = Join-Path $contextDest '05_github.md'
Copy-TemplateFile -SourcePath (Join-Path $FilesPath 'github\01_github_workflow.md') -DestPath $githubDest

$memoryDest = Join-Path $ProjectPath '.specify\memory'
Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'specify') -DestDir $memoryDest -Filter '*.md'

# Sustituciones mecánicas best-effort (el resto de casillas [ ] quedan para revisión humana)

$pythonCtxPath = Join-Path $contextDest '03_python.md'
if (Test-Path -LiteralPath $pythonCtxPath) {
    $content = Get-Content -LiteralPath $pythonCtxPath -Raw -Encoding UTF8
    $newContent = $content.Replace('[3.14.7]', $PythonVersion)
    if ($newContent -ne $content) {
        Set-Content -LiteralPath $pythonCtxPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Ok "versión de Python fijada a $PythonVersion en 03_python.md"
    }
}
Add-ManualStep 'Completar en context/03_python.md: framework del proyecto (backend/frontend/móvil) y cobertura mínima de tests'

$dbCtxPath = Join-Path $contextDest '04_base_datos.md'
if (Test-Path -LiteralPath $dbCtxPath) {
    $content = Get-Content -LiteralPath $dbCtxPath -Raw -Encoding UTF8
    $newContent = $content.Replace('- [x] PostgreSQL `[versión]`', '- [ ] PostgreSQL `[versión]`').Replace('- [x] SQL Server `[versión]`', '- [ ] SQL Server `[versión]`')
    if ($DbEngine -eq 'PostgreSQL') {
        $newContent = $newContent.Replace('- [ ] PostgreSQL `[versión]`', '- [x] PostgreSQL `[versión]`')
    } elseif ($DbEngine -eq 'SQLServer') {
        $newContent = $newContent.Replace('- [ ] SQL Server `[versión]`', '- [x] SQL Server `[versión]`')
    }
    if ($newContent -ne $content) {
        Set-Content -LiteralPath $dbCtxPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Ok "motor de base de datos marcado ($DbEngine) en 04_base_datos.md"
    }
}
Add-ManualStep 'Completar en context/04_base_datos.md: versión del motor, convención de PK, uso de schemas y herramienta de migraciones'

if (Test-Path -LiteralPath $githubDest) {
    $content = Get-Content -LiteralPath $githubDest -Raw -Encoding UTF8
    $visibilityEs = 'privado'
    if ($Visibility -eq 'public') { $visibilityEs = 'público' }
    $find = 'Este proyecto es: `[público / privado ' + [char]0x2014 + ' indicar]`.'
    $replace = 'Este proyecto es: `' + $visibilityEs + '`.'
    $newContent = $content.Replace($find, $replace)
    if ($newContent -ne $content) {
        Set-Content -LiteralPath $githubDest -Value $newContent -NoNewline -Encoding UTF8
        Write-Ok "visibilidad ($visibilityEs) fijada en 05_github.md"
    } elseif ($content.Contains($replace)) {
        Write-Skip "visibilidad ya estaba fijada en 05_github.md"
    } else {
        Write-Warn2 'no se pudo localizar el placeholder de visibilidad en 05_github.md; revísalo a mano'
    }
}

# ---------------------------------------------------------------------------
# Paso 3 — Skills, subagentes y hooks
# ---------------------------------------------------------------------------

Write-Section 'Paso 3: skills, subagentes y hooks'

$skillsSrc = Join-Path $FilesPath 'native\skills'
$skillsDest = Join-Path $ProjectPath '.claude\skills'
Ensure-Dir $skillsDest
if (Test-Path -LiteralPath $skillsSrc) {
    Get-ChildItem -LiteralPath $skillsSrc -Directory | ForEach-Object {
        Copy-TemplateDirectory -SourcePath $_.FullName -DestPath (Join-Path $skillsDest $_.Name)
    }
}

$agentsDest = Join-Path $ProjectPath '.claude\agents'
Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'native\agents') -DestDir $agentsDest -Filter '*.md'

$hooksDest = Join-Path $ProjectPath '.claude\hooks'
Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'native\hooks') -DestDir $hooksDest -Filter '*.sh'

$settingsSrc = Join-Path $FilesPath 'native\hooks\settings.json'
$settingsDest = Join-Path $ProjectPath '.claude\settings.json'
if ((Test-Path -LiteralPath $settingsDest) -and (-not $Force)) {
    $stagingSettings = Join-Path $ProjectPath '.claude\settings.template.json'
    Copy-TemplateFile -SourcePath $settingsSrc -DestPath $stagingSettings
    Write-Warn2 '.claude/settings.json ya existía; los hooks de la plantilla se dejaron en .claude/settings.template.json para fusionar a mano'
    Add-ManualStep 'Fusionar .claude/settings.template.json con .claude/settings.json (ya existía uno distinto en el destino)'
} else {
    Copy-TemplateFile -SourcePath $settingsSrc -DestPath $settingsDest
}

# ---------------------------------------------------------------------------
# Paso 4 — Prompt de CLAUDE.md y biblioteca de prompts
# ---------------------------------------------------------------------------

Write-Section 'Paso 4: prompt de CLAUDE.md'

$claudeMdPromptSrc = Join-Path $FilesPath 'prompts\01_ClaudeMD.md'
$promptContent = Get-Content -LiteralPath $claudeMdPromptSrc -Raw -Encoding UTF8

$nonObvious = $NonObviousCommands
if ([string]::IsNullOrWhiteSpace($nonObvious)) {
    $nonObvious = '[PENDIENTE - completar a mano]'
}

$promptContent = $promptContent.Replace('[NOMBRE_PROYECTO]', $ProjectName)
$promptContent = $promptContent.Replace('[COMANDOS_NO_OBVIOS]', $nonObvious)
$descPlaceholder = '[DESCRIPCI' + [char]0x00D3 + 'N_UNA_L' + [char]0x00CD + 'NEA]'
$promptContent = $promptContent.Replace($descPlaceholder, $ProjectDescription)

$stagingPromptPath = Join-Path $ProjectPath '.claude\CLAUDE_MD_PROMPT.md'
if ((Test-Path -LiteralPath $stagingPromptPath) -and (-not $Force)) {
    Write-Skip $stagingPromptPath
} else {
    Ensure-Dir (Split-Path -Parent $stagingPromptPath)
    Set-Content -LiteralPath $stagingPromptPath -Value $promptContent -NoNewline -Encoding UTF8
    Write-Ok $stagingPromptPath
}
Add-ManualStep 'Abrir `claude` dentro del proyecto, pegar el bloque de prompt de .claude/CLAUDE_MD_PROMPT.md y revisar el CLAUDE.md generado antes de darlo por bueno'

foreach ($promptFile in @('02_Desarrollo.md', '03_Cierre.md', '04_Mantenimiento.md')) {
    Copy-TemplateFile -SourcePath (Join-Path $FilesPath "prompts\$promptFile") -DestPath (Join-Path $ProjectPath ".claude\$promptFile")
}

# ---------------------------------------------------------------------------
# Paso 5 — Estructura de Obsidian
# ---------------------------------------------------------------------------

if ($SkipObsidian) {
    Write-Section 'Paso 5: Obsidian (omitido por -SkipObsidian)'
} else {
    Write-Section 'Paso 5: estructura de Obsidian (docs/)'

    $docsPath = Join-Path $ProjectPath 'docs'
    $emptyDirs = @('Specs', 'ADR\records', 'Data-Model', 'Runbooks', 'Changelog')
    foreach ($dir in $emptyDirs) {
        $fullDir = Join-Path $docsPath $dir
        Ensure-Dir $fullDir
        $gitkeep = Join-Path $fullDir '.gitkeep'
        if (-not (Test-Path -LiteralPath $gitkeep)) {
            New-Item -ItemType File -Path $gitkeep | Out-Null
        }
    }

    Ensure-Dir (Join-Path $docsPath 'Meta\Templates')
    Ensure-Dir (Join-Path $docsPath 'Prompts')

    Copy-TemplateFile -SourcePath (Join-Path $FilesPath 'obsidian\01_obsidian_setup.md') -DestPath (Join-Path $docsPath 'Meta\Setup.md')
    Copy-TemplateFile -SourcePath (Join-Path $FilesPath 'obsidian\02_obsidian_workflow.md') -DestPath (Join-Path $docsPath 'Meta\Workflow.md')
    Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'obsidian\templates') -DestDir (Join-Path $docsPath 'Meta\Templates') -Filter '*.md'
    Copy-TemplateFilesInDir -SourceDir (Join-Path $FilesPath 'prompts') -DestDir (Join-Path $docsPath 'Prompts') -Filter '*.md'

    Add-ManualStep 'Abrir el vault de Obsidian en docs/ e instalar los plugins comunitarios: Dataview, Templater, obsidian-git, Kanban/Tasks, Excalidraw (ver docs/Meta/Setup.md)'
}

# ---------------------------------------------------------------------------
# Paso 6 — CI de GitHub Actions (siempre)
# ---------------------------------------------------------------------------

Write-Section 'Paso 6: .github/workflows/ci.yml'

$workflowsDir = Join-Path $ProjectPath '.github\workflows'
Ensure-Dir $workflowsDir
$ciPath = Join-Path $workflowsDir 'ci.yml'

$ciYaml = @'
name: CI
on:
  pull_request:
    branches: [dev, main]
  push:
    branches: [dev]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - name: Check for pyproject.toml
        id: check
        run: echo "exists=$(test -f pyproject.toml && echo true || echo false)" >> "$GITHUB_OUTPUT"
      - uses: astral-sh/setup-uv@v5
        if: steps.check.outputs.exists == 'true'
      - run: uv sync
        if: steps.check.outputs.exists == 'true'
      - run: uv run ruff check src/
        if: steps.check.outputs.exists == 'true'
      - run: uv run ruff format --check src/
        if: steps.check.outputs.exists == 'true'
      - run: uv run ty check
        if: steps.check.outputs.exists == 'true'
      - run: uv run pytest -q
        if: steps.check.outputs.exists == 'true'
'@

if ((Test-Path -LiteralPath $ciPath) -and (-not $Force)) {
    Write-Skip $ciPath
} else {
    Set-Content -LiteralPath $ciPath -Value $ciYaml -Encoding UTF8
    Write-Ok $ciPath
}

# ---------------------------------------------------------------------------
# Paso 7 — Automatización de GitHub remoto (solo con -SetupGitHub)
# ---------------------------------------------------------------------------

if ($SetupGitHub) {
    Write-Section 'Paso 7: repositorio remoto de GitHub'

    $repoArg = $ProjectName
    if (-not [string]::IsNullOrWhiteSpace($GitHubOwner)) {
        $repoArg = "$GitHubOwner/$ProjectName"
    }
    $visFlag = '--private'
    if ($Visibility -eq 'public') { $visFlag = '--public' }

    Write-Host ''
    Write-Host "Esto va a:" -ForegroundColor Yellow
    Write-Host "  - hacer commit de $ProjectPath si hay cambios pendientes"
    Write-Host "  - crear el repositorio remoto '$repoArg' ($Visibility) con 'gh repo create'"
    Write-Host "  - publicar las ramas 'main' y 'dev'"
    Write-Host "  - intentar activar branch protection en 'main' y crear un GitHub Project"
    $confirm = Read-Host '¿Continuar? (s/N)'

    if ($confirm -ine 's') {
        Write-Skip 'automatización de GitHub cancelada por el usuario'
        Add-ManualStep 'Completar a mano el checklist de github/01_github_workflow.md (repo, ramas, branch protection, Project, spending limit)'
    } else {
        Push-Location $ProjectPath
        try {
            git add -A
            $status = git status --porcelain
            if ($status) {
                git commit -m 'chore: scaffold inicial de la plantilla SDD' | Out-Null
                Write-Ok 'commit inicial creado'
            } else {
                Write-Skip 'no hay cambios pendientes de commit'
            }

            git branch -M main
            Write-Ok "rama actual renombrada a 'main'"

            try {
                gh repo create $repoArg $visFlag --source=. --remote=origin --push
                if ($LASTEXITCODE -ne 0) { throw "gh repo create devolvió el código $LASTEXITCODE" }
                Write-Ok "repo remoto creado y 'main' publicada"

                git checkout -b dev
                git push -u origin dev
                if ($LASTEXITCODE -ne 0) { throw "no se pudo publicar la rama dev (código $LASTEXITCODE)" }
                Write-Ok "rama 'dev' publicada"

                $nameWithOwner = gh repo view --json nameWithOwner -q .nameWithOwner
                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nameWithOwner)) {
                    throw 'no se pudo obtener el nombre del repositorio remoto (owner/repo)'
                }

                try {
                    gh repo edit $nameWithOwner --default-branch dev
                    if ($LASTEXITCODE -ne 0) { throw "gh repo edit devolvió el código $LASTEXITCODE" }
                    Write-Ok "'dev' marcada como rama por defecto"
                } catch {
                    Write-Warn2 "no se pudo marcar 'dev' como rama por defecto: $($_.Exception.Message)"
                    Add-ManualStep "Marcar 'dev' como rama por defecto a mano (Settings -> Branches -> Default branch)"
                }

                try {
                    $protectionBody = @{
                        required_status_checks       = @{ strict = $true; contexts = @('quality') }
                        enforce_admins                = $false
                        required_pull_request_reviews = @{ required_approving_review_count = 0 }
                        restrictions                   = $null
                    } | ConvertTo-Json -Depth 5
                    $protectionBody | gh api --method PUT "repos/$nameWithOwner/branches/main/protection" --input -
                    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE (branch protection no suele estar disponible en repos privados sin GitHub Pro/Team)" }
                    Write-Ok "branch protection activada en 'main'"
                } catch {
                    Write-Warn2 "no se pudo activar branch protection automáticamente: $($_.Exception.Message)"
                    Add-ManualStep 'Activar branch protection en main a mano (Settings -> Branches): requiere PR + CI en verde'
                }

                try {
                    $owner = $GitHubOwner
                    if ([string]::IsNullOrWhiteSpace($owner)) {
                        $owner = gh api user -q .login
                        if ($LASTEXITCODE -ne 0) { throw 'no se pudo determinar el owner autenticado' }
                    }
                    $projectJson = gh project create --owner $owner --title $ProjectName --format json | ConvertFrom-Json
                    if ($LASTEXITCODE -ne 0 -or -not $projectJson -or -not $projectJson.number) {
                        throw 'gh project create no devolvió un proyecto válido (revisa que el token tenga el scope "project": gh auth refresh -s project)'
                    }
                    gh project link $projectJson.number --owner $owner --repo $nameWithOwner | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "gh project link devolvió el código $LASTEXITCODE" }
                    Write-Ok "GitHub Project '$ProjectName' creado y vinculado (número $($projectJson.number))"
                    Add-ManualStep 'Configurar a mano las Workflows nativas del GitHub Project recién creado (Item added/closed, PR merged, Auto-add) — ver checklist de github/01_github_workflow.md'
                } catch {
                    Write-Warn2 "no se pudo crear el GitHub Project automáticamente: $($_.Exception.Message)"
                    Add-ManualStep 'Crear el GitHub Project (Board/Kanban) y vincularlo al repo a mano — ver checklist de github/01_github_workflow.md'
                }
            } catch {
                Write-Warn2 "automatización de GitHub interrumpida: $($_.Exception.Message)"
                Add-ManualStep 'La creación del repo remoto/ramas no terminó bien: revisa el estado en GitHub y completa a mano lo que falte (ver github/01_github_workflow.md)'
            }
        } finally {
            Pop-Location
        }
    }
} else {
    Add-ManualStep 'Completar a mano el checklist de github/01_github_workflow.md (repo, ramas, branch protection, Project) — o relanzar este script con -SetupGitHub'
}

Add-ManualStep 'Fijar Spending limit = $0 en GitHub (Settings -> Billing) — no tiene API/CLI'

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------

Write-Section 'Checklist final'

Write-Host 'Automatizado por el script:' -ForegroundColor Green
Write-Host '  - specify init, .claude/context, .specify/memory, .claude/skills, .claude/agents, .claude/hooks'
Write-Host '  - .claude/CLAUDE_MD_PROMPT.md (prompt ya relleno, listo para pegar en claude)'
if (-not $SkipObsidian) {
    Write-Host '  - estructura del vault de Obsidian en docs/'
}
Write-Host '  - .github/workflows/ci.yml'
if ($SetupGitHub) {
    Write-Host '  - repositorio remoto, rama dev y (best-effort) branch protection / GitHub Project'
}

Write-Host ''
Write-Host 'Pendiente de revisión/acción humana:' -ForegroundColor Yellow
foreach ($step in $script:ManualSteps) {
    Write-Host "  - $step"
}

Write-Host ''
Write-Host 'Cuando termines, dentro de una sesión de Claude Code en el proyecto ejecuta /context y /doctor para verificar.'

exit 0
