---
name: envinit-plan
description: A partir del informe de envinit-detect, guía la elección del medio de ejecución de la app (contenedor Docker o runtime nativo en el host) y, para cada dependencia de entorno detectada, su origen — crear el servicio en Docker o conectar la app a un servicio existente fuera del proyecto (instalado en el SO, en la nube o de otro equipo), del que la persona aporta los datos de conexión. Para servicios de terceros deriva a envinit-mocks (conexión real vs. mock). Usar después de envinit-detect, o cuando el usuario quiere decidir "cómo corro cada cosa".
---

# Skill: envinit-plan

## Requisitos previos

Tener el resumen de `envinit-detect` (stack, versión de runtime, cómo
arranca hoy, dependencias detectadas, configuración) ya mostrado a la persona.
Esta skill trabaja sobre lo que se detectó del proyecto, sea cual sea su estado
— con muchas dependencias, con una, o con ninguna. **No hay un cuestionario de
dependencias hipotéticas:** si el proyecto todavía no usa una base de datos, una
caché o un broker, no se pregunta por ellos; la persona puede pedir agregarlos
después ("agregá Redis al entorno").

## Regla de presentación

Para cada decisión, **presentá las opciones sin recomendar ninguna**. En cada
opción explicá en una línea y en lenguaje simple qué significa para la persona
(qué necesita tener, si tarda más, si queda algo instalado), no cuál te parece
mejor ni cómo funciona por dentro. No marques ninguna como "recomendada". Seguí
"Cómo comunicarte" de `AGENT.md`. Usá el selector interactivo
(`AskUserQuestion`) cuando el asistente lo tenga.

Las descripciones de cada opción de abajo son la referencia de lo que implica;
al preguntar, resumilas en palabras simples (p. ej. "En Docker — necesitás
Docker abierto; no hace falta instalar nada más" / "En tu máquina — arranca más
rápido; necesitás tener Node 20 instalado").

## Procedimiento

### 0. Medio de ejecución de la app

Antes de recorrer las dependencias, preguntá cómo se quiere levantar la
**aplicación misma**:

- **En contenedor (Docker).** Necesita Docker instalado y el daemon corriendo;
  descarga/arma una imagen. Aísla el runtime de tu SO. Si no hay Dockerfile, se
  crea uno en `local/Dockerfile.dev`.
- **En el host, con el runtime nativo.** Usa el Node/Python/JVM/Go de tu máquina
  (o el que instale tu gestor de versiones). Arranque más rápido y hot-reload
  directo; depende de tener la versión de runtime correcta instalada. Se
  materializa con scripts en `local/` y, si el proyecto tiene varios procesos, un
  `local/Procfile`. La versión de runtime que pide el proyecto (de
  `envinit-detect`) queda anotada como prerrequisito; el agente no instala
  runtimes.

El comando concreto (`npm run dev`, `./gradlew bootRun`, …) sale de
`envinit-detect`; confirmalo. Esta decisión define si más adelante hace falta
un `Dockerfile` de desarrollo o un archivo de versiones de runtime.

Si `envinit-detect` **no encontró ninguna dependencia de entorno**, esta es
la única decisión: elegido el medio, pasás directo al resumen final del plan y de
ahí a materializar (`envinit-compose` si la app va en Docker, `envinit-native` si
va nativa) y `envinit-document`.

### 1. Origen de cada dependencia

Recorré el inventario **de a una dependencia por vez**: presentás sus hallazgos,
preguntás su origen y cerrás su configuración antes de pasar a la siguiente. No
juntes en una misma pregunta decisiones de dependencias distintas. El detalle
técnico de lo que se crea en Docker (imagen/tag/memoria/puerto) **no** se
pregunta: lo decide el agente (ver paso 3 y "Lo que el agente decide solo" en
`AGENT.md`).

Para cada **dependencia de infraestructura** (base de datos, caché, mensajería,
storage, búsqueda), presentá dos opciones (al preguntar: "Crear una nueva en
Docker — lista para usar, vacía" / "Usar una que ya tenés — me pasás los datos
para conectarme"):

1. **Crear en Docker.** Se agrega un servicio nuevo a `local/docker-compose.yml`
   (o a `local/docker-compose.override.yml` / `local/docker-compose.dev.yml` si el
   repo ya tiene un compose propio fuera de `local/` — nunca al compose existente).
   El agente elige imagen, versión, memoria y puerto (ver `envinit-recipes`); vos
   solo preguntás los nombres de espacio lógico y credenciales de dev (nombre de
   DB/schema/bucket/vhost, usuario y contraseña, y nombre de
   contenedor/volumen/red si hay preferencia). Deriva a `envinit-compose` +
   `envinit-recipes`.
2. **Usar un servicio existente.** La app se conecta a un servicio que ya corre
   fuera del proyecto: instalado en el sistema operativo (`localhost:<puerto>`),
   en la nube o infraestructura de otro equipo. Pedí host, puerto, credenciales y
   el espacio lógico (base de datos / schema / vhost / bucket) **ya provisto por
   la persona** — el agente no crea nada en ese servicio ni toca su
   configuración. Guardá los valores en `local/.env.local` y verificá
   conectividad de red. No hace falta agregar ningún servicio al compose.

Para cada **servicio de terceros o de otro equipo** (pagos, OIDC, APIs,
microservicios ajenos) → deriva a `envinit-mocks`: conexión real al servicio
externo vs. mock (que corre como contenedor Docker bajo `--profile mock`).

## Manejo de conflictos (no destructivo)

- **Puerto de un servicio creado en Docker ocupado** → el agente usa el puerto
  estándar; si al levantar el entorno `envinit-verify` detecta la colisión,
  ahí propone el siguiente libre y ajusta la variable. Nunca mates el proceso
  que lo usa sin permiso explícito.
- **Nombre de contenedor/volumen/red en uso** → usá un nombre nuevo con prefijo
  del proyecto.
- **Ya existe una DB/schema con ese nombre en el servicio en Docker** → proponé
  un nombre alternativo; no la sobrescribas.
- **Versión de runtime distinta** entre lo que pide el proyecto y lo instalado
  (app nativa) → avisá; proponé el gestor de versiones (nvm/pyenv/asdf/mise) o
  correr la app en Docker. El agente no instala ni cambia el runtime global.

## Salida

Una tabla de decisiones, de uso **interno** (para el handoff a las demás
skills; se muestra solo si la persona pide el detalle):

| Dependencia | Origen (Docker / servicio existente / mock) | Espacio lógico | Variables de entorno a setear | Archivo destino (dentro de `local/`) |
|---|---|---|---|---|

Los nombres de espacios lógicos de lo que se crea en Docker son **propuestas
editables** que confirmás con la persona antes del handoff, en una sola pregunta
simple. Para un servicio existente, el espacio lógico lo aporta la persona. El
detalle técnico de lo que se crea en Docker **no** va en esta confirmación
por-dependencia: lo resuelve el agente y se muestra solo si la persona lo pide.

### Resumen final antes de materializar

Con todas las dependencias resueltas (o directamente después del medio de
ejecución, si no había ninguna), presentá un **resumen corto del plan** en
lenguaje simple, por ejemplo:

> Esto es lo que voy a armar:
> - La app corre en tu máquina con Node 20.
> - Base de datos: se crea una nueva en Docker.
> - Pagos: se simula, así no necesitás credenciales reales.
>
> Todo queda en la carpeta `local/`, que no se sube al repo.
> ¿Querés cambiar algo, o ver el detalle técnico antes de seguir?

Si la persona pide el detalle técnico, mostrá la tabla de arriba, el detalle
que decidió el agente para cada servicio creado en Docker (imagen/variante,
tag, memoria y puerto) con una línea de por qué, y la lista de archivos que se
van a crear en `local/` (compose y/o scripts, `Procfile`, `.nvmrc` o
equivalente, `.env.example`, `.env.local`, `Dockerfile.dev`, mocks,
`ENVIRONMENT.md`). Solo con el plan confirmado, hacé el handoff a
`envinit-compose` y/o `envinit-native`, y a `envinit-document`.
