# Agente inicializador de entornos (*Environment Initializer Agent*)

Un agente con *skills*, **agnóstico al modelo de IA**, que te ayuda a **poner en
marcha una aplicación con todas sus dependencias de entorno** (bases de datos,
caché, mensajería, almacenamiento de objetos, servicios externos) **en tu
máquina local**, en proyectos nuevos (*greenfield*) o existentes (*brownfield*).

El **medio de ejecución no se da por sentado**: según el proyecto y lo que
prefieras, el entorno puede armarse con **Docker / Docker Compose**, con el
**runtime nativo corriendo en el host** (Node/Python/JVM/Go y su gestor de
versiones), con **servicios de infra instalados en tu SO** (brew/apt/winget),
con **binarios o emuladores nativos**, o con una **mezcla**. El objetivo no es
que corras un comando concreto: es que la app **arranque y responda localmente**
por el medio que elijas, de forma reproducible y documentada.

Funciona como un **wizard conversacional**: te hace preguntas, te muestra las
opciones disponibles **sin recomendarte ninguna** y termina generando el entorno.
Habla siempre en **español latinoamericano** y **nunca borra ni sobrescribe**
recursos o datos existentes, ni desinstala nada de tu SO.

## Qué hace

- **Analiza primero.** Escanea el repo (o, si es un proyecto nuevo, te
  pregunta) para detectar stack tecnológico, versión de runtime, cómo arranca
  hoy, dependencias y configuración, y te muestra un resumen **antes** de
  preguntar nada ni tocar tu máquina.
- **Elige el medio de ejecución.** Te pregunta cómo querés correr la app
  (contenedor, runtime nativo en el host, o lo que el proyecto ya use) y te
  explica qué implica cada opción, sin empujar una.
- **Brownfield:** por cada dependencia te propone **reutilizar**, **conectar a
  una instancia externa**, **crear desde cero** (en Docker *o* instalada nativa)
  o **mockear**. Solo revisa qué tenés en la máquina (contenedores, servicios
  del SO, gestores de paquetes, puertos) si alguna de esas decisiones realmente
  lo necesita.
- **Greenfield:** te pregunta qué necesita el proyecto (monorepo/multirepo, tipo
  de app, persistencia, caché, mensajería, storage, integraciones) y arma el
  entorno.
- **Antes de crear nada,** te muestra el plan completo y te deja cambiar o
  personalizar cualquier cosa.
- **Infra compartida:** te ofrece —sin empujarla— una pila de servicios
  centralizada del equipo (`dev-infra`) para ahorrar recursos, aislando cada
  proyecto por schema / base numerada / vhost / bucket / prefijo.
- **Servicios externos:** conexión real o simulación (WireMock / Mockoon / Prism
  / LocalStack / OIDC falso), como contenedor o como proceso nativo, con modo
  mixto.
- **Verifica** que todo levante y **documenta** el resultado en
  `env/ENVIRONMENT.md`.
- **Todo queda en `env/`.** Compose, scripts de arranque (con o sin Docker),
  `.env*`, Dockerfile de desarrollo, archivo de versiones de runtime, `Procfile`
  local, notas de instalación y documentación se generan dentro de una carpeta
  `env/` en la raíz de tu proyecto, que se agrega a `.gitignore`: es tu entorno
  personal, no se commitea ni se comparte con el equipo por git.

Contexto y decisiones de diseño completos: [`context.md`](context.md).

## Estructura del repo

```
context.md                        Documento de contexto (el "por qué" y el "qué")
agent/
  AGENT.md                        Identidad y reglas del agente (fuente de verdad, agnóstica)
  skills/
    detect-environment/SKILL.md   Escaneo de repo brownfield
    greenfield-wizard/SKILL.md    Cuestionario de proyecto nuevo
    brownfield-wizard/SKILL.md    Medio de ejecución + estrategia por dependencia
    inspect-local-resources/…     Qué hay en la máquina (Docker, SO, paquetes, runtimes)
    shared-infra/SKILL.md         Pila de infraestructura compartida
    compose-builder/SKILL.md      Materializar el camino Docker
    native-setup/SKILL.md         Materializar el camino nativo (scripts, Procfile, instalación)
    service-recipes/SKILL.md      Recetas por servicio (compose + instalación nativa)
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
$repo = "C:\ruta\a\agent-environment-initializer"
New-Item -ItemType Directory -Force "$HOME\.claude\skills","$HOME\.claude\agents" | Out-Null
Copy-Item "$repo\agent\skills\*" "$HOME\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" "$HOME\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" "$HOME\.claude\agents\" -Force
```

Luego, en cualquier repo:

```
> quiero levantar este proyecto localmente
> prefiero correr todo en el host, sin Docker
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
             resumen del plan + ajustes ─> compose-builder y/o native-setup ─> verify-environment ─> document-environment
```

`inspect-local-resources` (el chequeo de la máquina) solo se ejecuta si alguna
decisión va a reutilizar un contenedor o servicio local, crear un servicio en
Docker, instalar algo nativo o depender de una versión de runtime concreta; si
todo se resuelve con conexión externa o mock y la app corre con un runtime que
ya está, se salta. Antes de materializar, siempre hay un resumen del plan
completo con la posibilidad de cambiar algo.

Puedes hablarle en cualquier momento, aunque el entorno esté a medio configurar.

## Reglas que el agente nunca rompe

- Español latinoamericano en toda interacción.
- No recomienda un medio de ejecución ni una estrategia: presenta las opciones y
  vos elegís.
- No ejecuta `docker compose down -v`, `docker volume rm`, `DROP`, `TRUNCATE`,
  `rm -rf` sobre recursos existentes sin que se lo pidas de forma explícita, ni
  desinstala/reconfigura servicios que ya tenías en el SO.
- No instala software en tu máquina (servicios, runtimes) sin permiso y sin
  mostrarte antes el comando exacto.
- Muestra el diff de cada archivo antes de escribirlo.
- Analiza el proyecto y te muestra el resumen **antes** de preguntar nada, y
  revisa la máquina recién si una decisión elegida lo necesita.
- Antes de escribir un solo archivo, te muestra el plan completo y te deja
  cambiarlo.
- Todo lo que genera vive en `env/`, que agrega a `.gitignore`: es tu
  entorno personal, nunca se commitea.
- Ofrece siempre reutilizar / conectar / crear / mockear, y ofrece la infra
  compartida.

## Qué NO cubre (por ahora)

Despliegue a producción, IaC (Terraform / Kubernetes prod), CI/CD, gestión de
secretos productivos y migración de datos de negocio.
