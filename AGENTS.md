# Guía para asistentes que trabajan en este repo

Este repositorio **construye** el agente `envinit`, un wizard que ayuda a
levantar cualquier aplicación con sus dependencias en un entorno local. Acá
**no** se ejecuta el agente: se diseña, se escribe y se evoluciona. Si te piden
"levantar el proyecto", "detectar dependencias" o algo parecido, no apliques el
flujo de `envinit` sobre este repo. Pregunta si se refieren a modificar el
agente.

## Mapa del repo

```
agent/                  EL PRODUCTO: lo único que se instala en otros proyectos
  AGENT.md              reglas y flujo del agente (fuente de verdad, agnóstica)
  adapters/             frontmatter por herramienta (claude-code/, opencode/)
  skills/envinit-*/     una skill por paso del flujo
scripts/                install.sh / install.ps1: instalan agent/ en un proyecto
docs/                   documentación para quien usa el agente (INSTALL, context)
openspec/               specs y cambios con los que se evoluciona el agente
.claude/  .opencode/    tooling de desarrollo (comandos opsx y skills openspec-*)
```

- **`.claude/` y `.opencode/` de este repo NO son el agente.** Contienen el
  tooling de OpenSpec para trabajar acá. El agente vive solo en `agent/`.
  No copies nada de `agent/` a esas carpetas.
- `docs/context.md` explica el porqué y las decisiones de diseño del agente.
  Léelo antes de cambiar su comportamiento.

## Cómo se trabaja

Todo cambio al agente, a los scripts o a la estructura del repo se propone y se
implementa con **OpenSpec**:

- `/opsx:explore`: pensar un problema antes de comprometerse a algo.
- `/opsx:propose`: crear un cambio con propuesta, specs, diseño y tareas.
- `/opsx:apply`: implementar las tareas de un cambio.
- `/opsx:archive`: archivar el cambio terminado y consolidar sus specs.

En OpenCode, los mismos comandos se llaman `/opsx-explore`, `/opsx-propose`,
etc. Las specs vigentes están en `openspec/specs/` y los cambios en curso en
`openspec/changes/`.

## Reglas al editar `agent/`

- **Rutas instaladas, no rutas del repo.** Dentro de `AGENT.md`, los adaptadores
  y las skills, las rutas se escriben como quedan en el proyecto destino
  (`.claude/envinit/AGENT.md`, `.opencode/skills/...`), nunca como
  `agent/...`.
- `AGENT.md` es la única fuente de verdad de reglas y flujo. Los adaptadores
  solo tienen el frontmatter de cada herramienta y la instrucción de leer
  `AGENT.md`: no les copies reglas.
- Toda skill nueva lleva el prefijo `envinit-` (los scripts dependen de eso para
  instalar y desinstalar) y un frontmatter con `name` y `description`.
- El agente habla en español neutro y en lenguaje simple, porque lo usan
  personas no técnicas. Escribe las skills con ese mismo criterio.

## Cómo probar el agente

Instálalo con el script en **otro** proyecto (uno de prueba o temporal), nunca
en este repo:

```bash
scripts/install.sh --tool claude --target ../proyecto-de-prueba
```

```powershell
.\scripts\install.ps1 -Tool claude -Target ..\proyecto-de-prueba
```

Si cambias los scripts, mantén `install.sh` e `install.ps1` equivalentes: el
mismo resultado en el proyecto destino (ver la spec `agent-installation`).
`install.sh` debe funcionar con bash 3.2 (macOS) y `install.ps1` con Windows
PowerShell 5.1, que necesita el archivo guardado en UTF-8 con BOM.

## Convenciones

- Commits en español con prefijo convencional (`feat:`, `fix:`, `docs:`,
  `refactor:`).
- Documentación en español neutro.
