---
name: envinit-recipes
description: Recetas de configuración por tipo de servicio de infraestructura (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MinIO, Elasticsearch/OpenSearch, LocalStack, Keycloak, Mailpit). Define qué decide el agente solo, qué sigue preguntando y qué bloque de docker-compose + variables generar. Usar cuando hay que crear un servicio en Docker y se necesitan los detalles de configuración.
---

# Skill: envinit-recipes

Para cada servicio que **se crea en Docker**: **valores que el agente decide
solo** (imagen, versión, memoria, puerto), **datos que sigue preguntando**
(nombres/credenciales) y **bloque de compose**. Siempre incluir healthcheck y
volumen persistente nombrado.

Un servicio que se resolvió como **servicio existente** no usa estas recetas:
solo se registran sus datos de conexión en `local/.env.local` (ver
`envinit-plan`). La "ficha de conexión" de abajo sí
aplica a los dos casos.

## Camino Docker

> Los bloques de abajo muestran la forma del servicio. Al materializar,
> `envinit-compose` aplica sobre ellos: **imagen/tag por variable con default**
> (`image: ${SVC_IMAGE:-repo:tag-alpine}`), **variante pequeña primero** (alpine →
> slim → full, según lo que soporte la imagen) y **límites de recursos**
> (`deploy.resources.limits` + `mem_limit`). Aquí se escriben con el default ya
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

No preguntes imagen/variante, versión/tag, memoria ni puerto uno por uno — eso
frena el wizard con detalles técnicos que el agente puede resolver mejor que
haciendo preguntas. Decídelos tú con el criterio de abajo (ver también "Lo que
el agente decide solo" en `AGENT.md`) y déjalos, junto con una línea del porqué,
en el **resumen final del plan** de `envinit-plan`, donde solo entonces la
persona puede pedir cambiarlos.

Lo que **sí** sigues preguntando de forma explícita para cada servicio nuevo
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

0. **Imágenes ya descargadas primero.** Corre `docker image ls --format
   "{{.Repository}}:{{.Tag}}"` y busca una imagen del mismo repositorio que el
   servicio. Si hay una compatible (misma versión mayor que pide el proyecto, o
   cualquiera si no pide ninguna, y con tag numerado), úsala como default en vez
   de la de la tabla, para no descargar nada. Si hay varias, la variante más
   chica y luego la versión más nueva. Anota en `.env.example` que se eligió
   porque ya estaba descargada.
1. **Variante / imagen base** (si no hay ninguna descargada que sirva). Elige la
   variante más chica que soporte el stack:
   `alpine` (default de la tabla de abajo) → `slim`/`-bookworm-slim` si la imagen
   no publica alpine o el stack necesita glibc/extensiones nativas → `full` como
   último recurso.
2. **Versión / tag.** Si el proyecto ya fija una versión (driver/cliente con
   versión mínima), alinéate a esa. Si no hay pista, usa la estable/LTS que
   sugiere la receta. Nunca `latest` ni un tag sin número.
3. **Presupuesto de memoria.** Usa el perfil por defecto de la receta (`xs`
   256m / `s` 512m / `m` 1g / `l` 2g según el tipo de servicio).
4. **Puerto en el host.** Usa el puerto estándar del servicio. Si al levantar el
   entorno resulta estar ocupado, `envinit-verify` lo detecta y elige el
   siguiente puerto libre.

Con estos cuatro resueltos (más los nombres/credenciales que sí preguntaste)
haces el handoff a `envinit-compose`.

## Después de crear: ficha de conexión

Al terminar cada servicio, arma su **ficha de conexión** (ver "Resumen de
conexión y valores editables" en `AGENT.md`): host/puerto desde la app y desde
el host, credenciales (`local/.env.local`), espacio lógico, cadena de conexión lista
para pegar, variable/s de entorno, URL de consola/UI y comando de cliente
rápido. La ficha completa va a `local/ENVIRONMENT.md`; en el chat, solo una
línea simple (y la URL de la consola si tiene), con la ficha completa si la
persona la pide.

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
`envinit-compose` parametriza la imagen y la memoria al materializar
(`image: ${POSTGRES_IMAGE:-postgres:16-alpine}`, `mem_limit: ${POSTGRES_MEM:-512m}`)
y documenta las alternativas en `local/.env.example`
(`# POSTGRES_IMAGE=postgres:16-alpine (default) | 16-bookworm | 16`,
`# POSTGRES_MEM=512m (perfil s) | 256m | 1g`).
Vars: `DATABASE_URL=postgres://user:pass@postgres:5432/db`.

> Nota: en los bloques, solo las credenciales quedan como `${VAR}` (salen de
> `local/.env.local`); imagen, puerto y memoria van con el valor resuelto y los
> parametriza `envinit-compose`.

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
Comprobación: `mc ready local` (`mc` viene en la imagen).
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
Toda credencial generada va a `local/.env.local`, con su equivalente de
ejemplo en `local/.env.example`. Nunca escribas secretos fijos en el
compose.
