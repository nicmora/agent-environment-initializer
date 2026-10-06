# Instalación en un proyecto

Esta guía explica cómo agregar el agente `envinit` a un proyecto. Para saber
qué hace el agente y cómo usarlo, mira el [README](../README.md).

El agente se instala con un script incluido en este repo. No hace falta instalar
nada más: solo tener este repo clonado o descargado. Se puede instalar para
**Claude Code**, para **OpenCode** o para las dos.

## Instalar

Abre una terminal en la carpeta de este repo y ejecuta el script de tu sistema.

### Windows (PowerShell)

```powershell
.\scripts\install.ps1
```

Si Windows no te deja ejecutar el script por la política de ejecución, usa:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

### macOS / Linux / Git Bash

```bash
bash scripts/install.sh
```

### Qué te pregunta

1. **La ruta del proyecto.** Es la carpeta raíz del proyecto donde quieres usar
   el agente. Puedes escribirla o pegarla: si la copias con comillas (como hace
   "Copiar como ruta" en Windows) o la arrastras a la terminal, el script la
   entiende igual. Si la carpeta no existe, te lo dice y te la vuelve a pedir.
2. **Las herramientas.** Aparece una lista con casillas. Escribe `1` o `2` y
   presiona Enter para marcar o desmarcar cada una; cuando estén las que usas,
   presiona Enter sin escribir nada. Tienes que marcar al menos una.

   ```
   ¿Para qué herramientas quieres instalar envinit?
     [x] 1) Claude Code
     [ ] 2) OpenCode
   Escribe un número para marcar o desmarcar, y Enter para continuar:
   ```

3. **La confirmación.** El script te muestra qué va a hacer y te pregunta si
   continúa. Enter o `s` instala; `n` cancela sin tocar nada.

### Sin preguntas

Si indicas la ruta y las herramientas al ejecutar el script, no pregunta nada.
Sirve para instalar en varios proyectos o desde otro script:

```powershell
.\scripts\install.ps1 -Tool claude,opencode -Target C:\ruta\a\tu-proyecto
```

```bash
bash scripts/install.sh --tool claude,opencode --target ~/ruta/a/tu-proyecto
```

| PowerShell | Bash | Qué hace |
|---|---|---|
| `-Tool claude` / `-Tool opencode` / `-Tool claude,opencode` | `--tool claude` / `--tool opencode` / `--tool claude,opencode` | Herramientas donde se instala. Si no las indicas, el script te las pregunta. |
| `-Target <ruta>` | `--target <ruta>` | Raíz del proyecto. Tiene que existir. Si no la indicas, el script te la pregunta. |
| `-Uninstall` | `--uninstall` | Quita el agente en lugar de instalarlo. |
| `Get-Help .\scripts\install.ps1` | `--help` | Muestra la ayuda. |

Si indicas solo una de las dos opciones, el script pregunta la otra y después
pide confirmación.

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

Ejecuta el script con la opción de desinstalar. Te hace las mismas preguntas
(la ruta y las herramientas) y quita el agente en lugar de instalarlo:

```powershell
.\scripts\install.ps1 -Uninstall
```

```bash
bash scripts/install.sh --uninstall
```

También puedes indicar todo para que no pregunte:

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
