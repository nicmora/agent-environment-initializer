## Why

En este repositorio conviven dos cosas sin una frontera visible: el **producto**
(el agente `envinit` que se instala en otros proyectos) y la **fábrica** (el
tooling de Claude Code, OpenCode y OpenSpec que se usa para evolucionarlo). El
agente está partido entre `agents/envinit/` y `skills/`, y `.claude/` y `.opencode/`
significan cosas distintas acá y en el proyecto destino. Además, la instalación
es una copia manual que depende de la estructura interna del repo: cada vez que
se mueve un archivo hay que reescribir el README y el INSTALL, y quien instala
puede equivocarse fácilmente (por ejemplo, copiando `agents/` entero).

## What Changes

- **BREAKING (rutas del repo):** el producto se concentra en un único directorio
  `agent/`, que contiene `AGENT.md`, `adapters/` y `skills/`. Desaparecen
  `agents/envinit/` y `skills/` de la raíz.
- Nuevos scripts de instalación `scripts/install.ps1` (Windows) y
  `scripts/install.sh` (macOS / Linux / Git Bash) para instalar, actualizar y
  desinstalar el agente en un proyecto destino, con Claude Code u OpenCode.
  Los scripts también limpian la versión antigua (`env-initializer`).
- Nuevo `AGENTS.md` en la raíz, con su puntero `CLAUDE.md`, que explica a los
  asistentes que este repo **construye** un agente: dónde está el producto, que
  `.claude/` y `.opencode/` son tooling de desarrollo y que los cambios se
  trabajan con OpenSpec.
- La documentación de uso pasa a `docs/`: `INSTALL.md` se reescribe en torno a
  los scripts y `context.md` se mueve sin cambiar su contenido. El README queda
  como presentación y mapa del repo.
- Se completa el `context` de `openspec/config.yaml` con la descripción del
  proyecto.
- No se instala el agente dentro de este repo para probarlo (sin dogfooding).

## Capabilities

### New Capabilities
- `agent-installation`: cómo se instala, actualiza y desinstala el agente en un
  proyecto destino mediante scripts. Cubre la selección de la herramienta, las
  rutas de destino, la limpieza de versiones antiguas y la garantía de no tocar
  archivos ajenos al agente.

### Modified Capabilities
<!-- Ninguna: todavía no hay specs. El comportamiento del agente (AGENT.md y
     skills) no cambia; solo cambia su ubicación en el repo. -->

## Impact

- **Repo:** se mueven `agents/envinit/**` y `skills/**` a `agent/**`, y
  `INSTALL.md` y `context.md` a `docs/`. Se crean `scripts/`, `AGENTS.md` y
  `CLAUDE.md`. Se actualizan `README.md` y `openspec/config.yaml`.
- **Referencias internas:** hay que revisar las rutas que mencionan `AGENT.md`,
  los adaptadores y las skills (por ejemplo, el adaptador de Claude Code que
  remite a `AGENT.md`). Las rutas *instaladas* en el proyecto destino no
  cambian.
- **Usuarios existentes:** quienes copiaban a mano desde `agents/` y `skills/`
  tienen que pasar a usar los scripts. Las instalaciones previas siguen
  funcionando y se pueden actualizar con el script.
- **Fuera de alcance:** migrar `context.md` a specs de OpenSpec queda para un
  cambio posterior (`specs-from-context`).
