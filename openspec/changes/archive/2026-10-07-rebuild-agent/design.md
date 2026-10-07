## Context

Ver proposal.md, sección Why. El agente es Markdown: `AGENT.md`, dos adaptadores
y skills `envinit-*` que se instalan en `.claude/` u `.opencode/` del proyecto
destino. Los scripts de instalación dependen del prefijo `envinit-` y eliminan
solos las skills que ya no existen en la versión nueva. El comportamiento está
definido en las seis specs nuevas de este cambio. Este documento define cómo se
reparten esas reglas entre archivos y algunas decisiones técnicas que las specs
no fijan.

## Goals / Non-Goals

**Goals:**
- Que cada regla del agente viva en un solo archivo, para que una corrección
  futura toque un solo lugar.
- Que cada skill corresponda a una spec, para que un cambio de comportamiento se
  rastree de la spec al archivo.
- Que los archivos generados funcionen en las dos ubicaciones en que se usan:
  ejecutados desde la raíz del proyecto y leídos por Docker Compose desde
  `env-local/`.

**Non-Goals:**
- Soportar otros mocks que no sean WireMock o simular colas, eventos y OIDC.
- Límites de recursos, perfiles de compose o imágenes parametrizadas.

## Decisions

### 1. Un dueño por regla

| Archivo | Spec que implementa | Contenido |
|---|---|---|
| `AGENT.md` | `agent-conduct` | Objetivo, comunicación, límites, flujo y qué skill usa cada paso |
| `envinit-scan` | `project-scan` | Scan y resumen |
| `envinit-wizard` | `setup-wizard` | Preguntas, datos de conexión, migraciones, datos de prueba, resumen final |
| `envinit-mocks` | `service-mocks` | WireMock, mappings y datos de mocks |
| `envinit-docker` | `docker-services` | Decisiones técnicas, encendido de Docker, reuso de imágenes, puertos |
| `envinit-build` | `environment-files` | Archivos de `env-local/`, verificación y entrega |

Una skill puede nombrar a otra para decir cuándo pasar a ella, pero no repite
sus reglas. Las reglas de comunicación y los límites solo están en `AGENT.md`:
las skills no los recuerdan ni los refuerzan. Alternativa descartada: repetir
los límites críticos en cada skill "por las dudas". Así nacieron las
contradicciones de la versión actual.

### 2. Adaptadores sin reglas

Cada adaptador tiene solo el frontmatter de su herramienta y la indicación de
leer `AGENT.md` en su ruta instalada. El nombre del selector de opciones de
cada herramienta (`AskUserQuestion` en Claude Code) va en `AGENT.md`, en la
regla de cómo preguntar, para no agregar reglas al adaptador.

### 3. Skills cortas y en el orden del flujo

Cada skill describe qué hace en su paso, qué produce y a qué skill se pasa
después. Lo que cada skill necesita de la anterior (por ejemplo, la lista de
dependencias del scan) se nombra en su entrada. No se incluyen ejemplos largos
de YAML por servicio: el modelo ya conoce las imágenes oficiales, y las
decisiones de `envinit-docker` alcanzan para elegirlas.

### 4. Rutas del compose relativas a env-local

`env-local/docker-compose.yml` escribe todas sus rutas relativas a su propia
carpeta: el contexto de build del proyecto es `..` y los mappings de WireMock
son `./wiremock/...`. Los scripts lo invocan con
`docker compose -f env-local/docker-compose.yml`. El compose declara `name:` con
el prefijo del proyecto, que también separa sus contenedores de los de otros
proyectos. Alternativa descartada: rutas relativas a la raíz. Docker Compose
resuelve las rutas desde la carpeta del archivo, y ese fue uno de los errores de
la versión actual.

### 5. Dockerfile

Si una aplicación se levanta con Docker y el proyecto tiene un `Dockerfile`, el
compose lo usa tal cual. Si no tiene, el agente crea uno en `env-local/` para
desarrollo. El `Dockerfile` original nunca se modifica.

### 6. Variables de entorno

Un solo archivo, `env-local/.env`, con todas las variables. Las aplicaciones en
Docker lo reciben por `env_file`. Las nativas lo cargan desde el script de
arranque antes de iniciar cada proceso. Las direcciones de cada dependencia se
escriben según desde dónde se conecta la aplicación: el nombre del servicio del
compose si la app corre en Docker, `localhost` y el puerto publicado si corre
nativa, y `host.docker.internal` si la app corre en Docker y el servicio
existente está en la máquina de la persona.

### 7. Arranque y apagado

El script de arranque levanta los contenedores en segundo plano y después
arranca las aplicaciones nativas, también en segundo plano. Guarda el
identificador de cada proceso nativo en `env-local/.run/` y sus logs en
`env-local/logs/`. El script de apagado detiene solo esos procesos y ejecuta
`docker compose down` sin `-v`. Así el apagado nunca afecta servicios que el
script no levantó y la verificación puede apagar todo sin intervención.
Alternativa descartada: arrancar la aplicación en primer plano. No sirve para
monorepos con varias aplicaciones nativas ni para que el agente verifique y
apague solo.

### 8. Migraciones y datos de prueba

El agente los corre una sola vez durante la verificación, con los contenedores
arriba y antes de comprobar la aplicación. Primero corre las migraciones con el
comando que el proyecto ya define y después los datos de prueba. No forman parte
del script de arranque, porque los datos de prueba duplicarían filas en cada
arranque. Los datos generados quedan en `env-local/seed/`, y el README explica
cómo volver a correr las migraciones y los datos.

### 9. Encender Docker

En Windows y macOS, el agente abre Docker Desktop. En Linux, intenta
`systemctl start docker`. Si necesita permisos de administrador que no tiene, le
explica a la persona cómo encenderlo y espera. En todos los casos espera a que
`docker info` responda antes de seguir.

## Risks / Trade-offs

- [El scan no encuentra todos los endpoints que consume la app y el mock queda
  incompleto] → El README de `env-local/` explica dónde están los mappings y cómo
  agregar uno.
- [Los procesos nativos en segundo plano quedan huérfanos si la verificación se
  interrumpe] → El script de apagado usa los identificadores guardados en
  `env-local/.run/` y se puede correr en cualquier momento.
- [Los datos de prueba fallan porque las migraciones no se corrieron] → Si la
  persona eligió datos de prueba sin migraciones, el agente lo avisa en el
  resumen final.
- [Los scripts PowerShell no corren en Windows PowerShell 5.1] → Se escriben
  compatibles con 5.1 y se guardan en UTF-8 con BOM.

## Migration Plan

1. Borrar `agent/AGENT.md`, los adaptadores y las ocho skills actuales.
2. Escribir `AGENT.md`, los dos adaptadores y las cinco skills nuevas.
3. Actualizar los mensajes de los scripts de instalación y la documentación.
4. Probar la instalación en un proyecto de prueba y recorrer el flujo completo.

Para volver atrás, se reinstala la versión anterior del repositorio. El
instalador reemplaza las skills y no toca `env-local/`.
