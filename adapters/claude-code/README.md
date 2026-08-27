# Adaptador: Claude Code

Las skills de `agent/skills/*` ya vienen con frontmatter compatible con Claude
Code (`name`, `description`), así que se instalan tal cual.

## Opción A — Instalación global (recomendada)

Disponible en todos tus proyectos.

**macOS / Linux**
```bash
REPO=/ruta/a/sk-agent-environment-initializer
mkdir -p ~/.claude/skills ~/.claude/agents
cp -R "$REPO"/agent/skills/* ~/.claude/skills/
cp "$REPO"/agent/AGENT.md ~/.claude/skills/AGENT.md
cp "$REPO"/adapters/claude-code/agents/env-initializer.md ~/.claude/agents/
```

**Windows (PowerShell)**
```powershell
$repo = "C:\ruta\a\sk-agent-environment-initializer"
New-Item -ItemType Directory -Force "$HOME\.claude\skills","$HOME\.claude\agents" | Out-Null
Copy-Item "$repo\agent\skills\*" "$HOME\.claude\skills\" -Recurse -Force
Copy-Item "$repo\agent\AGENT.md" "$HOME\.claude\skills\AGENT.md" -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" "$HOME\.claude\agents\" -Force
```

## Opción B — Por proyecto

```powershell
Copy-Item "$repo\agent" ".\.claude\agent" -Recurse -Force
Copy-Item "$repo\agent\skills\*" ".\.claude\skills\" -Recurse -Force
Copy-Item "$repo\adapters\claude-code\agents\env-initializer.md" ".\.claude\agents\" -Force
```

## Uso

- Escribí lo que necesitás en lenguaje natural: *"quiero levantar este proyecto
  localmente"*, *"agregá Redis al entorno"*, *"¿por qué no arranca la base?"*.
  Las skills `env-*` se activan solas.
- O invocá el subagente: `@env-initializer levantá el entorno de este repo`.
- Podés pedir una skill puntual por nombre: *"usá env-detect-environment"*.

## Actualizar

Volvé a correr el `cp` / `Copy-Item`. Para desinstalar, borrá los archivos
`env-*` de `~/.claude/skills/` y `~/.claude/agents/env-initializer.md`.
