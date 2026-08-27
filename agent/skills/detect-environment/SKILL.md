---
name: env-detect-environment
description: Escanea un repositorio existente (brownfield) para detectar sus dependencias de entorno — bases de datos, caché, mensajería, storage, servicios externos — a partir de manifiestos, archivos de infraestructura, configuración y código, y produce un informe con evidencia. Usar al inicio de un proyecto brownfield o cuando el usuario pide "escaneá el proyecto" / "detectá qué necesita para correr".
---

# Skill: detect-environment

## Objetivo

Producir un **inventario de dependencias de entorno** del repositorio actual, con
evidencia (archivo y línea) y nivel de confianza (confirmado / inferido).

## Procedimiento

1. **Manifiestos de dependencias.** Buscá y leé:
   `package.json`, `pnpm-lock.yaml`/`yarn.lock`, `pom.xml`, `build.gradle(.kts)`,
   `requirements*.txt`, `pyproject.toml`, `Pipfile`, `go.mod`, `Gemfile`,
   `composer.json`, `*.csproj`, `Cargo.toml`.
   Identificá clientes conocidos: `pg`/`psycopg`/`mysql2`/`mongoose`/`redis`/
   `ioredis`/`amqplib`/`kafkajs`/`@aws-sdk/*`/`elasticsearch`/`minio`, drivers
   JDBC, `spring-boot-starter-data-*`, etc.

2. **Infraestructura existente.** Buscá:
   `docker-compose*.yml`, `compose*.yaml`, `Dockerfile*`, `.devcontainer/`,
   `Makefile`, `Taskfile*`, `Procfile`, `k8s/`, `helm/`, `charts/`, `skaffold*`.
   Si ya hay un `docker-compose*.yml`, listá sus servicios y volúmenes; **no lo
   modifiques** en esta skill.

3. **Configuración.** Leé:
   `.env`, `.env.*`, `application*.yml`/`application*.properties`, `config/`,
   `settings*.py`, `appsettings*.json`, `*.config.js`, `knexfile*`, `ormconfig*`,
   `prisma/schema.prisma`, `alembic.ini`, `flyway*`, `liquibase*`.
   Extraé cadenas de conexión y hosts/puertos.

4. **Código.** Grep de:
   - URLs y esquemas: `postgres://`, `mysql://`, `mongodb://`, `redis://`,
     `amqp://`, `kafka:`, `s3://`, `https://` a dominios de terceros.
   - Lectura de variables de entorno (`process.env.X`, `os.environ[...]`,
     `System.getenv`, `@Value("${...}")`, `config(...)`) para armar la lista de
     variables **referenciadas pero no definidas**.

5. **Pruebas de integración.** Buscá `Testcontainers`, `docker-compose` de test,
   `@SpringBootTest`, fixtures que levanten servicios. Suelen revelar versiones
   exactas de imágenes.

6. **Migraciones de esquema.** Detectá Flyway/Liquibase/Alembic/Prisma
   Migrate/Knex/EF Core y su ubicación. No las ejecutes todavía.

7. **Documentación.** Leé `README*`, `CONTRIBUTING*`, `docs/` buscando la sección
   de "cómo correr localmente".

## Salida

Presentá una tabla:

| Dependencia | Tipo | Evidencia (archivo:línea) | Versión sugerida | Confianza | Variables de entorno relacionadas |
|---|---|---|---|---|---|

Y una lista de **variables referenciadas sin valor** y de **puertos** que el
proyecto espera.

Terminá preguntando si seguimos con `inspect-local-resources` (ver qué hay en la
máquina) y luego `brownfield-wizard` (elegir estrategia por dependencia).

## Reglas

- Solo lectura. No escribas ni ejecutes servicios en esta skill.
- Si algo es ambiguo, marcá "inferido" y explicá por qué.
