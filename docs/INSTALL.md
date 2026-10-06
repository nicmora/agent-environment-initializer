# Instalación en un proyecto

Esta guía explica cómo agregar el agente `envinit` a un proyecto. Para saber
qué hace el agente y cómo usarlo, mira el [README](../README.md).

El agente se instala con un script incluido en este repo. No hace falta instalar
nada más: solo tener este repo clonado o descargado. Se instala para una
herramienta a la vez: **Claude Code** u **OpenCode**.

## Instalar

Abre una terminal en la carpeta de este repo y ejecuta el script de tu sistema.
Reemplaza la ruta por la raíz del proyecto donde quieres usar el agente.

### Windows (PowerShell)

```powershell
.\scripts\install.ps1 -Tool claude -Target C:\ruta\a\tu-proyecto
```

Si Windows no te deja ejecutar el script por la política de ejecución, usa:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Tool claude -Target C:\ruta\a\tu-proyecto
```

### macOS / Linux / Git Bash

```bash
bash scripts/install.sh --tool claude --target ~/ruta/a/tu-proyecto
```

### Opciones

| PowerShell | Bash | Qué hace |
|---|---|---|
| `-Tool claude` / `-Tool opencode` | `--tool claude` / `--tool opencode` | Herramienta donde se instala. Si no la indicas, el script te la pregunta. |
| `-Target <ruta>` | `--target <ruta>` | Raíz del proyecto. Tiene que existir. |
| `-Uninstall` | `--uninstall` | Quita el agente en lugar de instalarlo. |
| `Get-Help .\scripts\install.ps1` | `--help` | Muestra la ayuda. |

Si usas las dos herramientas en el mismo proyecto, ejecuta el script dos veces,
una con `claude` y otra con `opencode`.

## Qué instala

Para Claude Code queda así (en OpenCode es igual, pero con `.opencode/`):

```
<tu-proyecto>/
└── .claude/
    ├── envinit/
    │   └── AGENT.md            ← reglas y flujo del agente
    ├── agents/
    │   └── envinit.md          ← el agente, en el formato de la herramienta
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

El script **solo toca archivos del agente**: `envinit/`, `agents/envinit.md` y
las carpetas `envinit-*`. Si tu proyecto ya tiene otras skills u otros agentes,
quedan como estaban. La carpeta `local/` que genera el agente tampoco se toca.

## Comprobar la instalación

**Claude Code:** abre Claude Code en la raíz del proyecto y escribe `@envinit`.
Si aparece en el autocompletado, quedó instalado.

**OpenCode:** abre `opencode` en la raíz del proyecto y presiona **Tab** hasta
que aparezca el agente `envinit`.

> En versiones viejas de OpenCode las carpetas tienen nombres en singular
> (`.opencode/agent/`, `.opencode/skill/`). Si el agente no aparece, renómbralas.

## Actualizar

Actualiza este repo y vuelve a ejecutar el mismo comando de instalación. El
script reemplaza los archivos del agente por los de la versión nueva y quita las
skills que ya no existan.

Si tenías instalada la versión anterior, cuando el agente se llamaba
`env-initializer`, el script también borra esos archivos viejos y te muestra
cuáles quitó.

## Desinstalar

Ejecuta el mismo comando con la opción de desinstalar:

```powershell
.\scripts\install.ps1 -Tool claude -Target C:\ruta\a\tu-proyecto -Uninstall
```

```bash
bash scripts/install.sh --tool claude --target ~/ruta/a/tu-proyecto --uninstall
```

La carpeta `local/` que generó el agente es tu entorno y el script no la borra.
Bórrala a mano solo si ya no la necesitas.

## Otros asistentes (ChatGPT, Gemini, Cursor, etc.)

Para estos asistentes no hay script: se instala a mano.

1. Copia `agent/AGENT.md` y la carpeta `agent/skills/` a una carpeta del
   proyecto.
2. Pega el contenido de `AGENT.md` como *system prompt* o como instrucciones del
   proyecto.
3. Si el asistente no puede leer archivos, pega también el contenido de cada
   skill (`skills/<nombre>/SKILL.md`) cuando el flujo la pida.
