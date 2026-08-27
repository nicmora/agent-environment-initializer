---
name: env-compose-builder
description: Genera o actualiza archivos docker-compose (base, override o dev) y los .env asociados a partir de las decisiones del wizard, sin reescribir ni romper la infraestructura existente. Maneja redes, volúmenes, perfiles (--profile), depends_on con healthchecks y mapeo de puertos evitando colisiones. Usar cuando ya está decidida la estrategia por dependencia y hay que "crear los archivos" / "armar el compose".
---

# Skill: compose-builder

## Entrada

La tabla de decisiones de `brownfield-wizard` o `greenfield-wizard`, la lista de
puertos ocupados de `inspect-local-resources`, y las recetas de
`service-recipes`.

## Reglas de archivos

- **Greenfield sin compose previo** → creá `docker-compose.yml` + `.env.example`
  + `.env.local`.
- **Brownfield con compose previo** → NO lo toques. Creá
  `docker-compose.override.yml` (se aplica automático) o
  `docker-compose.dev.yml` (se aplica con `-f`). Preferí `override` salvo que ya
  exista uno con otro propósito.
- Mostrá siempre el archivo completo o el *diff* y pedí confirmación antes de
  escribir.
- Actualizá `.gitignore`: agregá `.env.local`, `.env.*.local`,
  `docker-compose.dev.yml` si contiene datos sensibles (si no, versionalo).

## Construcción

1. **Servicios de la app.** Si la app corre en contenedor, definí `build:` o
   `image:`, `env_file: [.env, .env.local]`, `ports`, `depends_on` con
   `condition: service_healthy`, `develop.watch` o bind mounts para hot reload.
2. **Servicios de infra creados desde cero.** Tomá la definición de
   `service-recipes` (imagen+versión, env, volumen nombrado, healthcheck).
   Ponelos bajo un `profiles: ["infra"]` si la persona quiere poder omitirlos.
3. **Conexión a pila compartida.** No redefinas la infra; declará la red externa
   y apuntá las variables al nombre de servicio de la pila (ver `shared-infra`).
4. **Conexión a recurso local / externo.** No agregues servicio; solo seteá las
   variables en `.env.local`. Para servicios del host desde un contenedor usá
   `host.docker.internal` (agregá `extra_hosts: ["host.docker.internal:host-gateway"]`
   en Linux).
5. **Mocks.** Agregá los servicios de mock bajo `profiles: ["mock"]` (ver
   `external-mocks`).
6. **Puertos.** Para cada puerto publicado, verificá contra la lista de ocupados.
   Si choca, asigná el siguiente libre y reflejalo en `.env.example`.
7. **Redes y volúmenes.** Nombres con prefijo del proyecto. Nunca reutilices el
   nombre de un volumen existente con datos.

## Variables de entorno

- `.env.example`: todas las claves con valores de ejemplo/dev **no sensibles**.
  Versionado.
- `.env.local`: valores reales/secretos. Ignorado por git. Generá los que
  correspondan a conexiones externas o credenciales creadas.
- Documentá cada variable con un comentario de una línea.

## Scripts de conveniencia

Creá (si la persona quiere) en `scripts/`:
- `dev-up` → `docker compose --profile infra up -d && docker compose up`
- `dev-down` → `docker compose down` (SIN `-v`)
- `dev-logs` → `docker compose logs -f`
O los targets equivalentes en `Makefile` / `Taskfile.yml`.

## Salida

Lista de archivos creados/modificados y el comando de arranque. Handoff a
`verify-environment`.
