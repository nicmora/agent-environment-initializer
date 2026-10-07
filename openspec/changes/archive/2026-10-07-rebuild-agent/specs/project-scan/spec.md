## Purpose

Define qué analiza el agente del proyecto antes de preguntar nada y cómo
presenta lo que encontró, incluidos los repositorios con varios proyectos.

## ADDED Requirements

### Requirement: Scan solo del proyecto
El scan SHALL analizar únicamente los archivos del proyecto. Durante el scan, el
agente MUST NOT verificar qué herramientas tiene instaladas la persona (Docker,
runtimes u otras).

#### Scenario: Scan sin chequear herramientas
- **WHEN** el agente hace el scan de un proyecto
- **THEN** no ejecuta comandos que consulten Docker ni versiones de runtimes
  instalados

### Requirement: Qué detecta el scan
El scan SHALL detectar el lenguaje y su runtime, el gestor de dependencias, los
scripts de arranque, los puertos, los archivos de configuración (`.env`,
`.env.example`, `application.yml`, `docker-compose`, `Dockerfile` y similares)
y las variables de entorno que usa el proyecto. También MUST detectar sus
dependencias: bases de datos, caches, colas, almacenamiento y APIs o servicios
externos. Para cada base de datos, MUST detectar si el proyecto tiene
migraciones o scripts que inicializan el esquema con datos.

#### Scenario: Proyecto con base de datos y migraciones
- **WHEN** el proyecto usa PostgreSQL y tiene una carpeta de migraciones
- **THEN** el scan registra la base de datos como dependencia y anota que tiene
  migraciones

#### Scenario: Proyecto que consume una API externa
- **WHEN** el código llama a una API de pagos de un tercero
- **THEN** el scan registra esa API como dependencia externa

### Requirement: Monorepos
Si el repositorio contiene varios proyectos, el scan SHALL identificar cada
proyecto, sus dependencias y si alguno consume a otro del mismo repositorio.

#### Scenario: Frontend que consume un backend del mismo repo
- **WHEN** el repositorio tiene un frontend y un backend, y el frontend llama a
  la API del backend
- **THEN** el scan identifica los dos proyectos y registra que el frontend
  depende del backend

### Requirement: Resumen del scan
Después del scan, el agente SHALL mostrar un resumen breve con qué es la
aplicación, qué proyectos tiene y qué dependencias necesita. Si no tiene
dependencias, MUST decirlo y pasar directo a preguntar la forma de arranque.

#### Scenario: Proyecto sin dependencias
- **WHEN** el scan no encuentra dependencias
- **THEN** el resumen dice que no necesita otros servicios y la siguiente
  pregunta es la forma de arranque
