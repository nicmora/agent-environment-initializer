---
name: env-brownfield-wizard
description: Para cada dependencia detectada en un proyecto existente, guía la elección de estrategia — reutilizar un recurso local o la pila compartida, conectar a una instancia externa, crear el servicio desde cero en Docker, o simularlo (mock). Usar después de detect-environment e inspect-local-resources, o cuando el usuario quiere decidir "cómo conecto cada cosa".
---

# Skill: brownfield-wizard

## Requisitos previos

Tener el resumen de `detect-environment` (stack, dependencias, configuración) ya
mostrado a la persona. **Todavía no ejecutes `inspect-local-resources`** — se
invoca recién más adelante, y solo para las dependencias donde haga falta (ver
paso 2).

## Procedimiento

### 0. Cómo arranca la app

Antes de recorrer las dependencias, pregunta cómo se quiere levantar la
aplicación misma: ¿en contenedor propio (Docker) o corriendo en el host?, ¿con
qué comando (`npm run dev`, `./gradlew bootRun`, …) si va a correr en el host?
Esto define si más adelante hace falta un `Dockerfile` de desarrollo.

### 1. Estrategia por dependencia

Recorre el inventario **de a una dependencia por vez**: presentas sus hallazgos,
preguntas su estrategia y cierras su configuración (espacio lógico,
credenciales) antes de pasar a la siguiente. No juntes en una misma pregunta
decisiones de dependencias distintas (la DB y el mock de un servicio externo van
en preguntas separadas). El puerto **no** se pregunta: si se reutiliza un
recurso, es el que ya tiene; si se crea desde cero, lo decide el agente (ver
paso 4 y "Lo que el agente decide solo" en `AGENT.md`).

Para cada dependencia, presenta las opciones y pide una decisión. Orden de
preferencia sugerido (pero la persona elige):

1. **Pila de infraestructura compartida.** ¿Existe o se quiere crear una pila
   compartida del equipo? → deriva a `shared-infra`. Se crea un espacio lógico
   aislado para este servicio (schema/DB, base numerada de Redis, vhost de
   RabbitMQ, topic namespace de Kafka, bucket de MinIO, prefijo de claves).
2. **Recurso ya presente en la máquina.** Recién acá hace falta mirar la
   máquina: ejecuta `inspect-local-resources` (si todavía no la corriste en
   esta sesión) para saber qué hay.
   - Contenedor Docker corriendo → conectar a ese: detecta nombre, red, puerto
     publicado y credenciales (de `docker inspect` / variables del contenedor si
     se pueden leer). Configura la app para usar ese host/puerto.
   - Servicio instalado en el SO (Postgres, Redis, etc. en el host) → apunta la
     app a `localhost:<puerto>` y, si hace falta, crea una DB/usuario nuevos
     **sin tocar** lo existente.
   - En ambos casos: **no metas la app en una DB/schema/vhost/bucket existente
     sin preguntar.** Ofrece crear un espacio lógico propio y propón un nombre
     (editable) para él.
3. **Instancia externa** (staging, cloud, otro equipo) → pide host, puerto,
   credenciales y guárdalas en `env/.env.local`. Verifica conectividad de
   red. No hace falta tocar Docker para esta estrategia.
4. **Crear desde cero en Docker** → esto también requiere `inspect-local-resources`
   (Docker instalado/iniciado, puertos libres) si todavía no se corrió. Solo
   preguntas nombre de DB/schema/usuario/contraseña de dev si aplica. Deriva a
   `service-recipes`, que **decide solo** (sin preguntar) la variante/imagen
   base, la versión/tag, el presupuesto de memoria y el puerto en el host, con
   el criterio de esa skill; el servicio va a
   `env/docker-compose.override.yml` o `env/docker-compose.dev.yml`
   (nunca al compose existente fuera de `env/`). Esos valores técnicos aparecen
   recién en el resumen final (paso siguiente), no acá.
5. **Servicio de terceros / de otro equipo** → deriva a `external-mocks`:
   conexión real vs. simulación. No requiere Docker salvo que el mock elegido
   corra como contenedor.

Si al terminar de recorrer todas las dependencias ninguna quedó en "reutilizar
local" ni "crear desde cero", nunca se ejecutó `inspect-local-resources` — está
bien, no hacía falta.

## Manejo de conflictos (no destructivo)

- **Puerto ocupado** → el agente elige directamente el siguiente puerto libre
  en el host y ajusta la variable de conexión (lo anota en el resumen final,
  no hace falta preguntarlo). Nunca mates el proceso que lo usa sin permiso
  explícito.
- **Nombre de contenedor/volumen/red en uso** → usa un nombre nuevo con prefijo
  del proyecto.
- **Ya existe una DB/schema con ese nombre** → propón un nombre alternativo; no
  la sobrescribas.
- **Versión distinta** entre lo detectado y lo disponible → avisa y deja que la
  persona decida.

## Salida

Una tabla de decisiones:

| Dependencia | Estrategia elegida | Espacio lógico (DB/schema/vhost/bucket) | Variables de entorno a setear | Archivo destino (dentro de `env/`) |
|---|---|---|---|---|

Los nombres de espacios lógicos (DB, schema, usuario, base de Redis, vhost,
bucket, prefijo) son **propuestas editables** que confirmás con la persona
antes del handoff. El puerto y, para lo que se crea desde cero, la imagen,
versión y memoria **no** van en esta confirmación por-dependencia: los resuelve
el agente y aparecen por primera vez en el resumen final de abajo.

### Resumen final antes de materializar

Con todas las dependencias resueltas, presenta un **resumen consolidado del
plan completo**: la tabla de arriba, más — para cada servicio creado desde
cero — la imagen/variante, versión, memoria y puerto que decidió el agente
(con una línea de por qué), más la lista de archivos que se van a crear en
`env/` (compose, `.env.example`, `.env.local`, Dockerfile, scripts, mocks,
`ENVIRONMENT.md`). Pregunta explícitamente si hay algo para cambiar o
personalizar — acá es donde la persona puede pedir otra imagen, otro puerto,
etc. Solo con el plan confirmado, haz el handoff a `compose-builder` (para lo
que haya que crear) y a `document-environment`.
