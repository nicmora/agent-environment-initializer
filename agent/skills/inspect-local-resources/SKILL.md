---
name: env-inspect-local-resources
description: Inspecciona la máquina para descubrir contenedores Docker en ejecución, redes y volúmenes, servicios de infraestructura instalados en el sistema operativo, y puertos ocupados. Sirve para ofrecer reutilizar recursos existentes y evitar colisiones de puertos. Usar recién cuando una dependencia va a reutilizar un contenedor local o crear un servicio en Docker, o cuando el usuario dice "ya tengo una base de datos en un contenedor" / "fíjate qué tengo instalado".
---

# Skill: inspect-local-resources

## Objetivo

Saber qué hay disponible en la máquina para poder ofrecer **reutilizar** en vez
de crear.

## Cuándo se invoca (bajo demanda, no al inicio)

Esta skill **no** se ejecuta como parte del análisis inicial del proyecto
(`detect-environment` no la dispara). Se invoca recién cuando, dependencia por
dependencia en `brownfield-wizard`/`greenfield-wizard`, la persona elige una
estrategia que realmente toca Docker o la máquina:

- Quiere **reutilizar** un recurso local (contenedor Docker o servicio del SO).
- Quiere **crear desde cero** un servicio nuevo (hay que saber si Docker está
  instalado/iniciado y qué puertos están libres antes de `service-recipes`).

Si todas las dependencias del proyecto se resuelven con **conexión externa** o
**mock**, no hace falta ejecutar esta skill en absoluto: no hay nada que revisar
en la máquina.

## Procedimiento (solo lectura)

### Docker

**Primero verifica que el daemon responda:** `docker info` (o `docker ps`).

Si falla con "Cannot connect to the Docker daemon" / "error during connect" /
pipe `docker_engine` no encontrado, **Docker está instalado pero apagado**. No
sigas como si no hubiera nada: puede haber contenedores detenidos (postgres,
rabbit, emuladores) que sirven para reutilizar. Detente y **ofrece arrancar
Docker**:

- Windows: `Start-Process "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"`
  y espera en loop a que `docker info` responda (timeout ~90 s).
- macOS: `open -a Docker`, mismo poll.
- Linux: `sudo systemctl start docker` (pide confirmación por el `sudo`).

Es una acción no destructiva (solo levanta el servicio), pero **pide permiso
antes** porque arranca software y consume recursos. Si la persona prefiere no
levantarlo, sigue sin Docker y deja anotado que no se pudo inspeccionar.

Con el daemon arriba:
- `docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'`
  (incluye `-a`: los contenedores **detenidos** también son candidatos a
  reutilizar — ofrece arrancarlos con `docker start <name>`, nunca recrearlos).
- `docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'`
- `docker network ls` y `docker volume ls`
- Para candidatos relevantes (imágenes de postgres, mysql, mongo, redis,
  rabbitmq, kafka, minio, elasticsearch, keycloak, localstack…):
  `docker inspect <name>` para obtener puerto publicado, red, variables de
  entorno (credenciales por defecto), y montajes de volumen.
- Detecta si hay un proyecto de Compose ya corriendo
  (`docker compose ls`).

### Servicios del sistema operativo
- Windows: `Get-Service | Where-Object {$_.Status -eq 'Running'}` y filtra por
  `postgres`, `mysql`, `redis`, `mongodb`, `rabbitmq`; `Get-NetTCPConnection
  -State Listen`.
- Linux/macOS: `ss -tlnp` / `lsof -iTCP -sTCP:LISTEN`, `systemctl list-units
  --type=service --state=running`, `brew services list`.

### Puertos
- Arma la lista de puertos en escucha para cruzar con los que el proyecto espera
  (de `detect-environment`) y detectar colisiones.

## Salida

| Recurso | Origen (Docker / SO / —) | Estado (corriendo / detenido) | Endpoint | Credenciales conocidas | ¿Reutilizable para? |
|---|---|---|---|---|---|

Y una lista de **puertos ocupados** relevante para `compose-builder`.

Si el daemon de Docker estaba apagado, déjalo explícito en la salida: "Docker
estaba apagado; lo levanté con permiso y encontré N contenedores" o "la persona
optó por no levantarlo, no se pudo inspeccionar Docker".

## Reglas

- Nunca **borres ni reinicies** contenedores/servicios existentes.
- Sí puedes, **con permiso explícito**, arrancar el daemon de Docker si está
  apagado y hacer `docker start <name>` de un contenedor detenido que la persona
  quiera reutilizar. Nada más.
- Si no tienes permiso para ejecutar comandos, pide a la persona que levante
  Docker y pegue la salida de `docker ps -a` y de la lista de puertos.
- No asumas credenciales: si no puedes leerlas, pregunta.
