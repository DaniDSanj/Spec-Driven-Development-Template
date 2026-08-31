<#
.SYNOPSIS
  Completa la puesta en marcha de un proyecto creado a partir de esta plantilla SDD (GitHub Template
  Repository), siguiendo el mismo orden de pasos que las secciones "Instalación de Spec-Kit" y
  "Configuración del harness" de README.md.

.DESCRIPTION
  El repositorio ya nace con todo el harness en su sitio (.claude/context, .claude/skills,
  .claude/agents, .claude/hooks, .specify/memory, docs/, .github/workflows/ci.yml) porque se generó
  con "Use this template" / `gh repo create --template`. Este script solo se encarga de lo que
  todavía depende del proyecto concreto: ejecutar `specify init`, rellenar los placeholders mecánicos
  (versión de Python, motor de BD, visibilidad), dejar listo el prompt de CLAUDE.md, y — si se pide —
  completar la parte de GitHub que un repo recién generado desde plantilla aún no tiene (rama dev,
  branch protection, GitHub Project).

  Lo que la metodología exige que decida o revise un humano queda fuera a propósito: rellenar
  convenciones que dependen del stack (motor de migraciones, convención de PK, uso de schemas),
  generar y revisar CLAUDE.md, instalar plugins de Obsidian, crear el GitHub Project y fijar el
  spending limit. El script deja todo eso listado en un checklist final.

.PARAMETER ProjectName
  Nombre del proyecto: rellena [NOMBRE_PROYECTO] en el prompt de CLAUDE.md. Si se usa -SetupGitHub,
  se usa también para nombrar el GitHub Project.

.PARAMETER ProjectDescription
  Descripción de una línea del proyecto: rellena [DESCRIPCIÓN_UNA_LÍNEA].

.PARAMETER NonObviousCommands
  Comandos no evidentes (ej. cómo levantar la BD local). Rellena [COMANDOS_NO_OBVIOS]. Si se omite,
  se deja marcado como pendiente de completar a mano.

.PARAMETER PythonVersion
  Versión de Python a fijar en .claude/context/03_python.md (por defecto 3.12).

.PARAMETER DbEngine
  Motor de base de datos: PostgreSQL, SQLServer o Ninguno. Marca la casilla correspondiente en
  .claude/context/04_base_datos.md (por defecto PostgreSQL, que ya es el default documentado).

.PARAMETER Visibility
  Visibilidad del repositorio: private o public. Rellena .claude/context/05_github.md y, si se usa
  -SetupGitHub, decide el flag de `gh api` para branch protection.

.PARAMETER SpecifyScriptType
  Tipo de scripts que instala Spec-Kit (sh, ps o py) — evita el selector interactivo de
  `specify init`. Por defecto ps, acorde al shell principal de este entorno.

.PARAMETER SetupGitHub
  Si se indica, intenta completar en el repositorio remoto ya existente (creado al usar la plantilla)
  lo que "Use this template" no hace por sí solo: rama dev, marcarla como rama por defecto, branch
  protection en main y un GitHub Project. Requiere `gh` ya instalado y autenticado (`gh auth login` es
  un paso manual, con login por navegador, que este script no automatiza). Pide confirmación explícita
  antes de tocar nada remoto.

.PARAMETER InstallGh
  Solo tiene efecto junto con -SetupGitHub. Si falta `gh` (GitHub CLI), lo instala con winget antes de
  continuar, igual que este script ya asume que tú instalaste `uv`/`specify` de antemano — aquí, bajo
  petición explícita, lo hace el propio script. La autenticación (`gh auth login`) sigue siendo manual
  por naturaleza (login por navegador): si tras instalar `gh` no está autenticado, el script se detiene
  con instrucciones en vez de continuar.

.PARAMETER Force
  Sobrescribe ficheros ya modificados a mano. Sin este flag, el script nunca pisa nada que ya
  parezca personalizado — es seguro volver a ejecutarlo sobre un proyecto ya iniciado.

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
[CmdletBinding()]
param(
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

    [switch]$InstallGh,

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

# ---------------------------------------------------------------------------
# Validación inicial
# ---------------------------------------------------------------------------

$ProjectPath = (Get-Location).ProviderPath

if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.git'))) {
    throw "No se encuentra '.git' en $ProjectPath. Ejecuta este script desde la raíz del repositorio ya creado con 'Use this template' (o `gh repo create --template`) y clonado localmente."
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
# Paso 2 — Placeholders mecánicos en .claude/context
# ---------------------------------------------------------------------------

Write-Section 'Paso 2: placeholders en .claude/context'

$contextDest = Join-Path $ProjectPath '.claude\context'

$pythonCtxPath = Join-Path $contextDest '03_python.md'
if (Test-Path -LiteralPath $pythonCtxPath) {
    $content = Get-Content -LiteralPath $pythonCtxPath -Raw -Encoding UTF8
    $newContent = $content.Replace('[3.14.7]', $PythonVersion)
    if ($newContent -ne $content) {
        Set-Content -LiteralPath $pythonCtxPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Ok "versión de Python fijada a $PythonVersion en 03_python.md"
    } else {
        Write-Skip '03_python.md: placeholder de versión ya no está presente (¿ya se rellenó?)'
    }
}
Add-ManualStep 'Completar en .claude/context/03_python.md: framework del proyecto (backend/frontend/móvil) y cobertura mínima de tests'

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
Add-ManualStep 'Completar en .claude/context/04_base_datos.md: versión del motor, convención de PK, uso de schemas y herramienta de migraciones'

$githubDest = Join-Path $contextDest '05_github.md'
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
# Paso 3 — Prompt de CLAUDE.md
# ---------------------------------------------------------------------------

Write-Section 'Paso 3: prompt de CLAUDE.md'

$claudeMdPromptSrc = Join-Path $ProjectPath '.claude\prompts\01_ClaudeMD.md'
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
    Set-Content -LiteralPath $stagingPromptPath -Value $promptContent -NoNewline -Encoding UTF8
    Write-Ok $stagingPromptPath
}
Add-ManualStep 'Abrir `claude` dentro del proyecto, pegar el bloque de prompt de .claude/CLAUDE_MD_PROMPT.md y revisar el CLAUDE.md generado (sobrescribe el CLAUDE.md de la plantilla) antes de darlo por bueno'

# ---------------------------------------------------------------------------
# Paso 4 — Obsidian
# ---------------------------------------------------------------------------

Write-Section 'Paso 4: Obsidian'

Add-ManualStep 'Abrir el vault de Obsidian en docs/ e instalar los plugins comunitarios: Dataview, Templater, obsidian-git, Kanban/Tasks, Excalidraw (ver docs/Meta/Setup.md)'

# ---------------------------------------------------------------------------
# Paso 5 — Completar en GitHub lo que "Use this template" no hace (solo con -SetupGitHub)
# ---------------------------------------------------------------------------

if ($SetupGitHub) {
    Write-Section 'Paso 5: completar el repositorio de GitHub'

    $nameWithOwner = gh repo view --json nameWithOwner -q .nameWithOwner
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nameWithOwner)) {
        Write-Warn2 'no se pudo obtener el nombre del repositorio remoto (owner/repo); ¿tiene origin configurado?'
        Add-ManualStep 'Completar a mano el checklist de .claude/context/05_github.md (rama dev, branch protection, Project, spending limit)'
    } else {
        Write-Host ''
        Write-Host "Esto va a, sobre '$nameWithOwner':" -ForegroundColor Yellow
        Write-Host "  - hacer commit de los placeholders rellenados y publicarlo en la rama actual"
        Write-Host "  - crear y publicar la rama 'dev', y marcarla como rama por defecto"
        Write-Host "  - intentar activar branch protection en 'main' y crear un GitHub Project"
        $confirm = Read-Host '¿Continuar? (s/N)'

        if ($confirm -ine 's') {
            Write-Skip 'automatización de GitHub cancelada por el usuario'
            Add-ManualStep 'Completar a mano el checklist de .claude/context/05_github.md (rama dev, branch protection, Project, spending limit)'
        } else {
            try {
                git add -A
                $status = git status --porcelain
                if ($status) {
                    git commit -m 'chore: rellenar placeholders de la plantilla SDD' | Out-Null
                    git push
                    Write-Ok 'placeholders publicados'
                } else {
                    Write-Skip 'no hay cambios pendientes de commit'
                }

                git checkout -b dev
                git push -u origin dev
                if ($LASTEXITCODE -ne 0) { throw "no se pudo publicar la rama dev (código $LASTEXITCODE)" }
                Write-Ok "rama 'dev' publicada"

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
                    $owner = ($nameWithOwner -split '/')[0]
                    $projectJson = gh project create --owner $owner --title $ProjectName --format json | ConvertFrom-Json
                    if ($LASTEXITCODE -ne 0 -or -not $projectJson -or -not $projectJson.number) {
                        throw 'gh project create no devolvió un proyecto válido (revisa que el token tenga el scope "project": gh auth refresh -s project)'
                    }
                    gh project link $projectJson.number --owner $owner --repo $nameWithOwner | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "gh project link devolvió el código $LASTEXITCODE" }
                    Write-Ok "GitHub Project '$ProjectName' creado y vinculado (número $($projectJson.number))"
                    Add-ManualStep 'Configurar a mano las Workflows nativas del GitHub Project recién creado (Item added/closed, PR merged, Auto-add) — ver checklist de .claude/context/05_github.md'
                } catch {
                    Write-Warn2 "no se pudo crear el GitHub Project automáticamente: $($_.Exception.Message)"
                    Add-ManualStep 'Crear el GitHub Project (Board/Kanban) y vincularlo al repo a mano — ver checklist de .claude/context/05_github.md'
                }
            } catch {
                Write-Warn2 "automatización de GitHub interrumpida: $($_.Exception.Message)"
                Add-ManualStep 'La configuración de rama/branch protection no terminó bien: revisa el estado en GitHub y completa a mano lo que falte (ver .claude/context/05_github.md)'
            }
        }
    }
} else {
    Add-ManualStep 'Completar a mano el checklist de .claude/context/05_github.md (rama dev, branch protection, Project) — o relanzar este script con -SetupGitHub'
}

Add-ManualStep 'Fijar Spending limit = $0 en GitHub (Settings -> Billing) — no tiene API/CLI'

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------

Write-Section 'Checklist final'

Write-Host 'Automatizado por el script:' -ForegroundColor Green
Write-Host '  - specify init (.specify/memory/constitution.md)'
Write-Host '  - placeholders en .claude/context/03_python.md, 04_base_datos.md, 05_github.md'
Write-Host '  - .claude/CLAUDE_MD_PROMPT.md (prompt ya relleno, listo para pegar en claude)'
if ($SetupGitHub) {
    Write-Host '  - rama dev y (best-effort) branch protection / GitHub Project'
}

Write-Host ''
Write-Host 'Pendiente de revisión/acción humana:' -ForegroundColor Yellow
foreach ($step in $script:ManualSteps) {
    Write-Host "  - $step"
}

Write-Host ''
Write-Host 'Cuando termines, dentro de una sesión de Claude Code en el proyecto ejecuta /context y /doctor para verificar.'

exit 0
