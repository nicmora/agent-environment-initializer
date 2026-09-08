# Agente inicializador de entornos (*Environment Initializer Agent*)

Un agente con *skills*, **agnóstico al modelo de IA**, que te ayuda a **poner en
marcha una aplicación con todas sus dependencias de entorno** (bases de datos,
caché, mensajería, almacenamiento de objetos, servicios externos) en proyectos
nuevos (*greenfield*) o existentes (*brownfield*).

Funciona como un **wizard conversacional**: te hace preguntas, te ofrece
alternativas y termina generando un entorno **Docker / Docker Compose**
reproducible. Habla siempre en **español latinoamericano** y **nunca borra ni
sobrescribe** recursos o datos existentes.

## Qué hace

- **Analiza primero.** Escanea el repo (o, si es un proyecto nuevo, te
  pregunta) para detectar stack tecnológico, dependencias y configuración, y te
  muestra un resumen **antes** de preguntar nada ni tocar tu máquina.
- **Brownfield:** con ese resumen sobre la mesa, te propone por cada
  dependencia: **reutilizar**, **conectar a una instancia externa**, **crear
  desde cero** o **mockear**. Solo revisa qué tienes en Docker/tu máquina
  (contenedores, servicios del SO, puertos) si alguna de esas estrategias
  realmente depende de Docker.
- **Greenfield:** te pregunta qué necesita el proyecto (monorepo/multirepo, tipo
  de app, persistencia, caché, mensajería, storage, integraciones) y arma el
  entorno.
- **Antes de crear nada,** te muestra el plan completo y te deja cambiar o
  personalizar cualquier cosa.
- **Infra compartida:** te ofrece una pila de servicios centralizada del equipo
  (`dev-infra`) para ahorrar recursos, aislando cada proyecto por
  schema / base numerada / vhost / bucket / prefijo — sin pisar a los demás.
- **Servicios externos:** conexión real o simulación (WireMock / Mockoon / Prism
  / LocalStack / OIDC falso), con modo mixto y perfiles de compose.
- **Verifica** que todo levante y **documenta** el resultado en
  `env/ENVIRONMENT.md`.
- **Todo queda en `env/`.** Compose, `.env*`, Dockerfile de desarrollo,
  scripts y documentación se generan dentro de una carpeta `env/` en la
  raíz de tu proyecto, que se agrega a `.gitignore`: es tu entorno personal, no
  se commitea ni se comparte con el equipo por git.

Contexto y decisiones de diseño completos: [`context.md`](context.md).

## Estructura del repo

```
context.md                        Documento de contexto (el "por qué" y el "qué")
agent/
  AGENT.md                        Identidad y reglas del agente (fuente de verdad, agnóstica)
  skills/
    detect-environment/SKILL.md   Escaneo de repo brownfield
    greenfield-wizard/SKILL.md    Cuestionario de proyecto nuevo
    brownfield-wizard/SKILL.md    Estrategia por dependencia
    inspect-local-resources/…     Qué hay en la máquina
    shared-infra/SKILL.md         Pila de infraestructura compartida
    compose-builder/SKILL.md      Generación de compose y .env
    service-recipes/SKILL.md      Recetas por servicio (Postgres, Redis, Kafka, …)
    external-mocks/SKILL.md       Conexión real vs. mock
    verify-environment/SKILL.md   Healthchecks y arranque de prueba
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
$repo = "C:\Users\nicmora\Projects\sk-agent-environment-initializer"
New-Item -ItemType Directory -Force "$HOME\.claude\skills","$HOME\.claude\agents" | Out-Null
Copy-Item "$repo\agent\skills\*" "$HOME\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" "$HOME\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" "$HOME\.claude\agents\" -Force
```

Luego, en cualquier repo:

```
> quiero levantar este proyecto localmente
> agregá Redis al entorno de desarrollo
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

El agente detecta (o te pregunta) si el proyecto es *greenfield* o *brownfield* y
arranca el flujo:

```
detect-environment ─> brownfield-wizard ──┬─> (si hace falta) inspect-local-resources ─┐
                            │  ▲           │                                            │
greenfield-wizard ──────────┘  └─ shared-infra ─┴─ service-recipes ─ external-mocks    │
                                                                                         ▼
                                          resumen del plan + ajustes ─> compose-builder ─> verify-environment ─> document-environment
```

`inspect-local-resources` (el chequeo de Docker y de la máquina) solo se ejecuta
si alguna dependencia va a reutilizar un contenedor local o crear un servicio
desde cero; si todo se resuelve con conexión externa o mock, se salta. Antes de
`compose-builder`, siempre hay un resumen del plan completo con la posibilidad
de cambiar algo.

Puedes hablarle en cualquier momento, aunque el entorno esté a medio configurar.

## Reglas que el agente nunca rompe

- Español latinoamericano en toda interacción.
- No ejecuta `docker compose down -v`, `docker volume rm`, `DROP`, `TRUNCATE`,
  `rm -rf` sobre recursos existentes sin que se lo pidas de forma explícita.
- Muestra el diff de cada archivo antes de escribirlo.
- Analiza el proyecto y te muestra el resumen **antes** de preguntar nada, y
  revisa Docker recién si una estrategia elegida lo necesita.
- Antes de escribir un solo archivo, te muestra el plan completo y te deja
  cambiarlo.
- Todo lo que genera vive en `env/`, que agrega a `.gitignore`: es tu
  entorno personal, nunca se commitea.
- Ofrece siempre reutilizar / conectar / crear / mockear, y prioriza la infra
  compartida.

## Qué NO cubre (por ahora)

Despliegue a producción, IaC (Terraform / Kubernetes prod), CI/CD, gestión de
secretos productivos y migración de datos de negocio.
