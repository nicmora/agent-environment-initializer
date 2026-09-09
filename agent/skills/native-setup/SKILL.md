---
name: env-native-setup
description: Materializa el camino de ejecución nativo (sin Docker o combinado con Docker) — dentro de env/ genera el archivo de versiones de runtime, los scripts de arranque/apagado/logs, un Procfile local para orquestar procesos, un INSTALL.md con los comandos exactos para instalar cada servicio de infraestructura en el sistema operativo, y el .env para arranque nativo. Usar cuando ya está decidido que la app o alguna dependencia corre nativa y hay que "crear los archivos" / "armar el arranque en el host".
---

# Skill: native-setup

Esta skill materializa el **camino nativo**. Si otra parte del plan va en Docker,
la maneja `compose-builder`; en un plan mixto, ambas generan sus artefactos en
`env/` y el script de `env/scripts/dev-up` los orquesta.

## Entrada

El **plan ya confirmado** (con la persona habiendo tenido la oportunidad de
cambiar algo, ver "Resumen final" en `brownfield-wizard`/`greenfield-wizard`): la
tabla de decisiones, la salida de `inspect-local-resources` (gestor de paquetes,
runtime instalado, puertos ocupados) y las recetas de `service-recipes`. No
materialices nada si ese resumen final todavía no se mostró y confirmó.

## Todo vive en `env/`

Igual que `compose-builder`: todo lo que esta skill genera va **dentro de una
carpeta `env/` en la raíz del proyecto**, y `env/` se agrega a `.gitignore` la
primera vez (créalo si no existe y muéstraselo a la persona). Nunca toques un
`Procfile`, `Makefile`, `.nvmrc` o script que ya exista fuera de `env/`; si hay
que apoyarse en ellos, referencialos desde `env/`.

## Artefactos

### 1. Versión de runtime — `env/.tool-versions` (o equivalente)

- Fija la versión que pide el proyecto (de `detect-environment`: `.nvmrc`,
  `engines`, `.python-version`, `go.mod`, `pom.xml`, …).
- Formato según el gestor detectado por `inspect-local-resources`:
  - `asdf`/`mise` → `env/.tool-versions` (`nodejs 20.11.1`, `python 3.12.2`).
  - `nvm`/`fnm` → `env/.nvmrc`. `pyenv` → `env/.python-version`.
  - `sdkman` → `env/.sdkmanrc`.
- Si **no hay** gestor de versiones, deja la versión anotada en `INSTALL.md` y en
  `ENVIRONMENT.md` como prerrequisito, con el link de descarga oficial.
- La versión es una variable/archivo pisable, no algo hardcodeado en los scripts.

### 2. Instalación de servicios de infra — `env/INSTALL.md`

Para cada dependencia que se resolvió como **instalar nativo**, una sección con:

- **Comando de instalación exacto** para el gestor de paquetes de este SO
  (ver tabla en `service-recipes`), p. ej.:
  - macOS: `brew install postgresql@16`
  - Debian/Ubuntu: `sudo apt install postgresql-16`
  - Windows: `winget install PostgreSQL.PostgreSQL.16`
- **Cómo arrancar el servicio** (`brew services start postgresql@16`,
  `sudo systemctl enable --now postgresql`, servicio de Windows).
- **Creación del espacio lógico** de forma aditiva (`createdb`, `CREATE ROLE`,
  `redis` base numerada, `rabbitmqctl add_vhost`, `mc mb`), sin `DROP` de nada.
- **Puerto** en el que queda escuchando (el estándar, o el alternativo si el
  estándar estaba ocupado).

**Los comandos se documentan; no los ejecuta la skill.** El agente puede
ofrecer correrlos, uno por uno y con permiso explícito para cada `install`.

### 3. Orquestación de procesos — `env/Procfile`

Si la app tiene más de un proceso (web + worker + scheduler, o app + tailwind
watcher), un `env/Procfile` para `foreman` / `overmind` / `hivemind` / `honcho`:

```procfile
web: npm run dev
worker: npm run worker
```

- Un solo proceso → no hace falta Procfile; el script lo arranca directo.
- Documenta qué runner se usa y cómo se instala (es una dependencia de dev más).

### 4. Variables de entorno — `env/.env.example` y `env/.env.local`

- Mismas reglas que `compose-builder`: todas las claves con ejemplo en
  `.env.example`, valores reales/secretos en `.env.local`, un comentario por
  variable, **sin rutas absolutas de máquina**.
- En arranque nativo los hosts suelen ser `localhost` tanto desde la app como
  desde el host (no hay red de contenedores): `DATABASE_URL=postgres://user:pass@localhost:5432/db`.
- El script de arranque carga este archivo (`set -a; . env/.env.local; set +a`,
  o `dotenv`, o el `--env-file` del runner).

### 5. Scripts — `env/scripts/`

- `dev-up`:
  1. Selecciona la versión de runtime (`nvm use`, `pyenv local`, `asdf install`,
     o nada si no hay gestor).
  2. Arranca los servicios de infra nativos que no estén ya corriendo
     (`brew services start …`, `pg_ctl start`, …) — comprobando primero, sin
     duplicar.
  3. Si el plan es mixto: `docker compose … up -d` para la parte en contenedor.
  4. Carga `env/.env.local` y arranca la app: el runner sobre `env/Procfile`, o
     el comando directo.
- `dev-down`: baja lo que `dev-up` levantó. Para servicios de infra que **ya
  estaban** antes de la sesión, no los pares: solo los que arrancó el script.
  Nunca borres datos ni directorios de datos.
- `dev-logs`: `tail`/`journalctl`/`brew services` de los servicios + logs de la
  app.
- Haz los scripts para el shell de la persona (`.sh` POSIX y/o `.ps1`), sin
  rutas absolutas — relativas a la raíz del repo.

## Datos persistentes (no destructivo)

- Un servicio nativo guarda sus datos en el datadir del SO (p. ej.
  `/opt/homebrew/var/postgresql@16`, `/var/lib/postgresql`). **Nunca** lo borres
  ni lo reinicialices para "destrabar".
- Si hace falta un datadir aislado para el proyecto, créalo bajo `env/data/`
  (queda en `.gitignore`) y apuntá el servicio ahí al arrancarlo — sin tocar el
  datadir por defecto.

## Salida

Lista de archivos creados/modificados dentro de `env/` (y la línea agregada a
`.gitignore`), el comando de arranque completo, y los comandos de instalación
pendientes que la persona todavía tiene que autorizar. Handoff a
`verify-environment`.

## Renombrar valores

Igual que `compose-builder`: si la persona pide cambiar un nombre (DB, schema,
usuario, base de Redis, vhost, bucket, puerto, datadir), aplicá el cambio **en
todos los archivos a la vez** (`.env.local`, `.env.example`, `INSTALL.md`,
scripts, `Procfile`, `ENVIRONMENT.md`, todos dentro de `env/`). Mostrá el diff.
Si el recurso viejo ya se había creado, no lo borres sin permiso: acláralo entre
los pendientes.
