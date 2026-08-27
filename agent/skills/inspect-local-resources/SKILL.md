---
name: env-inspect-local-resources
description: Inspecciona la máquina para descubrir contenedores Docker en ejecución, redes y volúmenes, servicios de infraestructura instalados en el sistema operativo, y puertos ocupados. Sirve para ofrecer reutilizar recursos existentes y evitar colisiones de puertos. Usar en brownfield antes del wizard, o cuando el usuario dice "ya tengo una base de datos en un contenedor" / "fijate qué tengo instalado".
---

# Skill: inspect-local-resources

## Objetivo

Saber qué hay disponible en la máquina para poder ofrecer **reutilizar** en vez
de crear.

## Procedimiento (solo lectura)

### Docker
- `docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'`
- `docker network ls` y `docker volume ls`
- Para candidatos relevantes (imágenes de postgres, mysql, mongo, redis,
  rabbitmq, kafka, minio, elasticsearch, keycloak, localstack…):
  `docker inspect <name>` para obtener puerto publicado, red, variables de
  entorno (credenciales por defecto), y montajes de volumen.
- Detectá si hay un proyecto de Compose ya corriendo
  (`docker compose ls`).

### Servicios del sistema operativo
- Windows: `Get-Service | Where-Object {$_.Status -eq 'Running'}` y filtrá por
  `postgres`, `mysql`, `redis`, `mongodb`, `rabbitmq`; `Get-NetTCPConnection
  -State Listen`.
- Linux/macOS: `ss -tlnp` / `lsof -iTCP -sTCP:LISTEN`, `systemctl list-units
  --type=service --state=running`, `brew services list`.

### Puertos
- Armá la lista de puertos en escucha para cruzar con los que el proyecto espera
  (de `detect-environment`) y detectar colisiones.

## Salida

| Recurso | Origen (Docker / SO / —) | Endpoint | Credenciales conocidas | ¿Reutilizable para? |
|---|---|---|---|---|

Y una lista de **puertos ocupados** relevante para `compose-builder`.

## Reglas

- Nunca detengas, reinicies ni borres contenedores/servicios. Solo observás.
- Si no tenés permiso para ejecutar comandos, pedí a la persona que pegue la
  salida de `docker ps` y de la lista de puertos.
- No asumas credenciales: si no podés leerlas, preguntá.
