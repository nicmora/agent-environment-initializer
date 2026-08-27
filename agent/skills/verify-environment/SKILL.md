---
name: env-verify-environment
description: Verifica que el entorno quedó operativo — valida la sintaxis del compose, levanta los servicios, espera los healthchecks, corre migraciones de esquema si el proyecto las tiene y el usuario lo aprueba, y confirma que la aplicación arranca y responde. Reporta qué quedó pendiente. Usar como paso final después de compose-builder, o cuando el usuario dice "probá si levanta" / "por qué no arranca".
---

# Skill: verify-environment

## Procedimiento

1. **Validar configuración.**
   `docker compose config` (detecta errores de sintaxis/variables sin resolver).

2. **Levantar infra primero.**
   `docker compose --profile infra up -d` (o la pila compartida si aplica).
   Esperá healthchecks: `docker compose ps` hasta `healthy`. Timeout razonable;
   si algo no pasa a healthy, mostrá `docker compose logs <svc>`.

3. **Migraciones de esquema (opcional, con permiso).**
   Si el proyecto tiene Flyway/Liquibase/Alembic/Prisma/Knex/EF y la persona
   aprueba, corré **solo** el comando de migración hacia adelante
   (`migrate`/`upgrade`/`deploy`). Nunca `down`/`reset`/`drop`.

4. **Levantar la app.**
   `docker compose up` (o el comando de dev del proyecto). Verificá:
   - health endpoint (`/health`, `/actuator/health`, etc.) responde 200, o
   - el log muestra "listening on :PORT" / "started", o
   - un `curl` a la ruta principal responde.

5. **Smoke test mínimo.**
   Si hay tests de humo o un endpoint que toca DB/cache, ejecutalo para confirmar
   conectividad real.

## Reporte final

- ✅ Servicios arriba y healthy.
- ✅ App responde en `http://localhost:<puerto>`.
- ⚠️ Pendientes: variables que faltan, servicios en modo mock, credenciales
  externas no provistas, migraciones no corridas, etc.
- Comando para levantar y para apagar (recordá: `down` sin `-v`).

## Reglas

- Si algo falla, **diagnosticá** (logs, puertos, variables) y proponé el arreglo;
  no borres volúmenes ni recrees servicios para "destrabar".
- No dejes servicios corriendo sin avisar; preguntá si los bajo o los dejo.
