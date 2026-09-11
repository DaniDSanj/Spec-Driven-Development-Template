# Ejemplo de bootstrap: Nombre-Proyecto

Supone que ya creaste el repositorio `Nombre-Proyecto` a partir de esta plantilla (botón "Use this template" en GitHub, o `gh repo create Nombre-Proyecto --template DaniDSanj/Spec-Driven-Development-Template --clone`) y lo tienes clonado localmente.

Script de ejemplo, listo para copiar y pegar en **PowerShell 7 (`pwsh`)**, que ejecuta [`bootstrap.ps1`](./bootstrap.ps1) **desde la raíz de ese repositorio ya clonado** (no desde la plantilla). Incluye **todos** los parámetros del script (obligatorios y opcionales) como un hashtable editable, para poder revisarlos y modificarlos antes de lanzarlo.

> **PowerShell 7 o superior, no Windows PowerShell 5.1.** El script lo declara con `#Requires -Version 7.0` y se detendrá solo si lo lanzas con `powershell.exe`. Si no tienes `pwsh`: `winget install Microsoft.PowerShell`.

Documentación completa de cada parámetro (qué rellena, valores válidos, efectos secundarios): `Get-Help .\bootstrap.ps1 -Full`, o la cabecera de comentarios del propio script.

```powershell
# Ejecutar con pwsh desde la raíz de Nombre-Proyecto (el repo creado desde la plantilla, no la plantilla misma).
$params = @{
    # --- Obligatorios ---
    ProjectName         = "Nombre-Proyecto"                                          # Rellena [NOMBRE_PROYECTO] en .claude/context/00_perfil_proyecto.md y se usa para nombrar el GitHub Project si se usa -SetupGitHub
    ProjectDescription  = "EDITAR: descripción de una línea del proyecto"            # Rellena [DESCRIPCIÓN_UNA_LÍNEA] en el perfil del proyecto

    # --- Opcionales (valor por defecto entre paréntesis) ---
    # NonObviousCommands = ""           # Comandos no evidentes, ej. cómo levantar la BD local (por defecto: queda pendiente de completar a mano)
    # PythonVersion      = "3.14.7"     # Sin default: si se omite, el placeholder queda intacto y el checklist final lo recuerda (el perfil declara como default "la última estable")
    DbEngine            = "PostgreSQL"  # PostgreSQL | SQLServer | Ninguno (por defecto "PostgreSQL")
    Visibility          = "private"     # private | public (por defecto "private")
    SpecifyScriptType   = "ps"          # sh | ps | py (por defecto "ps")

    # --- Switches (comentados = desactivados) ---
    # SetupGitHub       = $true         # Completa en el repo remoto lo que "Use this template" no hace: rama dev, branch protection, secret scanning con push protection, Dependabot alerts, GitHub Project (pide confirmación antes de tocar nada remoto)
    # InstallGh         = $true         # Solo con -SetupGitHub: instala gh con winget si falta
}

.\bootstrap.ps1 @params
```

Al terminar, el script imprime un checklist con lo que quedó pendiente de revisión humana (generar y revisar `CLAUDE.md`, completar los campos del perfil sin default, instalar plugins de Obsidian, crear el GitHub Project si no se usó `-SetupGitHub`, fijar el spending limit, activar la red local de `.githooks/` —`pre-commit` con `gitleaks` y `pre-push`—, instalar `gitleaks` si falta, etc.).
