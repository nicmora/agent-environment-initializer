## Context

El producto está repartido en dos lugares (`agents/envinit/` y `skills/`), y la
instalación es una copia manual que se describe en `README.md` e `INSTALL.md`.
Las referencias internas del agente (adaptadores, `AGENT.md` y skills) apuntan a
las rutas **instaladas** (`.claude/envinit/AGENT.md`, `.claude/skills/`, etc.),
no a rutas del repo. Por eso mover archivos dentro del repo no afecta al agente
instalado. La única excepción es la sección final de `AGENT.md`, que describe
dónde se copia cada cosa y debe revisarse.

En este repo, `.claude/` y `.opencode/` contienen solo tooling de OpenSpec
(`opsx`, `openspec-*`) para desarrollar el agente.

## Goals / Non-Goals

**Goals:**
- Que un único directorio, `agent/`, contenga todo lo que se instala y nada más.
- Que la instalación no dependa de que la persona conozca el layout interno del
  repo.
- Que un asistente (Claude u OpenCode) que abra este repo entienda de inmediato
  que está desarrollando un agente y no ejecutándolo.

**Non-Goals:**
- Cambiar el comportamiento, el texto o las reglas del agente o de las skills.
- Empaquetar o distribuir el agente por un gestor de paquetes (npm, brew, etc.).
- Instalar el agente para "otros asistentes" (ChatGPT, Gemini, Cursor) desde el
  script: esos casos siguen documentados como copia manual.
- Migrar `context.md` a specs (cambio `specs-from-context`).

## Decisions

### Layout final

```
agent/                      producto (lo único que se instala)
  AGENT.md
  adapters/claude-code/envinit.md
  adapters/opencode/envinit.md
  skills/envinit-*/SKILL.md
scripts/install.ps1, install.sh
docs/INSTALL.md, docs/context.md
AGENTS.md, CLAUDE.md, README.md
openspec/   .claude/   .opencode/
```

- **`agent/` en singular, sin subcarpeta `envinit/`:** el repo tiene un solo
  agente (decisión confirmada), así que un nivel extra no aporta nada. Se
  descartó `agents/envinit/` porque sugiere un catálogo de agentes, y `src/`
  porque no es código.
- **Las skills dentro de `agent/`:** así "lo que se instala" queda en una sola
  carpeta y el script copia desde una única raíz.

### Mover con `git mv`

Se usa `git mv` para conservar el historial de cada archivo. El movimiento va en
un commit propio, sin cambios de contenido, para que git detecte los renombres
al 100% y el diff de las ediciones posteriores se lea por separado.

### Scripts: interfaz

| | PowerShell | Bash |
|---|---|---|
| Herramienta | `-Tool claude\|opencode` | `--tool claude\|opencode` |
| Proyecto | `-Target <ruta>` | `--target <ruta>` |
| Desinstalar | `-Uninstall` | `--uninstall` |
| Ayuda | `Get-Help` / `-?` | `--help` |

Cada script respeta las convenciones de su shell en lugar de forzar una sintaxis
común. La semántica de las opciones es la misma en ambos (ver spec).

- **La herramienta no se deduce del proyecto:** un proyecto nuevo puede no tener
  ni `.claude/` ni `.opencode/`, y uno puede tener las dos. Si falta y la
  terminal es interactiva, se pregunta; si no, el script falla. Así se mantiene
  predecible en CI o al pegar comandos.
- **Una herramienta por ejecución:** para instalar en las dos, se corre el script
  dos veces. Se descartó `--tool both` porque es un caso raro y complica el
  resumen.

### Scripts: comportamiento

1. Resuelven la raíz del repo a partir de la ubicación del propio script (no del
   directorio actual), y desde ahí ubican `agent/`.
2. Validan la herramienta y el proyecto destino antes de escribir nada.
3. Eliminan los restos de la versión antigua (`env-initializer`) y todas las
   carpetas `<dir>/skills/envinit-*` existentes.
4. Copian `AGENT.md`, el adaptador y las skills a las rutas de la spec.
5. Imprimen el resumen.

Borrar las `envinit-*` antes de copiar hace que la actualización sea
idempotente y que no queden skills retiradas. El borrado se limita
estrictamente a ese prefijo.

- **Compatibilidad:** `install.ps1` debe funcionar en Windows PowerShell 5.1
  (la que viene con Windows), no solo en PowerShell 7. `install.sh` usa bash
  y utilidades POSIX disponibles en macOS, Linux y Git Bash. No usa
  extensiones exclusivas de GNU.
- **Sin dependencias externas:** ninguno de los dos requiere instalar nada.

### AGENTS.md como fuente para asistentes de desarrollo

`AGENTS.md` es la guía canónica: OpenCode lo lee de forma nativa. `CLAUDE.md`
solo lo importa (`@AGENTS.md`), para no duplicar el contenido. `AGENTS.md`
explica:
- Qué es el producto (`agent/`) y que es lo único que se instala.
- Que `.claude/` y `.opencode/` de este repo son tooling de desarrollo y no el
  agente.
- Que los cambios se proponen y trabajan con OpenSpec (`/opsx:*`).
- Que las referencias de rutas dentro de `agent/` se escriben como rutas
  *instaladas* (`.claude/...` u `.opencode/...`).
- Que el agente se prueba instalándolo con el script en otro proyecto, nunca en
  este repo.

### Documentación

- `README.md`: qué es el agente, un mapa del repo (producto, proceso y tooling),
  instalación rápida con el script y enlaces a `docs/`.
- `docs/INSTALL.md`: uso de los scripts (instalar, actualizar, desinstalar,
  comprobar) y la copia manual para otros asistentes.
- `docs/context.md`: movido sin cambios de contenido.
- `openspec/config.yaml`: se completa `context` con una descripción breve del
  proyecto y del layout. No se agregan `rules` en este cambio.

## Risks / Trade-offs

- [Enlaces rotos a `context.md`, `INSTALL.md` o rutas viejas desde otros
  documentos] → Buscar en todo el repo `agents/envinit`, `skills/`,
  `context.md` e `INSTALL.md` después de mover, y corregir.
- [Diferencias de comportamiento entre `.ps1` y `.sh`] → Probar los dos con los
  mismos escenarios de la spec sobre proyectos de prueba temporales y comparar
  los árboles resultantes.
- [Un error en el borrado elimina archivos ajenos] → Borrado solo por rutas
  exactas o por el prefijo `envinit-` dentro de `<dir>/skills/`, nunca con
  comodines más amplios. Probar con un proyecto que tenga otras skills y una
  carpeta `local/`.
- [Política de ejecución de PowerShell bloquea `install.ps1`] → Documentar en
  `docs/INSTALL.md` cómo ejecutarlo
  (`powershell -ExecutionPolicy Bypass -File ...`).
- [Quien ya copiaba a mano busca `agents/` y `skills/` y no los encuentra] → El
  README muestra el script en la primera sección de instalación.

## Migration Plan

1. Commit 1: `git mv` de `agents/envinit/*` y `skills/*` a `agent/`, y de
   `INSTALL.md` y `context.md` a `docs/`.
2. Commit 2: scripts, `AGENTS.md`, `CLAUDE.md`, la documentación actualizada y
   `config.yaml`.
3. Rollback: revertir los dos commits. Las instalaciones en proyectos destino no
   se ven afectadas, porque las rutas instaladas no cambian.
