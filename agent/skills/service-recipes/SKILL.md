---
name: env-service-recipes
description: Recetas de configuración por tipo de servicio de infraestructura (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MinIO, Elasticsearch/OpenSearch, LocalStack, Keycloak, Mailpit). Define qué decide el agente solo, qué sigue preguntando y qué bloque de docker-compose + variables generar para cada uno. Usar cuando hay que crear un servicio desde cero y se necesitan los detalles de configuración.
---

# Skill: service-recipes

Para cada servicio: **valores que el agente decide solo** (imagen, versión,
memoria, puerto), **datos que sigue preguntando** (nombres/credenciales) y
**bloque de compose**. Siempre incluir healthcheck y volumen nombrado.

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
| Mailpit | `axllent/mailpit:latest` → fija versión | — | imagen ya mínima |

## Qué decide el agente solo, y qué sigue preguntando

No preguntes imagen/variante, versión/tag, memoria ni puerto uno por uno — eso
frena el wizard con detalles técnicos que el agente puede resolver mejor que
haciendo preguntas. Decidilos vos con el criterio de abajo (ver también "Lo que
el agente decide solo" en `AGENT.md`) y déjalos, junto con una línea del
porqué, en el **resumen final del plan** de `brownfield-wizard`/
`greenfield-wizard`, donde recién ahí la persona puede pedir cambiarlos.

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
Preguntas: versión (default 16), nombre de DB, usuario/clave de dev, puerto host
(default 5432), ¿volumen persistente? (default sí).
```yaml
postgres:
  image: ${POSTGRES_IMAGE:-postgres:16-alpine}
  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  ports: ["${POSTGRES_PORT:-5432}:5432"]
  volumes: ["pgdata:/var/lib/postgresql/data"]
  mem_limit: ${POSTGRES_MEM:-512m}
  deploy:
    resources:
      limits: { cpus: "${POSTGRES_CPUS:-1}", memory: "${POSTGRES_MEM:-512m}" }
      reservations: { memory: "${POSTGRES_MEM_RES:-128m}" }
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
    interval: 5s
    timeout: 5s
    retries: 10
```
`env/.env.example`: `# POSTGRES_IMAGE=postgres:16-alpine (default) | 16-bookworm | 16`
y `# POSTGRES_MEM=512m (perfil s) | 256m | 1g`.
Vars: `DATABASE_URL=postgres://user:pass@postgres:5432/db`.

## MySQL / MariaDB
Preguntas: versión (8.4 / 11), DB, usuario/clave, root pass, puerto (3306).
Healthcheck: `mysqladmin ping`. Volumen `/var/lib/mysql`.

## MongoDB
Preguntas: versión (7), usuario/clave root, DB inicial, puerto (27017),
¿replica set? (default no; sí si usa transacciones/change streams).
Healthcheck: `mongosh --eval "db.adminCommand('ping')"`.

## Redis
Preguntas: versión (7), ¿password? (default no en dev), ¿persistencia AOF?
(default no), puerto (6379), base numerada a usar.
Healthcheck: `redis-cli ping`. Vars: `REDIS_URL=redis://redis:6379/<n>`.

## RabbitMQ
Preguntas: usuario/clave, vhost, puerto AMQP (5672), ¿UI de management? (15672).
```yaml
rabbitmq:
  image: rabbitmq:3-management
  environment:
    RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER}
    RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASS}
    RABBITMQ_DEFAULT_VHOST: ${RABBITMQ_VHOST:-/}
  ports: ["5672:5672", "15672:15672"]
  healthcheck:
    test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
```

## Kafka (KRaft, sin Zookeeper)
Preguntas: ¿imagen (bitnami/kafka o confluentinc)?, puerto externo (9092),
¿schema registry? ¿kafka-ui?. Prefijo de topics del proyecto.
Healthcheck: `kafka-topics.sh --bootstrap-server localhost:9092 --list`.

## MinIO (S3 local)
Preguntas: usuario/clave root, puerto API (9000) y consola (9001), bucket inicial.
```yaml
minio:
  image: minio/minio
  command: server /data --console-address ":9001"
  environment:
    MINIO_ROOT_USER: ${MINIO_ROOT_USER}
    MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
  ports: ["9000:9000", "9001:9001"]
  volumes: ["miniodata:/data"]
  healthcheck:
    test: ["CMD", "mc", "ready", "local"]
```
Vars: `S3_ENDPOINT=http://minio:9000`, `S3_FORCE_PATH_STYLE=true`.

## Elasticsearch / OpenSearch
Preguntas: versión, `discovery.type=single-node`, memoria (`ES_JAVA_OPTS=-Xms512m
-Xmx512m`), seguridad on/off (default off en dev), puerto (9200).

## LocalStack (AWS)
Preguntas: qué servicios (`SERVICES=s3,sqs,sns,...`), puerto (4566).
Vars de la app: `AWS_ENDPOINT_URL=http://localstack:4566`, credenciales dummy.

## Keycloak (OIDC)
Preguntas: admin user/pass, realm del proyecto, puerto (8080), ¿import de realm?
`command: start-dev`. Healthcheck en `/health/ready`.

## Mailpit (SMTP de pruebas)
```yaml
mailpit:
  image: axllent/mailpit
  ports: ["1025:1025", "8025:8025"]
```
Vars: `SMTP_HOST=mailpit`, `SMTP_PORT=1025`.

## Regla general
Toda credencial generada va a `env/.env.local`, con su equivalente de
ejemplo en `env/.env.example`. Nunca escribas secretos fijos en el
compose.
