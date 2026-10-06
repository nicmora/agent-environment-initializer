## Why

Hoy los scripts de instalación exigen escribir `--target` a mano y solo dejan
elegir una herramienta por vez. Para quien no es técnico es más fácil ejecutar el
script, pegar la ruta del proyecto y marcar con una cruz las herramientas que
usa, incluidas las dos a la vez.

## What Changes

- Si falta la ruta del proyecto y la terminal es interactiva, el script la
  pregunta en lugar de terminar con error. Acepta la ruta tal como se pega
  (con comillas, `\` de escape o `~`) y vuelve a preguntar si no sirve.
- El script rechaza como destino el propio repositorio del agente, se indique
  por flag o por pregunta.
- Si falta la herramienta y la terminal es interactiva, el script muestra una
  lista con cruces (`[ ]` / `[x]`) para Claude Code y OpenCode. Se marca y se
  desmarca escribiendo el número. No hay nada marcado al empezar y no avanza
  hasta que haya al menos una cruz.
- `--tool` / `-Tool` acepta varias herramientas separadas por comas
  (`claude,opencode`). Instalar y desinstalar se aplican a cada una.
- Si el script hizo alguna pregunta, pide confirmación (S/n) antes de escribir.
  Con todos los flags completos no pregunta nada, como hoy.
- El resumen final muestra, por cada herramienta, qué se hizo y cómo invocar al
  agente.
- `--uninstall` sigue siendo la única forma de desinstalar. Hace las mismas
  preguntas (ruta y cruces), pero quita el agente.
- Fuera de alcance: un lanzador con doble clic, el selector de carpetas del
  sistema, moverse por la lista con flechas y un menú para elegir entre
  instalar y desinstalar.

## Capabilities

### New Capabilities

_Ninguna._

### Modified Capabilities

- `agent-installation`: la selección de herramienta admite varias y se pregunta
  con cruces. La ruta del proyecto se pregunta si falta y se rechaza este repo.
  Se agrega una confirmación cuando hubo preguntas. La desinstalación y el
  resumen se aplican a cada herramienta.

## Impact

- `scripts/install.sh` y `scripts/install.ps1`: deben seguir siendo
  equivalentes, con bash 3.2 y Windows PowerShell 5.1 (UTF-8 con BOM).
- `docs/INSTALL.md`: documentar el modo interactivo y `--tool claude,opencode`.
- No cambia nada dentro de `agent/` ni las rutas que se instalan en el proyecto
  destino.
