# Ejemplo de instalación: Financial-Health-App

Script de ejemplo, listo para copiar y pegar en PowerShell, que ejecuta [`install.ps1`](./install.ps1) sobre el proyecto `Financial-Health-App`. Incluye **todos** los parámetros del script (obligatorios y opcionales) como un hashtable editable, para poder revisarlos y modificarlos antes de lanzarlo.

Documentación completa de cada parámetro (qué rellena, valores válidos, efectos secundarios): `Get-Help .\install.ps1 -Full` desde `Plantilla_Spec-Driven-Development/`, o la cabecera de comentarios del propio script.

```powershell
# Ejecutar desde la raíz de esta plantilla (Plantilla_Spec-Driven-Development/), o ajustar -TemplatePath si no.
$params = @{
    # --- Obligatorios ---
    ProjectPath        = "H:\Mi unidad\Proyectos\Profesional\Financial-Health-App"  # Carpeta del proyecto destino (se crea si no existe)
    ProjectName         = "Financial-Health-App"                                     # Rellena [NOMBRE_PROYECTO] en el prompt de CLAUDE.md y da nombre al repo si se usa -SetupGitHub
    ProjectDescription  = "EDITAR: descripción de una línea del proyecto"            # Rellena [DESCRIPCIÓN_UNA_LÍNEA]

    # --- Opcionales (valor por defecto entre paréntesis) ---
    # TemplatePath      = ""            # Raíz de esta plantilla (por defecto: carpeta padre de install.ps1, no hace falta si se ejecuta desde aquí)
    # NonObviousCommands = ""           # Comandos no evidentes, ej. cómo levantar la BD local (por defecto: queda pendiente de completar a mano)
    PythonVersion       = "3.12"        # Versión de Python (por defecto "3.12")
    DbEngine            = "PostgreSQL"  # PostgreSQL | SQLServer | Ninguno (por defecto "PostgreSQL")
    Visibility          = "private"     # private | public (por defecto "private")
    SpecifyScriptType   = "ps"          # sh | ps | py (por defecto "ps")
    # GitHubOwner       = ""            # Owner/organización de GitHub (solo con -SetupGitHub; por defecto, cuenta autenticada en gh)

    # --- Switches (comentados = desactivados) ---
    # SetupGitHub       = $true         # Crea repo remoto, rama dev, branch protection y GitHub Project (pide confirmación antes de tocar nada remoto)
    # InstallGh         = $true         # Solo con -SetupGitHub: instala gh con winget si falta
    # SkipObsidian      = $true         # Omite el montaje de la estructura del vault de Obsidian (docs/)
    # Force             = $true         # Sobrescribe ficheros/carpetas ya existentes en el destino
}

.\install.ps1 @params
```

Al terminar, el script imprime un checklist con lo que quedó pendiente de revisión humana (generar y revisar `CLAUDE.md`, instalar plugins de Obsidian, crear el GitHub Project si no se usó `-SetupGitHub`, fijar el spending limit, etc.).
