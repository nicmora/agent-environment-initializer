---
name: document-environment
description: Genera o actualiza env/ENVIRONMENT.md — medio de ejecución elegido, inventario de servicios, modo de conexión de cada dependencia (real/creada en Docker/instalada nativa/reutilizada/mock), variables de entorno, puertos, y procedimientos de arranque y apagado. Usar al cerrar cada sesión o cada vez que cambia algo del entorno.
---

# Skill: document-environment

## Objetivo

Mantener `env/ENVIRONMENT.md` como la referencia única de cómo correr la
app localmente.

## Portabilidad — el archivo no se versiona, pero igual evita atarlo a esta máquina

`env/ENVIRONMENT.md` vive dentro de `env/`, que está en
`.gitignore` (ver regla 4 de `AGENT.md`): es personal, no lo usa el resto del
equipo vía git. Aun así, evita atarlo a esta máquina puntual — si la persona
reclona el repo o regenera `env/` en otra carpeta/equipo, el documento
tiene que seguir siendo útil sin editarlo a mano. Evita en este archivo (y en
`.env.example`, scripts y compose de `env/`):

- Rutas absolutas con usuario (`C:\Users\nicmora\…`, `/home/nico/…`,
  `/Users/nico/…`).
- Nombres de carpeta propios de tu equipo (`Prueba IA`, `pruebas-nico`).
- Secretos reales, tokens, hosts de staging con credenciales (sí puede tenerlos
  `env/.env.local`, que tampoco se versiona, pero mejor mantenerlo
  centralizado ahí y no repetido en la documentación).

En su lugar:

- **Contenedor de dependencias compartido (si se reutiliza uno):** no anotes su
  ruta ni su nombre de otra máquina. Documentá el **nombre de la red de Docker
  externa** y los **nombres de servicio** (`postgres`, `redis`, …), que son
  estables, y dejá credenciales y puertos en `env/.env.local`. Aclará como
  prerrequisito que ese contenedor y esa red tienen que existir en la máquina.
- **Credenciales de dev:** en `ENVIRONMENT.md` muestra el valor de ejemplo y
  aclara "definido en `env/.env.local`". El valor real vive solo ahí; en
  `env/.env.example` va un placeholder.
- Si necesitas mostrar una ruta, que sea **relativa a la raíz del repo**.

## Plantilla

```markdown
# Entorno de desarrollo

> Generado y mantenido por el agente inicializador de entornos.
> Última actualización: <fecha>

## Medio de ejecución

<Docker / nativo en el host / mixto>. <Una línea de por qué se eligió, si la
persona lo dijo.>

## Prerrequisitos

Según el medio:

- **Docker:** Docker + Docker Compose.
- **Nativo:** runtime `<lenguaje> <versión>` (fijada en `env/.tool-versions` /
  `.nvmrc`), gestor de versiones `<nvm/pyenv/asdf/mise>` si se usa, runner de
  procesos `<foreman/overmind>` si hay `env/Procfile`, y los servicios de
  `env/INSTALL.md` instalados.
- <si aplica> Contenedor de dependencias compartido de la persona corriendo, con
  su red de Docker (`<red>`) disponible.

## Cómo levantar

```bash
<comando de arranque completo>   # p. ej. ./env/scripts/dev-up
# Docker:  docker compose -f docker-compose.yml -f env/docker-compose.override.yml --env-file env/.env.local --profile infra up -d && docker compose ... up
# Nativo:  brew services start postgresql@16 redis && nvm use && set -a && . env/.env.local && set +a && overmind start -f env/Procfile
```

## Cómo apagar

```bash
<comando de apagado>   # ./env/scripts/dev-down
# Docker:  docker compose ... down   # NUNCA con -v (borraría los datos)
# Nativo:  detener solo lo que arrancó dev-up; los servicios que ya estaban NO se bajan
```

## Servicios

| Servicio | Estrategia | Medio | Endpoint (desde la app / desde el host) | Imagen o paquete (variable) | Mem límite | Perfil | Notas |
|---|---|---|---|---|---|---|---|
| postgres | reutilizado (contenedor compartido) | Docker | postgres:5432 / localhost:5432 | — (contenedor externo) | — | — | schema `miproyecto` |
| redis | creado | nativo | localhost:6379 / localhost:6379 | `redis` (brew, v7) | — | — | base `2`; arranca `brew services` |
| payments-api | mock (Prism) | nativo | localhost:4010 | `npx @stoplight/prism-cli` | — | mock | stubs en env/mocks/payments |
| ... | ... | ... | ... | ... | ... | ... | ... |

Anota que imagen/paquete y límite son defaults pisables desde `env/.env.local`.

## Variables de entorno

| Variable | Dónde se define | Ejemplo | Descripción |
|---|---|---|---|
| DATABASE_URL | env/.env.local | postgres://... | conexión principal |
| ... | ... | ... | ... |

## Espacios lógicos usados en el contenedor compartido

- Postgres: DB/schema `miproyecto`
- Redis: base `2`
- RabbitMQ: vhost `/miproyecto`
- MinIO: bucket `miproyecto`

## Pendientes / decisiones abiertas

- [ ] ...
```

## Procedimiento

1. Si `env/ENVIRONMENT.md` no existe, créalo con la plantilla (creando
   `env/` y agregándola a `.gitignore` si todavía no existía).
2. Si existe, **actualiza solo las secciones que cambiaron** (no reescribas lo
   que la persona haya editado a mano; muestra el diff).
2b. **Antes de escribir, revisa que no haya rutas absolutas con usuario, nombres
   de carpeta personales ni secretos reales** (ver "Portabilidad"). Si los hay,
   reemplázalos por la convención portable y avisa.
3. Refleja siempre: medio de ejecución, estrategia y medio por dependencia,
   perfiles de compose o entradas del `Procfile`, comandos de instalación
   pendientes, comandos de arranque/apagado, y los espacios lógicos creados en un
   contenedor de dependencias compartido si se reutilizó uno.
