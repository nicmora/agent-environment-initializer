---
name: envinit-compose
description: Genera o actualiza archivos docker-compose (base, override o dev) y los .env asociados a partir de las decisiones del wizard, sin reescribir ni romper la infraestructura existente. Maneja redes, volúmenes, perfiles (--profile), depends_on con healthchecks y mapeo de puertos evitando colisiones. Usar cuando ya está decidida la estrategia por dependencia y hay que "crear los archivos" / "armar el compose".
---

# Skill: envinit-compose

Esta skill materializa el **camino Docker**: los servicios de infra que se crean
en Docker, los mocks, y la app si corre en contenedor. Si la app corre **nativa**
(runtime en el host), esa parte la maneja `envinit-native`; cuando el plan es mixto
(app nativa + dependencias en Docker), las dos skills generan sus artefactos en
`local/` y un mismo script de arranque en `local/scripts/` los orquesta.

Las dependencias que se resolvieron como **servicio existente** no generan
servicio en el compose: solo variables en `local/.env.local`.

## Entrada

El **plan ya confirmado** (con la persona habiendo tenido la oportunidad de
cambiar algo, ver "Resumen final" en `envinit-plan`): la tabla de decisiones
y las recetas de `envinit-recipes`. No materialices nada si ese resumen final
todavía no se mostró y confirmó.

## Todo vive en `local/`

Todo lo que esta skill genera va **dentro de una carpeta `local/` en la
raíz del proyecto**, nunca en la raíz junto al código. Es la carpeta 3 de las
reglas invariables de `AGENT.md`: personal, no versionada.

- Primera vez que se crea `local/` en el proyecto: agrega la línea
  `local/` a `.gitignore` (créalo si no existe) y muéstraselo a la persona.
  No hace falta ignorar archivo por archivo — la carpeta entera queda afuera de
  git.
- **Sin `docker-compose*.yml` propio fuera de `local/`** → crea
  `local/docker-compose.yml` + `local/.env.example` + `local/.env.local`. Todo el
  compose vive en ese archivo.
- **Con un `docker-compose*.yml` propio en la raíz del repo** → **NO lo
  toques.** Crea `local/docker-compose.override.yml` o
  `local/docker-compose.dev.yml`. Como ya no vive al lado del compose base,
  Docker Compose **no lo va a mezclar solo**: el comando de arranque (script en
  `local/`, ver más abajo) tiene que pasar ambos con `-f` explícito, p. ej.
  `docker compose -f docker-compose.yml -f local/docker-compose.override.yml
  --env-file local/.env.local up`. Documenta ese comando exacto en el
  resumen y en `ENVIRONMENT.md`.
- Pide confirmación antes de escribir, diciendo en lenguaje simple qué archivos
  vas a crear o cambiar y para qué (regla 2 de `AGENT.md`). Ofrecé mostrar el
  archivo completo o el *diff*, y mostralo si la persona lo pide.

## Construcción

1. **Servicios de la app.** Si la app corre en contenedor, define `build:` o
   `image:`, `env_file: [local/.env.example, local/.env.local]`,
   `ports`, `depends_on` con `condition: service_healthy`, `develop.watch` o
   bind mounts para hot reload.
2. **Servicios de infra creados en Docker.** Toma la definición de
   `envinit-recipes` (imagen+versión, env, volumen nombrado, healthcheck).
   Ponlos bajo un `profiles: ["infra"]` si la persona quiere poder omitirlos.
   Parametriza imagen/tag y límites de recursos (ver secciones siguientes).
3. **Conexión a un servicio existente.** No agregues servicio al compose; solo
   define las variables en `local/.env.local` con el host/puerto/credenciales que
   aportó la persona y el espacio lógico que ya tiene provisto. Si la app corre
   en contenedor y el servicio está en el host de la persona, usa
   `host.docker.internal` (agrega `extra_hosts: ["host.docker.internal:host-gateway"]`
   en Linux); si es un host remoto, va tal cual.
4. **Mocks.** Agrega los servicios de mock bajo `profiles: ["mock"]` (ver
   `envinit-mocks`).
5. **Puertos.** Usa el puerto estándar de cada servicio (lo fijó
   `envinit-recipes`). No hay lista previa de ocupados: si al levantar el entorno
   hay colisión, `envinit-verify` la detecta y propone el siguiente libre,
   que se refleja en `.env.example`/`.env.local`.
6. **Redes y volúmenes.** Nombres con prefijo del proyecto. Nunca reutilices el
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
`envinit-recipes`):

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
  vienen decididos por el agente cuando llegás a esta skill (`envinit-recipes`
  los resolvió con su criterio automático y los mostró en el resumen final). No
  hace falta volver a preguntarlos acá; si la persona pidió cambiar alguno en
  ese resumen, materializa con el valor que confirmó.

## Dockerfile de desarrollo

Cuando la app necesita contenedor propio y no hay Dockerfile:

- Va a `local/Dockerfile.dev`. El contexto de build sigue siendo la raíz
  del proyecto (para que los `COPY` vean el código), solo cambia dónde vive el
  Dockerfile:
  ```yaml
  build:
    context: .
    dockerfile: local/Dockerfile.dev
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
  `local/.dockerignore` (o el `.dockerignore` de la raíz si ya existe; no lo
  dupliques).

## Variables de entorno

- `local/.env.example`: todas las claves con valores de ejemplo/dev.
- **Sin rutas absolutas de máquina** en ningún archivo de `local/`, aunque
  no se versionen: si la persona regenera el entorno en otra máquina o desde
  otra carpeta, tiene que volver a armarse sin fricción.
- `local/.env.local`: valores reales/secretos. Genera los que correspondan a
  conexiones externas o credenciales creadas.
- Documenta cada variable con un comentario de una línea.

## Scripts de conveniencia

Crea (si la persona quiere) en `local/scripts/` (o directo en `local/`
si son pocos):
- `dev-up` → arma el comando completo con los `-f` que correspondan, p. ej.
  `docker compose -f docker-compose.yml -f local/docker-compose.override.yml
  --env-file local/.env.local --profile infra up -d && docker compose -f
  docker-compose.yml -f local/docker-compose.override.yml --env-file
  local/.env.local up` (si no hay compose previo, sin el primer `-f`, usando solo
  `local/docker-compose.yml`, pero manteniendo `--env-file local/.env.local`).
- `dev-down` → el mismo comando con `down` (SIN `-v`).
- `dev-logs` → el mismo comando con `logs -f`.
O los targets equivalentes en `local/Makefile` / `local/Taskfile.yml`.

**Plan mixto (app nativa + dependencias en Docker):** el script de
`local/scripts/dev-up` hace las dos cosas en orden — primero levanta la infra en
contenedor (`docker compose … --profile infra up -d`), después delega en el
arranque nativo de la app de `envinit-native` (fijar runtime, `foreman`/`overmind`
sobre `local/Procfile`, o el comando directo). Coordiná los nombres con
`envinit-native` para no duplicar.

## Salida

Lista de archivos creados/modificados dentro de `local/` (y la línea
agregada a `.gitignore`), y el comando de arranque completo con sus `-f`.
Si el plan es mixto, hacé también el handoff a `envinit-native` antes de
`envinit-verify`; si es solo Docker, handoff directo a `envinit-verify`.

## Renombrar valores

Si la persona pide cambiar un nombre (DB, schema, usuario, volumen, contenedor,
red, base de Redis, vhost, bucket, prefijo de topics, puerto host), aplica el
cambio **en todos los archivos a la vez**: compose/override, `.env.local`,
`.env.example`, scripts y `ENVIRONMENT.md` (todos dentro de `local/`; deriva
a `envinit-document`). Contá en una línea qué cambia y ofrecé mostrar el diff. Si el recurso viejo ya se
había creado, no lo borres sin permiso: acláralo entre los pendientes.
