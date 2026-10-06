# Agente inicializador de entornos (*Environment Initializer Agent*)

Un agente con *skills*, **agnóstico al modelo de IA**, que te ayuda a **poner en
marcha una aplicación con todas sus dependencias de entorno** (bases de datos,
caché, mensajería, almacenamiento de objetos, servicios externos) **en tu
máquina local**.

Analiza **cualquier proyecto, en el estado en que esté**: escanea el repo,
detecta qué necesita para correr y te ayuda a levantarlo. Si todavía no usa
ninguna dependencia de entorno, no cambia de modo ni te hace un cuestionario:
simplemente te ayuda a levantar la app con su propio runtime. No hay distinción
entre "proyecto nuevo" y "proyecto existente".

El **medio de ejecución no se da por sentado**. Hay dos decisiones que el wizard
nunca asume:

- **Cómo corre la app:** en un contenedor (Docker) o con el **runtime nativo en
  el host** (Node/Python/JVM/Go y su gestor de versiones).
- **De dónde sale cada dependencia:** se **crea en Docker** (un contenedor por
  servicio) o tu app **se conecta a un servicio existente** fuera del proyecto
  —instalado en tu SO, en la nube o de otro equipo—, del que vos pasás los datos
  de conexión.

El objetivo no es que corras un comando concreto: es que la app **arranque y
responda localmente** por el medio que elijas, de forma reproducible y
documentada.

Funciona como un **wizard conversacional**: te hace preguntas, te muestra las
opciones disponibles **sin recomendarte ninguna** y termina generando el entorno.
Habla siempre en **español latinoamericano** y **nunca borra ni sobrescribe**
recursos o datos existentes, ni instala servicios de infra en tu SO.

## Qué hace

- **Analiza primero.** Escanea el repo para detectar stack tecnológico, versión
  de runtime, cómo arranca hoy, dependencias y configuración, y te muestra un
  resumen **antes** de preguntar nada ni tocar tu máquina. Si no hay
  dependencias de entorno, te lo dice y sigue igual.
- **Elige el medio de ejecución de la app.** Te pregunta cómo querés correr la
  app (contenedor Docker o runtime nativo en el host) y te explica qué implica
  cada opción, sin empujar una.
- **Por cada dependencia, dos opciones:** **crearla en Docker** (un contenedor
  nuevo en `local/`, el agente elige imagen/versión/memoria/puerto) o **usar un
  servicio existente** (le pasás host, puerto y credenciales de un servicio que
  ya corre en tu SO, en la nube o en la infra de otro equipo). Para servicios de
  terceros (pagos, OIDC, APIs): conexión real o **mock** en Docker.
- **Antes de crear nada,** te muestra el plan completo y te deja cambiar o
  personalizar cualquier cosa.
- **Servicios de terceros:** conexión real o mock (WireMock / Mockoon / Prism /
  LocalStack / OIDC falso), corriendo como contenedor Docker, con modo mixto.
- **Verifica** que todo levante (incluida la resolución de colisiones de puerto)
  y **documenta** el resultado en `local/ENVIRONMENT.md`.
- **Todo queda en `local/`.** Compose, scripts de arranque (con o sin Docker),
  `.env*`, Dockerfile de desarrollo, archivo de versiones de runtime, `Procfile`
  local y documentación se generan dentro de una carpeta `local/` en la raíz de tu
  proyecto, que se agrega a `.gitignore`: es tu entorno personal, no se commitea
  ni se comparte con el equipo por git.

Contexto y decisiones de diseño completos: [`context.md`](context.md).

## Estructura del repo

```
context.md                        Documento de contexto (el "por qué" y el "qué")
agents/
  envinit/
    AGENT.md                      Identidad y reglas del agente (fuente de verdad, agnóstica)
    adapters/
      claude-code/envinit.md      Agente en formato Claude Code (remite a AGENT.md)
      opencode/envinit.md         Agente en formato OpenCode (remite a AGENT.md)
skills/
  envinit-detect/SKILL.md         Escaneo del repo (cualquier proyecto)
  envinit-plan/SKILL.md           Medio de ejecución + origen de cada dependencia
  envinit-compose/SKILL.md        Materializar los servicios en Docker
  envinit-native/SKILL.md         Materializar el arranque nativo de la app (scripts, Procfile)
  envinit-recipes/SKILL.md        Recetas de compose por servicio
  envinit-mocks/SKILL.md          Conexión real vs. mock (servicios de terceros)
  envinit-verify/SKILL.md         Healthchecks, colisiones de puerto y arranque de prueba
  envinit-document/SKILL.md       Generación de ENVIRONMENT.md
```

Cada agente vive en su propia carpeta dentro de `agents/`, junto con sus
adaptadores; las skills están en `skills/`. Todas llevan el prefijo `envinit-`
para que se identifique a qué agente pertenecen cuando conviven con otras skills
del proyecto.

Las *skills* son **archivos Markdown con un procedimiento paso a paso**. Cada una
lleva un frontmatter (`name`, `description`) que Claude Code y OpenCode usan para
activarlas solas; para otros asistentes, el agente simplemente **lee el archivo**
cuando lo necesita.

`AGENT.md` es la única fuente de verdad de las reglas y el flujo. Los archivos de
`adapters/` son solo una "cáscara" con el frontmatter que pide cada herramienta y
la instrucción de leer `AGENT.md`, así las reglas no se duplican.

## Cómo lo uso en otros proyectos

> Guía de instalación paso a paso, con comandos para copiar desde la terminal:
> [`INSTALL.md`](INSTALL.md).

El agente se **copia a mano en cada proyecto** donde lo quieras usar, dentro de
la carpeta de la herramienta: `.claude/` para Claude Code u `.opencode/` para
OpenCode. Copiá solo la de la herramienta que vayas a usar. Podés hacerlo con el
explorador de archivos o con la terminal de tu sistema operativo.

### Qué se copia y adónde

| Desde este repo | Claude Code | OpenCode |
|---|---|---|
| `agents/envinit/AGENT.md` | `.claude/envinit/AGENT.md` | `.opencode/envinit/AGENT.md` |
| el contenido de `skills/` (las 8 carpetas) | `.claude/skills/` | `.opencode/skills/` |
| `agents/envinit/adapters/<herramienta>/envinit.md` | `.claude/agents/envinit.md` | `.opencode/agents/envinit.md` |

No copies la carpeta `agents/` entera a `.claude/agents/` u `.opencode/agents/`:
ahí va **solo** el `.md` del adaptador de tu herramienta.

Todas las rutas de destino son relativas a la **raíz del proyecto**. El
resultado queda así (en OpenCode, igual pero con `.opencode/`):

```
<tu-proyecto>/
└── .claude/
    ├── envinit/
    │   └── AGENT.md                ← reglas y flujo del agente
    ├── agents/
    │   └── envinit.md
    └── skills/
        ├── envinit-detect/SKILL.md
        ├── envinit-plan/SKILL.md
        ├── envinit-compose/SKILL.md
        ├── envinit-native/SKILL.md
        ├── envinit-recipes/SKILL.md
        ├── envinit-mocks/SKILL.md
        ├── envinit-verify/SKILL.md
        └── envinit-document/SKILL.md
```

`AGENT.md` va dentro de una carpeta `envinit/` para que no se confunda
con archivos de otros agentes que tenga el proyecto. No lo pongas dentro de
`agents/`: las dos herramientas tratan cada `.md` de esa carpeta como un agente.

Si después actualizás este repo, volvé a copiar los mismos archivos encima.

### Claude Code

Abrí Claude Code en la raíz del proyecto y pedíselo al agente:

```
> @envinit quiero levantar este proyecto localmente
```

También podés hablar sin mencionarlo (*"agregá Redis al entorno"*, *"ya tengo un
Postgres corriendo, conectate a ese"*): las skills se activan solas.

### OpenCode

El agente **no fija ningún modelo**: usa el que tengas seleccionado en OpenCode,
así que funciona con cualquier proveedor o gateway.

1. Abrí `opencode` en la raíz del proyecto y elegí el modelo.
2. Apretá **Tab** hasta que aparezca el agente `envinit`.
3. Pedile lo que necesitás: *"quiero levantar este proyecto localmente"*.

> En versiones viejas de OpenCode las carpetas se llamaban en singular
> (`.opencode/agent/`, `.opencode/skill/`). Si el agente no aparece, probá con
> esos nombres.

### Otros asistentes (GPT / ChatGPT / Gemini / Cursor)

1. Copiá `agents/envinit/AGENT.md` y `skills/` a una carpeta del proyecto.
2. Pegá el contenido de `AGENT.md` como *system prompt* / instrucciones del
   proyecto.
3. Si el asistente no puede leer archivos, pegá también el contenido de las
   skills (`skills/<nombre>/SKILL.md`) a medida que el flujo las pida.

## Cómo empieza una sesión

El flujo es siempre el mismo, sin importar el estado del proyecto:

```
envinit-detect ─> envinit-plan ──> envinit-recipes ─ envinit-mocks ─┐
                                                                    ▼
   resumen del plan + ajustes ─> envinit-compose y/o envinit-native ─> envinit-verify ─> envinit-document
```

Por cada dependencia elegís: **crearla en Docker** o **conectarte a un servicio
existente** (le pasás los datos de conexión). Para servicios de terceros:
conexión real o mock. Antes de materializar, siempre hay un resumen del plan
completo con la posibilidad de cambiar algo.

Puedes hablarle en cualquier momento, aunque el entorno esté a medio configurar.

## Reglas que el agente nunca rompe

- Español latinoamericano en toda interacción.
- No recomienda un medio de ejecución ni el origen de una dependencia: presenta
  las opciones y vos elegís.
- No ejecuta `docker compose down -v`, `docker volume rm`, `DROP`, `TRUNCATE`,
  `rm -rf` sobre recursos existentes sin que se lo pidas de forma explícita, ni
  toca la configuración o los datos de un servicio externo al que te conectás.
- No instala servicios de infra ni runtimes en tu máquina: los servicios se
  crean en Docker o ya existen.
- Muestra el diff de cada archivo antes de escribirlo.
- Analiza el proyecto y te muestra el resumen **antes** de preguntar nada.
- Antes de escribir un solo archivo, te muestra el plan completo y te deja
  cambiarlo.
- Todo lo que genera vive en `local/`, que agrega a `.gitignore`: es tu
  entorno personal, nunca se commitea.
- Ofrece siempre las dos opciones por dependencia: crear en Docker o conectar a
  un servicio existente (y, para servicios de terceros, real o mock).

## Qué NO cubre (por ahora)

Despliegue a producción, IaC (Terraform / Kubernetes prod), CI/CD, gestión de
secretos productivos y migración de datos de negocio.
