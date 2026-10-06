## 1. Mover el producto a `agent/`

- [x] 1.1 Mover con `git mv` `agents/envinit/AGENT.md` y `agents/envinit/adapters/` a `agent/`, y `skills/envinit-*` a `agent/skills/`. Verificar que `agents/` y `skills/` ya no existan en la raíz y que `git status` muestre solo renombres
- [x] 1.2 Mover con `git mv` `INSTALL.md` y `context.md` a `docs/`, sin cambiar el contenido. Verificar con `git diff --cached -M --stat` que todos los movimientos se detectan como renombres al 100%
- [x] 1.3 Revisar la sección "Cómo se invocan las skills" de `agent/AGENT.md` y los adaptadores. Confirmar que solo mencionan rutas instaladas (`.claude/...` y `.opencode/...`) y ajustar si alguna apunta a una ruta del repo. Verificar con una búsqueda de `agents/envinit` dentro de `agent/` que no devuelva resultados
- [x] 1.4 Crear el commit de solo movimientos y verificar con `git show --stat -M` que no incluye cambios de contenido

## 2. Script de instalación para Bash

- [x] 2.1 Crear `scripts/install.sh` con el parseo de `--tool`, `--target`, `--uninstall` y `--help`, y la resolución de la raíz del repo desde la ubicación del script. Verificar que `--help` muestra el uso y que una herramienta inválida o un destino inexistente terminan con código distinto de 0 sin escribir archivos
- [x] 2.2 Implementar la pregunta interactiva cuando falta `--tool`, y el error cuando falta y no hay terminal interactiva. Verificar ejecutando con `</dev/null` que falla sin escribir nada
- [x] 2.3 Implementar la instalación: limpiar la versión antigua, borrar `<dir>/skills/envinit-*`, copiar `AGENT.md`, el adaptador y las skills, y mostrar el resumen. Verificar sobre un proyecto temporal vacío que el árbol resultante coincide con las rutas de la spec
- [x] 2.4 Implementar `--uninstall`. Verificar sobre un proyecto temporal que no queda ningún archivo del agente, que `<dir>/`, `agents/` y `skills/` siguen existiendo, y que correrlo sin el agente instalado termina sin error

## 3. Script de instalación para PowerShell

- [x] 3.1 Crear `scripts/install.ps1` con los parámetros `-Tool`, `-Target` y `-Uninstall`, la ayuda basada en comentarios y la resolución de la raíz desde `$PSScriptRoot`. Verificar que `Get-Help` muestra el uso y que las validaciones fallan sin escribir archivos
- [x] 3.2 Implementar la pregunta interactiva cuando falta `-Tool` y el error cuando no hay terminal interactiva. Verificar ejecutando con `-NonInteractive`
- [x] 3.3 Implementar la instalación con el mismo comportamiento que `install.sh`. Verificar en Windows PowerShell 5.1 (`powershell.exe`) y en PowerShell 7 (`pwsh`) sobre un proyecto temporal vacío
- [x] 3.4 Implementar `-Uninstall`. Verificar con los mismos casos de la tarea 2.4

## 4. Verificación cruzada de los scripts

- [x] 4.1 Instalar con cada script, para `claude` y para `opencode`, en proyectos temporales idénticos, y comparar los árboles resultantes. Verificar que son idénticos
- [x] 4.2 Preparar un proyecto temporal con otras skills y agentes en `.claude/`, una carpeta `local/` y restos de `env-initializer`. Instalar y verificar que los restos antiguos desaparecen y lo ajeno queda intacto (comparar hashes antes y después)
- [x] 4.3 Instalar dos veces seguidas y verificar que el resultado es idéntico. Agregar una skill falsa `envinit-vieja`, reinstalar y verificar que desaparece

## 5. Guía para asistentes de desarrollo

- [x] 5.1 Crear `AGENTS.md` con qué es el producto (`agent/`), qué son `.claude/` y `.opencode/` en este repo, el trabajo con OpenSpec, la regla de rutas instaladas dentro de `agent/` y cómo probar con el script en otro proyecto. Verificar que menciona cada punto de la sección correspondiente de `design.md`
- [x] 5.2 Crear `CLAUDE.md` que importe `@AGENTS.md`. Verificar que al abrir Claude Code en el repo el contenido aparece en contexto (por ejemplo, con `/memory`)
- [x] 5.3 Completar `context` en `openspec/config.yaml` con la descripción del proyecto y su layout. Verificar con `openspec instructions proposal --change restructure-repo --json` que el contexto aparece en la salida

## 6. Documentación

- [x] 6.1 Reescribir `docs/INSTALL.md` en torno a los scripts: instalar, actualizar, desinstalar, comprobar, política de ejecución de PowerShell y copia manual para otros asistentes desde `agent/`. Verificar que no queden tablas de copia manual para Claude Code ni para OpenCode
- [x] 6.2 Actualizar `README.md`: presentación, mapa del repo (producto, proceso y tooling), instalación rápida con el script y enlaces a `docs/`. Verificar que la sección de estructura coincide con el árbol real
- [x] 6.3 Buscar en todo el repo, excluyendo `openspec/changes/`, `agents/envinit`, rutas `skills/envinit-` sin el prefijo `agent/`, y enlaces a `context.md` e `INSTALL.md` en la raíz. Verificar que no queda ninguna referencia rota
- [x] 6.4 Ejecutar `openspec validate restructure-repo --strict` y verificar que pasa
