## Purpose

Define cómo se instala, actualiza y desinstala el agente `envinit` en un
proyecto destino mediante scripts, para Claude Code u OpenCode, sin tocar nada
del proyecto que no pertenezca al agente.

## ADDED Requirements

### Requirement: Scripts de instalación equivalentes por plataforma
El repositorio SHALL proveer un script de instalación para Windows (PowerShell)
y otro para macOS, Linux y Git Bash. Los dos MUST aceptar las mismas opciones y
producir el mismo resultado en el proyecto destino.

#### Scenario: Mismo resultado en ambas plataformas
- **WHEN** se instala el agente para la misma herramienta en dos proyectos
  idénticos, uno con cada script
- **THEN** los archivos instalados y sus rutas son idénticos en ambos proyectos

### Requirement: Selección explícita de la herramienta
El script SHALL requerir que se indique la herramienta destino: `claude` (Claude
Code) u `opencode` (OpenCode). Si no se indica y la terminal es interactiva, el
script MUST preguntarla. Si no se indica y la terminal no es interactiva, el
script MUST terminar con error sin escribir nada. El script MUST NOT deducir la
herramienta a partir del contenido del proyecto.

#### Scenario: Herramienta indicada
- **WHEN** se ejecuta el script con la herramienta `opencode` y un proyecto
  destino válido
- **THEN** el agente se instala bajo `.opencode/` del proyecto destino

#### Scenario: Herramienta omitida en terminal interactiva
- **WHEN** se ejecuta el script sin indicar la herramienta en una terminal
  interactiva
- **THEN** el script pregunta entre `claude` y `opencode` antes de escribir
  cualquier archivo

#### Scenario: Herramienta omitida sin terminal interactiva
- **WHEN** se ejecuta el script sin indicar la herramienta y sin terminal
  interactiva
- **THEN** el script termina con un código de error y un mensaje que explica la
  opción faltante, sin escribir archivos

#### Scenario: Herramienta inválida
- **WHEN** se indica una herramienta distinta de `claude` u `opencode`
- **THEN** el script termina con un código de error sin escribir archivos

### Requirement: Proyecto destino existente
El script SHALL requerir la ruta del proyecto destino. Si la ruta no existe o no
es un directorio, el script MUST terminar con error sin crearla.

#### Scenario: Ruta inexistente
- **WHEN** se indica un proyecto destino que no existe
- **THEN** el script termina con un código de error y no crea ningún directorio

### Requirement: Rutas de instalación
Al instalar para una herramienta `<dir>` (`.claude` para Claude Code,
`.opencode` para OpenCode), el script SHALL dejar en el proyecto destino:
- `<dir>/envinit/AGENT.md`: las reglas y el flujo del agente.
- `<dir>/agents/envinit.md`: el adaptador correspondiente a la herramienta.
- `<dir>/skills/envinit-*/`: una carpeta por cada skill del agente.

El script MUST crear los directorios que falten bajo `<dir>`.

#### Scenario: Instalación en un proyecto sin carpeta de la herramienta
- **WHEN** se instala para `claude` en un proyecto que no tiene `.claude/`
- **THEN** el proyecto queda con `.claude/envinit/AGENT.md`,
  `.claude/agents/envinit.md` y todas las skills `envinit-*` en
  `.claude/skills/`

#### Scenario: Solo el adaptador de la herramienta elegida
- **WHEN** se instala para `claude`
- **THEN** `.claude/agents/` contiene el adaptador de Claude Code como
  `envinit.md` y no contiene `AGENT.md` ni el adaptador de OpenCode

### Requirement: No tocar archivos ajenos al agente
El script MUST crear, sobrescribir o borrar únicamente estos archivos del agente:
`<dir>/envinit/`, `<dir>/agents/envinit.md` y `<dir>/skills/envinit-*/`, además
de los archivos de la versión antigua definidos en "Limpieza de la versión
antigua". Cualquier otro archivo del proyecto destino MUST quedar intacto,
incluidas otras skills, otros agentes y la carpeta `local/` que genera el
agente.

#### Scenario: Proyecto con otras skills y agentes
- **WHEN** se instala en un proyecto cuyo `.claude/skills/` y `.claude/agents/`
  ya contienen skills y agentes propios
- **THEN** esas skills y esos agentes quedan sin cambios después de instalar

#### Scenario: Entorno local ya generado
- **WHEN** se instala, se actualiza o se desinstala en un proyecto que tiene una
  carpeta `local/`
- **THEN** la carpeta `local/` y su contenido quedan sin cambios

### Requirement: Actualización idempotente
Ejecutar la instalación sobre un proyecto que ya tiene el agente SHALL dejarlo
igual que una instalación limpia de la versión actual. Las skills `envinit-*`
instaladas que ya no existan en la versión actual MUST eliminarse.

#### Scenario: Reinstalar la misma versión
- **WHEN** se ejecuta la instalación dos veces seguidas con las mismas opciones
- **THEN** el resultado es idéntico al de ejecutarla una sola vez

#### Scenario: Skill retirada en la versión nueva
- **WHEN** el proyecto tiene instalada una skill `envinit-*` que la versión
  actual del agente ya no incluye y se ejecuta la instalación
- **THEN** esa skill deja de estar en `<dir>/skills/`

### Requirement: Limpieza de la versión antigua
Al instalar, el script SHALL eliminar del directorio de la herramienta los
restos de la versión anterior del agente, cuando el agente se llamaba
`env-initializer`: `<dir>/env-initializer/`, `<dir>/agents/env-initializer.md`
y las carpetas de skills `detect-environment`, `plan-environment`,
`compose-builder`, `native-setup`, `service-recipes`, `external-mocks`,
`verify-environment` y `document-environment` dentro de `<dir>/skills/`.

#### Scenario: Proyecto con la versión antigua
- **WHEN** se instala en un proyecto que tiene `.claude/agents/env-initializer.md`
  y `.claude/skills/detect-environment/`
- **THEN** después de instalar esos archivos ya no existen y el agente `envinit`
  quedó instalado

### Requirement: Desinstalación
El script SHALL ofrecer una opción de desinstalación que elimine del proyecto
destino, para la herramienta indicada, `<dir>/envinit/`,
`<dir>/agents/envinit.md`, todas las carpetas `<dir>/skills/envinit-*/` y los
restos de la versión antigua. La desinstalación MUST NOT borrar los
directorios `<dir>/`, `<dir>/agents/` ni `<dir>/skills/`, aunque queden vacíos.

#### Scenario: Desinstalar
- **WHEN** se ejecuta la desinstalación para `claude` en un proyecto con el
  agente instalado y otras skills propias
- **THEN** no queda ningún archivo del agente bajo `.claude/` y las otras
  skills siguen presentes

#### Scenario: Desinstalar sin el agente instalado
- **WHEN** se ejecuta la desinstalación en un proyecto que no tiene el agente
- **THEN** el script termina sin error e informa que no había nada para quitar

### Requirement: Resumen al terminar
Al terminar, el script SHALL mostrar en español la herramienta, el proyecto
destino, la acción realizada (instalación o desinstalación), qué se eliminó de
la versión antigua (si hubo algo) y cómo invocar al agente con esa herramienta.

#### Scenario: Resumen tras instalar
- **WHEN** termina una instalación para `opencode`
- **THEN** el script muestra la ruta del proyecto y la de `.opencode/`, y cómo
  seleccionar el agente `envinit` en OpenCode
