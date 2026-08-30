# Guía completa: cómo configurar un proyecto en Claude Code desde cero

**Perfil objetivo:** primer contacto con Claude Code · Windows · Python + SQL como base, web como área en aprendizaje · integración con GitHub y con Notion/Obsidian.

Esta guía está organizada en fases. No hace falta que hagas todo el primer día: las primeras secciones son las imprescindibles para empezar; el resto lo vas incorporando según lo necesites.

---

## Índice

0. Conceptos previos (qué es Claude Code y por qué importa el "contexto")
1. Instalación y primer arranque en Windows
2. CLI vs extensión de VS Code: cómo trabajar realmente
3. Estructura de carpetas de un proyecto bien planteado
4. `CLAUDE.md`: el documento más importante que vas a escribir
5. `.claudeignore`: proteger tu presupuesto de tokens
6. Permisos, Plan Mode y Checkpoints: trabajar con red de seguridad
7. Integración con GitHub
8. Integración con Notion y con Obsidian (comparativa + configuración)
9. Ejemplo práctico paso a paso: API + base de datos SQL + web
10. Buenas prácticas para minimizar el gasto de tokens
11. Flujo de trabajo diario recomendado (resumen)

---

## 0. Conceptos previos

Antes de tocar nada, tres ideas que lo cambian todo si las entiendes desde el principio:

- **Claude Code no es un autocompletado.** Es un agente que vive en tu terminal, lee tus archivos cuando los necesita (no hace falta que se los "subas" tú), propone cambios, y te pide permiso antes de modificar nada. Piensa en él como un compañero de equipo junior muy rápido, no como un plugin del editor.
- **Todo lo que Claude "sabe" en una sesión vive en la ventana de contexto.** Cuantos más archivos lee, más larga es la conversación, más "peso" tiene que cargar en cada respuesta. Esto se traduce directamente en coste (tokens) y, pasado cierto punto, en pérdida de precisión. Por eso buena parte de las "buenas prácticas" de esta guía giran en torno a **decirle a Claude solo lo que necesita saber, cuando lo necesita**.
- **`CLAUDE.md` es la pieza central.** Es un archivo que Claude lee automáticamente al empezar cada sesión en tu proyecto. Ahí van tus convenciones, comandos habituales y reglas — no tu documentación entera.

---

## 1. Instalación y primer arranque en Windows

Tienes dos vías. Como Git for Windows habilita que Claude Code use Bash como herramienta de shell (más fiable para tareas de desarrollo), te recomiendo instalarlo si no lo tienes ya.

**Paso 1 — Instalar Git para Windows** (si no lo tienes):
Descárgalo de [git-scm.com/downloads/win](https://git-scm.com/downloads/win) e instálalo con las opciones por defecto.

**Paso 2 — Instalar Claude Code.** Abre PowerShell y ejecuta:

```powershell
irm https://claude.ai/install.ps1 | iex
```

> Si ves el error `'irm' is not recognized`, estás en CMD en lugar de PowerShell. En CMD usarías en su lugar:
> `curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd`

Esta instalación nativa se actualiza sola en segundo plano; no tendrás que reinstalar manualmente.

**Paso 3 — Autenticarte.** En cualquier carpeta, escribe:

```powershell
claude
```

Te pedirá iniciar sesión (se abre el navegador). Si ya pagas Claude Pro o Max, esa suscripción ya incluye Claude Code — no necesitas nada adicional. Una vez logueado, las credenciales quedan guardadas.

**Paso 4 — Verificar que funciona.** Sitúate dentro de una carpeta de proyecto (o crea una vacía) y lanza:

```powershell
cd C:\ruta\a\tu\proyecto
claude
```

Dentro de la sesión, prueba:

```
what does this project do?
```

Si el proyecto está vacío, te lo dirá. Es normal — aún no hay nada que analizar.

> **Nota sobre cuota:** el límite de uso de tu plan (Pro/Max) se mide en una ventana móvil de 5 horas y **se comparte entre claude.ai y Claude Code**. Si has tenido conversaciones largas aquí en el chat, tu cuota disponible para Claude Code en las horas siguientes será proporcionalmente menor. Tenlo en cuenta si vas a alternar mucho entre ambos.

---

## 2. CLI vs extensión de VS Code: cómo trabajar realmente

Esta es la duda más habitual al empezar, así que merece su propia sección.

**No son dos herramientas distintas.** La extensión de VS Code usa por debajo el mismo CLI — solo que empaqueta una copia propia para su panel de chat. La diferencia está en la experiencia, no en el motor:

| | **CLI en terminal** | **Extensión de VS Code** |
|---|---|---|
| Funciones disponibles | Todas, y las recibe primero | Un subconjunto — va un paso por detrás en novedades |
| Comandos slash completos | Sí | Sí, pero con retraso frente al CLI |
| Multi-repo (`/add-dir`) | Sí | No |
| Revisión de diffs | Texto en terminal | Panel visual lado a lado — mucho más cómodo |
| Checkpoints (deshacer a un punto anterior) | `/rewind` | Botón "rewind" al pasar el ratón sobre un mensaje |
| Curva de aprendizaje | Algo más árida al principio | Más intuitiva, se siente como un chat |
| Fiabilidad reportada | Muy estable | Más reportes de bugs de PATH/login |

**Detalle importante:** instalar la extensión **no** te da el comando `claude` en la terminal. Son instalaciones separadas — necesitas el CLI standalone (el que instalaste en la Sección 1) para poder escribir `claude` en cualquier terminal, incluida la integrada de VS Code.

### Mi recomendación para tu perfil

1. **Instala también la extensión** de VS Code (`Ctrl+Shift+X` → busca "Claude Code" → instalar). Es gratis y comparte historial con el CLI.
2. **Trabaja con el CLI dentro de la terminal integrada de VS Code** (`Ctrl+` `` para abrirla) como forma principal. Así tienes el editor y el agente en la misma ventana, sin renunciar a ninguna función del CLI.
3. **Usa el panel de la extensión para revisar diffs y para preguntas rápidas** mientras editas — ahí gana claramente por comodidad visual, especialmente útil mientras aprendes web y quieres ver el cambio resaltado línea a línea antes de aceptarlo.
4. Si empiezas una conversación en el panel y quieres continuarla en el CLI (o al revés), usa `claude --resume`: comparten el mismo historial, no pierdes nada.

En resumen: no es "CLI o extensión", es **CLI dentro de la terminal integrada de VS Code + panel de la extensión como complemento visual**. Es la combinación que tanto la documentación oficial como la comunidad señalan como la más productiva, y encaja bien con tu perfil porque no renuncias a funciones mientras conservas el apoyo visual que ayuda al aprender una tecnología nueva.

---

## 3. Estructura de carpetas de un proyecto bien planteado

Antes de escribir una sola línea de código, monta el esqueleto. Esto no es opcional si quieres que Claude Code sea eficiente: una estructura clara reduce drásticamente cuánto tiene que "explorar" Claude para entender dónde está cada cosa, y por tanto cuántos tokens gasta orientándose.

```
mi-proyecto/
├── .git/
├── .claude/
│ ├── settings.json # permisos y configuración del proyecto
│ └── commands/ # comandos personalizados (opcional, más adelante)
├── .claudeignore # qué NO debe leer Claude nunca
├── .gitignore
├── .env # secretos — nunca se commitea
├── CLAUDE.md # el "manual de instrucciones" del proyecto
├── docs/
│ ├── architecture.md # detalle que CLAUDE.md solo referencia
│ └── database-schema.md
├── src/ # código de la app
│ ├── api/
│ ├── db/
│ └── web/
├── tests/
└── README.md
```

**Por qué esta estructura importa para el coste de tokens:** `CLAUDE.md` se carga en *cada* sesión, siempre. Si metes ahí toda la documentación técnica, pagas ese peso en cada arranque aunque esa sesión no la necesite. La estrategia correcta es: `CLAUDE.md` corto y con enlaces a `docs/`, y Claude solo abre esos documentos largos cuando la tarea realmente los requiere.

---

## 4. `CLAUDE.md`: el documento más importante que vas a escribir

### Cómo generarlo

No lo escribas desde cero. Dentro de una sesión de Claude Code, en la raíz de tu proyecto, ejecuta:

```
/init
```

Esto analiza tu código (si ya existe algo) y te genera un `CLAUDE.md` inicial detectando gestor de dependencias, framework de tests, etc. Lo tomas como punto de partida y lo vas afinando.

### Reglas de oro

- **Corto.** La recomendación de la propia documentación y de la comunidad ronda las ~100 líneas. Es un archivo que se carga siempre, no un wiki.
- **Nada de secretos aquí.** Ni tokens, ni claves de API, ni contraseñas de base de datos. Van en `.env` (y `.env` va en `.gitignore`).
- **Incluye:** comandos de terminal habituales (cómo levantar el entorno, cómo correr tests), convenciones de estilo de código, y reglas de flujo de trabajo (por ejemplo, "commits pequeños, uno por archivo cambiado").
- **Incluye una sección de "no hagas esto".** Los antipatrones prohibidos funcionan tan bien como las reglas positivas.
- **Actualízalo cuando corrijas a Claude.** Regla del propio creador de Claude Code: cada vez que Claude se equivoque y tú lo corrijas, añade una línea a `CLAUDE.md` para que el error no se repita. Con el tiempo se convierte en la memoria institucional del proyecto.
- **Para documentación extensa, no la pegues entera: referencia el archivo.** Ejemplo: `"Al trabajar con la base de datos, lee primero docs/database-schema.md"`. Claude solo abrirá ese archivo cuando la tarea lo requiera — así no pagas ese contexto en sesiones donde no hace falta.

### Ejemplo mínimo de `CLAUDE.md`

```markdown
# Proyecto: Gestor de tareas (API + SQL + Web)

## Stack
- Backend: Python 3.12, FastAPI
- Base de datos: PostgreSQL, acceso vía SQLAlchemy
- Frontend: HTML/CSS + JS simple (sin framework todavía)

## Comandos habituales
- Levantar entorno: `poetry install && poetry shell`
- Arrancar API: `uvicorn src.api.main:app --reload`
- Tests: `pytest -q`
- Migraciones DB: `alembic upgrade head`

## Convenciones
- Todas las funciones públicas llevan type hints.
- Los endpoints devuelven siempre un modelo Pydantic, nunca un dict suelto.
- SQL: preferir queries parametrizadas, nunca f-strings para construir SQL.

## No hacer
- No instalar dependencias nuevas sin preguntar primero.
- No modificar `alembic/versions/` a mano.
- No hacer commit directo a `main`: siempre rama + PR.

## Contexto adicional (leer solo si aplica)
- Esquema de base de datos: docs/database-schema.md
- Decisiones de arquitectura: docs/architecture.md
```

---

## 5. `.claudeignore`: proteger tu presupuesto de tokens

Funciona igual que `.gitignore`, pero le dice a Claude Code qué carpetas o archivos **no debe leer ni indexar nunca**. Es tu herramienta principal para mantener fuera del contexto tanto archivos irrelevantes (que solo consumen tokens) como archivos sensibles.

```
# .claudeignore
node_modules/
.venv/
__pycache__/
*.log
data/raw/ # datasets pesados, Claude no necesita leerlos entero
.env
secrets/
```

No cuesta nada ser generoso aquí: todo lo que no necesitas que Claude toque, ignóralo.

---

## 6. Permisos, Plan Mode y Checkpoints: trabajar con red de seguridad

Como esta es tu primera vez con un agente que puede modificar archivos y ejecutar comandos por su cuenta, estas tres funciones son las que te dan tranquilidad mientras coges confianza. Merece la pena dominarlas desde el principio.

### Permisos: por defecto, Claude pregunta

Por defecto, Claude Code pide tu aprobación antes de cualquier acción que modifique tu sistema: escribir archivos, ejecutar comandos de terminal, usar herramientas MCP. Es seguro pero, en sesiones largas, cansa aprobar todo uno a uno. Tienes tres formas de reducir esas interrupciones sin perder el control:

- **`Shift+Tab`** dentro de una sesión, para ciclar entre modos de permiso (por ejemplo, pasar a un modo donde acepta ediciones automáticamente).
- **`/permissions`**, para crear una lista blanca de comandos concretos que no necesitan tu aprobación cada vez (por ejemplo, `pytest` sí, `rm -rf` nunca).
- **`/sandbox`**, para aislamiento a nivel de sistema operativo — Claude puede trabajar con más libertad porque está limitado a un entorno contenido.

**Para tus primeras semanas, te recomiendo dejar el modo por defecto** (pregunta antes de cada acción) y solo pasar a un modo más permisivo cuando ya reconozcas el patrón de qué tipo de cambios propone Claude en tu proyecto.

### Plan Mode: pedir el plan antes de ejecutar

Es exactamente la práctica que ya vimos en el ejemplo práctico (Sección 9): pedirle a Claude que primero te explique cómo va a abordar una tarea, sin tocar código, y solo dar luz verde después. Claude Code tiene un modo dedicado a esto — actívalo también con `Shift+Tab` para entrar en modo "plan". Es la forma más barata (en tokens y en errores) de evitar que Claude construya sobre una base que no encaja con lo que querías.

### Checkpoints: tu botón de deshacer

Antes de cada cambio, Claude Code guarda automáticamente el estado de tu código. Si algo no salió como esperabas:

- En el **CLI**: pulsa `Esc` dos veces, o usa `/rewind`, para volver a un punto anterior. Puedes elegir si restauras solo el código, solo la conversación, o ambos.
- En la **extensión de VS Code**: pasa el ratón sobre cualquier mensaje anterior y aparece el botón de rebobinar, con tres opciones (bifurcar conversación, revertir código, o ambas).

**Importante:** los checkpoints cubren los cambios que hace Claude, no los tuyos manuales ni comandos de bash con efectos externos (como escribir en una base de datos real). Por eso siguen siendo imprescindibles el control de versiones con Git y, para tu proyecto de ejemplo, no apuntar nunca estas pruebas contra una base de datos de producción.

---

## 7. Integración con GitHub

Tienes dos niveles de integración, y para tu caso te recomiendo empezar por el primero:

### Nivel 1 — GitHub CLI (`gh`), lo más simple

Si tienes instalado y autenticado [GitHub CLI](https://cli.github.com/), Claude Code lo detecta y lo usa automáticamente para crear issues, abrir pull requests y leer comentarios, sin configuración adicional. Sin `gh`, Claude puede seguir usando la API de GitHub, pero sin autenticar y con límites de peticiones más bajos.

```powershell
winget install --id GitHub.cli
gh auth login
```

### Nivel 2 — Servidor MCP de GitHub (para operaciones más profundas)

MCP (*Model Context Protocol*) es el estándar que permite a Claude Code conectarse a herramientas externas — GitHub, Notion, tu base de datos, Figma, etc. — de forma que puede llamarlas como si fueran funciones propias.

Desde tu terminal (no dentro de la sesión de Claude, sino en PowerShell normal):

```powershell
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN=$env:GITHUB_PAT -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
```

Esto requiere Docker instalado. Si prefieres no usar Docker, existe también la variante remota vía HTTP con tu token personal — la documentación oficial del servidor GitHub MCP la detalla si llegas a necesitarla.

**Nota de seguridad importante:** nunca pongas el token directamente en el comando ni en un archivo versionado. Guárdalo en una variable de entorno o en `.env`, y da al token el mínimo de permisos que necesites (si solo vas a leer issues, no le des permisos de escritura). Este mismo principio de "mínimo permiso necesario" aplícalo a **cualquier** servidor MCP que conectes: antes de instalar uno de la comunidad (no oficial), revisa qué hace, porque un servidor MCP corre código con acceso a red y a tu sistema de archivos.

Para un uso inicial como el tuyo, con `gh` autenticado ya tienes cubierto el 90% de los casos (crear PRs, revisar issues, gestionar ramas). El servidor MCP lo añades cuando necesites automatizaciones más complejas.

---

## 8. Integración con Notion y con Obsidian

Como quieres comparar ambos, aquí tienes las diferencias prácticas antes de la configuración:

| | **Notion** | **Obsidian** |
|---|---|---|
| Dónde vive la info | En la nube (servidor de Notion) | Archivos `.md` locales en tu disco |
| Cómo accede Claude Code | Vía servidor MCP (API de Notion) | Leyendo directamente los archivos del vault, como cualquier carpeta |
| Ventaja principal | Colaboración, bases de datos relacionales visuales, bueno para trip planning o gestión de proyecto con otras personas | Cero fricción con Claude Code: es texto plano, no necesita ni MCP ni API — es "otra carpeta más" |
| Fricción de configuración | Requiere token de integración + MCP server | Prácticamente ninguna si el vault está en tu disco |
| Ideal para | Documentación que compartes con otras personas, trackers, bases de datos | Notas técnicas personales, decisiones de arquitectura, tu segundo cerebro de desarrollo |

### Configurar Notion vía MCP

```powershell
claude mcp add notion -- npx -y @notionhq/notion-mcp-server
```

(La primera vez te pedirá autenticarte contra tu workspace de Notion vía OAuth). Una vez conectado, puedes pedirle a Claude cosas como *"crea una página en Notion con el resumen de este sprint"* o *"lee la base de datos de tareas pendientes en Notion y priorízalas"*.

### Configurar Obsidian

Si tu vault de Obsidian está en, por ejemplo, `C:\Users\Dani\Obsidian\Notas-Dev`, no necesitas MCP en absoluto para lo básico: puedes simplemente decirle a Claude Code, dentro de una sesión, algo como:

```
lee el archivo C:\Users\Dani\Obsidian\Notas-Dev\decisiones-arquitectura.md y resume las decisiones tomadas sobre la API
```

Si quieres una integración más profunda (búsqueda semántica dentro del vault, creación de notas con metadatos/backlinks correctos), existen servidores MCP de comunidad para Obsidian, pero para tu nivel actual te recomiendo **empezar sin MCP**: referencia el vault directamente desde `CLAUDE.md` con una ruta relativa o absoluta, y solo complica la configuración si notas que lo necesitas.

**Recomendación práctica para tu combinación de casos de uso** (código + gestión de proyectos personales como tu viaje a Galicia): usa **Obsidian para documentación técnica** que Claude Code va a consultar constantemente durante el desarrollo (decisiones de arquitectura, notas de sesión) — es más barato en tokens y no depende de ninguna API externa — y **Notion para todo lo que sea gestión de proyecto compartida con otras personas** o bases de datos estructuradas, donde sí compensa pagar la fricción del MCP.

---

## 9. Ejemplo práctico paso a paso: API + base de datos SQL + web

Vamos a montar un proyecto de ejemplo: un pequeño **gestor de tareas** con API en Python (FastAPI), base de datos SQL (SQLite para simplificar el ejemplo, migrable a PostgreSQL) y un frontend web muy simple.

### Paso 1 — Crear el repositorio en GitHub

```powershell
mkdir gestor-tareas
cd gestor-tareas
git init
gh repo create gestor-tareas --private --source=. --remote=origin
```

### Paso 2 — Montar el esqueleto de carpetas

```powershell
mkdir src, src\api, src\db, src\web, docs, tests
```

### Paso 3 — Arrancar Claude Code y generar el `CLAUDE.md` inicial

```powershell
claude
```

Dentro de la sesión:

```
/init
```

Revísalo y ajústalo con el ejemplo de la Sección 4.

### Paso 4 — Primer prompt real: define el plan antes de picar código

En lugar de pedir todo de golpe, dale la tarea en pasos explícitos — esto reduce iteraciones fallidas, que son las que más tokens gastan. Aprovecha el Plan Mode de la Sección 6:

```
Vamos a construir un gestor de tareas. Antes de escribir código, dime en 5 líneas
cómo estructurarías esto con FastAPI + SQLAlchemy + SQLite, y qué tablas propones
para la base de datos. No escribas código todavía, solo el plan.
```

Deja que te responda, corrige si algo no encaja, y **solo entonces** pide la implementación:

```
Perfecto, ese plan me sirve. Ahora:
1. Crea el modelo SQLAlchemy para la tabla "tareas" en src/db/models.py
2. Crea el endpoint GET /tareas y POST /tareas en src/api/main.py
3. Añade un test básico en tests/test_api.py
```

### Paso 5 — Frontend sencillo (como estás iniciándote en web)

```
Crea una página HTML simple en src/web/index.html que consuma el endpoint GET /tareas
y muestre la lista. Sin framework, JS vanilla, explícame brevemente qué hace cada bloque
porque quiero aprender, no solo tener el código.
```

Pedir la explicación es clave para tu caso: como estás iniciándote en web, aprovecha que Claude puede enseñarte mientras construye, no solo generar código opaco.

### Paso 6 — Revisar y commitear con Git conversacional

```
qué archivos he cambiado?
```
```
commit mis cambios con un mensaje descriptivo
```

Claude Code propondrá el mensaje de commit; revísalo antes de aceptar. Si algo no te convence tras aplicarlo, recuerda que tienes `/rewind` (Sección 6) para deshacer sin perder el resto de la conversación.

### Paso 7 — Documentar la decisión en Obsidian (o Notion)

```
resume en 5 líneas las decisiones de arquitectura de esta sesión y guárdalas en
C:\Users\Dani\Obsidian\Notas-Dev\gestor-tareas\decisiones.md
```

---

## 10. Buenas prácticas para minimizar el gasto de tokens

Esta es la sección que más impacto tiene en tu factura y en la calidad de las respuestas conforme el proyecto crece:

1. **Sé específico desde el primer prompt.** "Arregla el bug" obliga a Claude a explorar todo el proyecto para entender a qué te refieres. "Arregla el bug de login donde el usuario ve pantalla en blanco tras poner credenciales incorrectas" va directo al archivo relevante.

2. **Divide tareas grandes en pasos numerados** en lugar de un prompt gigante y ambiguo. Cada paso bien delimitado es más barato de ejecutar correctamente a la primera que un prompt vago que necesita tres rondas de corrección.

3. **Deja que Claude explore antes de pedirle que construya**, usando Plan Mode como en el Paso 4 del ejemplo. Un plan mal orientado que hay que rehacer sale mucho más caro que dos minutos de planificación previa.

4. **Vigila el porcentaje de contexto ocupado y actúa por umbrales**, no esperes a que se llene solo:
 - 0–50% ocupado: trabaja con normalidad.
 - 50–70%: presta atención, ya estás acumulando bastante historial.
 - 70–90%: usa `/compact` tú mismo para resumir intencionadamente lo que quieres conservar.
 - 90%+: usa `/clear` sin dudarlo — seguir por encima de este umbral aumenta el riesgo de respuestas erráticas, no solo el coste.

5. **Usa `/clear` entre tareas no relacionadas.** Si terminaste con la API y vas a pasar al frontend sin relación directa, limpia el historial de conversación — mantiene tu `CLAUDE.md`, pero descarta el resto.

6. **`.claudeignore` generosamente**, como se explicó en la Sección 5. No cuesta nada ignorar carpetas pesadas o irrelevantes (entornos virtuales, datasets, logs).

7. **Mantén `CLAUDE.md` corto y usa referencias a `docs/`** para todo lo extenso, como se explicó en la Sección 4.

8. **Elige el modelo según la tarea con `/model`.** Para tareas simples (formateo, fixes pequeños, dudas puntuales) un modelo más ligero es suficiente y más barato; resérvate el modelo más potente para diseño de arquitectura o debugging complejo. Consulta la documentación oficial para ver qué modelos están disponibles según tu plan, ya que esto cambia con el tiempo.

9. **Revisa los diffs antes de aceptar**, no solo por seguridad — pillar un error pronto evita que Claude siga construyendo sobre una base equivocada en turnos posteriores, lo cual sale caro en tokens de "deshacer y rehacer". Los checkpoints (Sección 6) son tu red de seguridad si algo se cuela.

10. **Recuerda que la cuota se comparte con claude.ai** (ventana móvil de 5 horas, ver nota en la Sección 1). Si vas a hacer una sesión larga de Claude Code, evita agotar la cuota antes en conversaciones largas aquí en el chat.

---

## 11. Flujo de trabajo diario recomendado (resumen)

```
1. Abre VS Code → terminal integrada (Ctrl+`) → claude
2. Si es una tarea nueva y no relacionada con la anterior → /clear
3. Si la tarea es compleja → Plan Mode primero (Shift+Tab), aprueba el plan, luego ejecuta
4. Prompt específico, dividido en pasos si es complejo
5. Revisar el plan/propuesta antes de aprobar cambios grandes
6. Si algo sale mal → Esc Esc o /rewind para volver atrás
7. git diff / git status para revisar antes de commitear
8. Commit con mensaje descriptivo (puede generarlo Claude, lo revisas tú)
9. Si tomaste una decisión de arquitectura → anótala en Obsidian/Notion
10. Si Claude se equivocó en algo → añade la regla a CLAUDE.md para que no se repita
```

---

### Próximos pasos cuando te sientas cómodo con lo básico

- **Skills**: paquetes de instrucciones reutilizables para tareas que repites (por ejemplo, "generar informe de análisis de datos").
- **Subagentes**: sesiones aisladas con su propio contexto, útiles para tareas independientes dentro del mismo proyecto grande.
- **Hooks**: acciones automáticas garantizadas (por ejemplo, correr el linter siempre después de cada edición), a diferencia de las reglas en `CLAUDE.md`, que son solo orientativas.

No los necesitas para empezar. Domina primero `CLAUDE.md`, `.claudeignore`, los permisos/Plan Mode/checkpoints y el flujo Git básico — con eso ya cubres la gran mayoría del valor de la herramienta.
