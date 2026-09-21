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
agent/
  AGENT.md                        Identidad y reglas del agente (fuente de verdad, agnóstica)
  skills/
    detect-environment/SKILL.md   Escaneo del repo (cualquier proyecto)
    plan-environment/SKILL.md     Medio de ejecución + origen de cada dependencia
    compose-builder/SKILL.md      Materializar los servicios en Docker
    native-setup/SKILL.md         Materializar el arranque nativo de la app (scripts, Procfile)
    service-recipes/SKILL.md      Recetas de compose por servicio
    external-mocks/SKILL.md       Conexión real vs. mock (servicios de terceros)
    verify-environment/SKILL.md   Healthchecks, colisiones de puerto y arranque de prueba
    document-environment/SKILL.md Generación de ENVIRONMENT.md
adapters/
  claude-code/                    Skills + subagente nativos de Claude Code
```

Las *skills* son **archivos Markdown con un procedimiento paso a paso**. Cada una
lleva un frontmatter (`name`, `description`) que Claude Code usa para activarlas
solas; para otros asistentes, el agente simplemente **lee el archivo** cuando lo
necesita.

## Cómo lo uso en otros proyectos

### Claude Code

Instalación global (una vez), disponible en todos los proyectos:

```powershell
$repo = "C:\ruta\a\agent-environment-initializer"
New-Item -ItemType Directory -Force "$HOME\.claude\skills","$HOME\.claude\agents" | Out-Null
Copy-Item "$repo\agent\skills\*" "$HOME\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" "$HOME\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" "$HOME\.claude\agents\" -Force
```

Luego, en cualquier repo:

```
> quiero levantar este proyecto localmente
> prefiero correr la app en el host
> agregá Redis al entorno de desarrollo
> ya tengo un Postgres corriendo, conectate a ese
> @env-initializer ¿por qué no arranca la base?
```

Detalle y opción por-proyecto: [`adapters/claude-code/README.md`](adapters/claude-code/README.md).

### GPT / ChatGPT / Gemini / Cursor / otros

1. Copia la carpeta `agent/` a la raíz del proyecto.
2. Pega el contenido de [`agent/AGENT.md`](agent/AGENT.md) como *system prompt* /
   instrucciones del proyecto.
3. Si el asistente no puede leer archivos, pega también el contenido de las
   skills (`agent/skills/<nombre>/SKILL.md`) a medida que el flujo las pida.

## Cómo empieza una sesión

El flujo es siempre el mismo, sin importar el estado del proyecto:

```
detect-environment ─> plan-environment ──> service-recipes ─ external-mocks ─┐
                                                                            ▼
   resumen del plan + ajustes ─> compose-builder y/o native-setup ─> verify-environment ─> document-environment
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
