# Adaptador: Claude Code

Las skills de `agent/skills/*` ya vienen con frontmatter compatible con Claude
Code (`name`, `description`), así que se instalan tal cual. El `name` de cada
skill coincide con el nombre de su carpeta y con cómo la nombran `AGENT.md` y los
cuerpos de las skills (`detect-environment`, `native-setup`, …): un solo nombre
en todos lados. Son 8: `detect-environment`, `plan-environment`,
`compose-builder`, `native-setup`, `service-recipes`, `external-mocks`,
`verify-environment`, `document-environment`.

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
  localmente"*, *"prefiero correr la app en el host"*, *"agrega Redis al
  entorno"*, *"ya tengo un Postgres, quiero conectarme a ese"*, *"¿por qué no
  arranca la base?"*. Las skills se activan solas.
- O invoca el subagente: `@env-initializer levanta el entorno de este repo`.
- Puedes pedir una skill puntual por nombre: *"usa detect-environment"*,
  *"usa native-setup"*.

El agente te pregunta el **medio de ejecución de la app** (contenedor Docker o
runtime nativo en el host) y, por cada dependencia, si la **creás en Docker** o
te **conectás a un servicio existente**, y te presenta las opciones sin
recomendarte ninguna.

## Actualizar

Vuelve a ejecutar el `cp` / `Copy-Item`. Para desinstalar, borra de
`~/.claude/skills/` las carpetas de skills (`detect-environment`,
`plan-environment`, `compose-builder`, `native-setup`, `service-recipes`,
`external-mocks`, `verify-environment`, `document-environment`) y `AGENT.md`,
más `~/.claude/agents/env-initializer.md`.
