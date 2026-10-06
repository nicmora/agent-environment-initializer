---
name: envinit-document
description: Genera o actualiza local/ENVIRONMENT.md — medio de ejecución de la app, inventario de servicios, origen de cada dependencia (creada en Docker / servicio existente / mock), variables de entorno, puertos, y procedimientos de arranque y apagado. Usar al cerrar cada sesión o cada vez que cambia algo del entorno.
---

# Skill: envinit-document

## Objetivo

Mantener `local/ENVIRONMENT.md` como la referencia única de cómo correr la
app localmente.

## Portabilidad — el archivo no se versiona, pero igual evita atarlo a esta máquina

`local/ENVIRONMENT.md` vive dentro de `local/`, que está en
`.gitignore` (ver regla 4 de `AGENT.md`): es personal, no lo usa el resto del
equipo vía git. Aun así, evita atarlo a esta máquina puntual — si la persona
reclona el repo o regenera `local/` en otra carpeta/equipo, el documento
tiene que seguir siendo útil sin editarlo a mano. Evita en este archivo (y en
`.env.example`, scripts y compose de `local/`):

- Rutas absolutas con usuario (`C:\Users\nicmora\…`, `/home/nico/…`,
  `/Users/nico/…`).
- Nombres de carpeta propios de tu equipo (`Prueba IA`, `pruebas-nico`).
- Secretos reales, tokens, hosts de staging con credenciales (sí puede tenerlos
  `local/.env.local`, que tampoco se versiona, pero mejor mantenerlo
  centralizado ahí y no repetido en la documentación).

En su lugar:

- **Servicios existentes (a los que la app se conecta):** no anotes host,
  puerto ni credenciales en `ENVIRONMENT.md`. Dejá esos valores en
  `local/.env.local` y en el documento solo la variable de conexión
  (`DATABASE_URL`, `REDIS_URL`, …) y una nota de que el servicio tiene que estar
  disponible como prerrequisito.
- **Credenciales de dev:** en `ENVIRONMENT.md` muestra el valor de ejemplo y
  aclara "definido en `local/.env.local`". El valor real vive solo ahí; en
  `local/.env.example` va un placeholder.
- Si necesitas mostrar una ruta, que sea **relativa a la raíz del repo**.

## Plantilla

```markdown
# Entorno de desarrollo

> Generado y mantenido por el agente inicializador de entornos.
> Última actualización: <fecha>

## Medio de ejecución de la app

<Docker / nativo en el host>. <Una línea de por qué se eligió, si la persona lo
dijo.>

## Prerrequisitos

- **Si hay servicios en Docker:** Docker + Docker Compose.
- **Si la app corre nativa:** runtime `<lenguaje> <versión>` (fijada en
  `local/.nvmrc` / `local/.tool-versions`), gestor de versiones
  `<nvm/pyenv/asdf/mise>` si se usa, y el runner de procesos `<foreman/overmind>`
  si hay `local/Procfile`. El agente no instala el runtime: hay que tenerlo.
- **Servicios existentes:** `<Postgres en la nube / Redis del SO / API de pagos>`
  disponibles y accesibles, con sus datos de conexión cargados en
  `local/.env.local`.

## Cómo levantar

```bash
<comando de arranque completo>   # p. ej. ./local/scripts/dev-up
# Docker:  docker compose -f docker-compose.yml -f local/docker-compose.override.yml --env-file local/.env.local --profile infra up -d && docker compose ... up
# App nativa + infra en Docker:  docker compose ... --profile infra up -d && nvm use && set -a && . local/.env.local && set +a && overmind start -f local/Procfile
```

## Cómo apagar

```bash
<comando de apagado>   # ./local/scripts/dev-down
# Docker:  docker compose ... down   # NUNCA con -v (borraría los datos)
# Servicios existentes: nunca se tocan
```

## Servicios

| Servicio | Origen | Endpoint (desde la app / desde el host) | Imagen (variable) | Mem límite | Perfil | Notas |
|---|---|---|---|---|---|---|
| postgres | Docker | postgres:5432 / localhost:5432 | `${POSTGRES_IMAGE:-postgres:16-alpine}` | 512m | infra | DB `miproyecto` |
| redis | servicio existente | redis.midominio.com:6379 (mismo) | — | — | — | base `2`; datos de conexión en `local/.env.local` |
| payments-api | mock (Prism, Docker) | localhost:4010 / localhost:4010 | `stoplight/prism:4` | 256m | mock | stubs en local/mocks/payments |
| ... | ... | ... | ... | ... | ... | ... |

Anota que imagen y límite son defaults pisables desde `local/.env.local`.

## Variables de entorno

| Variable | Dónde se define | Ejemplo | Descripción |
|---|---|---|---|
| DATABASE_URL | local/.env.local | postgres://... | conexión principal |
| ... | ... | ... | ... |

## Espacios lógicos creados en Docker

- Postgres: DB/schema `miproyecto`
- RabbitMQ: vhost `/miproyecto`
- MinIO: bucket `miproyecto`

(Para servicios existentes, el espacio lógico lo provee la persona; no se crea
nada.)

## Pendientes / decisiones abiertas

- [ ] ...
```

## Procedimiento

1. Si `local/ENVIRONMENT.md` no existe, créalo con la plantilla (creando
   `local/` y agregándola a `.gitignore` si todavía no existía).
2. Si existe, **actualiza solo las secciones que cambiaron** (no reescribas lo
   que la persona haya editado a mano; ofrecé mostrar el diff).
2b. **Antes de escribir, revisa que no haya rutas absolutas con usuario, nombres
   de carpeta personales ni secretos reales** (ver "Portabilidad"). Si los hay,
   reemplázalos por la convención portable y avisa.
3. Refleja siempre: medio de ejecución de la app, origen de cada dependencia
   (Docker / servicio existente / mock), perfiles de compose o entradas del
   `Procfile`, prerrequisitos pendientes, comandos de arranque/apagado, y los
   espacios lógicos creados en Docker.
