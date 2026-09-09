---
name: env-inspect-local-resources
description: Inspecciona la máquina para descubrir contenedores Docker (con sus redes y volúmenes), un contenedor de dependencias compartido si la persona mantiene uno (un contenedor con varios servicios de infraestructura, o una red de Docker propia que los agrupe), servicios de infraestructura instalados en el sistema operativo, gestores de paquetes disponibles (brew/apt/winget/scoop), gestores de versiones de runtime (nvm/pyenv/asdf/mise) y versiones instaladas, y puertos ocupados. Sirve para ofrecer reutilizar recursos existentes, saber cómo instalar lo que falte y evitar colisiones de puertos. Usar recién cuando una decisión va a reutilizar un recurso local, crear un servicio en Docker, instalar algo nativo o depender de una versión de runtime concreta, o cuando el usuario dice "ya tengo una base de datos" / "fíjate qué tengo instalado".
---

# Skill: inspect-local-resources

## Objetivo

Saber qué hay disponible en la máquina para poder ofrecer **reutilizar** en vez
de crear.

## Cuándo se invoca (bajo demanda, no al inicio)

Esta skill **no** se ejecuta como parte del análisis inicial del proyecto
(`detect-environment` no la dispara). Se invoca recién cuando, dependencia por
dependencia en `brownfield-wizard`/`greenfield-wizard`, la persona elige algo que
realmente toca la máquina:

- Quiere **reutilizar** un recurso local (contenedor Docker o servicio del SO).
- Quiere **crear desde cero en Docker** (hay que saber si Docker está
  instalado/iniciado y qué puertos están libres).
- Quiere **instalar un servicio nativo** (hay que saber si ya está, con qué
  gestor de paquetes se instala en este SO y qué puertos están libres).
- La app va a correr **nativa** y hay que verificar la versión de runtime
  instalada / el gestor de versiones disponible.

Si todas las dependencias se resuelven con **conexión externa** o **mock** y la
app corre con un runtime que ya está, no hace falta ejecutar esta skill.

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

### Contenedor de dependencias compartido

Algunas personas mantienen un solo contenedor (o proyecto de Compose propio) con
varios servicios de infraestructura y una red de Docker reutilizable, y lo usan
en todos sus proyectos. Búscalo **solo cuando la persona ya eligió Docker para
crear o reutilizar alguna dependencia** (si no, no aporta):

- Un contenedor que publique varios puertos de infraestructura a la vez
  (5432 + 6379 + 5672…), o cuya imagen agrupe varios servicios.
- Una red de Docker creada por la persona (no `bridge`/`host`/`none` ni la
  `*_default` de un compose del propio proyecto) a la que estén conectados
  contenedores de Postgres, Redis, RabbitMQ, etc.: `docker network inspect <red>`
  para ver qué contenedores agrupa.

Si encontrás un candidato, anotá: nombre de la red, nombres de servicio /
contenedor, puertos publicados y credenciales por defecto (`docker inspect`). Se
ofrece como **una opción más de reutilización** frente a crear un contenedor
nuevo — nunca como recomendación, y nunca se ofrece crearlo. Si no hay ninguno,
seguí sin mencionarlo.

### Servicios del sistema operativo
- Windows: `Get-Service | Where-Object {$_.Status -eq 'Running'}` y filtra por
  `postgres`, `mysql`, `redis`, `mongodb`, `rabbitmq`; `Get-NetTCPConnection
  -State Listen`.
- Linux/macOS: `ss -tlnp` / `lsof -iTCP -sTCP:LISTEN`, `systemctl list-units
  --type=service --state=running`, `brew services list`.

### Gestores de paquetes disponibles (para instalar lo que falte, camino nativo)
- macOS: `brew --version`, `port version`.
- Linux: `apt`/`apt-get`, `dnf`/`yum`, `pacman`, `apk`, `nix`.
- Windows: `winget --version`, `scoop --version`, `choco --version`.
- Anota cuál está disponible; es lo que `native-setup` va a usar en `INSTALL.md`.

### Runtimes y gestores de versiones (para la app nativa)
- Runtime instalado: `node -v`, `python --version`, `go version`, `java -version`,
  `ruby -v`, `dotnet --version` — y si coincide con lo que pide el proyecto.
- Gestores de versiones: `nvm`, `fnm`, `pyenv`, `rbenv`, `sdkman`, `asdf`,
  `mise`, `volta`. Si hay uno, `native-setup` lo usa para fijar la versión sin
  tocar la global.

### Puertos
- Arma la lista de puertos en escucha para cruzar con los que el proyecto espera
  (de `detect-environment`) y detectar colisiones.

## Salida

| Recurso | Origen (Docker / SO / —) | Estado (corriendo / detenido) | Endpoint | Credenciales conocidas | ¿Reutilizable para? |
|---|---|---|---|---|---|

Más:

- **Contenedor de dependencias compartido**, si se detectó: red, servicios,
  puertos publicados y credenciales conocidas, para que los wizards lo ofrezcan
  como reutilización con espacio lógico aislado (nunca como creación).
- **Puertos ocupados** (relevante para `compose-builder` y `native-setup`).
- **Gestor de paquetes** a usar en este SO para el camino nativo.
- **Runtime instalado vs. requerido** y gestor de versiones disponible.

Si el daemon de Docker estaba apagado, déjalo explícito en la salida: "Docker
estaba apagado; lo levanté con permiso y encontré N contenedores" o "la persona
optó por no levantarlo, no se pudo inspeccionar Docker".

## Reglas

- Nunca **borres, reinicies, desinstales ni reconfigures** contenedores o
  servicios existentes. Un contenedor de dependencias compartido tampoco se
  recrea ni se modifica: cualquier uso posterior es aditivo (una DB/schema/vhost/
  bucket nuevo).
- Esta skill es **solo lectura**: no instala nada. Descubrir el gestor de
  paquetes sirve para que `native-setup` escriba el comando; la instalación la
  decide la persona más adelante, con permiso.
- Sí puedes, **con permiso explícito**, arrancar el daemon de Docker si está
  apagado y hacer `docker start <name>` de un contenedor detenido que la persona
  quiera reutilizar. Nada más.
- Si no tienes permiso para ejecutar comandos, pide a la persona que levante
  Docker y pegue la salida de `docker ps -a` y de la lista de puertos.
- No asumas credenciales: si no puedes leerlas, pregunta.
