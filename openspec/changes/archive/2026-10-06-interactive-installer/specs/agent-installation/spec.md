## MODIFIED Requirements

### Requirement: Selección explícita de la herramienta
El script SHALL requerir que se indique al menos una herramienta destino:
`claude` (Claude Code), `opencode` (OpenCode) o ambas. Por opción, se indican
como una lista separada por comas (por ejemplo `claude,opencode`). Si no se
indica y la terminal es interactiva, el script MUST preguntarla con una lista de
casillas, una por herramienta, que se marcan y desmarcan escribiendo su número.
Al empezar, ninguna casilla MUST estar marcada, y el script MUST NOT avanzar
mientras no haya al menos una marcada. Si no se indica y la terminal no es
interactiva, el script MUST terminar con error sin escribir nada. El script MUST
NOT deducir la herramienta a partir del contenido del proyecto. La acción
(instalar o desinstalar) MUST aplicarse a cada herramienta elegida, y una
herramienta repetida en la lista MUST tratarse como una sola.

#### Scenario: Herramienta indicada
- **WHEN** se ejecuta el script con la herramienta `opencode` y un proyecto
  destino válido
- **THEN** el agente se instala bajo `.opencode/` del proyecto destino

#### Scenario: Ambas herramientas indicadas
- **WHEN** se ejecuta el script con las herramientas `claude,opencode` y un
  proyecto destino válido
- **THEN** el agente queda instalado bajo `.claude/` y bajo `.opencode/` del
  proyecto destino, cada uno con el adaptador de su herramienta

#### Scenario: Herramienta omitida en terminal interactiva
- **WHEN** se ejecuta el script sin indicar la herramienta en una terminal
  interactiva
- **THEN** el script muestra Claude Code y OpenCode como casillas sin marcar
  antes de escribir cualquier archivo

#### Scenario: Marcar y desmarcar casillas
- **WHEN** en la lista de casillas se escribe `2`, luego `1` y luego `2`, y se
  confirma
- **THEN** solo queda marcada Claude Code y el agente se instala únicamente
  para `claude`

#### Scenario: Confirmar sin ninguna casilla marcada
- **WHEN** en la lista de casillas se confirma sin haber marcado ninguna
- **THEN** el script avisa que hay que marcar al menos una herramienta y vuelve
  a mostrar la lista, sin escribir archivos

#### Scenario: Herramienta omitida sin terminal interactiva
- **WHEN** se ejecuta el script sin indicar la herramienta y sin terminal
  interactiva
- **THEN** el script termina con un código de error y un mensaje que explica la
  opción faltante, sin escribir archivos

#### Scenario: Herramienta inválida
- **WHEN** se indica una herramienta distinta de `claude` u `opencode`, sola o
  dentro de una lista
- **THEN** el script termina con un código de error sin escribir archivos para
  ninguna herramienta

### Requirement: Proyecto destino existente
El script SHALL requerir la ruta del proyecto destino. Si no se indica y la
terminal es interactiva, el script MUST preguntarla. La ruta escrita o pegada
MUST aceptarse aunque esté rodeada de comillas, tenga espacios al principio o
al final, empiece con `~` o, en macOS, Linux y Git Bash, tenga espacios
escapados con `\`. Si no se indica y la terminal no es interactiva, el script
MUST terminar con error sin escribir nada. Si la ruta no existe, no es un
directorio o es el propio repositorio del agente, el script MUST NOT crearla ni
escribir en ella: si la ruta se preguntó, MUST explicar el problema y volver a
preguntar; si se indicó por opción, MUST terminar con error.

#### Scenario: Ruta inexistente
- **WHEN** se indica por opción (`--target` / `-Target`) un proyecto destino
  que no existe
- **THEN** el script termina con un código de error y no crea ningún directorio

#### Scenario: Ruta omitida en terminal interactiva
- **WHEN** se ejecuta el script sin indicar el proyecto destino en una terminal
  interactiva
- **THEN** el script pregunta la ruta del proyecto antes de escribir cualquier
  archivo

#### Scenario: Ruta pegada con comillas
- **WHEN** a la pregunta de la ruta se responde con la ruta de un proyecto
  existente rodeada de comillas dobles
- **THEN** el script acepta la ruta sin las comillas y continúa

#### Scenario: Ruta inválida respondida a la pregunta
- **WHEN** a la pregunta de la ruta se responde con una carpeta que no existe
- **THEN** el script explica que la carpeta no existe y vuelve a preguntar, sin
  crear ningún directorio

#### Scenario: Destino igual al repositorio del agente
- **WHEN** el proyecto destino es la carpeta raíz del repositorio que contiene
  el script
- **THEN** el script no escribe ningún archivo y explica que el agente se
  instala en otro proyecto

#### Scenario: Ruta omitida sin terminal interactiva
- **WHEN** se ejecuta el script sin indicar el proyecto destino y sin terminal
  interactiva
- **THEN** el script termina con un código de error y un mensaje que explica la
  opción faltante, sin escribir archivos

### Requirement: Desinstalación
El script SHALL ofrecer una opción de desinstalación que elimine del proyecto
destino, para cada herramienta elegida, `<dir>/envinit/`,
`<dir>/agents/envinit.md`, todas las carpetas `<dir>/skills/envinit-*/` y los
restos de la versión antigua. La desinstalación MUST pedir la ruta y las
herramientas igual que la instalación cuando falten. La desinstalación MUST NOT
borrar los directorios `<dir>/`, `<dir>/agents/` ni `<dir>/skills/`, aunque
queden vacíos.

#### Scenario: Desinstalar
- **WHEN** se ejecuta la desinstalación para `claude` en un proyecto con el
  agente instalado y otras skills propias
- **THEN** no queda ningún archivo del agente bajo `.claude/` y las otras
  skills siguen presentes

#### Scenario: Desinstalar ambas herramientas
- **WHEN** se ejecuta la desinstalación para `claude,opencode` en un proyecto
  con el agente instalado para las dos
- **THEN** no queda ningún archivo del agente bajo `.claude/` ni bajo
  `.opencode/`

#### Scenario: Desinstalar sin el agente instalado
- **WHEN** se ejecuta la desinstalación en un proyecto que no tiene el agente
- **THEN** el script termina sin error e informa que no había nada para quitar

### Requirement: Resumen al terminar
Al terminar, el script SHALL mostrar en español el proyecto destino y, por cada
herramienta elegida, la acción realizada (instalación o desinstalación), qué se
eliminó de la versión antigua (si hubo algo) y cómo invocar al agente con esa
herramienta.

#### Scenario: Resumen tras instalar
- **WHEN** termina una instalación para `opencode`
- **THEN** el script muestra la ruta del proyecto y la de `.opencode/`, y cómo
  seleccionar el agente `envinit` en OpenCode

#### Scenario: Resumen tras instalar ambas herramientas
- **WHEN** termina una instalación para `claude,opencode`
- **THEN** el script muestra la ruta del proyecto y, para cada herramienta, la
  carpeta donde quedó el agente y cómo invocarlo

## ADDED Requirements

### Requirement: Confirmación antes de escribir
Si el script hizo al menos una pregunta (la ruta o las herramientas), SHALL
mostrar la acción, el proyecto destino y las herramientas elegidas, y MUST
pedir confirmación antes de escribir o borrar archivos. Si la respuesta es
negativa, el script MUST terminar sin escribir nada. Si no hizo ninguna
pregunta, el script MUST NOT pedir confirmación.

#### Scenario: Confirmar tras preguntas
- **WHEN** el script preguntó la ruta y las herramientas y se responde que sí a
  la confirmación
- **THEN** el script instala el agente para las herramientas elegidas

#### Scenario: Cancelar en la confirmación
- **WHEN** el script preguntó la ruta y se responde que no a la confirmación
- **THEN** el script termina sin escribir ni borrar archivos e informa que no
  se hizo nada

#### Scenario: Sin preguntas no hay confirmación
- **WHEN** se ejecuta el script indicando por opción la herramienta y un
  proyecto destino válido
- **THEN** el script instala sin pedir confirmación
