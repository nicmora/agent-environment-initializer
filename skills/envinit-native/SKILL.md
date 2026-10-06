---
name: envinit-native
description: Materializa el arranque nativo de la aplicación (la app corriendo con el runtime del host, sin contenedor) — dentro de local/ genera el archivo de versiones de runtime, un Procfile local para orquestar procesos, los scripts de arranque/apagado/logs y el .env para arranque nativo. No instala servicios de infraestructura: esos se crean en Docker (envinit-compose) o son servicios existentes a los que la app se conecta. Usar cuando ya está decidido que la app corre nativa y hay que "armar el arranque en el host".
---

# Skill: envinit-native

Esta skill materializa **el arranque nativo de la app**. Los servicios de infra
que van en Docker los maneja `envinit-compose`; los que son servicios existentes
solo aportan variables a `local/.env.local`. En un plan mixto (app nativa +
dependencias en Docker), ambas skills generan sus artefactos en `local/` y el
script de `local/scripts/dev-up` los orquesta.

## Entrada

El **plan ya confirmado** (con la persona habiendo tenido la oportunidad de
cambiar algo, ver "Resumen final" en `envinit-plan`): la tabla de
decisiones, la versión de runtime que pide el proyecto (de
`envinit-detect`) y el gestor de versiones que la persona dijo usar. No
materialices nada si ese resumen final todavía no se mostró y confirmó.

## Todo vive en `local/`

Igual que `envinit-compose`: todo lo que esta skill genera va **dentro de una
carpeta `local/` en la raíz del proyecto**, y `local/` se agrega a `.gitignore` la
primera vez (créalo si no existe y muéstraselo a la persona). Nunca toques un
`Procfile`, `Makefile`, `.nvmrc` o script que ya exista fuera de `local/`; si hay
que apoyarse en ellos, referencialos desde `local/`.

## Artefactos

### 1. Versión de runtime — `local/.nvmrc` (o equivalente)

- Fija la versión que pide el proyecto (de `envinit-detect`: `.nvmrc`,
  `engines`, `.python-version`, `go.mod`, `pom.xml`, …).
- Formato según el gestor de versiones que la persona use:
  - `asdf`/`mise` → `local/.tool-versions` (`nodejs 20.11.1`, `python 3.12.2`).
  - `nvm`/`fnm` → `local/.nvmrc`. `pyenv` → `local/.python-version`.
  - `sdkman` → `local/.sdkmanrc`.
- Si **no hay** gestor de versiones, deja la versión anotada en `ENVIRONMENT.md`
  como prerrequisito, con el link de descarga oficial. **El agente no instala
  runtimes.**
- La versión es una variable/archivo pisable, no algo hardcodeado en los scripts.

### 2. Orquestación de procesos — `local/Procfile`

Si la app tiene más de un proceso (web + worker + scheduler, o app + tailwind
watcher), un `local/Procfile` para `foreman` / `overmind` / `hivemind` / `honcho`:

```procfile
web: npm run dev
worker: npm run worker
```

- Un solo proceso → no hace falta Procfile; el script lo arranca directo.
- Documenta qué runner se usa y cómo se instala (es una dependencia de dev más).

### 3. Variables de entorno — `local/.env.example` y `local/.env.local`

- Mismas reglas que `envinit-compose`: todas las claves con ejemplo en
  `.env.example`, valores reales/secretos en `.env.local`, un comentario por
  variable, **sin rutas absolutas de máquina**.
- En arranque nativo, los hosts de las dependencias que van en Docker son
  `localhost:<puerto publicado>`; los de servicios existentes son el host que
  aportó la persona:
  `DATABASE_URL=postgres://user:pass@localhost:5432/db`.
- El script de arranque carga este archivo (`set -a; . local/.env.local; set +a`,
  o `dotenv`, o el `--env-file` del runner).

### 4. Scripts — `local/scripts/`

- `dev-up`:
  1. Selecciona la versión de runtime (`nvm use`, `pyenv local`, `asdf install`,
     o nada si no hay gestor).
  2. Si el plan es mixto: `docker compose … --profile infra up -d` para las
     dependencias en contenedor, y espera sus healthchecks.
  3. Carga `local/.env.local` y arranca la app: el runner sobre `local/Procfile`, o
     el comando directo.
- `dev-down`: baja lo que `dev-up` levantó (los contenedores de infra con
  `down`, **sin `-v`**). No para servicios existentes ni borra datos.
- `dev-logs`: logs de la app + `docker compose … logs -f` de la infra en
  contenedor si el plan es mixto.
- Haz los scripts para el shell de la persona (`.sh` POSIX y/o `.ps1`), sin
  rutas absolutas — relativas a la raíz del repo.

## Datos persistentes (no destructivo)

- Las dependencias en Docker guardan sus datos en volúmenes nombrados
  (`envinit-compose`). **Nunca** los borres para "destrabar".
- Un servicio existente tiene sus datos donde la persona los tenga. El agente no
  los toca.

## Salida

Lista de archivos creados/modificados dentro de `local/` (y la línea agregada a
`.gitignore`), el comando de arranque completo, y los prerrequisitos que la
persona todavía tiene que resolver por su cuenta (instalar el runtime en la
versión pedida, instalar el runner de procesos). Handoff a `envinit-verify`.

## Renombrar valores

Igual que `envinit-compose`: si la persona pide cambiar un nombre (variable de
conexión, puerto), aplicá el cambio **en todos los archivos a la vez**
(`.env.local`, `.env.example`, scripts, `Procfile`, `ENVIRONMENT.md`, todos
dentro de `local/`). Mostrá el diff.
