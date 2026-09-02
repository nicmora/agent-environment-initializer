---
name: env-compose-builder
description: Genera o actualiza archivos docker-compose (base, override o dev) y los .env asociados a partir de las decisiones del wizard, sin reescribir ni romper la infraestructura existente. Maneja redes, volúmenes, perfiles (--profile), depends_on con healthchecks y mapeo de puertos evitando colisiones. Usar cuando ya está decidida la estrategia por dependencia y hay que "crear los archivos" / "armar el compose".
---

# Skill: compose-builder

## Entrada

La tabla de decisiones de `brownfield-wizard` o `greenfield-wizard`, la lista de
puertos ocupados de `inspect-local-resources`, y las recetas de
`service-recipes`.

## Reglas de archivos

- **Greenfield sin compose previo** → crea `docker-compose.yml` + `.env.example`
  + `.env.local`.
- **Brownfield con compose previo** → NO lo toques. Crea
  `docker-compose.override.yml` (se aplica automático) o
  `docker-compose.dev.yml` (se aplica con `-f`). Prefiere `override` salvo que ya
  exista uno con otro propósito.
- Muestra siempre el archivo completo o el *diff* y pide confirmación antes de
  escribir.
- Actualiza `.gitignore`: agrega `.env.local`, `.env.*.local`,
  `docker-compose.dev.yml` si contiene datos sensibles (si no, versiónalo).

## Construcción

1. **Servicios de la app.** Si la app corre en contenedor, define `build:` o
   `image:`, `env_file: [.env, .env.local]`, `ports`, `depends_on` con
   `condition: service_healthy`, `develop.watch` o bind mounts para hot reload.
2. **Servicios de infra creados desde cero.** Toma la definición de
   `service-recipes` (imagen+versión, env, volumen nombrado, healthcheck).
   Ponlos bajo un `profiles: ["infra"]` si la persona quiere poder omitirlos.
   Parametriza imagen/tag y límites de recursos (ver secciones siguientes).
3. **Conexión a pila compartida.** No redefinas la infra; declara la red externa
   y apunta las variables al nombre de servicio de la pila (ver `shared-infra`).
4. **Conexión a recurso local / externo.** No agregues servicio; solo define las
   variables en `.env.local`. Para servicios del host desde un contenedor usa
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

Presupuestos sugeridos por tipo (ofrécelos como tabla y deja elegir):

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
- **No materialices ningún servicio sin haber confirmado con la persona el
  perfil de recursos y los valores concretos de `mem_limit` y `mem_reservation`**
  (default marcado como recomendado + alternativas + opción personalizada). Eso
  se pregunta en `service-recipes`; si llegaste acá sin esa respuesta, vuelve a
  preguntar antes de escribir el archivo. Lo mismo vale para la variante de
  imagen y la versión/tag.

## Dockerfile de desarrollo

Cuando la app necesita contenedor propio y no hay Dockerfile:

- Base como `ARG` con default pequeño y pisable en build:
  ```dockerfile
  ARG NODE_VERSION=20
  ARG NODE_VARIANT=alpine
  FROM node:${NODE_VERSION}-${NODE_VARIANT} AS base
  ```
- Elige la variante igual que para infra: alpine → slim → full, según lo que
  tolere el stack (paquetes nativos, Prisma, `sharp`, `puppeteer`, etc.).
- Expón los `ARG` en el compose para no editar el Dockerfile:
  ```yaml
  build:
    context: .
    args:
      NODE_VERSION: ${NODE_VERSION:-20}
      NODE_VARIANT: ${NODE_VARIANT:-alpine}
  ```
- Multi-stage: deps → build → runtime pequeño. Usuario no-root. `.dockerignore`.

## Variables de entorno

- `.env.example`: todas las claves con valores de ejemplo/dev **no sensibles**.
  Versionado. Incluye `SHARED_INFRA_DIR=` (vacío o `../docker-environment`) si el
  proyecto usa una pila compartida por ruta.
- **Sin rutas absolutas de máquina** en `.env.example`, compose ni scripts
  versionados. La ruta real de la pila compartida vive en `.env.local`.
- `.env.local`: valores reales/secretos. Ignorado por git. Genera los que
  correspondan a conexiones externas o credenciales creadas.
- Documenta cada variable con un comentario de una línea.

## Scripts de conveniencia

Crea (si la persona quiere) en `scripts/`:
- `dev-up` → `docker compose --profile infra up -d && docker compose up`
- `dev-down` → `docker compose down` (SIN `-v`)
- `dev-logs` → `docker compose logs -f`
O los targets equivalentes en `Makefile` / `Taskfile.yml`.

## Salida

Lista de archivos creados/modificados y el comando de arranque. Handoff a
`verify-environment`.

## Renombrar valores

Si la persona pide cambiar un nombre (DB, schema, usuario, volumen, contenedor,
red, base de Redis, vhost, bucket, prefijo de topics, puerto host), aplica el
cambio **en todos los archivos a la vez**: compose/override, `.env.local`,
`.env.example`, scripts y `ENVIRONMENT.md` (deriva a `document-environment`).
Muestra el diff completo. Si el recurso viejo ya se había creado, no lo borres
sin permiso: acláralo entre los pendientes.
