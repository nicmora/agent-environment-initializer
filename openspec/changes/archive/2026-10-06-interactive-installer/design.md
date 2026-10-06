## Context

`scripts/install.sh` (bash 3.2+) y `scripts/install.ps1` (Windows PowerShell
5.1+) ya validan todo antes de escribir, y ya preguntan la herramienta cuando
falta y la terminal es interactiva (`[ -t 0 ]` en bash y `Test-Interactive` en
PowerShell). Hoy la herramienta es un solo valor (`TOOL` / `$Tool`) y las
funciones `remove_legacy`/`remove_current` (`Remove-Legacy`/`Remove-Current`)
dependen de variables globales de esa herramienta (`TOOL_DIR`, `TOOL_DIR_NAME`).
Los requisitos están en la delta de `specs/agent-installation/spec.md`.

## Goals / Non-Goals

**Goals:**
- Los dos scripts se comportan igual en todas las preguntas: el mismo orden, los
  mismos textos y las mismas reglas de validación.
- No se agregan dependencias externas ni nada que necesite leer la terminal
  tecla por tecla.

**Non-Goals:**
- Cambiar qué archivos se instalan o dónde (los requisitos de rutas,
  idempotencia y limpieza de la versión antigua no cambian).
- Recordar respuestas anteriores o leer un archivo de configuración.

## Decisions

### Flujo en dos fases: resolver y luego ejecutar

```
parsear flags
  -> resolver destino   (flag | pregunta en bucle)
  -> resolver lista de herramientas (flag | casillas en bucle)
  -> si hubo preguntas: confirmar (S/n)
  -> por cada herramienta, en orden fijo claude, opencode: acción
  -> resumen
```

Todas las validaciones terminan antes del primer archivo escrito, así un error
en la segunda herramienta de la lista no deja instalada la primera. El orden
fijo hace que la salida sea la misma sin importar cómo se escribió la lista.

### Las funciones por herramienta reciben la herramienta

La instalación, la desinstalación y la limpieza se agrupan en una función que
recibe la herramienta y calcula su `TOOL_DIR`, `TOOL_DIR_NAME` y `ADAPTER`. En
bash 3.2 no hay arrays asociativos, así que la lista se guarda como un string
separado por espacios (`"claude opencode"`). El resumen se arma por herramienta
dentro de esa función. `REMOVED_LEGACY` y `REMOVED_ANY` se reinician en cada
vuelta.

### `-Tool` como `[string[]]` y además separado por comas

En PowerShell, `-Tool claude,opencode` llega como array si el parámetro es
`[string[]]`. Pero `powershell -File install.ps1 -Tool claude,opencode`, la
forma documentada en `docs/INSTALL.md` para saltar la política de ejecución,
lo entrega como un solo string `"claude,opencode"`. Por eso cada elemento se
separa por comas y se limpian los espacios. En bash, `--tool` se separa por
comas con `IFS`. En los dos scripts los repetidos se quitan.

Alternativa descartada: `--tool both`. Agrega un valor mágico y no escala si
aparece otra herramienta.

### Casillas manejadas con números (opción B)

Se muestra la lista con `[ ]`/`[x]`. Cada respuesta es un número que marca o
desmarca esa casilla, o vacía (Enter) para confirmar. Una respuesta que no es un
número válido muestra un aviso y vuelve a mostrar la lista. Si se confirma sin
marcas, se avisa y se repite. Se usa solo `read -r` / `Read-Host`, que
funcionan en bash 3.2, Git Bash/mintty, PowerShell 5.1, PowerShell 7 e ISE.

Alternativa descartada: flechas y espacio. Requiere leer la terminal tecla por
tecla (`read -rsn1` y secuencias de escape en bash, `[Console]::ReadKey` en
PowerShell), que falla en ISE y es inestable en mintty. Mantener iguales los
dos scripts sería mucho más difícil.

### Limpieza de la ruta pegada

Se aplica, en este orden, solo a la ruta respondida a la pregunta (la que viene
por flag ya la procesó la shell):
1. Quitar espacios al principio y al final.
2. Quitar un par de comillas, dobles o simples, que rodeen toda la ruta
   ("Copiar como ruta" de Windows y el arrastre en Windows Terminal las
   agregan).
3. Expandir un `~` inicial a la carpeta del usuario (`$HOME`; `$HOME` o
   `USERPROFILE` en PowerShell).
4. Solo en bash, y solo si la ruta no empieza con letra de unidad
   (`C:\...`): convertir `\<carácter>` en `<carácter>`, porque así escapa
   los espacios el arrastre en la Terminal de macOS. En PowerShell no se hace,
   porque `\` es el separador de rutas.

En Git Bash se acepta una ruta de Windows (`C:\Users\...`) tal cual, porque
`cd` la entiende. La regla 4 evita romperla.

### Rechazar el repositorio del agente

La raíz del repo es el padre de la carpeta del script (en bash ya se calcula
para `AGENT_SRC`). Se compara con el destino resuelto, usando `pwd -P` en bash
y `Resolve-Path` con comparación sin mayúsculas en PowerShell. La regla se
aplica tanto a la ruta por flag (error) como a la preguntada (vuelve a
preguntar).

### Confirmación

Se usa `S/n`, con S por defecto: Enter confirma. Se aceptan `s`, `si`, `sí`, `y`
y `yes` en mayúsculas o minúsculas como sí, y `n` y `no` como no. Cualquier otra
cosa vuelve a preguntar. Se muestra solo si el script hizo alguna pregunta, para
que la automatización con flags completos siga funcionando sin intervención.

### Fin de la entrada mientras se pregunta

Si `read` falla (Ctrl+D o la entrada se cierra) durante cualquier pregunta, el
script termina con error y sin escribir nada. Así se evita repetir la pregunta
para siempre.

## Risks / Trade-offs

- [Los textos y validaciones de los dos scripts se desincronizan] → Las tareas
  incluyen una prueba manual guiada con los mismos casos en ambos scripts, y
  los mensajes se copian literalmente de uno al otro.
- [En macOS el sistema de archivos no distingue mayúsculas, y `pwd -P` podría
  no detectar el repo si se escribe con otra capitalización] → Riesgo bajo y
  aceptable: el caso típico es pegar o arrastrar la ruta, que conserva la
  capitalización real.
- [Una ruta de Windows pegada en Git Bash con `\ ` real dentro del nombre] →
  No se desescapa por la regla de la letra de unidad. Es un caso extremo
  aceptable.
- [`install.ps1` pierde el BOM al editarlo] → Las tareas verifican la
  codificación UTF-8 con BOM antes de terminar.

## Migration Plan

Todas las invocaciones actuales con `--tool` y `--target` completos siguen
funcionando igual y sin preguntas. No hay migración. Para volver atrás, alcanza
con revertir los dos scripts y `docs/INSTALL.md`.
