---
name: env-service-recipes
description: Recetas de configuración por tipo de servicio de infraestructura (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ, Kafka, MinIO, Elasticsearch/OpenSearch, LocalStack, Keycloak, Mailpit). Define qué preguntar y qué bloque de docker-compose + variables generar para cada uno. Usar cuando hay que crear un servicio desde cero y se necesitan los detalles de configuración.
---

# Skill: service-recipes

Para cada servicio: **preguntas mínimas** (con defaults) y **bloque de compose**.
Siempre incluir healthcheck y volumen nombrado. Versiones: sugerí una LTS/estable
reciente y confirmá.

## Antes de generar: proponer y confirmar valores

Los defaults de cada receta son **propuestas**, no decisiones. Presentá una
tabla de "valores propuestos" y ofrecé editarlos antes de crear nada:

| Dato | Propuesto | ¿Cambiar? |
|---|---|---|
| nombre de DB / schema / bucket / vhost | `<default>` | |
| usuario / contraseña de dev | `<default>` | |
| puerto en el host | `<default>` | |
| nombre de contenedor / volumen / red | `<prefijo-proyecto>_…` | |
| versión de imagen | `<LTS>` | |

## Después de crear: ficha de conexión

Al terminar cada servicio, mostrá su **ficha de conexión** (ver "Resumen de
conexión y valores editables" en `AGENT.md`): host/puerto desde la app y desde
el host, credenciales (`.env.local`), espacio lógico, cadena de conexión lista
para pegar, variable/s de entorno, URL de consola/UI y comando de cliente
rápido.

## PostgreSQL
Preguntas: versión (default 16), nombre de DB, usuario/clave de dev, puerto host
(default 5432), ¿volumen persistente? (default sí).
```yaml
postgres:
  image: postgres:16
  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  ports: ["${POSTGRES_PORT:-5432}:5432"]
  volumes: ["pgdata:/var/lib/postgresql/data"]
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
    interval: 5s
    timeout: 5s
    retries: 10
```
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
`.env.example`. Nunca hardcodees secretos en el compose versionado.
