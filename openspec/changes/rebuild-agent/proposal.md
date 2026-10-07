## Why

El agente creció a fuerza de pedidos sueltos por prompt y hoy tiene reglas
repetidas en hasta ocho lugares, varias contradicciones entre `AGENT.md`, las
skills y los adaptadores, y algunos errores que generan entornos que no
arrancan (rutas relativas mal resueltas en el compose, mocks que nunca se
levantan). Además, su comportamiento no está especificado, así que no hay contra
qué validar una corrección. En lugar de seguir parchando, se reescribe el agente
desde cero a partir de una definición nueva y acotada de cómo debe funcionar.

## What Changes

- **BREAKING** Se borran `agent/AGENT.md`, los dos adaptadores y las ocho skills
  actuales (`envinit-detect`, `envinit-plan`, `envinit-compose`,
  `envinit-native`, `envinit-recipes`, `envinit-mocks`, `envinit-verify`,
  `envinit-document`), y se escriben de nuevo.
- El agente nuevo tiene cinco skills, una por tramo del flujo: `envinit-scan`,
  `envinit-wizard`, `envinit-mocks`, `envinit-docker` y `envinit-build`.
- Cada regla vive en un solo archivo. `AGENT.md` tiene el objetivo, la forma de
  comunicarse, los límites y el flujo. Los adaptadores solo tienen el
  frontmatter de la herramienta y la indicación de leer `AGENT.md`.
- Todo lo que genera el agente pasa de la carpeta `local/` a `env-local/`, y la
  guía del entorno pasa de `ENVIRONMENT.md` a `env-local/README.md`.
- Comportamiento nuevo respecto del agente actual:
  - El scan reconoce monorepos: proyectos, sus dependencias y cuáles consumen a
    otros del mismo repo. La forma de arranque se pregunta por proyecto.
  - Si el proyecto ya trae datos de conexión, se sugieren y se piden confirmar.
  - Los mocks se hacen siempre con WireMock en Docker, con mappings basados en
    los endpoints que el proyecto consume y datos de prueba coherentes.
  - El agente decide sin preguntar nombre de contenedor, puerto, red, imagen,
    volúmenes y healthchecks, y los muestra en el resumen final.
  - Antes de crear archivos, verifica que Docker esté encendido y ofrece
    encenderlo. Reusa imágenes ya descargadas y avisa si cambia alguna.
  - Para bases nuevas en Docker, pregunta si se corren las migraciones del
    proyecto y si se cargan datos de prueba.
  - Verifica que todo funcione, apaga lo que levantó y entrega el comando para
    que la persona arranque el entorno.
- Se quitan comportamientos que hoy existen: límites de memoria y CPU,
  imágenes parametrizadas por variable, perfiles de compose, `Procfile` y
  gestores de procesos, y las recetas por servicio.
- `docs/context.md`, `README.md` y `docs/INSTALL.md` se reescriben para la
  estructura nueva.

## Capabilities

### New Capabilities

- `agent-conduct`: cómo se comunica el agente, cómo pregunta y qué límites
  nunca cruza.
- `project-scan`: qué analiza el agente del proyecto y cómo presenta el
  resumen, incluidos los monorepos.
- `setup-wizard`: las preguntas sobre forma de arranque, dependencias, datos de
  conexión, migraciones y datos de prueba, y el resumen final con confirmación.
- `service-mocks`: cómo se simulan los servicios externos con WireMock.
- `docker-services`: lo que el agente decide solo para lo que corre en Docker,
  y la preparación de Docker antes de crear archivos.
- `environment-files`: los archivos que se generan en `env-local/`, la
  verificación del entorno y la entrega final.

### Modified Capabilities

- `agent-installation`: la carpeta que el instalador nunca toca pasa a ser
  `env-local/`.

## Impact

- `agent/`: se reemplaza por completo.
- `scripts/install.sh` y `scripts/install.ps1`: solo cambian los mensajes que
  nombran `local/`. Las skills retiradas se eliminan solas al reinstalar, por la
  regla de actualización idempotente.
- `docs/context.md`, `docs/INSTALL.md` y `README.md`: se reescriben.
