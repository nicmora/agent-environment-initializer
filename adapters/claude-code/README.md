# Adaptador: Claude Code

Las skills de `agent/skills/*` ya vienen con frontmatter compatible con Claude
Code (`name`, `description`), así que se instalan tal cual.

> Nota: en el frontmatter cada skill lleva el prefijo `env-`
> (`env-detect-environment`, `env-native-setup`, …). `AGENT.md` y los cuerpos de
> las skills las nombran sin prefijo (`detect-environment`) porque son la capa
> agnóstica al asistente; en Claude Code invocalas con el nombre `env-*`.

## Opción A — Instalación global (recomendada)

Disponible en todos tus proyectos.

**macOS / Linux**
```bash
REPO=/ruta/a/agent-environment-initializer
mkdir -p ~/.claude/skills ~/.claude/agents
cp -R "$REPO"/agent/skills/* ~/.claude/skills/
cp "$REPO"/agent/AGENT.md ~/.claude/skills/AGENT.md
cp "$REPO"/adapters/claude-code/agents/env-initializer.md ~/.claude/agents/
```

**Windows (PowerShell)**
```powershell
$repo = "C:\ruta\a\agent-environment-initializer"
New-Item -ItemType Directory -Force "$HOME\.claude\skills","$HOME\.claude\agents" | Out-Null
Copy-Item "$repo\agent\skills\*" "$HOME\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" "$HOME\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" "$HOME\.claude\agents\" -Force
```

## Opción B — Por proyecto

```powershell
Copy-Item "$repo\agent\skills\*" ".\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" ".\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" ".\.claude\agents\" -Force
```

## Uso

- Escribe lo que necesitas en lenguaje natural: *"quiero levantar este proyecto
  localmente"*, *"prefiero correr todo en el host, sin Docker"*, *"agrega Redis
  al entorno"*, *"¿por qué no arranca la base?"*. Las skills `env-*` se activan
  solas.
- O invoca el subagente: `@env-initializer levanta el entorno de este repo`.
- Puedes pedir una skill puntual por nombre: *"usa env-detect-environment"*,
  *"usa env-native-setup"*.

El agente te pregunta el **medio de ejecución** (Docker, runtime nativo en el
host, o mezcla) y la **estrategia de cada dependencia**, y te presenta las
opciones sin recomendarte ninguna.

## Actualizar

Vuelve a ejecutar el `cp` / `Copy-Item`. Para desinstalar, borra los archivos
`env-*` de `~/.claude/skills/` y `~/.claude/agents/env-initializer.md`.
