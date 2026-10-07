## Purpose

Define lo que el agente decide solo para todo lo que corre en Docker y cómo
prepara Docker antes de crear los archivos del entorno.

## ADDED Requirements

### Requirement: Decisiones técnicas sin preguntar
Para cada contenedor, el agente SHALL decidir sin preguntar:
- El nombre del contenedor, con un prefijo común del proyecto.
- El puerto, usando el estándar de la tecnología salvo que el proyecto indique
  otro.
- Una red de Docker compartida por todos los contenedores del proyecto.
- La imagen, con versión fija y priorizando variantes reducidas (`alpine`,
  `slim`). Si el proyecto define una versión, MUST respetarla.
- Los volúmenes para persistir datos, los healthchecks y las variables
  necesarias.

Estas decisiones MUST aparecer en el resumen final, donde la persona puede
cambiarlas.

#### Scenario: Base de datos con versión definida
- **WHEN** el proyecto declara PostgreSQL 15 y la base se levanta con Docker
- **THEN** la imagen elegida es una variante reducida de PostgreSQL 15 con tag
  numerado, sin preguntarlo

#### Scenario: Nombres con prefijo
- **WHEN** el proyecto se llama `tienda` y se levantan una base y un cache
- **THEN** los dos contenedores llevan el prefijo `tienda` y comparten una
  misma red

#### Scenario: Imagen sin versión fija
- **WHEN** el agente elige la imagen de cualquier contenedor
- **THEN** el tag tiene número de versión y nunca es `latest`

### Requirement: Docker encendido antes de crear archivos
Si algo se levanta con Docker, después de la confirmación del resumen final el
agente SHALL verificar si Docker está encendido. Si está apagado, MUST preguntar
si la persona quiere encenderlo. Si acepta, MUST encenderlo y seguir. Si no
acepta, MUST crear los archivos igual e indicar en `env-local/README.md` que hay
que encender Docker antes de arrancar.

#### Scenario: Docker apagado y la persona acepta
- **WHEN** Docker está apagado y la persona acepta encenderlo
- **THEN** el agente lo enciende y continúa con la implementación

#### Scenario: Docker apagado y la persona no acepta
- **WHEN** Docker está apagado y la persona no quiere encenderlo
- **THEN** el agente crea los archivos y el README indica que hay que encender
  Docker antes de arrancar

### Requirement: Reuso de imágenes descargadas
Con Docker encendido, el agente SHALL revisar las imágenes ya descargadas. Si
una es compatible con una dependencia (misma tecnología y versión compatible con
el proyecto), MUST usarla en lugar de descargar otra. Si eso reemplaza una
imagen del resumen confirmado, MUST avisar cuál cambia y por qué antes de crear
los archivos.

#### Scenario: Imagen compatible descargada
- **WHEN** el resumen confirmado usa `postgres:15-alpine` y la máquina ya tiene
  `postgres:15.4`
- **THEN** el agente avisa que usará `postgres:15.4` porque ya está descargada,
  y después crea los archivos

### Requirement: Puerto ocupado
Si el puerto elegido para un contenedor está ocupado en la máquina, el agente
SHALL usar el siguiente puerto libre y avisarlo antes de crear los archivos. MUST
NOT detener el proceso que ocupa el puerto.

#### Scenario: Puerto estándar en uso
- **WHEN** el puerto 5432 ya está en uso en la máquina
- **THEN** el agente usa el siguiente puerto libre, lo avisa y no detiene el
  proceso que usa el 5432
