## 1. install.sh

- [x] 1.1 Reorganizar instalar, desinstalar y limpiar en una función por herramienta que calcule su `TOOL_DIR`, `TOOL_DIR_NAME` y `ADAPTER`, y verificar que `install.sh --tool claude --target <prueba>` deja exactamente los mismos archivos que antes del cambio
- [x] 1.2 Aceptar en `--tool` una lista separada por comas, quitar los repetidos, ordenarla como claude y luego opencode, y fallar sin escribir si algún valor es inválido; verificar con `--tool claude,opencode`, `--tool opencode,claude,claude` y `--tool claude,foo`
- [x] 1.3 Preguntar la ruta cuando falta y la terminal es interactiva, con la limpieza del design (espacios, comillas, `~`, `\` de escape salvo con letra de unidad) y volver a preguntar si no existe, no es carpeta o es el repo; verificar pegando `"<ruta>"`, `~/...`, `mi\ app` y una ruta inexistente
- [x] 1.4 Rechazar el repo del agente como destino también cuando viene por `--target`, terminando con error; verificar con `--target .` desde la raíz del repo
- [x] 1.5 Mostrar las casillas sin marcar cuando falta `--tool` y la terminal es interactiva: un número marca o desmarca, Enter confirma, no avanza sin marcas y avisa ante una entrada inválida; verificar la secuencia `2`, `1`, `2`, Enter (solo queda claude) y Enter sin marcas
- [x] 1.6 Pedir confirmación `S/n` solo si hubo preguntas, y terminar sin escribir si la respuesta es no; verificar que con flags completos no pregunta y que con `n` no crea nada
- [x] 1.7 Terminar con error si la entrada se cierra durante cualquier pregunta; verificar con `install.sh < /dev/null` (sin terminal: falla por la opción faltante) y con Ctrl+D en la pregunta de la ruta
- [x] 1.8 Hacer el resumen por herramienta y aplicar `--uninstall` a cada herramienta de la lista; verificar instalando y desinstalando `claude,opencode` en un proyecto de prueba con otras skills propias y una carpeta `local/`, que quedan intactas
- [x] 1.9 Actualizar `usage()` con la lista por comas y el modo interactivo, y verificar que el script no use nada que no exista en bash 3.2 (`bash -n` y revisión: sin `declare -A`, `${var,,}`, `mapfile` ni `readarray`)

## 2. install.ps1

- [x] 2.1 Reorganizar instalar, desinstalar y limpiar en una función por herramienta, y verificar que `install.ps1 -Tool claude -Target <prueba>` deja los mismos archivos que antes del cambio
- [x] 2.2 Declarar `-Tool` como `[string[]]`, separar cada elemento por comas, limpiar espacios, quitar repetidos, ordenar y validar; verificar con `-Tool claude,opencode` y con `powershell -File .\scripts\install.ps1 -Tool claude,opencode -Target <prueba>`
- [x] 2.3 Preguntar la ruta con la misma limpieza (sin desescapar `\`) y las mismas validaciones y mensajes que `install.sh`, y rechazar el repo también por `-Target`; verificar con los mismos casos que 1.3 y 1.4
- [x] 2.4 Mostrar las casillas, la confirmación y el fin de la entrada igual que en `install.sh`; verificar con los mismos casos que 1.5, 1.6 y 1.7 en Windows PowerShell 5.1
- [x] 2.5 Hacer el resumen por herramienta y aplicar `-Uninstall` a cada herramienta de la lista; verificar con el mismo caso que 1.8
- [x] 2.6 Actualizar la ayuda basada en comentarios (`.PARAMETER Tool`, `.EXAMPLE`) y verificar que el archivo sigue en UTF-8 con BOM y que `Get-Help .\scripts\install.ps1` muestra bien los acentos

## 3. Equivalencia y documentación

- [x] 3.1 Ejecutar los dos scripts en modo interactivo sobre dos proyectos de prueba idénticos, eligiendo ambas herramientas, y verificar con un diff recursivo que los archivos instalados son idénticos y que las preguntas y mensajes coinciden
- [x] 3.2 Actualizar `docs/INSTALL.md`: el modo interactivo (pegar la ruta y marcar las casillas), `--tool claude,opencode` / `-Tool claude,opencode` y la confirmación; verificar que todos los ejemplos del documento funcionan tal como están escritos
