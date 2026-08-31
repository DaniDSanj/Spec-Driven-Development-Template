# Ejemplo de bootstrap: Nombre-Proyecto

Supone que ya creaste el repositorio `Nombre-Proyecto` a partir de esta plantilla (botón "Use this template" en GitHub, o `gh repo create Nombre-Proyecto --template <owner>/Spec-Driven-Development-Template --clone`) y lo tienes clonado localmente.

Script de ejemplo, listo para copiar y pegar en PowerShell, que ejecuta [`bootstrap.ps1`](./bootstrap.ps1) **desde la raíz de ese repositorio ya clonado** (no desde la plantilla). Incluye **todos** los parámetros del script (obligatorios y opcionales) como un hashtable editable, para poder revisarlos y modificarlos antes de lanzarlo.

Documentación completa de cada parámetro (qué rellena, valores válidos, efectos secundarios): `Get-Help .\bootstrap.ps1 -Full`, o la cabecera de comentarios del propio script.

```powershell
# Ejecutar desde la raíz de Nombre-Proyecto (el repo creado desde la plantilla, no la plantilla misma).
$params = @{
    # --- Obligatorios ---
    ProjectName         = "Nombre-Proyecto"                                          # Rellena [NOMBRE_PROYECTO] en el prompt de CLAUDE.md y se usa para nombrar el GitHub Project si se usa -SetupGitHub
    ProjectDescription  = "EDITAR: descripción de una línea del proyecto"            # Rellena [DESCRIPCIÓN_UNA_LÍNEA]

    # --- Opcionales (valor por defecto entre paréntesis) ---
    # NonObviousCommands = ""           # Comandos no evidentes, ej. cómo levantar la BD local (por defecto: queda pendiente de completar a mano)
    PythonVersion       = "3.12"        # Versión de Python (por defecto "3.12")
    DbEngine            = "PostgreSQL"  # PostgreSQL | SQLServer | Ninguno (por defecto "PostgreSQL")
    Visibility          = "private"     # private | public (por defecto "private")
    SpecifyScriptType   = "ps"          # sh | ps | py (por defecto "ps")

    # --- Switches (comentados = desactivados) ---
    # SetupGitHub       = $true         # Completa en el repo remoto lo que "Use this template" no hace: rama dev, branch protection, GitHub Project (pide confirmación antes de tocar nada remoto)
    # InstallGh         = $true         # Solo con -SetupGitHub: instala gh con winget si falta
    # Force             = $true         # Sobrescribe ficheros ya modificados a mano
}

.\bootstrap.ps1 @params
```

Al terminar, el script imprime un checklist con lo que quedó pendiente de revisión humana (generar y revisar `CLAUDE.md`, instalar plugins de Obsidian, crear el GitHub Project si no se usó `-SetupGitHub`, fijar el spending limit, etc.).
