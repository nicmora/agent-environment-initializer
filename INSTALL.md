# Instalación en un proyecto

Esta guía explica cómo agregar el agente `env-initializer` a un proyecto. Para
saber qué hace el agente y cómo usarlo, mirá el [README](README.md).

El agente se instala **copiando archivos a mano** en cada proyecto donde lo
quieras usar. No hace falta instalar nada más. Copiá solo los archivos de la
herramienta que vayas a usar: Claude Code u OpenCode.

## Qué se copia y adónde

Las rutas de destino son relativas a la **raíz de tu proyecto**.

| Desde este repo | Claude Code | OpenCode |
|---|---|---|
| `agents/env-initializer/AGENT.md` | `.claude/env-initializer/AGENT.md` | `.opencode/env-initializer/AGENT.md` |
| todas las carpetas de `skills/` | `.claude/skills/` | `.opencode/skills/` |
| `agents/env-initializer/adapters/<herramienta>/env-initializer.md` | `.claude/agents/env-initializer.md` | `.opencode/agents/env-initializer.md` |

> **Importante:** no copies la carpeta `agents/` entera a `.claude/agents/` u
> `.opencode/agents/`. Ahí va **solo** el `.md` del adaptador de tu herramienta.
> Las dos herramientas tratan cada `.md` de esa carpeta como un agente, por eso
> `AGENT.md` va en su propia carpeta `env-initializer/`.

## Resultado esperado

Para Claude Code queda así (en OpenCode es igual, pero con `.opencode/`):

```
<tu-proyecto>/
└── .claude/
    ├── env-initializer/
    │   └── AGENT.md
    ├── agents/
    │   └── env-initializer.md
    └── skills/
        ├── envinit-compose/SKILL.md
        ├── envinit-detect/SKILL.md
        ├── envinit-document/SKILL.md
        ├── envinit-mocks/SKILL.md
        ├── envinit-native/SKILL.md
        ├── envinit-plan/SKILL.md
        ├── envinit-recipes/SKILL.md
        └── envinit-verify/SKILL.md
```

Si tu proyecto ya tiene `.claude/skills/` u `.opencode/skills/` con otras
skills, no pasa nada: las del agente se suman a las que ya están.

## Copiar con la terminal

Podés copiar con el explorador de archivos o con estos comandos. En todos los
casos, reemplazá las dos rutas del principio:

- `REPO`: dónde clonaste este repo.
- `PROYECTO`: la raíz del proyecto donde lo instalás.

Para OpenCode, cambiá `.claude` por `.opencode` y `claude-code` por `opencode`.

### Windows (PowerShell)

```powershell
$REPO = "C:\ruta\a\agent-environment-initializer"
$PROYECTO = "C:\ruta\a\tu-proyecto"

New-Item -ItemType Directory -Force "$PROYECTO\.claude\env-initializer", "$PROYECTO\.claude\agents", "$PROYECTO\.claude\skills" | Out-Null
Copy-Item "$REPO\agents\env-initializer\AGENT.md" "$PROYECTO\.claude\env-initializer\"
Copy-Item "$REPO\agents\env-initializer\adapters\claude-code\env-initializer.md" "$PROYECTO\.claude\agents\"
Copy-Item "$REPO\skills\*" "$PROYECTO\.claude\skills\" -Recurse -Force
```

### macOS / Linux / Git Bash

```bash
REPO=~/ruta/a/agent-environment-initializer
PROYECTO=~/ruta/a/tu-proyecto

mkdir -p "$PROYECTO/.claude/env-initializer" "$PROYECTO/.claude/agents" "$PROYECTO/.claude/skills"
cp "$REPO/agents/env-initializer/AGENT.md" "$PROYECTO/.claude/env-initializer/"
cp "$REPO/agents/env-initializer/adapters/claude-code/env-initializer.md" "$PROYECTO/.claude/agents/"
cp -R "$REPO/skills/." "$PROYECTO/.claude/skills/"
```

## Comprobar la instalación

**Claude Code:** abrí Claude Code en la raíz del proyecto y escribí
`@env-initializer`. Si aparece en el autocompletado, quedó instalado.

**OpenCode:** abrí `opencode` en la raíz del proyecto y apretá **Tab** hasta que
aparezca el agente `env-initializer`.

> En versiones viejas de OpenCode las carpetas tienen nombres en singular
> (`.opencode/agent/`, `.opencode/skill/`). Si el agente no aparece, renombralas.

## Otros asistentes (ChatGPT, Gemini, Cursor, etc.)

1. Copiá `agents/env-initializer/AGENT.md` y la carpeta `skills/` a una carpeta
   del proyecto.
2. Pegá el contenido de `AGENT.md` como *system prompt* o como instrucciones del
   proyecto.
3. Si el asistente no puede leer archivos, pegá también el contenido de cada
   skill (`skills/<nombre>/SKILL.md`) cuando el flujo la pida.

## Actualizar

Cuando actualices este repo, volvé a copiar los mismos archivos encima de los
anteriores. Los comandos de arriba sirven igual: sobrescriben los archivos del
agente y no tocan nada más del proyecto.

> **Si instalaste una versión anterior a los nombres con prefijo `envinit-`**
> (`detect-environment`, `plan-environment`, `compose-builder`, `native-setup`,
> `service-recipes`, `external-mocks`, `verify-environment`,
> `document-environment`), borrá esas 8 carpetas de `.claude/skills/` u
> `.opencode/skills/` antes de copiar. Si no, quedan duplicadas junto a las
> nuevas.

## Desinstalar

Borrá estos archivos y carpetas del proyecto (con `.opencode/` si usás
OpenCode):

- `.claude/env-initializer/`
- `.claude/agents/env-initializer.md`
- las carpetas `envinit-*` dentro de `.claude/skills/` (todas las skills del
  agente llevan ese prefijo)

La carpeta `local/` que generó el agente es tu entorno. Borrala solo si ya no
la necesitás.
