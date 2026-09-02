---
name: env-document-environment
description: Genera o actualiza ENVIRONMENT.md en la raíz del proyecto — inventario de servicios, modo de conexión de cada dependencia (real/creada/reutilizada/compartida/mock), variables de entorno, puertos, y procedimientos de arranque y apagado. Usar al cerrar cada sesión o cada vez que cambia algo del entorno.
---

# Skill: document-environment

## Objetivo

Mantener un `ENVIRONMENT.md` en la raíz del repo que sea la referencia única de
cómo correr la app localmente.

## Portabilidad — el archivo se versiona

`ENVIRONMENT.md` se commitea y lo usa **todo el equipo**. Tiene que servir en
cualquier máquina. Prohibido en este archivo (y en `.env.example`, scripts y
compose versionados):

- Rutas absolutas con usuario (`C:\Users\nicmora\…`, `/home/nico/…`,
  `/Users/nico/…`).
- Nombres de carpeta propios de tu equipo (`Prueba IA`, `pruebas-nico`).
- Secretos reales, tokens, hosts de staging con credenciales.

En su lugar:

- **Pila compartida / infra externa:** referenciala por convención portable.
  Opción A (preferida): repo hermano — `../docker-environment/docker-compose.yml`,
  con un prerrequisito explícito ("cloná `docker-environment` al lado de este
  repo: `git clone <url>`"). Opción B: variable `SHARED_INFRA_DIR` que cada
  persona define en su `.env.local` con la ruta de su máquina; en la doc y los
  scripts usás `${SHARED_INFRA_DIR}`.
- **Credenciales de dev:** en `ENVIRONMENT.md` mostrá el valor de ejemplo y aclará
  "definido en `.env.local`". El valor real vive solo en `.env.local`; en
  `.env.example` va un placeholder.
- Si necesitás mostrar una ruta, que sea **relativa a la raíz del repo**.

## Plantilla

```markdown
# Entorno de desarrollo

> Generado y mantenido por el agente inicializador de entornos.
> Última actualización: <fecha>

## Prerrequisitos

- Docker + Docker Compose.
- <si aplica> Pila compartida `docker-environment` clonada como repo hermano
  (`../docker-environment`), o `SHARED_INFRA_DIR` seteado en `.env.local`.

## Cómo levantar

```bash
<comando de arranque>       # p. ej. ./scripts/dev-up  o  docker compose --profile infra up -d && docker compose up
```

## Cómo apagar

```bash
docker compose down          # NUNCA con -v (borraría los datos)
```

## Servicios

| Servicio | Estrategia | Endpoint (desde la app / desde el host) | Perfil | Notas |
|---|---|---|---|---|
| postgres | pila compartida (~/dev-infra) | postgres:5432 / localhost:5432 | — | schema `miproyecto`, usuario `miproyecto_user` |
| redis | creado (override) | redis:6379/2 / localhost:6380 | infra | — |
| payments-api | mock (Prism) | payments-mock:4010 | mock | stubs en ./mocks/payments |
| ... | ... | ... | ... | ... |

## Variables de entorno

| Variable | Dónde se define | Ejemplo | Descripción |
|---|---|---|---|
| DATABASE_URL | .env.local | postgres://... | conexión principal |
| ... | ... | ... | ... |

## Espacios lógicos usados en la pila compartida

- Postgres: DB/schema `miproyecto`
- Redis: base `2`
- RabbitMQ: vhost `/miproyecto`
- MinIO: bucket `miproyecto`

## Pendientes / decisiones abiertas

- [ ] ...
```

## Procedimiento

1. Si `ENVIRONMENT.md` no existe, crealo con la plantilla.
2. Si existe, **actualizá solo las secciones que cambiaron** (no reescribas lo
   que la persona haya editado a mano; mostrá el diff).
2b. **Antes de escribir, revisá que no haya rutas absolutas con usuario, nombres
   de carpeta personales ni secretos reales** (ver "Portabilidad"). Si los hay,
   reemplazalos por la convención portable y avisá.
3. Reflejá siempre: estrategia por dependencia, perfiles de compose, comandos, y
   espacios lógicos de la pila compartida.
4. Si tocaste la pila compartida, actualizá también su README
   (`~/dev-infra/README.md`) con el espacio lógico asignado a este proyecto.
