<#
.SYNOPSIS
  Configura en GitHub lo que "Use this template" no deja hecho: rama `dev`, branch protection en
  `dev` y `main`, secret scanning con push protection, Dependabot alerts, private vulnerability
  reporting, exigencia de SHA en Actions y un GitHub Project vinculado.

  Requiere PowerShell 7 o superior (`pwsh`), igual que `bootstrap.ps1`. Windows PowerShell 5.1 no
  sirve: los cuerpos JSON de este script se envían a `gh api --input -` por la tubería, y 5.1 la
  codifica con la página de códigos OEM de la consola en vez de UTF-8.

.DESCRIPTION
  Es la mitad "servidor" de la puesta en marcha, separada a propósito de `bootstrap.ps1`:

  - Tiene otros prerrequisitos. Aquí solo hacen falta `git` y `gh`; nada de `uv`, `specify`, `bash`
    ni `jq`, que `bootstrap.ps1` sí exige y sin los que aborta.
  - Tiene otro ciclo de vida. Rellenar el perfil o ejecutar `specify init` se hace una vez; la
    configuración de GitHub se **reaplica**: alguien desactiva un ajuste a mano, se añade un check
    requerido al CI, cambia la visibilidad del repo. Este script está pensado para volver a
    ejecutarse tantas veces como haga falta.

  Todo lo que hace es idempotente: comprueba antes de crear, y los `PUT` de configuración dejan el
  mismo estado si ya estaban aplicados. Cada bloque va en su propio `try/catch` (best-effort): un
  fallo esperable —branch protection y push protection no están disponibles en repos privados sin
  plan de pago— se anota en el checklist final como paso manual en vez de abortar el resto.

  No commitea, no pushea y no hace checkout de nada. Solo actúa sobre el repositorio remoto; el
  contenido del árbol de trabajo es cosa tuya.

  `bootstrap.ps1 -SetupGitHub` invoca este mismo script, así que la puesta en marcha completa sigue
  siendo un solo comando.

.PARAMETER ProjectName
  Título del GitHub Project que se crea y vincula al repo. Si se omite, se usa el nombre del propio
  repositorio.

.PARAMETER SkipProject
  No crea ni vincula el GitHub Project. Útil al reaplicar la configuración sobre un repo que ya
  tiene su tablero (`gh project create` no es idempotente: crearía un tablero duplicado).

.PARAMETER Yes
  Salta la confirmación interactiva. Pensado para reaplicar la configuración sin supervisión, una
  vez ya sabes lo que hace.

.PARAMETER KeepDefaultBranch
  No cambia la rama por defecto del repositorio. En un repositorio marcado como *template* el script
  ya lo hace solo: "Use this template" copia únicamente la rama por defecto, así que una plantilla
  cuya rama por defecto fuera `dev` generaría repos cliente sin `main` en absoluto. Este parámetro
  está para el resto de casos en los que quieras conservar la rama por defecto que ya tiene el repo.

.PARAMETER InstallGh
  Si falta `gh` (GitHub CLI), lo instala con winget antes de continuar. La autenticación
  (`gh auth login`) sigue siendo manual por naturaleza (login por navegador): si tras instalar `gh`
  no está autenticado, el script se detiene con instrucciones en vez de continuar.

.NOTES
  Requiere `gh` autenticado con permisos de administrador sobre el repo. Para crear el GitHub
  Project hace falta además el scope `project`: `gh auth refresh -s project`.

.EXAMPLE
  # Puesta en marcha de un repo recién creado desde la plantilla:
  pwsh -File .\setup-github.ps1 -ProjectName "mi-app"

.EXAMPLE
  # Reaplicar la configuración sobre un repo que ya tiene tablero, sin preguntar:
  pwsh -File .\setup-github.ps1 -SkipProject -Yes
#>

# Va DESPUÉS del bloque de ayuda a propósito: un #Requires por delante de él impide que `Get-Help
# .\setup-github.ps1 -Full` reconozca la ayuda basada en comentarios y solo devuelva la sintaxis.
#Requires -Version 7.0

[CmdletBinding()]
param(
    [string]$ProjectName = '',

    [switch]$SkipProject,

    [switch]$Yes,

    [switch]$KeepDefaultBranch,

    [switch]$InstallGh
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Utilidades
#
# Duplicadas a propósito de bootstrap.ps1: son cuarenta líneas de impresión por consola, y
# compartirlas obligaría a un tercer fichero que ambos tendrían que dot-sourcear y que cada proyecto
# downstream heredaría sin saber para qué sirve.
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
    param([string]$Name)
    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Ok $Name
        return $true
    }
    Write-Host "  [FALTA] $Name (obligatorio)" -ForegroundColor Red
    return $false
}

# ---------------------------------------------------------------------------
# Paso 0 — Prerrequisitos
# ---------------------------------------------------------------------------

Write-Section 'Paso 0: prerrequisitos'

if (-not (Test-Prereq 'git')) {
    Write-Host ''
    Write-Host 'Instala git (https://git-scm.com/downloads) y vuelve a ejecutar el script.' -ForegroundColor Red
    exit 1
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    Write-Host ''
    Write-Host 'Este directorio no está dentro de un repositorio git. Ejecuta el script desde el repo ya creado con "Use this template" y clonado localmente.' -ForegroundColor Red
    exit 1
}

$hasGh = Test-Prereq 'gh'

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
    # Refresca el PATH de esta sesión con el valor ya actualizado en el registro, para no depender de
    # abrir una terminal nueva (winget no propaga el PATH al proceso que lo invocó).
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machinePath + ';' + $userPath
    $hasGh = Test-Prereq 'gh'
}

if (-not $hasGh) {
    Write-Host ''
    Write-Host 'Falta gh (GitHub CLI).' -ForegroundColor Red
    Write-Host '  Instálalo tú (https://cli.github.com/) o relanza el script añadiendo -InstallGh.'
    exit 1
}

gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'gh no está autenticado. Ejecuta `gh auth login` (requiere navegador) y vuelve a lanzar el script.' -ForegroundColor Red
    exit 1
}
Write-Ok 'gh autenticado'

$nameWithOwner = gh repo view --json nameWithOwner -q .nameWithOwner
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nameWithOwner)) {
    Write-Host ''
    Write-Host 'No se pudo determinar el repositorio remoto (owner/repo). ¿Tiene este clon un remoto "origin" en GitHub?' -ForegroundColor Red
    exit 1
}
$owner = ($nameWithOwner -split '/')[0]
$repoName = ($nameWithOwner -split '/')[1]

# "Use this template" copia únicamente la rama por defecto del repositorio origen. Si la rama por
# defecto de una plantilla fuera 'dev', cada repo cliente nacería con una sola rama y sin 'main', y
# este mismo script no tendría desde dónde crear 'dev'. Por eso en un repositorio marcado como
# template no se toca nunca la rama por defecto.
$isTemplate = (gh api "repos/$nameWithOwner" -q '.is_template') -eq 'true'
if ($isTemplate) { $KeepDefaultBranch = $true }

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = $repoName
}

Write-Host "Repositorio objetivo: $nameWithOwner"

# Este script no publica nada: si quedan cambios sin commitear, avisa pero sigue — la configuración
# que aplica es del lado del servidor y no depende del árbol de trabajo.
$dirty = git status --porcelain
if ($dirty) {
    Write-Note 'hay cambios sin commitear en el árbol de trabajo; este script no los commitea ni los publica'
    Add-ManualStep 'Commitear y publicar los cambios pendientes del árbol de trabajo (este script solo configura el repositorio remoto)'
}

# ---------------------------------------------------------------------------
# Confirmación
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host "Esto va a, sobre '$nameWithOwner':" -ForegroundColor Yellow
if ($KeepDefaultBranch) {
    Write-Host "  - crear la rama 'dev' desde 'main' (por API) si aún no existe, sin tocar la rama por defecto"
} else {
    Write-Host "  - crear la rama 'dev' desde 'main' (por API) si aún no existe, y marcarla como rama por defecto"
}
Write-Host "  - intentar activar branch protection en 'dev' y 'main'"
Write-Host "  - intentar activar secret scanning y push protection, y las Dependabot alerts"
Write-Host "  - intentar activar private vulnerability reporting y exigir acciones fijadas por SHA"
if (-not $SkipProject) {
    Write-Host "  - crear un GitHub Project titulado '$ProjectName' y vincularlo al repo"
}

if ($Yes) {
    Write-Skip 'confirmación saltada (-Yes)'
} else {
    $confirm = Read-Host '¿Continuar? (s/N)'
    if ($confirm -ine 's') {
        Write-Host ''
        Write-Skip 'cancelado por el usuario; no se ha tocado nada'
        exit 0
    }
}

# ---------------------------------------------------------------------------
# Paso 1 — Rama dev
# ---------------------------------------------------------------------------

Write-Section 'Paso 1: rama dev'

try {
    $devExists = $false
    try {
        gh api "repos/$nameWithOwner/branches/dev" --silent 2>$null
        $devExists = ($LASTEXITCODE -eq 0)
    } catch {
        $devExists = $false
    }

    if ($devExists) {
        Write-Skip "la rama 'dev' ya existe en el remoto"
    } else {
        # Se crea por API, no con `git checkout -b` + push: así el script no depende del estado del
        # árbol de trabajo ni hace checkout de nada (una operación que en un repo alojado en una
        # unidad sincronizada en la nube puede fallar a mitad).
        $mainSha = gh api "repos/$nameWithOwner/git/ref/heads/main" -q '.object.sha'
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mainSha)) {
            throw "no se pudo leer el SHA de 'main' en el remoto"
        }
        gh api "repos/$nameWithOwner/git/refs" -X POST -f ref='refs/heads/dev' -f sha="$mainSha" --silent
        if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE al crear refs/heads/dev" }
        Write-Ok "rama 'dev' creada en el remoto desde 'main'"
    }

    # Trae la rama recién creada al clon local sin cambiar de rama.
    git fetch origin --quiet
    if ($LASTEXITCODE -ne 0) { Write-Note 'git fetch origin falló; la rama dev existe en el remoto pero no se ha traído al clon local' }
} catch {
    Write-Note "no se pudo asegurar la rama 'dev': $($_.Exception.Message)"
    Add-ManualStep "Crear la rama 'dev' desde 'main' a mano y volver a ejecutar este script"
}

if ($KeepDefaultBranch) {
    if ($isTemplate) {
        Write-Skip "repositorio marcado como template: no se toca la rama por defecto ('Use this template' solo copia esa rama, y con 'dev' por defecto los repos cliente nacerían sin 'main')"
    } else {
        Write-Skip '-KeepDefaultBranch: no se toca la rama por defecto'
    }
} else {
    try {
        gh repo edit $nameWithOwner --default-branch dev
        if ($LASTEXITCODE -ne 0) { throw "gh repo edit devolvió el código $LASTEXITCODE" }
        Write-Ok "'dev' marcada como rama por defecto"
    } catch {
        Write-Note "no se pudo marcar 'dev' como rama por defecto: $($_.Exception.Message)"
        Add-ManualStep "Marcar 'dev' como rama por defecto a mano (Settings -> Branches -> Default branch)"
    }
}

# ---------------------------------------------------------------------------
# Paso 2 — Branch protection
# ---------------------------------------------------------------------------

Write-Section 'Paso 2: branch protection'

# Modelo documentado por la skill git-update-repo. Igual en 'dev' y 'main' salvo dos cosas:
#
# - strict (rama al día con la base) solo en 'dev': a 'main' solo llega 'dev' por PR, y cada merge
#   deja en 'main' un commit sin contenido que 'dev' no tiene; con strict en 'main' habría que abrir
#   una PR 'main' -> 'dev' antes de cada integración.
# - source-branch-gate solo se exige en 'main': es el job de ci.yml que hace cumplir "a main solo se
#   llega desde dev". GitHub no tiene un ajuste nativo para restringir la rama origen de una PR.
#
# enforce_admins = $true es lo que hace que la rama de feature sea obligatoria de verdad (el push
# directo a 'dev' falla incluso siendo owner). required_approving_review_count = 0: PR obligatoria,
# pero sin aprobación de un tercero, o en un repo de una sola persona 'main' quedaría bloqueado.
$branchContexts = [ordered]@{
    'dev'  = @('quality')
    'main' = @('quality', 'source-branch-gate')
}

foreach ($branch in $branchContexts.Keys) {
    $contexts = $branchContexts[$branch]
    $strict = ($branch -eq 'dev')

    $protectionBody = @{
        required_status_checks           = @{ strict = $strict; contexts = $contexts }
        enforce_admins                   = $true
        required_pull_request_reviews    = @{
            required_approving_review_count = 0
            dismiss_stale_reviews           = $true
        }
        restrictions                     = $null
        # Ya son false por omisión en la API, pero se envían explícitos: documentan la intención y
        # sobreviven a un PUT futuro que reescriba el objeto entero.
        allow_force_pushes               = $false
        allow_deletions                  = $false
        required_conversation_resolution = $true
    } | ConvertTo-Json -Depth 5

    try {
        $protectionBody | gh api --method PUT "repos/$nameWithOwner/branches/$branch/protection" --input - | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE (branch protection no suele estar disponible en repos privados sin GitHub Pro/Team)" }

        # Un PUT aceptado no garantiza el estado: se relee antes de darlo por hecho.
        $actual = gh api "repos/$nameWithOwner/branches/$branch/protection" | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'no se pudo releer la protección aplicada para verificarla' }

        $problems = New-Object System.Collections.Generic.List[string]
        if (-not $actual.enforce_admins.enabled) { $problems.Add('enforce_admins') | Out-Null }
        if (-not $actual.required_conversation_resolution.enabled) { $problems.Add('required_conversation_resolution') | Out-Null }
        if ($actual.required_status_checks.strict -ne $strict) { $problems.Add('required_status_checks.strict') | Out-Null }
        $actualContexts = @($actual.required_status_checks.contexts) | Sort-Object
        if (($actualContexts -join ',') -ne (($contexts | Sort-Object) -join ',')) { $problems.Add('required_status_checks.contexts') | Out-Null }

        if ($problems.Count -gt 0) {
            throw "GitHub aceptó la petición pero estos ajustes no quedaron como se pidió: $($problems -join ', ')"
        }

        Write-Ok "branch protection verificada en '$branch' (checks: $($contexts -join ', '))"
    } catch {
        $strictText = if ($strict) { 'activado' } else { 'desactivado' }
        Write-Note "no se pudo aplicar branch protection en '$branch': $($_.Exception.Message)"
        Add-ManualStep "Activar branch protection en '$branch' a mano (Settings -> Branches): checks requeridos [$($contexts -join ', ')], strict $strictText, enforce admins, resolución de conversaciones obligatoria — ver la seccion 2.5 (Configurar GitHub) del README.md"
    }
}

# ---------------------------------------------------------------------------
# Paso 3 — Seguridad del repositorio
# ---------------------------------------------------------------------------

Write-Section 'Paso 3: seguridad del repositorio'

# Secret scanning + push protection: la capa de servidor del escaneo de secretos (ver SECURITY.md) —
# GitHub rechaza el push aunque nadie tenga la red local activada. Gratis en repos públicos; en
# privados exige GitHub Secret Protection, así que un fallo aquí es esperable y queda como paso manual.
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

# Dependabot alerts: avisan de CVEs en las dependencias. Las PRs de actualización las define
# .github/dependabot.yml, que ya viene en el repo; esto solo enciende las alertas.
try {
    gh api --method PUT "repos/$nameWithOwner/vulnerability-alerts" --silent
    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE" }
    Write-Ok 'Dependabot alerts activadas'
} catch {
    Write-Note "no se pudieron activar las Dependabot alerts: $($_.Exception.Message)"
    Add-ManualStep 'Activar Dependabot alerts a mano (Settings -> Advanced Security -> Dependabot alerts) — ver la seccion 2.5 (Configurar GitHub) del README.md'
}

# Private vulnerability reporting: el canal privado al que remite la sección "Reportar un problema"
# de SECURITY.md. Sin él, el formulario Security -> Report a vulnerability no existe.
try {
    gh api --method PUT "repos/$nameWithOwner/private-vulnerability-reporting" --silent
    if ($LASTEXITCODE -ne 0) { throw "gh api devolvió el código $LASTEXITCODE" }
    Write-Ok 'private vulnerability reporting activado'
} catch {
    Write-Note "no se pudo activar private vulnerability reporting: $($_.Exception.Message)"
    Add-ManualStep 'Activar private vulnerability reporting a mano (Settings -> Advanced Security) — ver la seccion 2.5 (Configurar GitHub) del README.md'
}

# Exigir acciones fijadas por SHA: ci.yml ya lo cumple; esto impide que una acción añadida después
# con @tag llegue a ejecutarse. PUT sobrescribe el objeto entero, así que se conserva el
# allowed_actions que tenga el repo.
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

# ---------------------------------------------------------------------------
# Paso 4 — GitHub Project
# ---------------------------------------------------------------------------

Write-Section 'Paso 4: GitHub Project'

if ($SkipProject) {
    # `gh project create` no es idempotente: sin este flag, reaplicar la configuración crearía un
    # tablero duplicado cada vez.
    Write-Skip '-SkipProject: no se crea ni se vincula ningún tablero'
} else {
    try {
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
}

Add-ManualStep 'Fijar Spending limit = $0 en GitHub (Settings -> Billing) — no tiene API/CLI'

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------

Write-Section 'Resumen'

Write-Host 'Pendiente de revisión/acción humana:' -ForegroundColor Yellow
foreach ($step in $script:ManualSteps) {
    Write-Host "  - $step"
}

Write-Host ''
Write-Host 'Verifica el estado real con:'
Write-Host "  gh api repos/$nameWithOwner/branches/dev/protection"
Write-Host "  gh api repos/$nameWithOwner/branches/main/protection"

exit 0
