---
name: detect-environment
description: Escanea un repositorio existente (brownfield) para detectar sus dependencias de entorno — bases de datos, caché, mensajería, storage, servicios externos — a partir de manifiestos, archivos de infraestructura, configuración y código, y produce un informe con evidencia. Usar al inicio de un proyecto brownfield o cuando el usuario pide "escanea el proyecto" / "detecta qué necesita para correr".
---

# Skill: detect-environment

## Objetivo

Producir un **inventario de dependencias de entorno** del repositorio actual, con
evidencia (archivo y línea) y nivel de confianza (confirmado / inferido).

## Procedimiento

1. **Manifiestos de dependencias.** Busca y lee:
   `package.json`, `pnpm-lock.yaml`/`yarn.lock`, `pom.xml`, `build.gradle(.kts)`,
   `requirements*.txt`, `pyproject.toml`, `Pipfile`, `go.mod`, `Gemfile`,
   `composer.json`, `*.csproj`, `Cargo.toml`.
   Identifica clientes conocidos: `pg`/`psycopg`/`mysql2`/`mongoose`/`redis`/
   `ioredis`/`amqplib`/`kafkajs`/`@aws-sdk/*`/`elasticsearch`/`minio`, drivers
   JDBC, `spring-boot-starter-data-*`, etc.

2. **Infraestructura existente.** Busca:
   `docker-compose*.yml`, `compose*.yaml`, `Dockerfile*`, `.devcontainer/`,
   `Makefile`, `Taskfile*`, `Procfile`, `k8s/`, `helm/`, `charts/`, `skaffold*`.
   Si ya hay un `docker-compose*.yml`, lista sus servicios y volúmenes; **no lo
   modifiques** en esta skill.

3. **Configuración.** Lee:
   `.env`, `.env.*`, `application*.yml`/`application*.properties`, `config/`,
   `settings*.py`, `appsettings*.json`, `*.config.js`, `knexfile*`, `ormconfig*`,
   `prisma/schema.prisma`, `alembic.ini`, `flyway*`, `liquibase*`.
   Extrae cadenas de conexión y hosts/puertos.

4. **Código.** Grep de:
   - URLs y esquemas: `postgres://`, `mysql://`, `mongodb://`, `redis://`,
     `amqp://`, `kafka:`, `s3://`, `https://` a dominios de terceros.
   - Lectura de variables de entorno (`process.env.X`, `os.environ[...]`,
     `System.getenv`, `@Value("${...}")`, `config(...)`) para armar la lista de
     variables **referenciadas pero no definidas**.

5. **Pruebas de integración.** Busca `Testcontainers`, `docker-compose` de test,
   `@SpringBootTest`, fixtures que levanten servicios. Suelen revelar versiones
   exactas de imágenes.

6. **Migraciones de esquema.** Detecta Flyway/Liquibase/Alembic/Prisma
   Migrate/Knex/EF Core y su ubicación. No las ejecutes todavía.

7. **Cómo arranca hoy y con qué runtime.** Busca la evidencia de cómo se corre
   la app actualmente y qué versión de runtime pide:
   - Scripts de arranque: `scripts` de `package.json`, `Makefile`, `Taskfile`,
     `Procfile`, `foreman`/`overmind`, `docker-compose*.yml`, `.devcontainer/`,
     comandos en el `README`.
   - Versión de runtime declarada: `.nvmrc`, `.node-version`, `engines` de
     `package.json`, `.python-version`, `pyproject.toml` (`requires-python`),
     `go.mod` (`go 1.x`), `<java.version>`/`<release>` en `pom.xml`,
     `.tool-versions` (asdf/mise), `.sdkmanrc`, `rust-toolchain*`.
   - Anota si el proyecto **ya trae** un camino de arranque en contenedor, uno
     nativo, o ambos.

8. **Documentación.** Lee `README*`, `CONTRIBUTING*`, `docs/` buscando la sección
   de "cómo correr localmente".

## Salida

Este es siempre el **primer paso** del flujo: la persona todavía no tomó
ninguna decisión y en la máquina no se tocó nada (ni Docker). Presenta, en este
orden:

1. **Resumen del stack tecnológico**, en prosa corta: lenguaje(s) y versión de
   runtime requerida, framework principal, gestor de paquetes, tipo de
   aplicación (backend/frontend/worker/CLI/full-stack), estructura del repo
   (monorepo/servicio único) y **cómo arranca hoy** (script de `package.json`,
   `Makefile`, `Procfile`, `docker-compose`, comando en el README), aclarando si
   ya hay un camino en contenedor, uno nativo, o ambos.
2. **Tabla de dependencias de entorno detectadas**:

   | Dependencia | Tipo | Evidencia (archivo:línea) | Versión sugerida | Confianza | Variables de entorno relacionadas |
   |---|---|---|---|---|---|

3. **Configuración existente**: archivos de config relevantes encontrados
   (`.env*`, `application.yml`, etc.) y si ya hay infraestructura declarada
   (`docker-compose*.yml`, `Dockerfile`, `k8s/`, …) — sin modificarla.
4. Lista de **variables referenciadas sin valor** y de **puertos** que el
   proyecto espera.

Con ese resumen mostrado, pasa directo a preguntar el medio de ejecución de la
app y la estrategia de cada dependencia (`brownfield-wizard`). **No ejecutes
`inspect-local-resources` todavía** — la máquina se revisa recién si alguna
decisión elegida más adelante realmente lo necesita (ver `AGENT.md`, regla 12).

## Reglas

- Solo lectura. No escribas ni ejecutes servicios en esta skill.
- Si algo es ambiguo, márcalo como "inferido" y explica por qué.
