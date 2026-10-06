---
name: envinit-detect
description: Escanea el repositorio actual para detectar sus dependencias de entorno — bases de datos, caché, mensajería, storage, servicios externos — a partir de manifiestos, archivos de infraestructura, configuración y código, y produce un informe con evidencia. Es siempre el primer paso, para cualquier proyecto y en cualquier estado (con dependencias, con una sola o con ninguna). Usar al inicio de cada sesión o cuando el usuario pide "escanea el proyecto" / "detecta qué necesita para correr".
---

# Skill: envinit-detect

## Objetivo

Producir un **inventario de dependencias de entorno** del repositorio actual, con
evidencia (archivo y línea) y nivel de confianza (confirmado / inferido).

Se corre para **cualquier** proyecto, sin importar su estado. Si el repo todavía
no usa ninguna dependencia de entorno, el informe lo dice explícitamente y el
flujo sigue igual: se elige el medio de ejecución de la app y se la levanta. No
se cambia de modo ni se abre un cuestionario de dependencias hipotéticas.

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
ninguna decisión. Seguí "Cómo comunicarte" de `AGENT.md`: el resumen es corto y
en lenguaje simple, pensado para alguien que puede no ser técnico.

**Lo que se muestra en el chat** (unas pocas líneas):

1. **Qué es el proyecto**, en una o dos frases: qué tipo de app es (p. ej. "una
   API en Node.js", "una web en React con su backend en Python") y la versión de
   lenguaje que necesita.
2. **Qué necesita para funcionar**, como lista corta en palabras simples, una
   línea por dependencia: "Una base de datos (PostgreSQL)", "Un servicio de
   pagos externo (Stripe)". Si algo es inferido, decilo en pocas palabras ("parece
   usar…").
3. Si ya hay algo armado para correrlo (p. ej. "ya tiene un archivo de Docker"),
   en una línea.
4. Una línea final: "Si querés, te muestro el detalle técnico de lo que
   encontré."

**Lo que se muestra solo si la persona lo pide** (y se usa internamente para el
resto del flujo):

- Detalle del stack: framework, gestor de paquetes, estructura del repo
  (monorepo/servicio único) y **cómo arranca hoy** (script de `package.json`,
  `Makefile`, `Procfile`, `docker-compose`, comando en el README).
- **Tabla de dependencias de entorno detectadas**:

  | Dependencia | Tipo | Evidencia (archivo:línea) | Versión sugerida | Confianza | Variables de entorno relacionadas |
  |---|---|---|---|---|---|

- **Configuración existente**: archivos de config relevantes encontrados
  (`.env*`, `application.yml`, etc.) y si ya hay infraestructura declarada
  (`docker-compose*.yml`, `Dockerfile`, `k8s/`, …) — sin modificarla.
- Lista de **variables referenciadas sin valor** y de **puertos** que el
  proyecto espera.

Si **no se detectó ninguna dependencia de entorno**, decilo claramente en el
resumen ("no necesita base de datos ni otros servicios; solo hay que levantar la
app") y no infieras dependencias que el código todavía no usa.

Con ese resumen mostrado, pasa directo a preguntar el medio de ejecución de la
app y —si hay dependencias— el origen de cada una (crear en Docker o usar un
servicio existente) con `envinit-plan`.

## Reglas

- Solo lectura. No escribas ni ejecutes servicios en esta skill.
- Si algo es ambiguo, márcalo como "inferido". El porqué, en el detalle técnico.
