# environment-files Specification

## Purpose

Define los archivos que el agente genera para el entorno local, cómo verifica
que funcionan y qué le entrega a la persona al terminar.

## Requirements

### Requirement: Todo en env-local
El agente SHALL crear todos los archivos del entorno dentro de la carpeta
`env-local/` en la raíz del proyecto, y MUST agregar `env-local/` al
`.gitignore` del proyecto si todavía no está.

#### Scenario: Primer uso en un proyecto
- **WHEN** el agente implementa el entorno en un proyecto sin `env-local/`
- **THEN** todos los archivos nuevos quedan dentro de `env-local/` y el
  `.gitignore` contiene la línea `env-local/`

### Requirement: Archivos mínimos
El agente SHALL crear como mínimo:
- Un script para arrancar todo.
- Un script para apagar todo.
- Un archivo de variables de entorno.
- Un `docker-compose.yml`, si algo se levanta con Docker.
- Los mappings y datos de WireMock, si hay mocks.
- Un script de datos de prueba, si la persona eligió generarlos.
- Un `README.md` con instrucciones simples: cómo arrancar, cómo apagar, puertos
  y URLs de acceso, qué es cada cosa y los requisitos que la persona tiene que
  cumplir.

Los scripts MUST ser para el sistema operativo de la persona: PowerShell en
Windows y shell en macOS o Linux.

#### Scenario: Entorno con Docker y mocks en Windows
- **WHEN** la persona usa Windows, la base se levanta con Docker y una API se
  mockea
- **THEN** `env-local/` contiene los scripts de arranque y apagado en
  PowerShell, el archivo de variables, el `docker-compose.yml`, los mappings de
  WireMock y el `README.md`

#### Scenario: Aplicación nativa sin dependencias
- **WHEN** la aplicación se levanta de forma nativa y no tiene dependencias
- **THEN** `env-local/` no contiene `docker-compose.yml`

### Requirement: Apagado acotado
El script de apagado SHALL detener únicamente lo que levanta el script de
arranque, sin borrar volúmenes ni datos.

#### Scenario: Servicio existente en la máquina
- **WHEN** la aplicación se conecta a un PostgreSQL ya instalado en la máquina
  y se ejecuta el script de apagado
- **THEN** ese PostgreSQL sigue corriendo

### Requirement: Verificación del entorno
Después de crear los archivos, el agente SHALL verificar que el entorno
funciona: arranca todo con el script de arranque, corre una sola vez las
migraciones y los datos de prueba que la persona eligió (primero las
migraciones), comprueba que la aplicación responde y apaga todo con el script de
apagado. Al terminar, MUST NOT quedar levantada la aplicación ni los contenedores
que arrancó la verificación. Si algo falla, MUST explicar el problema en
palabras simples y proponer una solución. Si Docker quedó apagado porque la
persona no quiso encenderlo, MUST omitir la verificación de lo que corre en
Docker y decirlo.

#### Scenario: Verificación exitosa
- **WHEN** el entorno arranca y la aplicación responde
- **THEN** el agente apaga todo con el script de apagado y no queda ningún
  proceso ni contenedor del entorno corriendo

#### Scenario: Migraciones y datos de prueba
- **WHEN** la persona eligió correr migraciones y generar datos de prueba
- **THEN** durante la verificación se corren las migraciones y después los
  datos de prueba, una sola vez, y el README explica cómo volver a correrlos

#### Scenario: La aplicación no responde
- **WHEN** la aplicación no responde durante la verificación
- **THEN** el agente explica la causa en palabras simples, propone una solución
  y no borra datos ni volúmenes

### Requirement: Entrega final
Al terminar, el agente SHALL indicar el comando exacto para arrancar el entorno
y la URL donde ver la aplicación, para que la persona lo arranque.

#### Scenario: Cierre
- **WHEN** termina la verificación
- **THEN** el último mensaje incluye el comando para arrancar y la URL de la
  aplicación
