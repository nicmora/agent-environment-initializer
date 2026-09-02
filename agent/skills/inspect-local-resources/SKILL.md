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

**Primero verificá que el daemon responda:** `docker info` (o `docker ps`).

Si falla con "Cannot connect to the Docker daemon" / "error during connect" /
pipe `docker_engine` no encontrado, **Docker está instalado pero apagado**. No
sigas como si no hubiera nada: puede haber contenedores parados (postgres,
rabbit, emuladores) que sirven para reutilizar. Frená y **ofrecé arrancar
Docker**:

- Windows: `Start-Process "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"`
  y esperá en loop a que `docker info` responda (timeout ~90 s).
- macOS: `open -a Docker`, mismo poll.
- Linux: `sudo systemctl start docker` (pedí confirmación por el `sudo`).

Es una acción no destructiva (solo levanta el servicio), pero **pedí permiso
antes** porque arranca software y consume recursos. Si la persona prefiere no
levantarlo, seguí sin Docker y dejá anotado que no se pudo inspeccionar.

Con el daemon arriba:
- `docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'`
  (incluí `-a`: los contenedores **parados** también son candidatos a reutilizar
  — ofrecé arrancarlos con `docker start <name>`, nunca recrearlos).
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

| Recurso | Origen (Docker / SO / —) | Estado (corriendo / parado) | Endpoint | Credenciales conocidas | ¿Reutilizable para? |
|---|---|---|---|---|---|

Y una lista de **puertos ocupados** relevante para `compose-builder`.

Si el daemon de Docker estaba apagado, dejalo explícito en la salida: "Docker
estaba apagado; lo levanté con permiso y encontré N contenedores" o "la persona
optó por no levantarlo, no se pudo inspeccionar Docker".

## Reglas

- Nunca **borres ni reinicies** contenedores/servicios existentes.
- Sí podés, **con permiso explícito**, arrancar el daemon de Docker si está
  apagado y hacer `docker start <name>` de un contenedor parado que la persona
  quiera reutilizar. Nada más.
- Si no tenés permiso para ejecutar comandos, pedí a la persona que levante
  Docker y pegue la salida de `docker ps -a` y de la lista de puertos.
- No asumas credenciales: si no podés leerlas, preguntá.
