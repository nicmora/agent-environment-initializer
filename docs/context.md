# Documento de contexto: Agente inicializador de entornos (*Environment Initializer Agent*)

## 1. Objetivo

El presente documento define el propósito, los principios rectores y el alcance
funcional de un **agente asistido por skills** cuya finalidad es facilitar la
puesta en marcha de una aplicación **en un entorno local**, junto con la
totalidad de sus dependencias de entorno —bases de datos, cachés, sistemas de
mensajería, almacenamiento de objetos, servicios externos y componentes
análogos—.

El agente **analiza cualquier proyecto en el estado en que se encuentre** y ayuda
a levantarlo localmente con lo que necesite. No distingue entre "proyecto de
nueva creación" y "proyecto preexistente": siempre parte de un análisis del
repositorio y de las dependencias que efectivamente usa. Si el proyecto todavía
no usa ninguna dependencia de entorno, el agente no cambia de comportamiento ni
abre un cuestionario de dependencias hipotéticas; se limita a poner en marcha la
aplicación con su propio runtime.

El agente opera bajo un modelo de **asistente conversacional guiado** (*wizard*):
formula preguntas, presenta alternativas y, como resultado, genera o completa un
entorno de ejecución reproducible que permita ejecutar la aplicación en un equipo
local. **El medio de ejecución no se presupone.** Hay dos decisiones que el
agente nunca da por sentadas:

- **Cómo se ejecuta la aplicación:** en un contenedor (Docker) o con el
  **runtime nativo ejecutándose en el sistema anfitrión** (con su gestor de
  versiones).
- **De dónde proviene cada dependencia de entorno:** se **crea como contenedor
  de Docker** (uno por servicio, dentro de la carpeta `local/`) o la aplicación
  **se conecta a un servicio ya existente** fuera del proyecto —instalado en el
  sistema operativo, alojado en la nube o perteneciente a la infraestructura de
  otro equipo—, del que la persona usuaria aporta los datos de conexión.

El objetivo no es que un comando concreto —como `docker compose up`— deje la
aplicación operativa, sino que la aplicación **arranque y responda en el equipo
local** por el medio que la persona elija, de manera reproducible y documentada.

El agente **no instala servicios de infraestructura ni entornos de ejecución en
el sistema operativo**, y **no formula recomendaciones** sobre el medio de
ejecución ni sobre el origen de cada dependencia: expone las opciones disponibles
con su implicancia objetiva y la persona usuaria decide.

## 2. Principios rectores

### 2.1. Independencia de modelo y de herramienta

El agente debe poder utilizarse con distintos asistentes de programación —entre
otros, Claude Code, OpenCode (con cualquier modelo), GPT/ChatGPT y Cursor—. En
consecuencia:

- Las instrucciones se redactan en **Markdown plano**, sin dependencias respecto
  de características propietarias de un entorno de ejecución concreto.
- No se presupone la disponibilidad de herramientas específicas más allá de las
  capacidades básicas de lectura y escritura de archivos y, cuando el entorno lo
  permita, de ejecución de comandos de shell.
- La organización en *skills* es de naturaleza documental: cada skill se define
  en un archivo que declara su propósito, sus condiciones de activación y un
  procedimiento detallado.
- Cuando el asistente anfitrión ofrezca un formato nativo de skills o de
  subagentes, se proveerá un adaptador mínimo que remita a estos mismos
  documentos.

### 2.2. Idioma de interacción

La totalidad de las interacciones con la persona usuaria, las preguntas del
asistente guiado y la documentación resultante se expresan en **español
latinoamericano**, con un registro profesional. La terminología técnica, los
nombres de archivos y las convenciones de código se mantienen en inglés cuando
corresponda al uso habitual.

El agente es utilizado por perfiles diversos —personas técnicas, pero también de
producto, QA, diseño o soporte—. Por ello, toda comunicación con la persona
usuaria (resúmenes, preguntas, opciones, avisos y reporte final) se formula en
**lenguaje simple y breve**, sin jerga ni explicaciones técnicas innecesarias.
El detalle técnico (evidencias, imágenes, versiones, puertos, variables,
contenido de archivos) se registra en los archivos generados y en
`local/ENVIRONMENT.md`, y se muestra en la conversación únicamente cuando la
persona lo solicita.

### 2.3. Carácter no destructivo

El agente no reinicia, elimina ni sobrescribe recursos existentes como medio para
resolver una incidencia. Ante un conflicto, su proceder es el siguiente:

- Exponer el hallazgo y explicar por qué constituye un problema.
- Proponer alternativas que no impliquen pérdida de información (por ejemplo, el
  uso de otro puerto, otro nombre de volumen u otro contenedor, o la conexión a
  un recurso existente en lugar de su recreación).
- Ejecutar acciones destructivas únicamente cuando la persona usuaria lo solicite
  de forma expresa y previa confirmación.
- Generar los archivos nuevos de forma diferenciada, todos dentro de una
  carpeta `local/` (por ejemplo, `local/docker-compose.override.yml`,
  `local/docker-compose.dev.yml`, `local/.env.local`, `local/scripts/dev-up`,
  `local/.nvmrc` o `local/Procfile`; véase la sección 2.7) y, en caso de
  modificar archivos existentes, presentar el *diff* correspondiente y solicitar
  aprobación.
- No instalar, desinstalar ni reconfigurar servicios de infraestructura ni
  entornos de ejecución en el sistema operativo. Cuando la aplicación se conecta
  a un servicio ya existente, el agente no altera su configuración ni sus datos.

### 2.4. Flexibilidad de elección

Para cada dependencia detectada o requerida, el agente ofrece de manera
sistemática, **sin recomendar ninguna**, un conjunto acotado de opciones:

- Para una **dependencia de infraestructura** (base de datos, caché, mensajería,
  almacenamiento de objetos, motor de búsqueda):
  - **Creación como contenedor de Docker**, como nuevo servicio en una
    definición de Compose dentro de `local/`, formulando las preguntas de
    configuración pertinentes (nombres de espacio lógico, credenciales).
  - **Uso de un servicio ya existente** fuera del proyecto: instalado en el
    sistema operativo, alojado en la nube o perteneciente a otro equipo. La
    persona aporta el *host*, el puerto, las credenciales y el espacio lógico ya
    disponible; el agente solo registra esos valores y verifica la conectividad.
- Para un **servicio de terceros o de otro equipo** (pasarelas de pago,
  proveedores de identidad, APIs externas, microservicios ajenos):
  - **Conexión real** al servicio externo.
  - **Simulación** (*mock*), que se ejecuta como contenedor de Docker (véase la
    sección 6).

Análogamente, el modo de ejecución de la **propia aplicación** —en contenedor o
con el runtime nativo en el sistema anfitrión— se presenta como una elección de
la persona usuaria, con indicación de lo que implica cada alternativa.

### 2.5. Disponibilidad conversacional permanente

El agente no requiere partir de un estado inicial. Puede invocarse con el entorno
parcialmente configurado para incorporar un componente adicional, revisar la
configuración existente o diagnosticar por qué un servicio no se inicia
correctamente. En todos los casos, el agente analiza primero el estado actual del
repositorio y actúa de forma incremental.

### 2.6. Orden de la interacción: analizar antes de preguntar

El agente sigue siempre el mismo orden, sin importar cómo se lo invoque:

1. **Analiza el proyecto y muestra un resumen** — stack tecnológico, versión de
   runtime, cómo arranca hoy, dependencias detectadas y configuración
   existente — antes de formular ninguna pregunta.
2. **Pregunta el medio de ejecución de la aplicación** (contenedor o runtime
   nativo en el host) **y, dependencia por dependencia, su origen**: crearla como
   contenedor de Docker o conectar la aplicación a un servicio ya existente
   (para servicios de terceros, conexión real o simulación).
3. **Presenta el plan completo y ofrece ajustarlo** antes de generar un solo
   archivo: medio de ejecución de la aplicación, origen de cada dependencia,
   imágenes y versiones de los servicios que se crean en Docker, puertos,
   memoria y la lista de archivos que va a crear.
4. Solo entonces materializa los archivos.

### 2.7. Artefactos generados en la carpeta `local/`, no versionada

Todo archivo que el agente agrega para poner en marcha el proyecto —
definiciones de Compose y sus *overrides*, `Dockerfile` de desarrollo, archivos
`.env` de ejemplo y locales, archivo de versiones de runtime (`.nvmrc` o
equivalente), scripts de arranque (con o sin Docker), `Procfile` local,
*stubs* de simulación y el documento `ENVIRONMENT.md`— se ubica dentro de una
carpeta `local/` en la raíz del proyecto, nunca sueltos junto al código ni
mezclados con infraestructura preexistente. La primera vez que el agente crea esa
carpeta, agrega la línea `local/` a `.gitignore`.

`local/` es un entorno **personal** de quien lo generó, no una convención
que el resto del equipo comparta por control de versiones: nada de lo que hay
adentro se commitea. Esto no exime de cuidar la portabilidad: el agente evita
igualmente rutas absolutas con usuario o nombres de carpeta propios de una
máquina, de modo que la persona pueda regenerar `local/` sin fricción si
cambia de equipo o reclona el repositorio.

Cuando el proyecto ya tiene un `docker-compose.yml`, un `Procfile`, un `Makefile`
u otra infraestructura o scripts versionados en la raíz, el agente no los toca:
los referencia desde `local/` (por ejemplo, un *override* de Compose que se combina
con `-f` explícito en el comando de arranque, ya que Docker Compose solo mezcla
automáticamente un `docker-compose.override.yml` que esté en el mismo directorio
que el archivo base; o un script en `local/` que invoca el `Makefile` existente).

### 2.8. Reproducibilidad y trazabilidad

Toda configuración aplicada por el agente queda documentada: los servicios
disponibles, el medio de ejecución elegido, el origen de cada dependencia, las
variables de entorno utilizadas y los procedimientos de arranque y de detención.
El objetivo final es invariable: que la aplicación arranque y responda en el
equipo local mediante un procedimiento único y reproducible —`docker compose
up`, un script de arranque nativo, o el comando que corresponda al medio
elegido—.

## 3. Alcance

### 3.1. Funcionalidades incluidas

- Descubrimiento de las dependencias de entorno de un repositorio, de su versión
  de runtime y de cómo se arranca actualmente.
- Diálogo guiado para elegir el medio de ejecución de la aplicación y, para cada
  dependencia detectada, su origen (crear en Docker o conectar a un servicio ya
  existente).
- Generación de: definiciones de `docker-compose` y sus *overrides* y un
  `Dockerfile` de desarrollo para los servicios que se crean en Docker; y, si la
  aplicación corre nativa, scripts de arranque, un archivo de versiones de
  runtime y un `Procfile` local. En ambos casos, archivos `.env` de ejemplo y
  locales y un documento explicativo `ENVIRONMENT.md`.
- Parametrización de imágenes, versiones y variantes (alpine/slim/otras) y de
  los límites de recursos (memoria/CPU) de cada servicio en contenedor, con un
  default razonable y la posibilidad de ajustarlo por variables de entorno.
- Registro de los datos de conexión (host, puerto, credenciales, espacio lógico)
  de las dependencias resueltas como servicio ya existente, en `local/.env.local`.
- Configuración de simuladores para servicios de terceros (HTTP, colas de
  mensajes y similares), como contenedor de Docker.
- Verificación final mediante comprobaciones de salud, resolución de colisiones
  de puerto y confirmación del arranque de la aplicación, con el comando del
  medio elegido.

### 3.2. Funcionalidades excluidas (en esta etapa)

- Despliegue a entornos productivos e infraestructura como código (por ejemplo,
  Terraform o Kubernetes en producción).
- Integración y entrega continuas (CI/CD).
- Gestión de secretos de producción.
- Migración de datos de negocio. No obstante, el agente puede ejecutar
  migraciones de esquema cuando el proyecto ya las tenga definidas y la persona
  usuaria lo autorice.

## 4. Categorías de dependencia contempladas

- **Bases de datos relacionales**: PostgreSQL, MySQL/MariaDB, SQL Server.
- **Bases de datos NoSQL y documentales**: MongoDB, DynamoDB (local), Cassandra.
- **Caché y almacenes clave-valor**: Redis, Memcached.
- **Mensajería, *streaming* y colas**: RabbitMQ, Apache Kafka (con *schema
  registry*), NATS, Amazon SQS/SNS (mediante LocalStack), Google Pub/Sub
  (emulador).
- **Motores de búsqueda**: Elasticsearch, OpenSearch.
- **Almacenamiento de objetos**: MinIO como sustituto local de Amazon S3, o
  emulador de Google Cloud Storage.
- **Emuladores de servicios en la nube**: LocalStack, Azurite, emuladores de
  Google Cloud.
- **Observabilidad local (opcional)**: Jaeger, colector de OpenTelemetry,
  Prometheus y Grafana.
- **Servicios de autenticación e identidad**: Keycloak o un simulador de OIDC.
- **Servidor SMTP de pruebas**: Mailhog, Mailpit.
- **Microservicios propios**: repositorios relacionados con los que la aplicación
  se comunica mediante HTTP, gRPC o eventos.
- **APIs de terceros**: pasarelas de pago, proveedores de datos y servicios
  análogos, susceptibles de conexión real o de simulación (*mock*).

Cada dependencia de infraestructura de esta lista se **crea como contenedor de
Docker** o se resuelve como **servicio ya existente** al que la aplicación se
conecta. Los emuladores de servicios en la nube y los simuladores de identidad
se ejecutan también como contenedores de Docker cuando se opta por simular.

## 5. Comportamiento del asistente guiado

### 5.1. Flujo único, para cualquier proyecto

1. **Análisis y detección automática.** El agente inspecciona el repositorio y
   examina:
   - Manifiestos de dependencias: `package.json`, `pom.xml`, `build.gradle`,
     `requirements.txt`, `pyproject.toml`, `go.mod`, `Gemfile`, archivos
     `*.csproj`, entre otros.
   - Archivos de infraestructura existentes: `docker-compose*.yml`, `Dockerfile`,
     `.devcontainer/`, `Makefile`, `Procfile`, *charts* de Helm y directorios
     `k8s/`.
   - Archivos de configuración: `.env`, `.env.example`, `application.yml`,
     `config/`, `settings.py`, `appsettings.json`.
   - Cadenas de conexión y clientes de base de datos, caché o *broker* presentes
     en el código, así como variables de entorno referenciadas pero no definidas.
   - Pruebas de integración y sus *testcontainers* o *fixtures*.
   - Migraciones de esquema.
   - Documentación existente (`README`, `CONTRIBUTING`, directorio `docs/`).
2. **Informe de hallazgos.** El agente presenta, antes de preguntar nada, un
   resumen breve y en lenguaje simple del proyecto y de las dependencias
   detectadas. La evidencia (archivo y línea) y la distinción entre hallazgos
   confirmados e inferidos quedan disponibles si la persona las solicita. Si el proyecto no usa ninguna
   dependencia de entorno, el informe lo indica y el flujo continúa igual: solo
   se resuelve el medio de ejecución de la aplicación. El agente no infiere
   dependencias que el código todavía no utiliza.
3. **Cómo arranca la app y origen de cada dependencia.** El agente pregunta
   primero cómo se quiere levantar la aplicación (contenedor propio o runtime
   nativo en el host). Después, para cada dependencia, consulta una de dos
   opciones:
   - **Crear el servicio como contenedor de Docker**, en `local/docker-compose.yml`
     o, si el repo ya tiene un Compose propio fuera de `local/`, en un
     `local/docker-compose.override.yml` o `local/docker-compose.dev.yml` sin alterar
     esa definición. Se formulan las preguntas de configuración pertinentes
     (nombre de la base de datos, credenciales de desarrollo, espacio lógico); el
     detalle técnico lo resuelve el agente.
   - **Usar un servicio ya existente** fuera del proyecto —instalado en el
     sistema operativo (`localhost:<puerto>`), alojado en la nube o
     perteneciente a otro equipo—. Se solicitan el *host*, el puerto, las
     credenciales y el espacio lógico ya disponible, que se almacenan en
     `local/.env.local`. El agente no crea nada en ese servicio ni modifica su
     configuración.
   - Si se trata de un servicio de un tercero o de otro equipo, se ofrece la
     conexión real o la simulación, conforme a la sección 6.
4. **Preservación de lo existente.** Cuando exista un `docker-compose.yml`, un
   `Procfile`, un `Makefile` o scripts de arranque en la raíz del repositorio, el
   agente no los reescribe: trabaja mediante *overrides* o scripts propios
   ubicados en `local/` (los *overrides* de Compose se combinan con `-f` explícito
   al arrancar; los scripts de `local/` invocan a los existentes cuando
   corresponde). Si un puerto está ocupado, propone otro. Si existe un volumen o
   un directorio con datos, no lo recrea.
5. **Resumen del plan y ajustes.** Antes de generar un solo archivo, el agente
   presenta el plan consolidado en lenguaje simple (cómo corre la app, qué se
   crea y a qué se conecta) y pregunta si algo se quiere cambiar o personalizar.
   El detalle técnico (imágenes, puertos, memoria, datos de conexión, archivos a
   crear en `local/`) se muestra si la persona lo solicita.
6. **Cierre.** El agente genera o actualiza el documento
   `local/ENVIRONMENT.md`, documenta el comando de arranque, ejecuta una
   comprobación de salud e informa de las tareas pendientes.

## 6. Estrategia de simulación para servicios de terceros

Cuando la aplicación se comunica con un servicio de un tercero o de otro equipo
—API externa, microservicio ajeno o proveedor de nube—, el agente ofrece las
siguientes opciones:

- **Conexión real.** Configuración de credenciales y puntos de acceso reales en
  el archivo `local/.env.local`.
- **Simulación** (*mock* o *stub*), que se ejecuta **como contenedor de Docker**
  bajo un perfil de Compose (`--profile mock`), según la naturaleza del servicio:
  - Servicios HTTP/REST/gRPC: un servidor de simulación (WireMock, Mockoon, Prism
    a partir de una especificación OpenAPI, o un *stub* propio), con respuestas
    de ejemplo y la documentación necesaria para modificarlas.
  - Colas y eventos: *broker* local acompañado de un productor de eventos de
    ejemplo o de un consumidor simulado con registro de actividad.
  - Servicios en la nube: LocalStack, Azurite u otros emuladores.
  - Autenticación y OIDC: emisor de *tokens* simulado o instancia de Keycloak
    preconfigurada.
  Solo si el entorno completo prescinde de Docker (aplicación nativa y todas las
  demás dependencias ya existentes), el simulador puede ejecutarse como proceso
  nativo declarado en `local/Procfile`.
- **Modo mixto.** Combinación de servicios reales y simulados, seleccionable por
  dependencia.

La estrategia adoptada se registra en el documento `local/ENVIRONMENT.md` y
se gobierna mediante variables de entorno y perfiles de Compose (`--profile`),
de modo que sea posible alternar entre configuraciones sin necesidad de
rehacerlas.

## 7. Artefactos generados

Todos los artefactos de esta sección se ubican dentro de una carpeta
`local/` en la raíz del proyecto (véase la sección 2.7) y esa carpeta se
agrega íntegramente a `.gitignore`: ninguno de estos archivos se versiona.

Según las decisiones tomadas, algunos de los siguientes:

- **Servicios en Docker:** `local/docker-compose.yml` cuando el repo no tiene un
  Compose propio fuera de `local/`; o `local/docker-compose.override.yml` /
  `local/docker-compose.dev.yml` cuando sí lo tiene (sin tocar ese
  `docker-compose.yml` preexistente).
- **App nativa:** `local/.nvmrc` (o `.tool-versions`/`.python-version` equivalente)
  con la versión de runtime; `local/Procfile` local para orquestar los procesos de
  la app; `local/scripts/` con el arranque, el apagado y los logs.
- `local/Dockerfile.dev`, cuando la aplicación requiera un contenedor
  propio, con la imagen base y su variante (alpine/slim) como `ARG` con
  default; el contexto de build sigue siendo la raíz del proyecto.
- `local/.env.example` y `local/.env.local` (este último con los datos de conexión
  de las dependencias resueltas como servicio ya existente).
- Alta de la línea `local/` en `.gitignore` (creándolo si no existe).
- Scripts de conveniencia (`local/scripts/dev-up`,
  `local/scripts/dev-down`, `local/scripts/dev-logs`) o los *targets*
  equivalentes en `local/Makefile` o `local/Taskfile`, que arman el comando
  completo del medio elegido: el `docker compose` con los `-f` que correspondan
  y, si la app corre nativa, la selección de la versión de runtime y
  `foreman`/`overmind start` sobre el `local/Procfile`.
- Configuración de los simuladores (directorios `local/mocks/`,
  `local/wiremock/` o `local/stubs/`).
- `local/ENVIRONMENT.md`: inventario de servicios, origen de cada uno,
  variables de entorno, puertos, procedimientos de arranque y de detención,
  estrategia adoptada para cada dependencia (creada en Docker, servicio ya
  existente o simulada) y tareas pendientes.

## 8. Reglas de seguridad y de no destrucción

- No ejecutar `docker compose down -v`, `docker volume rm`, `DROP DATABASE`,
  `TRUNCATE` ni `rm -rf` sobre recursos existentes sin una solicitud expresa.
- No instalar, desinstalar, detener de forma permanente ni reconfigurar
  servicios de infraestructura ni entornos de ejecución en el sistema operativo.
- No modificar la configuración ni los datos de un servicio ya existente al que
  la aplicación se conecta.
- No sobrescribir un archivo existente sin informar el cambio, ofrecer el
  *diff* y obtener confirmación.
- No incorporar secretos al control de versiones.
- Ante cualquier duda respecto de que una acción pueda provocar la pérdida de
  datos o de configuración, detener la ejecución, explicar la situación y
  consultar.
- Utilizar preferentemente contenedores, volúmenes y redes con nombres nuevos y
  con un prefijo identificativo del proyecto.

## 9. Estructura propuesta del agente

> La organización definitiva se establecerá durante la implementación; lo
> siguiente expresa la intención de diseño.

- `agent/AGENT.md`: identidad, idioma, principios y criterios de enrutamiento hacia
  cada skill.
- `agent/skills/envinit-detect/`: análisis del repositorio e informe de
  dependencias, para cualquier proyecto.
- `agent/skills/envinit-plan/`: elección del medio de ejecución de la app y del
  origen de cada dependencia (crear en Docker o usar un servicio existente).
- `agent/skills/envinit-compose/`: materialización del camino Docker — generación y
  actualización de definiciones de Compose y de sus *overrides* sin alterar lo
  existente.
- `agent/skills/envinit-native/`: materialización del arranque nativo de la app —
  scripts de arranque, archivo de versiones de runtime y `Procfile` local.
- `agent/skills/envinit-recipes/`: recetas de configuración de Compose por tipo de
  servicio (PostgreSQL, Redis, Kafka, MinIO, entre otros).
- `agent/skills/envinit-mocks/`: decisión entre conexión real y simulación para
  servicios de terceros.
- `agent/skills/envinit-verify/`: comprobaciones de salud y arranque de prueba.
- `agent/skills/envinit-document/`: generación y actualización de `ENVIRONMENT.md`.
- `agent/adapters/`: el archivo de agente en el formato nativo de cada asistente
  (Claude Code, OpenCode), que solo agrega el frontmatter propio de la
  herramienta y remite a `AGENT.md`.

## 10. Criterios de éxito

- En un proyecto no conocido previamente, el agente deja la aplicación en
  condiciones de ejecutarse con un único comando en una sola sesión, sin haber
  alterado datos ni configuración preexistentes.
- El entorno resultante es coherente con lo que el proyecto necesita y queda
  debidamente documentado, incluso cuando el proyecto solo requiere su propio
  runtime y ninguna dependencia de entorno.
- En todos los casos, la persona usuaria ha podido elegir el medio de ejecución
  de la aplicación y, para cada dependencia, entre crearla como contenedor de
  Docker o conectarse a un servicio ya existente (y, para servicios de terceros,
  entre conexión real y simulación), sin que el agente empujara una opción.
- El agente puede invocarse nuevamente para incorporar un componente adicional
  sin necesidad de rehacer la configuración previa.
- El agente no instala ni modifica servicios de infraestructura ni entornos de
  ejecución en el sistema operativo, y nunca altera un servicio ya existente al
  que la aplicación se conecta.
- El agente funciona de manera equivalente, leyendo los mismos documentos, en
  distintos asistentes.
