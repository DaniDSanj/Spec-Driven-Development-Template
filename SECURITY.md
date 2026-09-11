# Seguridad

Este fichero **se conserva** en los proyectos creados desde la plantilla SDD, como `LICENSE`: describe
lo que el repositorio ejecuta, qué protege cada capa y qué hacer ante un incidente, y a él remiten
`.githooks/pre-commit` y `.claude/hooks/pre_edit_guard_sensitive.sh`. Adáptalo a tu proyecto en vez de
borrarlo — como mínimo, la sección [Reportar un problema](#reportar-un-problema).

## Qué ejecuta este repositorio en tu máquina

Antes de trabajar en él, conviene que sepas exactamente qué se ejecuta y cuándo. Este repositorio **no
es código pasivo**: al abrir Claude Code en él, `.claude/settings.json` registra hooks que se ejecutan
automáticamente sobre tu máquina.

| Cuándo | Qué se ejecuta | Fichero |
|---|---|---|
| Tras cada `Edit`/`Write` sobre un `.py` | `uv run ruff format` · `ruff check --fix` · `ty check` | `.claude/hooks/post_edit_python_format.sh` |
| Cuando Claude termina de responder | `uv run pytest -q` | `.claude/hooks/stop_run_tests.sh` |
| Antes de cada `Edit`/`Write`/`Read`/`Grep`/`Bash` | Comprobación de ruta; puede bloquear la acción | `.claude/hooks/pre_edit_guard_sensitive.sh` |
| Antes de cada `Edit`/`Write` del subagente `spec-verifier` | Comprobación de ruta; puede bloquear la acción | `.claude/hooks/guard-quickstart-agent.sh` |

Además, si activas la red local con `git config core.hooksPath .githooks`:

| Cuándo | Qué se ejecuta | Fichero |
|---|---|---|
| Antes de cada `commit` | `gitleaks git --pre-commit --staged` sobre lo que está en staging; aborta el commit si encuentra un posible secreto | `.githooks/pre-commit` (config en `.gitleaks.toml`) |
| Antes de cada `push` | `uv run ruff check` · `ruff format --check` · `ty check` · `pytest -q` · `uv export` + `uvx pip-audit` | `.githooks/pre-push` |

Todos son scripts de shell cortos y legibles. **Léelos antes de confiar en ellos**, igual que harías con
cualquier repositorio que configure hooks. Es exactamente el mismo consejo que da la documentación de
Claude Code sobre skills y hooks de proyecto.

## Qué protegen los guards y qué no

`pre_edit_guard_sensitive.sh` bloquea escrituras sobre `migrations/**` y ficheros `.env`, incluidas las
que intentarían rodearlo vía `Bash` (`alembic`, `flyway`, `liquibase`, `dotnet ef migrations`,
`manage.py migrate`, `sed -i`, redirecciones a `.env`).

Bloquea además que el asistente **lea** ficheros `.env` —con `Read`, con `Grep` apuntando a uno, o vía
`Bash` con `cat`, `less`, `more`, `head`, `tail`, `type`, `Get-Content`/`gc`, `grep`, `rg`, `findstr` o
`source`—, porque leerlo mete el secreto en la conversación y de ahí sale de tu máquina.
`.env.example`, `.env.sample` y `.env.template` se pueden leer y escribir siempre: son plantillas.
Las migraciones sí se pueden leer con `Read`/`Grep`.

Es una **red de seguridad, no un sandbox**. Está pensada para evitar que el asistente toque por descuido
superficies de datos de producción o de secretos; no está pensada para contener a un atacante con
capacidad de ejecutar comandos arbitrarios en tu máquina. Los límites conocidos:

- Solo cubre las herramientas `Write`, `Edit`, `Read`, `Grep` y `Bash`. Un MCP server con acceso a
  ficheros no pasa por él.
- Compara rutas por patrón, no resuelve symlinks ni rutas relativas exóticas.
- Solo impide que el contenido de un `.env` llegue a la conversación por las vías directas. No impide
  que un programa que el asistente ejecuta lo lea (la propia app cargando su configuración, un script
  de Python, `grep` recursivo sobre un directorio que contiene un `.env`, un `Grep` con `glob` en vez
  de `path`) ni que ese programa imprima un valor por pantalla.
- Si `jq` no está instalado, el hook **bloquea** en vez de dejar pasar (fail-closed) — pero eso significa
  que sin `jq` el harness no funciona en absoluto. Es intencionado.

## Qué detecta el escaneo de secretos y qué no

Hay tres capas. Las dos primeras usan `gitleaks` con la misma configuración (`.gitleaks.toml`):

- **Local, `.githooks/pre-commit`**: para un secreto **antes** de que entre en el historial, que es el
  único momento en que sacarlo no exige reescribir la historia.
- **CI, paso `Secret scan (gitleaks)` del job `quality`**: escanea **todo el historial** en cada PR y
  cada push a `dev`, corre siempre (antes del gate de `pyproject.toml`/`src/`) y, al ser parte del check
  `quality`, la branch protection impide mergear con un hallazgo. Es la capa obligatoria: no depende
  de que nadie haya activado nada en su máquina. Descarga el binario oficial de `gitleaks` fijado por
  versión y verifica su checksum antes de ejecutarlo.
- **Servidor, secret scanning con push protection de GitHub**: GitHub rechaza el `push` que contiene
  un secreto de un proveedor reconocido, antes de que llegue al repo remoto. `bootstrap.ps1 -SetupGitHub`
  intenta activarlo; es gratis en repos públicos, pero en privados exige GitHub Secret Protection (de
  pago) y, sin él, queda como paso manual. No lee `.gitleaks.toml`: sus patrones son los de GitHub, y
  se puede saltar puntualmente desde la propia interfaz de GitHub, que deja registro de quién lo hizo.

Cuando el CI encuentra algo, el secreto **ya está en GitHub**: trátalo como filtrado (ver
[Si se filtra un secreto](#si-se-filtra-un-secreto)).

Límites de la capa local:

- **Es opcional**: solo actúa si has activado `core.hooksPath` y tienes `gitleaks` instalado. Sin
  `gitleaks`, avisa y deja pasar el commit. `git commit --no-verify` lo salta.
- Si `gitleaks` está instalado pero **falla** (p. ej. un `.gitleaks.toml` con la sintaxis rota), el
  commit se **bloquea** con un mensaje distinto del de "secretos encontrados": se esperaba un escaneo
  y no se ha podido hacer.

Límites comunes a las dos capas de `gitleaks`:

- Detecta patrones conocidos (tokens de proveedores, claves privadas, cadenas de alta entropía). Una
  contraseña corta y sin forma reconocible dentro de una cadena de conexión puede no detectarse.
- `.gitleaks.toml` excluye `.env.example`/`.sample`/`.template` por ruta: un secreto real escrito en
  una de esas plantillas no se detecta.

En un repo **privado sin plan de pago** no hay push protection ni branch protection: quedan el escaneo
local y el del CI, pero nada impide mergear con el check `quality` en rojo.

## Cadena de suministro

- **`ci.yml` corre con el mínimo privilegio**: `permissions: contents: read` a nivel de workflow, y
  `checkout` con `persist-credentials: false`, para que ningún paso posterior herede un token con
  capacidad de escritura.
- **Acciones fijadas por SHA completo**, no por tag: un tag se puede mover a otro commit (es como se
  comprometieron acciones populares en ataques reales); un SHA no. El comentario al lado indica la
  versión. `bootstrap.ps1 -SetupGitHub` activa además la opción del repo que **exige** el fijado por
  SHA, así que un workflow que use una acción por tag falla en vez de ejecutarse.
- **`.github/dependabot.yml`** abre cada mes, si hay novedades, una PR por ecosistema hacia `dev` con
  las actualizaciones de las acciones (nuevos SHA) y de las dependencias `uv`. Cada una pasa `quality`
  y requiere revisión humana: Dependabot propone, no mergea.
- **`pip-audit` en `quality` (y en `pre-push`)** comprueba las dependencias de ejecución de `uv.lock`
  (sin el grupo `dev`) contra la base de datos de vulnerabilidades de PyPI y **bloquea** la PR si
  alguna tiene una CVE conocida. Consecuencia aceptada: una CVE recién publicada puede poner en rojo
  una PR que no tocó dependencias.
- **Dependabot alerts** avisan de vulnerabilidades conocidas en las dependencias. `bootstrap.ps1
  -SetupGitHub` intenta activarlas; si no puede, quedan como paso manual.
- **Herramientas que Dependabot no actualiza**: la versión de `gitleaks` está fijada en `ci.yml` junto
  a su checksum y se actualiza a mano; `pip-audit` se ejecuta con `uvx` en su última versión.

## Análisis estático del código

La skill `dev-python-coding` exige activar las reglas de seguridad `S` de Ruff (port de *bandit*) en
el `pyproject.toml` del proyecto. Ruff ya corre tras cada edición (hook `PostToolUse`), en `pre-push`
y en el job `quality`, así que el código vulnerable —SQL construido con f-strings, `shell=True`,
contraseñas en el código, `yaml.load` inseguro, peticiones sin `timeout`— se señala en el momento de
escribirlo. Es análisis por patrones dentro de cada fichero: no sigue el flujo de datos entre
funciones.

## Si se filtra un secreto

Un secreto que ha llegado a GitHub —aunque sea un momento, aunque el repo sea privado— está
comprometido: los bots que rastrean GitHub encuentran credenciales en minutos, y el historial vive
también en forks, clones y cachés. Borrarlo en un commit nuevo no sirve. El orden es este:

1. **Rotar primero.** Revoca la credencial en el servicio que la emitió y genera una nueva; guárdala
   en `.env`. Es lo único que neutraliza la fuga, y no espera a nada de lo siguiente.
2. **Revisar el uso.** Consulta los logs del servicio afectado (accesos, facturación, cambios) desde
   el momento del push.
3. **Limpiar el historial, si compensa.** Con la credencial ya rotada, el secreto en el historial es
   inofensivo. Si aun así hay que retirarlo (política, datos personales), usa `git filter-repo`,
   coordina el `push --force` con quien tenga clones —deben volver a clonar— y pide a GitHub Support
   que purgue las cachés y las referencias de PRs.
4. **Cerrar el hueco.** Averigua qué capa falló (red local sin activar, `--no-verify`, un patrón que
   `gitleaks` no reconoce) y corrígelo; si es un patrón propio, añádelo como regla en `.gitleaks.toml`.

## Reportar un problema

Si encuentras un fallo de seguridad en este repositorio —un guard que se puede rodear trivialmente, un
hook que ejecuta algo inesperado, código vulnerable, una instrucción que induce a commitear secretos—
**no abras un issue público**. Usa el formulario privado de GitHub: pestaña **Security → Report a
vulnerability** de este repositorio. Requiere que el repo tenga activado *private vulnerability
reporting*, que `bootstrap.ps1 -SetupGitHub` activa en la puesta en marcha.

Para cualquier otro fallo, un issue normal es lo correcto.

Si el fallo está en el andamiaje heredado de la plantilla SDD (los hooks, los guards, `bootstrap.ps1`)
y no en el código propio del proyecto, repórtalo también en el repositorio de la plantilla,
[`DaniDSanj/Spec-Driven-Development-Template`](https://github.com/DaniDSanj/Spec-Driven-Development-Template),
por la misma vía privada.

## Lo que este andamiaje no cubre

Los proyectos generados desde la plantilla SDD heredan el andamiaje, no una auditoría. El `.gitignore`
incluye `.env`, claves y certificados, y backups/dumps de base de datos, y el subagente
`security-reviewer` revisa las superficies sensibles de cada feature antes del cierre — pero la
seguridad del proyecto final es responsabilidad de quien lo escribe.
