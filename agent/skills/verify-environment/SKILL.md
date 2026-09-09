---
name: env-verify-environment
description: Verifica que el entorno quedó operativo — según el medio elegido, valida la sintaxis del compose o los scripts de arranque, levanta los servicios (contenedores o nativos), espera los healthchecks/comprobaciones, corre migraciones de esquema si el proyecto las tiene y el usuario lo aprueba, y confirma que la aplicación arranca y responde. Reporta qué quedó pendiente. Usar como paso final después de compose-builder o native-setup, o cuando el usuario dice "prueba si levanta" / "por qué no arranca".
---

# Skill: verify-environment

Usá el **comando del medio elegido**: el `docker compose … up` con sus `-f` (que
arma `compose-builder`), el script `env/scripts/dev-up` (que arma `native-setup`),
o ambos en orden si el plan es mixto.

## Procedimiento

1. **Validar configuración.**
   - Camino Docker: `docker compose … config` (detecta errores de
     sintaxis/variables sin resolver) con los `-f` completos (compose base +
     `env/docker-compose.override.yml` + `--env-file env/.env.local` si hay
     compose previo; solo `env/docker-compose.yml` en greenfield).
   - Camino nativo: revisá que la versión de runtime activa coincida con
     `env/.tool-versions`/`.nvmrc`, que `env/.env.local` tenga todas las claves
     de `env/.env.example`, y que el runner del `env/Procfile` esté instalado.

2. **Levantar la infra primero.**
   - Docker: `… --profile infra up -d` (o la pila compartida). Espera los
     healthchecks (`docker compose … ps` hasta `healthy`); si algo no pasa,
     mostrá `docker compose … logs <svc>`.
   - Nativo: arrancá los servicios instalados que no estén corriendo
     (`brew services start …`, `systemctl --now`, `pg_ctl start`) y comprobá
     cada uno con su check (`pg_isready`, `redis-cli ping`, `curl` a la UI).

3. **Migraciones de esquema (opcional, con permiso).**
   Si el proyecto tiene Flyway/Liquibase/Alembic/Prisma/Knex/EF y la persona
   aprueba, ejecuta **solo** el comando de migración hacia adelante
   (`migrate`/`upgrade`/`deploy`). Nunca `down`/`reset`/`drop`.

4. **Levantar la app.**
   `docker compose up`, `env/scripts/dev-up`, o el comando de dev del proyecto.
   Verifica:
   - el health endpoint (`/health`, `/actuator/health`, etc.) responde 200, o
   - el log muestra "listening on :PORT" / "started", o
   - un `curl` a la ruta principal responde.

5. **Smoke test mínimo.**
   Si hay tests de humo o un endpoint que toca DB/cache, ejecútalo para confirmar
   conectividad real.

## Reporte final

- ✅ Servicios arriba y healthy.
- ✅ App responde en `http://localhost:<puerto>`.
- **Ficha de conexión por dependencia** (ver "Resumen de conexión y valores
  editables" en `AGENT.md`). Una fila por servicio:

  | Servicio | Desde la app | Desde el host | Usuario / clave | Espacio lógico | Cadena de conexión / var | Consola / UI |
  |---|---|---|---|---|---|---|
  | postgres | `postgres:5432` | `localhost:5432` | `app` / `env/.env.local` | DB `miproyecto`, schema `public` | `DATABASE_URL=postgres://…` | — |
  | redis | `redis:6379` | `localhost:6380` | — | base `2` | `REDIS_URL=redis://redis:6379/2` | — |
  | rabbitmq | `rabbitmq:5672` | `localhost:5672` | `dev` / `env/.env.local` | vhost `/miproyecto` | `AMQP_URL=amqp://…` | http://localhost:15672 |

  Cierra recordando que cualquiera de esos nombres (DB, schema, vhost, bucket,
  base de Redis, puertos) se puede renombrar y tú lo propagas a compose,
  `.env*`, `ENVIRONMENT.md` y scripts, todos dentro de `env/`.
- ⚠️ Pendientes: variables que faltan, servicios en modo mock, credenciales
  externas no provistas, migraciones no corridas, etc.
- Comando para levantar y para apagar (recuerda: `down` sin `-v`).

## Reglas

- Si algo falla, **diagnostica** (logs, puertos, variables, versión de runtime)
  y propón el arreglo; no borres volúmenes ni datadirs ni recrees servicios para
  "destrabar".
- No dejes servicios corriendo sin avisar; pregunta si los bajas o los dejas.
  Los servicios nativos que **ya estaban** antes de la sesión no se bajan.
