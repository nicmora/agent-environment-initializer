---
name: env-service-recipes
description: Recetas de configuración por tipo de servicio de infraestructura (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MinIO, Elasticsearch/OpenSearch, LocalStack, Keycloak, Mailpit). Define qué preguntar y qué bloque de docker-compose + variables generar para cada uno. Usar cuando hay que crear un servicio desde cero y se necesitan los detalles de configuración.
---

# Skill: service-recipes

Para cada servicio: **preguntas mínimas** (con defaults) y **bloque de compose**.
Siempre incluir healthcheck y volumen nombrado. Versiones: sugiere una
LTS/estable reciente y confirma.

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

## Antes de generar: proponer y confirmar valores

Los defaults de cada receta son **propuestas**, no decisiones. Presenta una
tabla de "valores propuestos" y ofrece editarlos antes de crear nada:

| Dato | Propuesto | ¿Cambiar? |
|---|---|---|
| nombre de DB / schema / bucket / vhost | `<default>` | |
| usuario / contraseña de dev | `<default>` | |
| puerto en el host | `<default>` | |
| nombre de contenedor / volumen / red | `<prefijo-proyecto>_…` | |
| imagen y tag | `<repo:tag-alpine>` (variable `<SVC>_IMAGE`) | |
| variante base | `alpine` | `slim` / `full` |
| límite de memoria | `<perfil s = 512m>` (variable `<SVC>_MEM`) | `xs/s/m/l` |
| memoria reservada | `<perfil s = 128m>` (variable `<SVC>_MEM_RES`) | |

### Preguntas obligatorias por servicio (no las saltees)

Para **cada** servicio que se cree desde cero, antes de pasar a
`compose-builder` tienes que hacer estas tres preguntas de forma explícita. No
alcanza con aplicar el default en silencio: propón el default marcándolo como
recomendado y **ofrece las alternativas concretas**. Si el asistente tiene
selector interactivo (en Claude Code, `AskUserQuestion`), úsalo; puedes agrupar
las tres en una sola tanda porque son de la misma dependencia.

1. **Variante / imagen base.** Opciones: `alpine` (recomendada cuando la imagen
   la soporta), `slim` / `-bookworm-slim`, `full` / `-bookworm`, u **otra
   imagen** (p. ej. MariaDB en vez de MySQL, OpenSearch en vez de Elasticsearch).
   Muestra el repo:tag resultante de cada opción y por qué se recomienda la
   pequeña.
2. **Versión / tag.** Opciones: la versión estable/LTS sugerida por la receta
   (recomendada), una o dos versiones alternativas que publique esa imagen, o
   una versión a elección (entrada de texto). Nunca fijes `latest` ni un tag sin
   número.
3. **Presupuesto de memoria.** Ofrece la tabla de perfiles (`xs` 256m / `s`
   512m / `m` 1g / `l` 2g) con el default de la receta marcado como recomendado,
   y una opción **"personalizado"** que pida `mem_limit` y `mem_reservation` a
   mano. Aclara que ambos valores quedan como variables (`<SVC>_MEM` y
   `<SVC>_MEM_RES`) pisables desde `.env.local`.

Recién con esas tres respuestas (más los nombres/credenciales/puerto de la
tabla de arriba) haces el handoff a `compose-builder`.

## Después de crear: ficha de conexión

Al terminar cada servicio, muestra su **ficha de conexión** (ver "Resumen de
conexión y valores editables" en `AGENT.md`): host/puerto desde la app y desde
el host, credenciales (`.env.local`), espacio lógico, cadena de conexión lista
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
`.env.example`: `# POSTGRES_IMAGE=postgres:16-alpine (default) | 16-bookworm | 16`
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
Toda credencial generada va a `.env.local`, con su equivalente de ejemplo en
`.env.example`. Nunca escribas secretos fijos en el compose versionado.
