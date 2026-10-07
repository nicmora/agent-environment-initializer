# envinit: agente para levantar entornos locales

Un agente con *skills*, para Claude Code u OpenCode, que ayuda a **cualquier
persona, con o sin perfil técnico, a levantar una aplicación y sus dependencias
en su máquina local**: bases de datos, caches, colas, almacenamiento y APIs
externas.

## Qué hace

1. **Analiza el proyecto** y te muestra un resumen: qué es la aplicación, qué
   proyectos tiene y qué dependencias necesita. Reconoce monorepos.
2. **Te pregunta, de a una cosa por vez,** cómo levantar cada proyecto (con
   Docker o de forma nativa) y qué hacer con cada dependencia:
   - Bases de datos, caches y colas: levantarlas con Docker o conectarte a un
     servicio que ya existe.
   - APIs externas: conectarte al servicio real o simularlo con WireMock.
   - Otro proyecto del mismo repositorio: levantarlo también o simularlo.
3. **Decide solo los detalles técnicos de Docker**: nombres, puertos, red e
   imágenes livianas.
4. **Te muestra un resumen completo** y no crea nada hasta que lo confirmas.
5. **Crea el entorno en `env-local/`**, prueba que funciona, lo apaga y te da el
   comando para arrancarlo y la URL de la aplicación.

No modifica el código ni la configuración de tu proyecto: lo único que toca
fuera de `env-local/` es el `.gitignore`, para que esa carpeta no se suba al
repositorio.

Las decisiones de diseño están en [`docs/context.md`](docs/context.md) y el
comportamiento detallado en las specs de [`openspec/specs/`](openspec/specs/).

## Estructura del repo

Este repo **construye** el agente. Lo que se instala en tus proyectos está solo
en `agent/`.

```
agent/                         EL AGENTE (lo único que se instala)
  AGENT.md                     Objetivo, comunicación, límites y flujo
  adapters/
    claude-code/envinit.md     Agente en formato Claude Code (remite a AGENT.md)
    opencode/envinit.md        Agente en formato OpenCode (remite a AGENT.md)
  skills/
    envinit-scan/SKILL.md      Análisis del proyecto y resumen
    envinit-wizard/SKILL.md    Preguntas y resumen final
    envinit-docker/SKILL.md    Decisiones de Docker y preparación
    envinit-mocks/SKILL.md     Mocks con WireMock
    envinit-build/SKILL.md     Archivos, verificación y entrega
scripts/
  install.ps1                  Instalar / actualizar / desinstalar (Windows)
  install.sh                   Instalar / actualizar / desinstalar (macOS, Linux, Git Bash)
docs/
  INSTALL.md                   Guía de instalación
  context.md                   Para qué existe el agente y por qué funciona así
openspec/                      Specs y cambios con los que se evoluciona el agente
AGENTS.md, CLAUDE.md           Guía para asistentes que trabajan en este repo
.claude/, .opencode/           Tooling de desarrollo (OpenSpec), no es el agente
```

Cada regla del agente vive en un solo archivo, y cada archivo corresponde a una
spec. Los adaptadores solo tienen el formato de cada herramienta y la indicación
de leer `AGENT.md`.

## Cómo lo uso en otros proyectos

El agente se instala con un script, una vez por proyecto y por herramienta.
Desde la carpeta de este repo:

```powershell
# Windows
.\scripts\install.ps1 -Tool claude -Target C:\ruta\a\tu-proyecto
```

```bash
# macOS / Linux / Git Bash
bash scripts/install.sh --tool claude --target ~/ruta/a/tu-proyecto
```

Usa `opencode` en lugar de `claude` si trabajas con OpenCode. Si no indicas las
opciones, el script te las pregunta. Todos los detalles están en
[`docs/INSTALL.md`](docs/INSTALL.md).

### Claude Code

Abre Claude Code en la raíz del proyecto y escribe:

```
> @envinit quiero levantar este proyecto localmente
```

### OpenCode

1. Abre `opencode` en la raíz del proyecto y elige el modelo.
2. Presiona **Tab** hasta que aparezca el agente `envinit`.
3. Escribe: *"quiero levantar este proyecto localmente"*.

## Cómo evolucionar el agente

Los cambios se trabajan con [OpenSpec](openspec/) (`/opsx:explore`,
`/opsx:propose`, `/opsx:apply`, `/opsx:archive`): primero se cambia la spec y
después el archivo del agente que le corresponde. Antes de empezar, lee
[`AGENTS.md`](AGENTS.md).

## Qué no cubre

Despliegue a producción, CI/CD, secretos de producción, instalar runtimes o
servicios en el sistema operativo, y migrar datos de negocio.
