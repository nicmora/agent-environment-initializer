---
name: envinit-build
description: Paso 6 del agente envinit. Crea en env-local/ los archivos del entorno (compose, variables, scripts de arranque y apagado, datos de prueba, README), verifica que todo funciona, lo apaga y entrega el comando para arrancar y la URL de la aplicación. Usar después de que la persona confirma el resumen final.
---

# envinit-build

## Entrada

El resumen confirmado, las decisiones finales de `envinit-docker` y si Docker
quedó encendido o apagado.

## 1. Archivos

Agrega la línea `env-local/` al `.gitignore` del proyecto si no está. Si no hay
`.gitignore`, créalo con esa línea.

Crea dentro de `env-local/` lo que corresponda:

```
env-local/
  README.md
  .env
  start.ps1 / start.sh
  stop.ps1 / stop.sh
  docker-compose.yml      si algo corre en Docker
  Dockerfile.<proyecto>   si una app corre en Docker y no tiene Dockerfile
  wiremock/<servicio>/    si hay mocks (lo crea envinit-mocks)
  seed/                   si la persona eligió generar datos de prueba
```

Los scripts son para el sistema operativo de la persona: `.ps1` en Windows,
`.sh` en macOS o Linux.

### docker-compose.yml

- Declara `name: <prefijo>` y la red `<prefijo>-net`.
- Todas las rutas son relativas a `env-local/`, porque Docker Compose las
  resuelve desde la carpeta del archivo. El código del proyecto está en `..` y
  los mocks en `./wiremock/<servicio>`.
- Un servicio por contenedor, con el nombre, puerto, imagen, volumen,
  healthcheck y variables que decidió `envinit-docker`.
- Las aplicaciones en Docker usan `build` con contexto en la carpeta del
  proyecto (`..` o `../<proyecto>`), su propio `Dockerfile` o el de
  `env-local/`, `env_file: .env` y `depends_on` con
  `condition: service_healthy` hacia sus dependencias.
- Los mocks los define `envinit-mocks`.

### .env

Todas las variables que necesitan las aplicaciones y los contenedores, con un
comentario de una línea cada una. La dirección de cada dependencia depende de
desde dónde se conecta la aplicación:

| La app corre | La dependencia está | Dirección |
|---|---|---|
| En Docker | En Docker | `<nombre del servicio>:<puerto interno>` |
| Nativa | En Docker | `localhost:<puerto en la máquina>` |
| En Docker | En la máquina de la persona | `host.docker.internal:<puerto>` |
| Cualquiera | En otro servidor | El host y puerto que dio la persona |

Si la app corre en Docker y usa `host.docker.internal`, agrega
`extra_hosts: ["host.docker.internal:host-gateway"]` a su servicio.

### Scripts

Los scripts calculan la raíz del proyecto a partir de su propia ubicación, así
funcionan desde cualquier carpeta. No usan rutas absolutas.

**Arranque:**

1. Si hay Docker: verifica que Docker esté encendido y, si no, termina con un
   mensaje que pida encenderlo. Después ejecuta
   `docker compose -f env-local/docker-compose.yml up -d --build --wait`.
2. Para cada aplicación nativa: carga `env-local/.env`, entra a la carpeta del
   proyecto y arranca su comando en segundo plano. Guarda el identificador del
   proceso en `env-local/.run/<app>.pid` y su salida en
   `env-local/logs/<app>.log`.
3. Muestra la URL de cada aplicación.

**Apagado:**

1. Para cada archivo de `env-local/.run/`: detiene ese proceso y sus procesos
   hijos y borra el archivo. En Windows, usa `taskkill /PID <id> /T /F`. En
   macOS o Linux, detén primero los hijos con `pkill -P <id>` y después el
   proceso.
2. Si hay Docker: `docker compose -f env-local/docker-compose.yml down`, sin
   `-v`, para conservar los datos.

Los `.ps1` deben funcionar en Windows PowerShell 5.1 y guardarse en UTF-8 con
BOM. Los `.sh` deben funcionar con bash 3.2 y tener permiso de ejecución.

### seed/

Si la persona eligió generar datos de prueba, crea un script en el formato de
esa base (SQL para bases relacionales, un script de `mongosh` para MongoDB,
etc.). Los datos deben ser realistas y coherentes entre sí. Si eligió los
scripts del proyecto, no copies nada: usa los del proyecto.

### README.md

En lenguaje simple:

- Qué es cada cosa: cada aplicación y cada dependencia, con su modalidad.
- Requisitos: Docker encendido, si se usa, y el runtime y su versión para cada
  aplicación nativa. Si Docker quedó apagado, avisa que hay que encenderlo antes
  de arrancar.
- Cómo arrancar y cómo apagar, con el comando exacto.
- Puertos y URLs de acceso de cada aplicación y consola.
- Cómo volver a correr las migraciones y los datos de prueba, si se eligieron.
- Dónde están los mappings de los mocks y cómo agregar uno, si hay mocks.

## 2. Verificación

1. Si hay bases de datos con migraciones o datos de prueba elegidos, levanta
   solo esas bases
   (`docker compose -f env-local/docker-compose.yml up -d --wait <servicios>`)
   y corre una sola vez, en este orden:
   - Las migraciones, con el comando del proyecto. Si la app es nativa, desde su
     carpeta con `env-local/.env` cargado. Si corre en Docker, con
     `docker compose -f env-local/docker-compose.yml run --rm <app> <comando>`.
   - Los datos de prueba, con el script del proyecto o el de `seed/`.
2. Ejecuta el script de arranque.
3. Comprueba que cada aplicación responde: una petición HTTP a su URL que
   reciba respuesta. Si la aplicación no expone HTTP, revisa que el proceso siga
   vivo y que su log no muestre errores.
4. Ejecuta el script de apagado y confirma que no quedó ningún proceso ni
   contenedor del entorno corriendo.

Casos especiales:

- **Docker apagado:** no verifiques lo que corre en Docker y dilo. Tampoco
  verifiques las aplicaciones nativas que dependen de esos contenedores.
- **Runtime ausente:** si una aplicación nativa no arranca porque su runtime no
  está instalado, dilo y deja la versión necesaria en los requisitos del README.
- **Falla:** explica qué pasó en palabras simples y propone una solución. Si la
  solución cambia archivos de `env-local/`, aplícala solo cuando la persona
  acepte, y vuelve a verificar. Antes de responder, apaga lo que haya quedado
  levantado con el script de apagado.

## 3. Entrega

Termina con un mensaje corto que incluya:

- El comando exacto para arrancar, por ejemplo `.\env-local\start.ps1` o
  `./env-local/start.sh`.
- La URL donde ver la aplicación.
- El comando para apagar.
- Lo que quedó pendiente, si algo no se pudo verificar.
