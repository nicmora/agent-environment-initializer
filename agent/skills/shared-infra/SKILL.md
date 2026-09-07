---
name: env-shared-infra
description: Crea, detecta y gobierna una pila de infraestructura compartida del equipo (dev-infra) — un proyecto de Docker Compose reutilizable con Postgres, Redis, RabbitMQ/Kafka, MinIO, etc. y su propia red — para que varios proyectos la usen en lugar de levantar instancias dedicadas. Asigna a cada servicio un espacio lógico aislado (schema, base numerada, vhost, bucket, prefijo). Usar cuando el usuario quiere "una infra centralizada" / "compartir la base entre servicios" / "ahorrar recursos".
---

# Skill: shared-infra

## Concepto

Una sola pila de servicios de infraestructura por máquina/equipo, compartida por
todos los proyectos. El aislamiento entre proyectos es **lógico, no por
instancia**:

| Servicio | Espacio lógico por proyecto |
|---|---|
| PostgreSQL / MySQL / SQL Server | una base de datos **o** un schema + usuario propio |
| MongoDB | una base propia |
| Redis | una base numerada (`/0`..`/15`) o un prefijo de claves |
| RabbitMQ | un *virtual host* propio + usuario |
| Kafka | prefijo de nombres de *topics* (`<proj>.`) |
| MinIO / S3 | un *bucket* propio + credenciales de acceso limitadas |
| Elasticsearch/OpenSearch | prefijo de índices |
| Keycloak | un *realm* propio |

## Procedimiento

### 1. Detectar si ya existe
- Busca un proyecto de Compose llamado `dev-infra` / `shared-infra` /
  `local-infra` con `docker compose ls` y `docker network ls` (red tipo
  `dev-infra_default` o `shared-infra`).
- Busca una carpeta conocida (pregunta a la persona dónde la tiene; sugiere
  `~/dev-infra/`).
- Si existe: muestra sus servicios y su red. Pasa al **paso 3**.

### 2. Proponer crearla (si no existe y la persona quiere)
- Ubicación: carpeta **fuera** del proyecto actual (p. ej. `~/dev-infra/`), para
  que sea reutilizable. Confirma la ruta.
- Pregunta qué servicios incluir (solo los que el ecosistema del equipo usa).
- Genera `~/dev-infra/docker-compose.yml` con:
  - una red externa nombrada, p. ej. `name: devnet`, declarada como
    `networks: { devnet: { name: devnet } }`.
  - volúmenes con nombre estable por servicio.
  - `service-recipes` para la config de cada uno (versiones, credenciales de
    dev, puertos en el host).
  - healthchecks.
- Genera `~/dev-infra/README.md` con: cómo levantar (`docker compose up -d`),
  la lista de endpoints y credenciales, y **la tabla de espacios lógicos
  asignados** (se va completando a medida que cada proyecto se suma).

### 3. Conectar el proyecto actual a la pila compartida
- En `env/docker-compose.override.yml` (o `.dev.yml`) del proyecto, **no**
  redefinas los servicios de infra; en su lugar:
  - conecta los servicios de la app a la red externa compartida:
    `networks: { devnet: { external: true } }`.
  - define las variables de conexión de la app apuntando al **nombre de
    servicio** de la pila compartida (p. ej. `DB_HOST=postgres`,
    `REDIS_URL=redis://redis:6379/3`).
- Crea el **espacio lógico** de este proyecto de forma aditiva:
  - Postgres: `CREATE DATABASE <proj>;` o `CREATE SCHEMA <proj>; CREATE ROLE
    <proj>_user LOGIN PASSWORD '...';` — nunca `DROP` nada.
  - Redis: elige una base numerada libre (revisa cuáles ya están en uso en el
    README de la pila).
  - RabbitMQ: `rabbitmqctl add_vhost <proj>` + usuario + permisos.
  - MinIO: `mc mb local/<proj>` + usuario/policy.
- Actualiza la tabla de espacios lógicos en `~/dev-infra/README.md`.

### 4. Registrar la decisión
Devuelve a `document-environment` los datos: qué pila se usa, qué espacio lógico
se asignó y qué variables quedaron definidas.

**La ruta de la pila NO se hardcodea** en `env/ENVIRONMENT.md`, scripts,
compose ni `.env.example` — aunque `env/` no se versione, si la persona
regenera el entorno en otra máquina la ruta absoluta de hoy ya no sirve. Elige
una:

- **Repo hermano (preferido):** documenta que `docker-environment` va clonado al
  lado del proyecto y referéncialo como `../docker-environment/…`. Incluye el
  `git clone <url>` en los prerrequisitos.
- **Variable de entorno:** `SHARED_INFRA_DIR` en `env/.env.local` (cada
  persona pone su ruta), placeholder en `env/.env.example`; scripts y doc
  usan `${SHARED_INFRA_DIR}`.

Lo que sí es estable entre máquinas: el **nombre de la red externa** y los
**nombres de servicio** de la pila (`postgres`, `redis`, …).

## Reglas

- Nunca borres ni recrees la pila compartida ni sus volúmenes.
- Toda incorporación es aditiva y con confirmación previa.
- Nunca escribas rutas absolutas de la máquina en archivos versionados (ver
  paso 4).
- Si la persona no quiere pila compartida, vuelve a `brownfield-wizard` /
  `greenfield-wizard` con la opción de instancia dedicada.
