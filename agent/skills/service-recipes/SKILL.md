---
name: service-recipes
description: Recetas de configuración por tipo de servicio de infraestructura (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MinIO, Elasticsearch/OpenSearch, LocalStack, Keycloak, Mailpit). Define qué decide el agente solo, qué sigue preguntando, qué bloque de docker-compose + variables generar, y cómo instalar cada servicio de forma nativa (brew/apt/winget). Usar cuando hay que crear un servicio desde cero — en Docker o nativo — y se necesitan los detalles de configuración.
---

# Skill: service-recipes

Para cada servicio: **valores que el agente decide solo** (imagen/paquete,
versión, memoria, puerto), **datos que sigue preguntando** (nombres/credenciales),
**bloque de compose** (camino Docker) e **instalación nativa** (camino nativo).
Siempre incluir healthcheck/comprobación y almacenamiento persistente nombrado.

## Instalación nativa por servicio (camino sin Docker)

Cuando el servicio se resolvió como "instalar nativo", `native-setup` escribe en
`env/INSTALL.md` el comando del gestor de paquetes que reportó
`inspect-local-resources`. Nombres de paquete de referencia:

| Servicio | Homebrew (macOS) | apt (Debian/Ubuntu) | winget / scoop (Windows) | Arranque | Comprobación |
|---|---|---|---|---|---|
| PostgreSQL | `postgresql@16` | `postgresql-16` | `PostgreSQL.PostgreSQL.16` / `scoop install postgresql` | `brew services start postgresql@16` · `systemctl --now enable postgresql` | `pg_isready` |
| MySQL / MariaDB | `mysql` / `mariadb` | `mysql-server` / `mariadb-server` | `Oracle.MySQL` / `MariaDB.Server` | `brew services start mysql` | `mysqladmin ping` |
| MongoDB | `mongodb-community` (tap) | repo oficial `mongodb-org` | `MongoDB.Server` | `brew services start mongodb-community` | `mongosh --eval "db.adminCommand('ping')"` |
| Redis | `redis` | `redis-server` | `scoop install redis` / Memurai | `brew services start redis` | `redis-cli ping` |
| RabbitMQ | `rabbitmq` | `rabbitmq-server` | `scoop install rabbitmq` | `brew services start rabbitmq` | `rabbitmq-diagnostics -q ping` |
| Kafka | `kafka` | tarball de Apache | tarball de Apache | `brew services start kafka` | `kafka-topics --bootstrap-server localhost:9092 --list` |
| MinIO | `minio` | binario oficial | `scoop install minio` | `minio server env/data/minio` | `curl localhost:9000/minio/health/live` |
| Elasticsearch / OpenSearch | `elasticsearch` / `opensearch` | repo oficial | binario oficial | `brew services start …` | `curl localhost:9200` |
| Keycloak | `keycloak` | tarball oficial | tarball oficial | `keycloak start-dev` | `curl localhost:8080/health/ready` |
| Mailpit | `mailpit` | binario oficial | `scoop install mailpit` | `mailpit` | `curl localhost:8025` |

- **Versión:** la que pida el proyecto o la ya instalada si sirve; si no, la
  estable/LTS de la receta. Alineá el `@16` del paquete con esa decisión.
- **Puerto:** el estándar; si `inspect-local-resources` lo reporta ocupado,
  avisá y usá el flag del servicio para cambiarlo (`-p`, `--port`, `port=` en el
  config), reflejándolo en `env/.env.local`.
- **Datadir aislado (opcional):** `env/data/<servicio>/` en vez del datadir
  global, pasado como flag al arrancar. Nunca toques el datadir por defecto.
- Los comandos `install` se **muestran**; los ejecuta la persona o el agente con
  permiso explícito, uno por uno.

## Camino Docker

> Los bloques de abajo muestran la forma del servicio. Al materializar,
> `compose-builder` aplica sobre ellos: **imagen/tag por variable con default**
> (`image: ${SVC_IMAGE:-repo:tag-alpine}`), **variante pequeña primero** (alpine →
> slim → full, según lo que soporte la imagen) y **límites de recursos**
> (`deploy.resources.limits` + `mem_limit`). Acá se escriben con el default ya
> resuelto para que se lean; no los fijes así en el archivo final.

## Variantes de imagen recomendadas (default)

| Servicio | Default | Alternativas | Nota |
|---|---|---|---|
| PostgreSQL | `postgres:16-alpine` | `16-bookworm`, `16` | alpine ok salvo extensiones que pidan glibc |
| MySQL | `mysql:8.4` | `8.4-oracle`, `mariadb:11` | MySQL no publica alpine; MariaDB sí es más pequeña |
| MongoDB | `mongo:7` | — | sin alpine oficial; es la más pesada |
| Redis | `redis:7-alpine` | `7` | |
| RabbitMQ | `rabbitmq:3-management-alpine` | `3-management` | |
| Kafka | `bitnami/kafka:3.7` | `confluentinc/cp-kafka` | bitnami es más liviana |
| MinIO | `minio/minio` (release fija) | — | fija el tag `RELEASE.YYYY-…` |
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:8.x` | OpenSearch | pesada; límite ≥1g |
| Keycloak | `quay.io/keycloak/keycloak:25` | — | |
| Mailpit | `axllent/mailpit:v1.x` (tag fijo, nunca `latest`) | — | imagen ya mínima |

## Qué decide el agente solo, y qué sigue preguntando

No preguntes imagen/variante o paquete, versión/tag, memoria ni puerto uno por
uno — eso frena el wizard con detalles técnicos que el agente puede resolver
mejor que haciendo preguntas. Decidilos vos con el criterio de abajo (ver
también "Lo que el agente decide solo" en `AGENT.md`) y déjalos, junto con una
línea del porqué, en el **resumen final del plan** de `brownfield-wizard`/
`greenfield-wizard`, donde recién ahí la persona puede pedir cambiarlos. Esto
vale tanto para el camino Docker (imagen/tag/memoria/puerto) como para el nativo
(nombre de paquete, versión, puerto).

Lo que **sí** seguís preguntando de forma explícita para cada servicio nuevo
(son decisiones de la persona, no técnicas): nombre de DB/schema/bucket/vhost,
usuario y contraseña de dev, y nombre de contenedor/volumen/red si hay
preferencia.

| Dato | Quién decide |
|---|---|
| nombre de DB / schema / bucket / vhost | la persona (pregunta) |
| usuario / contraseña de dev | la persona (pregunta) |
| nombre de contenedor / volumen / red | la persona, con default `<prefijo-proyecto>_…` |
| imagen y variante (`<SVC>_IMAGE`) | el agente (ver criterio) |
| versión / tag | el agente (ver criterio) |
| puerto en el host | el agente (ver criterio) |
| límite y reserva de memoria (`<SVC>_MEM`, `<SVC>_MEM_RES`) | el agente (perfil por defecto de la receta) |

### Criterio para decidir imagen, versión, memoria y puerto

1. **Variante / imagen base.** Si `inspect-local-resources` detectó una imagen
   de este servicio ya pulleada o corriendo localmente y sirve (misma familia,
   versión compatible con lo que necesita el proyecto), usá esa — ahorra la
   descarga y mantiene consistencia con lo que ya hay. Si no hay nada
   reutilizable, elegí la variante más chica que soporte el stack: `alpine`
   (default de la tabla de abajo) → `slim`/`-bookworm-slim` si la imagen no
   publica alpine o el stack necesita glibc/extensiones nativas → `full` como
   último recurso.
2. **Versión / tag.** Si el proyecto ya fija una versión (driver/cliente con
   versión mínima, otro contenedor de ese motor ya corriendo), alineate a esa.
   Si no hay pista, usá la estable/LTS que sugiere la receta. Nunca `latest` ni
   un tag sin número.
3. **Presupuesto de memoria.** Usá el perfil por defecto de la receta (`xs`
   256m / `s` 512m / `m` 1g / `l` 2g según el tipo de servicio).
4. **Puerto en el host.** Usá el puerto estándar del servicio. Si
   `inspect-local-resources` reporta que ya está ocupado, elegí vos el
   siguiente puerto libre.

Con estos cuatro resueltos (más los nombres/credenciales que sí preguntaste)
hacés el handoff a `compose-builder`.

## Después de crear: ficha de conexión

Al terminar cada servicio, muestra su **ficha de conexión** (ver "Resumen de
conexión y valores editables" en `AGENT.md`): host/puerto desde la app y desde
el host, credenciales (`env/.env.local`), espacio lógico, cadena de conexión lista
para pegar, variable/s de entorno, URL de consola/UI y comando de cliente
rápido.

## PostgreSQL
Se pregunta: nombre de DB, usuario/clave de dev, ¿volumen persistente? (default sí).
El agente fija: imagen/variante (`postgres:16-alpine`), versión, memoria (perfil
`s`), puerto host (5432 o el siguiente libre).
```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  ports: ["5432:5432"]
  volumes: ["pgdata:/var/lib/postgresql/data"]
  mem_limit: 512m
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
    interval: 5s
    timeout: 5s
    retries: 10
```
`compose-builder` parametriza la imagen y la memoria al materializar
(`image: ${POSTGRES_IMAGE:-postgres:16-alpine}`, `mem_limit: ${POSTGRES_MEM:-512m}`)
y documenta las alternativas en `env/.env.example`
(`# POSTGRES_IMAGE=postgres:16-alpine (default) | 16-bookworm | 16`,
`# POSTGRES_MEM=512m (perfil s) | 256m | 1g`).
Vars: `DATABASE_URL=postgres://user:pass@postgres:5432/db`.

> Nota: en los bloques, solo las credenciales quedan como `${VAR}` (salen de
> `env/.env.local`); imagen, puerto y memoria van con el valor resuelto y los
> parametriza `compose-builder`.

## MySQL / MariaDB
Se pregunta: nombre de DB, usuario/clave de dev, root pass.
El agente fija: imagen/versión (`mysql:8.4`, o `mariadb:11` si se necesita una
variante más chica), memoria (perfil `s`), puerto (3306 o el siguiente libre).
Healthcheck: `mysqladmin ping`. Volumen `/var/lib/mysql`.

## MongoDB
Se pregunta: usuario/clave root, DB inicial, ¿replica set? (default no; sí si usa
transacciones/change streams).
El agente fija: imagen/versión (`mongo:7`), memoria (perfil `s`), puerto (27017 o
el siguiente libre).
Healthcheck: `mongosh --eval "db.adminCommand('ping')"`.

## Redis
Se pregunta: ¿password? (default no en dev), ¿persistencia AOF? (default no),
base numerada a usar.
El agente fija: imagen/versión (`redis:7-alpine`), memoria (perfil `xs`), puerto
(6379 o el siguiente libre).
Healthcheck: `redis-cli ping`. Vars: `REDIS_URL=redis://redis:6379/<n>`.

## RabbitMQ
Se pregunta: usuario/clave de dev, vhost, ¿UI de management? (15672).
El agente fija: imagen/versión (`rabbitmq:3-management-alpine`), memoria (perfil
`s`), puerto AMQP (5672 o el siguiente libre).
```yaml
rabbitmq:
  image: rabbitmq:3-management-alpine
  environment:
    RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
    RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASS}
    RABBITMQ_DEFAULT_VHOST: ${RABBITMQ_VHOST:-/}
  ports: ["5672:5672", "15672:15672"]
  healthcheck:
    test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
```

## Kafka (KRaft, sin Zookeeper)
Se pregunta: ¿schema registry? ¿kafka-ui? Prefijo de topics del proyecto.
El agente fija: imagen/versión (`bitnami/kafka:3.7`; `confluentinc/cp-kafka` como
alternativa), memoria (perfil `m`), puerto externo (9092 o el siguiente libre).
Healthcheck: `kafka-topics.sh --bootstrap-server localhost:9092 --list`.

## MinIO (S3 local)
Se pregunta: usuario/clave root, bucket inicial.
El agente fija: imagen (`minio/minio` con tag `RELEASE.YYYY-…` fijo), memoria
(perfil `s`), puerto API (9000) y consola (9001), o los siguientes libres.
```yaml
minio:
  image: minio/minio:RELEASE.2024-01-16T16-07-38Z   # fijar el release real al materializar
  command: server /data --console-address ":9001"
  environment:
    MINIO_ROOT_USER: ${MINIO_ROOT_USER}
    MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
  ports: ["9000:9000", "9001:9001"]
  volumes: ["miniodata:/data"]
  healthcheck:
    test: ["CMD", "mc", "ready", "local"]
```
Comprobación: `mc ready local` en Docker (`mc` viene en la imagen);
`curl -f localhost:9000/minio/health/live` en el camino nativo.
Vars: `S3_ENDPOINT=http://minio:9000`, `S3_FORCE_PATH_STYLE=true`.

## Elasticsearch / OpenSearch
Se pregunta: seguridad on/off (default off en dev).
El agente fija: imagen/versión
(`docker.elastic.co/elasticsearch/elasticsearch:8.x`; OpenSearch como
alternativa), `discovery.type=single-node`, memoria (perfil `l`, con
`ES_JAVA_OPTS=-Xms512m -Xmx512m` alineado al límite), puerto (9200 o el siguiente
libre).

## LocalStack (AWS)
Se pregunta: qué servicios AWS se emulan (`SERVICES=s3,sqs,sns,...`).
El agente fija: imagen/versión, memoria (perfil `l` si hay varios servicios),
puerto (4566 o el siguiente libre).
Vars de la app: `AWS_ENDPOINT_URL=http://localstack:4566`, credenciales dummy.

## Keycloak (OIDC)
Se pregunta: admin user/pass, realm del proyecto, ¿import de realm?
El agente fija: imagen/versión (`quay.io/keycloak/keycloak:25`), memoria (perfil
`m`), puerto (8080 o el siguiente libre).
`command: start-dev`. Healthcheck en `/health/ready`.

## Mailpit (SMTP de pruebas)
Se pregunta: nada (no tiene credenciales ni espacio lógico).
El agente fija: imagen/versión (`axllent/mailpit` con tag fijo), memoria (perfil
`xs`), puertos SMTP (1025) y UI (8025), o los siguientes libres.
```yaml
mailpit:
  image: axllent/mailpit:v1.21   # fijar el tag real al materializar
  ports: ["1025:1025", "8025:8025"]
```
Vars: `SMTP_HOST=mailpit`, `SMTP_PORT=1025`.

## Regla general
Toda credencial generada va a `env/.env.local`, con su equivalente de
ejemplo en `env/.env.example`. Nunca escribas secretos fijos en el
compose.
