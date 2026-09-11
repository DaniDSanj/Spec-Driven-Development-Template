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
  todavía depende del proyecto concreto: ejecutar `specify init`, rellenar el perfil del proyecto
  (.claude/context/00_perfil_proyecto.md: nombre, descripción, versión de Python, motor de BD,
  visibilidad) y — si se pide — completar la parte de GitHub que un repo recién generado desde
  plantilla aún no tiene (rama dev, branch protection, secret scanning con push protection,
  Dependabot alerts, private vulnerability reporting, exigencia de SHA en Actions, GitHub Project).

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
  Si se indica, intenta completar en el repositorio remoto ya existente (creado al usar la plantilla)
  lo que "Use this template" no hace por sí solo: rama dev, marcarla como rama por defecto, branch
  protection en dev y main, secret scanning con push protection, Dependabot alerts, private
  vulnerability reporting, exigir acciones fijadas por SHA y un GitHub Project. Requiere `gh` ya instalado y autenticado (`gh auth login` es
  un paso manual, con login por navegador, que este script no automatiza). Pide confirmación explícita
  antes de tocar nada remoto.

.PARAMETER InstallGh
  Solo tiene efecto junto con -SetupGitHub. Si falta `gh` (GitHub CLI), lo instala con winget antes de
  continuar, igual que este script ya asume que tú instalaste `uv`/`specify` de antemano — aquí, bajo
  petición explícita, lo hace el propio script. La autenticación (`gh auth login`) sigue siendo manual
  por naturaleza (login por navegador): si tras instalar `gh` no está autenticado, el script se detiene
  con instrucciones en vez de continuar.

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
# ---------------------------------------------------------------------------

if ($SetupGitHub) {
    Write-Section 'Paso 5: completar el repositorio de GitHub'

    $nameWithOwner = gh repo view --json nameWithOwner -q .nameWithOwner
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nameWithOwner)) {
        Write-Note 'no se pudo obtener el nombre del repositorio remoto (owner/repo); ¿tiene origin configurado?'
        Add-ManualStep 'Completar a mano el checklist de la seccion 2.5 (Configurar GitHub) del README.md (rama dev, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project, spending limit)'
    } else {
        Write-Host ''
        Write-Host "Esto va a, sobre '$nameWithOwner':" -ForegroundColor Yellow
        Write-Host "  - hacer commit de los placeholders rellenados y publicarlo en la rama actual"
        Write-Host "  - crear y publicar la rama 'dev', y marcarla como rama por defecto"
        Write-Host "  - intentar activar branch protection en 'dev' y 'main'"
        Write-Host "  - intentar activar secret scanning y push protection, y las Dependabot alerts"
        Write-Host "  - intentar activar private vulnerability reporting y exigir acciones fijadas por SHA"
        Write-Host "  - crear un GitHub Project"
        $confirm = Read-Host '¿Continuar? (s/N)'

        if ($confirm -ine 's') {
            Write-Skip 'automatización de GitHub cancelada por el usuario'
            Add-ManualStep 'Completar a mano el checklist de la seccion 2.5 (Configurar GitHub) del README.md (rama dev, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project, spending limit)'
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

                # En una segunda ejecución la rama 'dev' ya existe: `git checkout -b` falla y, sin
                # comprobarlo, el script seguiría trabajando desde la rama actual sin darse cuenta.
                git rev-parse --verify --quiet refs/heads/dev *> $null
                if ($LASTEXITCODE -eq 0) {
                    Write-Skip "la rama 'dev' ya existe en local"
                    git checkout dev
                    if ($LASTEXITCODE -ne 0) { throw "no se pudo cambiar a la rama dev (código $LASTEXITCODE)" }
                } else {
                    git checkout -b dev
                    if ($LASTEXITCODE -ne 0) { throw "no se pudo crear la rama dev (código $LASTEXITCODE)" }
                }

                git push -u origin dev
                if ($LASTEXITCODE -ne 0) { throw "no se pudo publicar la rama dev (código $LASTEXITCODE)" }
                Write-Ok "rama 'dev' publicada"

                try {
                    gh repo edit $nameWithOwner --default-branch dev
                    if ($LASTEXITCODE -ne 0) { throw "gh repo edit devolvió el código $LASTEXITCODE" }
                    Write-Ok "'dev' marcada como rama por defecto"
                } catch {
                    Write-Note "no se pudo marcar 'dev' como rama por defecto: $($_.Exception.Message)"
                    Add-ManualStep "Marcar 'dev' como rama por defecto a mano (Settings -> Branches -> Default branch)"
                }

                # Modelo documentado por la skill git-update-repo: igual en 'dev' y 'main' salvo strict.
                # enforce_admins = $true es lo que hace que la rama de feature sea obligatoria de
                # verdad (el push directo a 'dev' falla incluso siendo owner).
                # required_approving_review_count = 0: PR obligatoria, pero sin aprobación de un
                # tercero, o en un repo de una sola persona 'main' quedaría bloqueado.
                # strict (rama al día con la base) solo en 'dev': a 'main' solo llega 'dev' por PR, y cada
                # merge deja en 'main' un commit sin contenido que 'dev' no tiene; con strict en 'main'
                # habría que abrir una PR 'main' -> 'dev' antes de cada integración.
                foreach ($branch in @('dev', 'main')) {
                    $protectionBody = @{
                        required_status_checks        = @{ strict = ($branch -eq 'dev'); contexts = @('quality') }
                        enforce_admins                = $true
                        required_pull_request_reviews = @{ required_approving_review_count = 0 }
                        restrictions                  = $null
                    } | ConvertTo-Json -Depth 5

                    try {
                        $protectionBody | gh api --method PUT "repos/$nameWithOwner/branches/$branch/protection" --input -
                        if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE (branch protection no suele estar disponible en repos privados sin GitHub Pro/Team)" }
                        Write-Ok "branch protection activada en '$branch'"
                    } catch {
                        Write-Note "no se pudo activar branch protection en '$branch': $($_.Exception.Message)"
                        Add-ManualStep "Activar branch protection en '$branch' a mano (Settings -> Branches): check 'quality' requerido, strict (solo en dev), enforce admins — ver la seccion 2.5 (Configurar GitHub) del README.md"
                    }
                }

                # Secret scanning + push protection: la capa de servidor del escaneo de secretos (ver
                # SECURITY.md) — GitHub rechaza el push aunque nadie tenga la red local activada.
                # Gratis en repos públicos; en privados exige GitHub Secret Protection, así que un
                # fallo aquí es esperable y queda como paso manual.
                $secretScanningBody = @{
                    security_and_analysis = @{
                        secret_scanning                 = @{ status = 'enabled' }
                        secret_scanning_push_protection = @{ status = 'enabled' }
                    }
                } | ConvertTo-Json -Depth 5

                try {
                    $secretScanningBody | gh api --method PATCH "repos/$nameWithOwner" --input - | Out-Null
                    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE (en repos privados requiere GitHub Secret Protection)" }
                    # Un PATCH aceptado no garantiza el cambio: se lee el estado real antes de darlo por hecho.
                    $pushProtection = gh api "repos/$nameWithOwner" -q '.security_and_analysis.secret_scanning_push_protection.status'
                    if ($pushProtection -ne 'enabled') { throw "GitHub aceptó la petición pero push protection sigue en '$pushProtection' (en repos privados requiere GitHub Secret Protection)" }
                    Write-Ok 'secret scanning y push protection activados'
                } catch {
                    Write-Note "no se pudo activar secret scanning/push protection: $($_.Exception.Message)"
                    Add-ManualStep 'Activar secret scanning y push protection a mano (Settings -> Advanced Security) si el plan lo permite — ver la seccion 2.5 (Configurar GitHub) del README.md'
                }

                # Dependabot alerts: avisan de CVEs en las dependencias. Las PRs de actualización las
                # define .github/dependabot.yml, que ya viene en el repo; esto solo enciende las alertas.
                try {
                    gh api --method PUT "repos/$nameWithOwner/vulnerability-alerts" --silent
                    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE" }
                    Write-Ok 'Dependabot alerts activadas'
                } catch {
                    Write-Note "no se pudieron activar las Dependabot alerts: $($_.Exception.Message)"
                    Add-ManualStep 'Activar Dependabot alerts a mano (Settings -> Advanced Security -> Dependabot alerts) — ver la seccion 2.5 (Configurar GitHub) del README.md'
                }

                # Private vulnerability reporting: el canal privado al que remite la sección "Reportar
                # un problema" de SECURITY.md. Sin él, el formulario Security -> Report a vulnerability
                # no existe.
                try {
                    gh api --method PUT "repos/$nameWithOwner/private-vulnerability-reporting" --silent
                    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE" }
                    Write-Ok 'private vulnerability reporting activado'
                } catch {
                    Write-Note "no se pudo activar private vulnerability reporting: $($_.Exception.Message)"
                    Add-ManualStep 'Activar private vulnerability reporting a mano (Settings -> Advanced Security) — ver la seccion 2.5 (Configurar GitHub) del README.md'
                }

                # Exigir acciones fijadas por SHA: ci.yml ya lo cumple; esto impide que una acción
                # añadida después con @tag llegue a ejecutarse. PUT sobrescribe el objeto entero, así
                # que se conserva el allowed_actions que tenga el repo.
                try {
                    $allowedActions = gh api "repos/$nameWithOwner/actions/permissions" -q '.allowed_actions'
                    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($allowedActions)) { throw 'no se pudo leer la configuración actual de Actions' }
                    gh api --method PUT "repos/$nameWithOwner/actions/permissions" -F enabled=true -f "allowed_actions=$allowedActions" -F sha_pinning_required=true --silent
                    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE" }
                    Write-Ok 'Actions exige acciones fijadas por SHA'
                } catch {
                    Write-Note "no se pudo exigir el fijado por SHA en Actions: $($_.Exception.Message)"
                    Add-ManualStep 'Exigir acciones fijadas por SHA a mano (Settings -> Actions -> General -> "Require actions to be pinned to a full-length commit SHA") — ver la seccion 2.5 (Configurar GitHub) del README.md'
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
                    Add-ManualStep 'Configurar a mano las Workflows nativas del GitHub Project recién creado (Item added/closed, PR merged, Auto-add) — ver checklist de la seccion 2.5 (Configurar GitHub) del README.md'
                } catch {
                    Write-Note "no se pudo crear el GitHub Project automáticamente: $($_.Exception.Message)"
                    Add-ManualStep 'Crear el GitHub Project (Board/Kanban) y vincularlo al repo a mano — ver checklist de la seccion 2.5 (Configurar GitHub) del README.md'
                }
            } catch {
                Write-Note "automatización de GitHub interrumpida: $($_.Exception.Message)"
                Add-ManualStep 'La configuración de rama/branch protection no terminó bien: revisa el estado en GitHub y completa a mano lo que falte (ver la seccion 2.5 (Configurar GitHub) del README.md)'
            }
        }
    }
} else {
    Add-ManualStep 'Completar a mano el checklist de la seccion 2.5 (Configurar GitHub) del README.md (rama dev, branch protection, secret scanning, Dependabot alerts, reporte privado, SHA en Actions, Project) — o relanzar este script con -SetupGitHub'
}

Add-ManualStep 'Fijar Spending limit = $0 en GitHub (Settings -> Billing) — no tiene API/CLI'
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
    Write-Host '  - rama dev y (best-effort) branch protection en dev y main / secret scanning y push protection / Dependabot alerts / private vulnerability reporting / SHA obligatorio en Actions / GitHub Project'
}

Write-Host ''
Write-Host 'Pendiente de revisión/acción humana:' -ForegroundColor Yellow
foreach ($step in $script:ManualSteps) {
    Write-Host "  - $step"
}

Write-Host ''
Write-Host 'Cuando termines, dentro de una sesión de Claude Code en el proyecto ejecuta /context y /doctor para verificar.'

exit 0
