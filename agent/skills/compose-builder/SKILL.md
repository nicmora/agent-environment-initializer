---
name: compose-builder
description: Genera o actualiza archivos docker-compose (base, override o dev) y los .env asociados a partir de las decisiones del wizard, sin reescribir ni romper la infraestructura existente. Maneja redes, volúmenes, perfiles (--profile), depends_on con healthchecks y mapeo de puertos evitando colisiones. Usar cuando ya está decidida la estrategia por dependencia y hay que "crear los archivos" / "armar el compose".
---

# Skill: compose-builder

Esta skill materializa el **camino Docker**. Si la app o alguna dependencia se
resolvió de forma **nativa** (runtime en el host, servicio instalado en el SO),
esa parte la maneja `native-setup`; cuando el plan es mixto, las dos skills
generan sus artefactos en `env/` y un mismo script de arranque en `env/scripts/`
los orquesta.

## Entrada

El **plan ya confirmado** (con la persona habiendo tenido la oportunidad de
cambiar algo, ver "Resumen final" en `brownfield-wizard`/`greenfield-wizard`):
la tabla de decisiones, la lista de puertos ocupados de
`inspect-local-resources` (si se ejecutó), y las recetas de `service-recipes`.
No materialices nada si ese resumen final todavía no se mostró y confirmó.

## Todo vive en `env/`

Todo lo que esta skill genera va **dentro de una carpeta `env/` en la
raíz del proyecto**, nunca en la raíz junto al código. Es la carpeta 3 de las
reglas invariables de `AGENT.md`: personal, no versionada.

- Primera vez que se crea `env/` en el proyecto: agrega la línea
  `env/` a `.gitignore` (créalo si no existe) y muéstraselo a la persona.
  No hace falta ignorar archivo por archivo — la carpeta entera queda afuera de
  git.
- **Greenfield sin compose previo** → crea `env/docker-compose.yml` +
  `env/.env.example` + `env/.env.local`.
- **Brownfield con `docker-compose*.yml` en la raíz del repo** → **NO lo
  toques.** Crea `env/docker-compose.override.yml` o
  `env/docker-compose.dev.yml`. Como ya no vive al lado del compose base,
  Docker Compose **no lo va a mezclar solo**: el comando de arranque (script en
  `env/`, ver más abajo) tiene que pasar ambos con `-f` explícito, p. ej.
  `docker compose -f docker-compose.yml -f env/docker-compose.override.yml
  --env-file env/.env.local up`. Documenta ese comando exacto en el
  resumen y en `ENVIRONMENT.md`.
- **Brownfield sin compose previo** → igual que greenfield: todo el compose vive
  en `env/docker-compose.yml`.
- Muestra siempre el archivo completo o el *diff* y pide confirmación antes de
  escribir.

## Construcción

1. **Servicios de la app.** Si la app corre en contenedor, define `build:` o
   `image:`, `env_file: [env/.env.example, env/.env.local]`,
   `ports`, `depends_on` con `condition: service_healthy`, `develop.watch` o
   bind mounts para hot reload.
2. **Servicios de infra creados desde cero.** Toma la definición de
   `service-recipes` (imagen+versión, env, volumen nombrado, healthcheck).
   Ponlos bajo un `profiles: ["infra"]` si la persona quiere poder omitirlos.
   Parametriza imagen/tag y límites de recursos (ver secciones siguientes).
3. **Conexión a un contenedor de dependencias compartido** (si la persona eligió
   reutilizar uno, según `inspect-local-resources`). No redefinas esos servicios:
   declará su red de Docker como externa
   (`networks: { <red>: { external: true } }`), conectá los servicios de la app a
   esa red y apuntá las variables al nombre de servicio del contenedor
   compartido (`DB_HOST=postgres`, `REDIS_URL=redis://redis:6379/<n>`). El
   espacio lógico (DB/schema, base numerada, vhost, bucket) se crea de forma
   aditiva, nunca con `DROP`. Si la app corre nativa, no hay red que unir: apuntá
   las variables a los puertos publicados en `localhost`. La ruta/nombre del
   contenedor de otra máquina no se hardcodea; lo estable es el nombre de la red
   y los nombres de servicio.
4. **Conexión a recurso local / externo.** No agregues servicio; solo define las
   variables en `env/.env.local`. Para servicios del host desde un contenedor usa
   `host.docker.internal` (agrega `extra_hosts: ["host.docker.internal:host-gateway"]`
   en Linux).
5. **Mocks.** Agrega los servicios de mock bajo `profiles: ["mock"]` (ver
   `external-mocks`).
6. **Puertos.** Para cada puerto publicado, verifica contra la lista de
   ocupados. Si choca, asigna el siguiente libre y refléjalo en `.env.example`.
7. **Redes y volúmenes.** Nombres con prefijo del proyecto. Nunca reutilices el
   nombre de un volumen existente con datos.

## Imágenes y versiones parametrizadas

Nunca fijes una imagen ni un tag fijo en el compose. Cada imagen sale de una
variable con **default embebido** para que funcione sin configurar nada, pero se
pueda pisar desde `.env.local` sin editar el YAML:

```yaml
postgres:
  image: ${POSTGRES_IMAGE:-postgres:16-alpine}
```

- En `.env.example` documenta la variable, el default y las alternativas
  reales de esa imagen (`# postgres:16-alpine (default) | 16-bookworm | 16`).
- **Prefiere variantes pequeñas**: `-alpine` primero; si la imagen no tiene
  alpine o rompe (glibc, extensiones nativas, `mongo`/`mssql` que no publican
  alpine), cae a `-slim` / `-bookworm-slim`; recién después a la full. Anota en
  `.env.example` por qué se eligió esa base.
- El tag siempre lleva versión explícita (`16-alpine`, no `alpine` ni `latest`).
- Mismo criterio para el `build:` de la app: pasa la base como `ARG`
  (ver "Dockerfile de desarrollo").

## Límites de recursos

Todo servicio (infra, mocks y app en contenedor) lleva un tope de memoria y CPU
con default conservador y override por variable. Reserva poco, limita con
holgura:

```yaml
x-svc-small: &svc-small
  deploy:
    resources:
      limits:   { cpus: "${SVC_CPUS:-1}",     memory: "${SVC_MEM:-512m}" }
      reservations: { memory: "${SVC_MEM_RES:-128m}" }

services:
  postgres:
    <<: *svc-small
    mem_limit: ${POSTGRES_MEM:-512m}   # compat con `docker compose up` sin swarm
```

Presupuestos por tipo — el agente elige el perfil, no lo pregunta (ver
`service-recipes`):

| Perfil | Límite mem | Uso |
|---|---|---|
| `xs` | 256m | Redis, Mailpit, mocks, adminers |
| `s` (default) | 512m | Postgres, MySQL, MongoDB, RabbitMQ, MinIO |
| `m` | 1g | Kafka, Keycloak, app en contenedor |
| `l` | 2g | Elasticsearch/OpenSearch, LocalStack con varios servicios |

- Para servicios JVM (ES/OpenSearch, Kafka), alinea el heap con el límite
  (`ES_JAVA_OPTS=-Xms512m -Xmx512m` dentro de un límite de 1g).
- Documenta cada tope en `.env.example` y suma una fila "memoria reservada" a la
  ficha de conexión.
- Si la persona no quiere límites, déjalos comentados con una nota, no los
  borres.
- La imagen/variante, la versión/tag, el perfil de memoria y el puerto ya
  vienen decididos por el agente cuando llegás a esta skill (`service-recipes`
  los resolvió con su criterio automático y los mostró en el resumen final). No
  hace falta volver a preguntarlos acá; si la persona pidió cambiar alguno en
  ese resumen, materializa con el valor que confirmó.

## Dockerfile de desarrollo

Cuando la app necesita contenedor propio y no hay Dockerfile:

- Va a `env/Dockerfile.dev`. El contexto de build sigue siendo la raíz
  del proyecto (para que los `COPY` vean el código), solo cambia dónde vive el
  Dockerfile:
  ```yaml
  build:
    context: .
    dockerfile: env/Dockerfile.dev
    args:
      NODE_VERSION: ${NODE_VERSION:-20}
      NODE_VARIANT: ${NODE_VARIANT:-alpine}
  ```
- Base como `ARG` con default pequeño y pisable en build:
  ```dockerfile
  ARG NODE_VERSION=20
  ARG NODE_VARIANT=alpine
  FROM node:${NODE_VERSION}-${NODE_VARIANT} AS base
  ```
- Elige la variante igual que para infra: alpine → slim → full, según lo que
  tolere el stack (paquetes nativos, Prisma, `sharp`, `puppeteer`, etc.).
- Multi-stage: deps → build → runtime pequeño. Usuario no-root.
  `env/.dockerignore` (o el `.dockerignore` de la raíz si ya existe; no lo
  dupliques).

## Variables de entorno

- `env/.env.example`: todas las claves con valores de ejemplo/dev.
- **Sin rutas absolutas de máquina** en ningún archivo de `env/`, aunque
  no se versionen: si la persona regenera el entorno en otra máquina o desde
  otra carpeta, tiene que volver a armarse sin fricción.
- `env/.env.local`: valores reales/secretos. Genera los que correspondan a
  conexiones externas o credenciales creadas.
- Documenta cada variable con un comentario de una línea.

## Scripts de conveniencia

Crea (si la persona quiere) en `env/scripts/` (o directo en `env/`
si son pocos):
- `dev-up` → arma el comando completo con los `-f` que correspondan, p. ej.
  `docker compose -f docker-compose.yml -f env/docker-compose.override.yml
  --env-file env/.env.local --profile infra up -d && docker compose -f
  docker-compose.yml -f env/docker-compose.override.yml --env-file
  env/.env.local up` (en greenfield/sin compose previo, sin el primer
  `-f`, usando solo `env/docker-compose.yml`).
- `dev-down` → el mismo comando con `down` (SIN `-v`).
- `dev-logs` → el mismo comando con `logs -f`.
O los targets equivalentes en `env/Makefile` / `env/Taskfile.yml`.

**Plan mixto (parte Docker + parte nativa):** el script de `env/scripts/dev-up`
hace las dos cosas en orden — primero levanta lo de Docker (`docker compose …
up -d` para la infra en contenedor), después delega en el arranque nativo de
`native-setup` (fijar runtime, levantar servicios del SO, `foreman`/`overmind`
sobre `env/Procfile`). Coordiná los nombres con `native-setup` para no duplicar.

## Salida

Lista de archivos creados/modificados dentro de `env/` (y la línea
agregada a `.gitignore`), y el comando de arranque completo con sus `-f`.
Si el plan es mixto, hacé también el handoff a `native-setup` antes de
`verify-environment`; si es solo Docker, handoff directo a `verify-environment`.

## Renombrar valores

Si la persona pide cambiar un nombre (DB, schema, usuario, volumen, contenedor,
red, base de Redis, vhost, bucket, prefijo de topics, puerto host), aplica el
cambio **en todos los archivos a la vez**: compose/override, `.env.local`,
`.env.example`, scripts y `ENVIRONMENT.md` (todos dentro de `env/`; deriva
a `document-environment`). Muestra el diff completo. Si el recurso viejo ya se
había creado, no lo borres sin permiso: acláralo entre los pendientes.
