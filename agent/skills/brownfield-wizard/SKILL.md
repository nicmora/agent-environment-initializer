---
name: env-brownfield-wizard
description: Para un proyecto existente, guía la elección del medio de ejecución de la app (contenedor Docker o runtime nativo en el host) y, para cada dependencia detectada, la estrategia — reutilizar un recurso local o la pila compartida, conectar a una instancia externa, crear el servicio desde cero (en Docker o instalado nativo), o simularlo (mock). Usar después de detect-environment, o cuando el usuario quiere decidir "cómo corro cada cosa".
---

# Skill: brownfield-wizard

## Requisitos previos

Tener el resumen de `detect-environment` (stack, versión de runtime, cómo
arranca hoy, dependencias, configuración) ya mostrado a la persona. **Todavía no
ejecutes `inspect-local-resources`** — se invoca recién más adelante, y solo para
las decisiones donde haga falta (ver paso 2).

## Regla de presentación

Para cada decisión, **presentá las opciones sin recomendar ninguna**. En cada
opción explicá qué implica de forma objetiva (qué necesita, qué deja instalado,
cómo se aísla), no cuál te parece mejor. No marques ninguna como "recomendada".
Usá el selector interactivo (`AskUserQuestion`) cuando el asistente lo tenga.

## Procedimiento

### 0. Medio de ejecución de la app

Antes de recorrer las dependencias, preguntá cómo se quiere levantar la
**aplicación misma**:

- **En contenedor (Docker).** Necesita Docker instalado y el daemon corriendo;
  descarga/arma una imagen. Aísla el runtime de tu SO. Si no hay Dockerfile, se
  crea uno en `env/Dockerfile.dev`.
- **En el host, con el runtime nativo.** Usa el Node/Python/JVM/Go de tu máquina
  (o el que instale tu gestor de versiones). Arranque más rápido y hot-reload
  directo; depende de tener la versión de runtime correcta. Se materializa con
  scripts en `env/` y, si el proyecto tiene varios procesos, un `env/Procfile`.
- **Lo que el proyecto ya use**, si `detect-environment` encontró un camino de
  arranque que la persona quiere conservar.

El comando concreto (`npm run dev`, `./gradlew bootRun`, …) sale de
`detect-environment`; confirmalo. Esta decisión define si más adelante hace falta
un `Dockerfile` de desarrollo o un archivo de versiones de runtime.

### 1. Estrategia por dependencia

Recorré el inventario **de a una dependencia por vez**: presentás sus hallazgos,
preguntás su estrategia (y, si aplica, si va en Docker o nativa) y cerrás su
configuración (espacio lógico, credenciales) antes de pasar a la siguiente. No
juntes en una misma pregunta decisiones de dependencias distintas. El detalle
técnico (imagen/tag/memoria/puerto en Docker; versión/forma de instalación si es
nativa) **no** se pregunta: lo decide el agente (ver paso 4 y "Lo que el agente
decide solo" en `AGENT.md`).

Para cada dependencia, presentá las opciones y pedí una decisión:

1. **Pila de infraestructura compartida.** ¿Existe o se quiere crear una pila
   compartida del equipo? → deriva a `shared-infra`. Se crea un espacio lógico
   aislado para este servicio (schema/DB, base numerada de Redis, vhost de
   RabbitMQ, topic namespace de Kafka, bucket de MinIO, prefijo de claves).
2. **Recurso ya presente en la máquina.** Recién acá hace falta mirar la
   máquina: ejecutá `inspect-local-resources` (si todavía no la corriste en
   esta sesión).
   - Contenedor Docker corriendo o detenido → conectar a ese: detectá nombre,
     red, puerto publicado y credenciales. Configurá la app para usar ese
     host/puerto.
   - Servicio instalado en el SO (Postgres, Redis, etc. en el host, o vía
     Homebrew/apt) → apuntá la app a `localhost:<puerto>` y, si hace falta, creá
     una DB/usuario nuevos **sin tocar** lo existente.
   - En ambos casos: **no metas la app en una DB/schema/vhost/bucket existente
     sin preguntar.** Ofrecé crear un espacio lógico propio y proponé un nombre
     (editable) para él.
3. **Instancia externa** (staging, cloud, otro equipo) → pedí host, puerto,
   credenciales y guardalas en `env/.env.local`. Verificá conectividad de red.
   No hace falta tocar la máquina para esta estrategia.
4. **Crear desde cero.** Ofrecé las dos variantes cuando ambas sean viables:
   - **En Docker** → requiere `inspect-local-resources` (Docker
     instalado/iniciado, puertos libres). El servicio va a
     `env/docker-compose.override.yml` o `env/docker-compose.dev.yml` (nunca al
     compose existente fuera de `env/`). Deriva a `compose-builder` +
     `service-recipes`.
   - **Instalado nativo en el SO** → requiere `inspect-local-resources` (ver si
     ya está, con qué gestor de paquetes se instala, puertos libres). Se genera
     `env/INSTALL.md` con el comando exacto (brew/apt/winget), el arranque del
     servicio y, si corresponde, la creación del espacio lógico. **El comando de
     instalación se muestra, no se ejecuta sin permiso.** Deriva a `native-setup`
     + `service-recipes`.
   - En cualquiera de las dos: solo preguntás nombre de DB/schema/usuario/
     contraseña de dev si aplica. El detalle técnico (imagen o paquete, versión,
     memoria, puerto) lo decide el agente y aparece recién en el resumen final.
5. **Servicio de terceros / de otro equipo** → deriva a `external-mocks`:
   conexión real vs. simulación. El mock puede correr como contenedor o como
   proceso nativo.

Si al terminar de recorrer todas las dependencias ninguna quedó en "reutilizar
local", "crear en Docker" ni "instalar nativo", y la app corre con un runtime ya
presente, nunca se ejecutó `inspect-local-resources` — está bien, no hacía falta.

## Manejo de conflictos (no destructivo)

- **Puerto ocupado** → el agente elige directamente el siguiente puerto libre en
  el host y ajusta la variable de conexión (lo anota en el resumen final). Nunca
  mates el proceso que lo usa sin permiso explícito.
- **Nombre de contenedor/volumen/red en uso** → usá un nombre nuevo con prefijo
  del proyecto.
- **Ya existe una DB/schema con ese nombre** → proponé un nombre alternativo; no
  la sobrescribas.
- **Servicio ya instalado en el SO con otra versión** → avisá y dejá que la
  persona decida (usar el que hay, instalar la versión pedida en paralelo si el
  gestor lo permite, o ir por Docker para esa dependencia). Nunca lo
  desinstales ni lo reconfigures.
- **Versión de runtime distinta** entre lo que pide el proyecto y lo instalado →
  avisá; proponé el gestor de versiones (nvm/pyenv/asdf/mise) o Docker.

## Salida

Una tabla de decisiones:

| Dependencia | Estrategia elegida | Medio (Docker / nativo / externo / —) | Espacio lógico | Variables de entorno a setear | Archivo destino (dentro de `env/`) |
|---|---|---|---|---|---|

Los nombres de espacios lógicos son **propuestas editables** que confirmás con la
persona antes del handoff. El detalle técnico de lo que se crea desde cero **no**
va en esta confirmación por-dependencia: lo resuelve el agente y aparece por
primera vez en el resumen final.

### Resumen final antes de materializar

Con todas las dependencias resueltas, presentá un **resumen consolidado del plan
completo**: el medio de ejecución de la app, la tabla de arriba, más — para cada
servicio creado desde cero — el detalle técnico que decidió el agente (imagen/
variante, tag, memoria y puerto si va en Docker; versión y comando de
instalación si va nativo), con una línea de por qué, más la lista de archivos que
se van a crear en `env/` (compose y/o scripts, `Procfile`, `.tool-versions`,
`INSTALL.md`, `.env.example`, `.env.local`, `Dockerfile.dev`, mocks,
`ENVIRONMENT.md`). Preguntá explícitamente si hay algo para cambiar. Solo con el
plan confirmado, hacé el handoff a `compose-builder` y/o `native-setup`, y a
`document-environment`.
