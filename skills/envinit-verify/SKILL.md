---
name: envinit-verify
description: Verifica que el entorno quedó operativo — valida la sintaxis del compose y los scripts de arranque, levanta los servicios en Docker, espera los healthchecks, detecta colisiones de puerto y propone alternativa, comprueba la conectividad a los servicios existentes, corre migraciones de esquema si el proyecto las tiene y el usuario lo aprueba, y confirma que la aplicación arranca y responde. Reporta qué quedó pendiente. Usar como paso final después de envinit-compose o envinit-native, o cuando el usuario dice "prueba si levanta" / "por qué no arranca".
---

# Skill: envinit-verify

Usá el **comando del medio elegido**: el `docker compose … up` con sus `-f` (que
arma `envinit-compose`), el script `local/scripts/dev-up` (que arma `envinit-native`),
o ambos en orden si el plan es mixto.

## Procedimiento

1. **Validar configuración.**
   - Compose: `docker compose … config` (detecta errores de sintaxis/variables
     sin resolver) con los `-f` completos (compose base +
     `local/docker-compose.override.yml` + `--env-file local/.env.local` si hay
     compose previo; solo `local/docker-compose.yml` si no hay compose propio
     fuera de `local/`).
   - App nativa: revisá que la versión de runtime activa coincida con
     `local/.nvmrc`/`.tool-versions`, que `local/.env.local` tenga todas las claves
     de `local/.env.example`, y que el runner del `local/Procfile` esté instalado.

2. **Levantar la infra en Docker primero.**
   - `… --profile infra up -d`. Espera los healthchecks
     (`docker compose … ps` hasta `healthy`); si algo no pasa, mostrá
     `docker compose … logs <svc>`.
   - **Colisión de puerto** (`bind: address already in use` / `port is already
     allocated`): elegí el siguiente puerto libre del host, actualizá el mapeo en
     `local/docker-compose*.yml` y la variable en `local/.env.local`/`.env.example`,
     mostrá el diff y volvé a levantar. Nunca mates el proceso que ocupa el
     puerto.

3. **Comprobar los servicios existentes.**
   Para cada dependencia resuelta como "servicio existente", verificá
   conectividad con las credenciales de `local/.env.local` (`pg_isready -h <host>`,
   `redis-cli -u <url> ping`, `curl` al endpoint). Si falla, es un pendiente: no
   toques ese servicio.

4. **Migraciones de esquema (opcional, con permiso).**
   Si el proyecto tiene Flyway/Liquibase/Alembic/Prisma/Knex/EF y la persona
   aprueba, ejecuta **solo** el comando de migración hacia adelante
   (`migrate`/`upgrade`/`deploy`). Nunca `down`/`reset`/`drop`.

5. **Levantar la app.**
   `docker compose up`, `local/scripts/dev-up`, o el comando de dev del proyecto.
   Verifica:
   - el health endpoint (`/health`, `/actuator/health`, etc.) responde 200, o
   - el log muestra "listening on :PORT" / "started", o
   - un `curl` a la ruta principal responde.

6. **Smoke test mínimo.**
   Si hay tests de humo o un endpoint que toca DB/cache, ejecútalo para confirmar
   conectividad real.

## Reporte final

Seguí "Cómo comunicarte" de `AGENT.md`. **En el chat**, un cierre corto y en
lenguaje simple, por ejemplo:

> ✅ Listo, la app está funcionando: abrila en http://localhost:3000
> ✅ La base de datos está andando.
> ⚠️ Falta: la clave del servicio de pagos (por ahora está simulado).
>
> Para levantar todo de nuevo: `local/scripts/dev-up`
> Para apagarlo: `local/scripts/dev-down`
>
> Todos los datos de conexión quedaron en `local/ENVIRONMENT.md`. Si querés, te
> los muestro acá.

Después preguntá si dejás los servicios corriendo o los apagás.

**Solo si la persona lo pide** (y siempre en `local/ENVIRONMENT.md`), el
detalle completo:

- **Ficha de conexión por dependencia** (ver "Resumen de conexión y valores
  editables" en `AGENT.md`). Una fila por servicio:

  | Servicio | Origen | Desde la app | Desde el host | Usuario / clave | Espacio lógico | Cadena de conexión / var | Consola / UI |
  |---|---|---|---|---|---|---|---|
  | postgres | Docker | `postgres:5432` | `localhost:5432` | `app` / `local/.env.local` | DB `miproyecto`, schema `public` | `DATABASE_URL=postgres://…` | — |
  | redis | Docker | `redis:6379` | `localhost:6380` | — | base `2` | `REDIS_URL=redis://redis:6379/2` | — |
  | payments | servicio existente | `api.stripe.com` | `api.stripe.com` | token / `local/.env.local` | — | `PAYMENTS_BASE_URL=https://…` | — |

  Cierra recordando que cualquiera de esos nombres (DB, schema, vhost, bucket,
  base de Redis, puertos) se puede renombrar y tú lo propagas a compose,
  `.env*`, `ENVIRONMENT.md` y scripts, todos dentro de `local/`.
- ⚠️ Pendientes: variables que faltan, servicios en modo mock, credenciales
  externas no provistas, migraciones no corridas, etc.
- Comando para levantar y para apagar (recuerda: `down` sin `-v`).

## Reglas

- Si algo falla, **diagnostica** (logs, puertos, variables, versión de runtime)
  y propón el arreglo; no borres volúmenes ni recrees servicios para "destrabar".
  Contale el problema y el arreglo en una o dos frases simples; los logs y el
  detalle técnico, solo si los pide.
- Las colisiones de puerto se explican sin jerga ("ese lugar ya estaba ocupado
  en tu máquina, así que usé otro").
- No dejes servicios corriendo sin avisar; pregunta si los bajas o los dejas.
- Nunca toques un servicio existente: si no responde, es un pendiente para la
  persona.
