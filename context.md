# Documento de contexto: Agente inicializador de entornos (*Environment Initializer Agent*)

## 1. Objetivo

El presente documento define el propósito, los principios rectores y el alcance
funcional de un **agente asistido por skills** cuya finalidad es facilitar la
puesta en marcha de una aplicación **en un entorno local**, junto con la
totalidad de sus dependencias de entorno —bases de datos, cachés, sistemas de
mensajería, almacenamiento de objetos, servicios externos y componentes
análogos—, tanto en proyectos de nueva creación (*greenfield*) como en proyectos
preexistentes (*brownfield*).

El agente opera bajo un modelo de **asistente conversacional guiado** (*wizard*):
formula preguntas, presenta alternativas y, como resultado, genera o completa un
entorno de ejecución reproducible que permita ejecutar la aplicación en un equipo
local. **El medio de ejecución no se presupone**: según el proyecto y la
preferencia de la persona usuaria, puede basarse en **Docker / Docker Compose**,
en el **runtime nativo ejecutándose en el sistema anfitrión** (con su gestor de
versiones), en **servicios de infraestructura instalados en el sistema operativo**
o mediante un gestor de paquetes, en **binarios o emuladores nativos**, o en una
**combinación** de estos enfoques. El objetivo no es que un comando concreto
—como `docker compose up`— deje la aplicación operativa, sino que la aplicación
**arranque y responda en el equipo local** por el medio que la persona elija, de
manera reproducible y documentada.

El agente **no formula recomendaciones** sobre el medio de ejecución ni sobre la
estrategia de cada dependencia: expone las opciones disponibles con su
implicancia objetiva y la persona usuaria decide.

## 2. Principios rectores

### 2.1. Independencia de modelo y de herramienta

El agente debe poder utilizarse con distintos asistentes de programación —entre
otros, Claude (Claude Code), GPT/ChatGPT y Cursor—. En
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
  carpeta `env/` (por ejemplo, `env/docker-compose.override.yml`,
  `env/docker-compose.dev.yml`, `env/.env.local`, `env/scripts/dev-up`,
  `env/.tool-versions` o `env/Procfile`; véase la sección 2.8) y, en caso de
  modificar archivos existentes, presentar el *diff* correspondiente y solicitar
  aprobación.
- No desinstalar ni reconfigurar un servicio ya presente en el sistema
  operativo. La instalación de software nuevo en la máquina (un servicio
  mediante `brew`/`apt`/`winget`, una versión de runtime) se realiza únicamente
  con autorización expresa y previa indicación del comando exacto.

### 2.4. Flexibilidad de elección

Para cada dependencia detectada o requerida, el agente ofrece de manera
sistemática el siguiente conjunto de opciones, **sin recomendar ninguna**:

- **Reutilización** de un recurso ya disponible en la máquina: un contenedor
  Docker en ejecución, un contenedor de dependencias compartido si la persona
  mantiene uno (véase la sección 2.6), un servicio instalado en el sistema
  operativo o una instancia alojada en la nube.
- **Conexión a un servicio externo** (entornos de *staging*, servicios en la nube
  o infraestructura de otro equipo).
- **Creación del recurso desde cero**, ya sea como nuevo servicio en una
  definición de Compose o mediante instalación nativa en el sistema operativo
  (gestor de paquetes o binario oficial). Cuando ambas variantes son viables, se
  presentan las dos. En cualquier caso se formulan las preguntas de
  configuración pertinentes.
- **Simulación** (*mock*) del servicio cuando se trate de una dependencia externa
  que no resulte conveniente o posible ejecutar de forma real; el simulador
  puede correr como contenedor o como proceso nativo.

Análogamente, el modo de ejecución de la **propia aplicación** —en contenedor o
con el runtime nativo en el sistema anfitrión— se presenta como una elección de
la persona usuaria, con indicación de lo que implica cada alternativa.

### 2.5. Disponibilidad conversacional permanente

El agente no requiere partir de un estado inicial. Puede invocarse con el entorno
parcialmente configurado para incorporar un componente adicional, revisar la
configuración existente o diagnosticar por qué un servicio no se inicia
correctamente. En todos los casos, el agente inspecciona primero el estado actual
y actúa de forma incremental.

### 2.6. Reutilización de un contenedor de dependencias compartido (si existe)

Algunas personas mantienen, por fuera de cualquier proyecto, un **contenedor de
dependencias compartido**: un contenedor de Docker (o un proyecto de Compose
propio) con varios servicios de infraestructura —base de datos, caché,
mensajería, almacenamiento de objetos— y una red de Docker reutilizable, que
emplean en todos sus proyectos para no levantar una instancia por proyecto. El
nombre del contenedor y de la red son arbitrarios.

El agente contempla este recurso **únicamente como un caso de reutilización**, no
como una práctica que promueva:

- **No lo crea.** El agente nunca genera un contenedor de dependencias
  compartido ni un proyecto de Compose centralizado, ni propone hacerlo. Si la
  persona no tiene uno, esta opción sencillamente no aparece.
- **No lo recomienda ni lo prioriza.** No se presenta antes que las demás
  estrategias ni con etiqueta de preferencia.
- **Solo lo ofrece si lo detecta.** Cuando la persona elige crear o reutilizar
  una dependencia **en Docker**, la inspección de la máquina (sección 2.7)
  busca, además de los contenedores individuales, un contenedor que exponga
  varios servicios de infraestructura o una red de Docker creada por la persona
  que agrupe contenedores de infraestructura. Si encuentra un candidato, lo
  ofrece como una opción más de reutilización, junto a la de crear un contenedor
  nuevo con las dependencias elegidas.
- **Aislamiento lógico y aditivo.** Al conectar el proyecto a ese contenedor, el
  agente crea un espacio lógico propio —una base de datos o un *schema* con su
  usuario, una base numerada o un prefijo de claves en Redis, un *virtual host*
  en la mensajería, un *bucket* en el almacenamiento de objetos, un prefijo de
  *topics*— sin alterar los datos ni la configuración de los demás proyectos que
  usan ese contenedor. Nunca ejecuta operaciones destructivas sobre él.
- **Portabilidad.** El agente no fija en los archivos de `env/` la ruta ni el
  nombre del contenedor de otra máquina: se apoya en el nombre de la red externa
  y en los nombres de servicio, y deja las credenciales y puertos en
  `env/.env.local`.

### 2.7. Orden de la interacción: analizar antes de preguntar, revisar la máquina solo si hace falta

El agente sigue siempre el mismo orden, sin importar cómo se lo invoque:

1. **Analiza el proyecto y muestra un resumen** — stack tecnológico, versión de
   runtime, cómo arranca hoy, dependencias detectadas y configuración
   existente — antes de formular ninguna pregunta y sin tocar la máquina.
2. **Pregunta el medio de ejecución de la aplicación** (contenedor, runtime
   nativo en el host, u otra forma que el proyecto ya use) **y, dependencia por
   dependencia, qué estrategia usar** (reutilizar, conectar a externo, crear
   —en Docker o nativo— o simular).
3. **Inspecciona la máquina únicamente si alguna decisión elegida lo requiere**
   (reutilizar un contenedor o servicio local, crear un servicio en Docker,
   instalar algo nativo, o verificar una versión de runtime). Si el proyecto se
   resuelve enteramente con conexiones externas o simulaciones y la aplicación
   corre con un runtime ya instalado, este paso se omite por completo.
4. **Presenta el plan completo y ofrece ajustarlo** antes de generar un solo
   archivo: medio de ejecución, estrategia y medio por dependencia, imágenes o
   versiones, puertos, memoria y la lista de archivos que va a crear.
5. Recién entonces materializa los archivos.

### 2.8. Artefactos generados en una carpeta local, no versionada

Todo archivo que el agente agrega para poner en marcha el proyecto —
definiciones de Compose y sus *overrides*, `Dockerfile` de desarrollo, archivos
`.env` de ejemplo y locales, archivo de versiones de runtime (`.tool-versions` o
equivalente), scripts de arranque (con o sin Docker), `Procfile` local, notas de
instalación de servicios del sistema operativo, *stubs* de simulación y el
documento `ENVIRONMENT.md`— se ubica dentro de una carpeta `env/` en la
raíz del proyecto, nunca sueltos junto al código ni mezclados con
infraestructura preexistente. La primera vez que el agente crea esa carpeta,
agrega la línea `env/` a `.gitignore`.

`env/` es un entorno **personal** de quien lo generó, no una convención
que el resto del equipo comparta por control de versiones: nada de lo que hay
adentro se commitea. Esto no exime de cuidar la portabilidad: el agente evita
igualmente rutas absolutas con usuario o nombres de carpeta propios de una
máquina, de modo que la persona pueda regenerar `env/` sin fricción si
cambia de equipo o reclona el repositorio.

Cuando el proyecto ya tiene un `docker-compose.yml`, un `Procfile`, un `Makefile`
u otra infraestructura o scripts versionados en la raíz, el agente no los toca:
los referencia desde `env/` (por ejemplo, un *override* de Compose que se combina
con `-f` explícito en el comando de arranque, ya que Docker Compose solo mezcla
automáticamente un `docker-compose.override.yml` que esté en el mismo directorio
que el archivo base; o un script en `env/` que invoca el `Makefile` existente).

### 2.9. Reproducibilidad y trazabilidad

Toda configuración aplicada por el agente queda documentada: los servicios
disponibles, el medio de ejecución elegido, el modo de conexión de la
aplicación, las variables de entorno utilizadas y los procedimientos de arranque
y de detención. El objetivo final es invariable: que la aplicación arranque y
responda en el equipo local mediante un procedimiento único y reproducible
—`docker compose up`, un script de arranque nativo, o el comando que corresponda
al medio elegido—.

## 3. Alcance

### 3.1. Funcionalidades incluidas

- Descubrimiento de las dependencias de entorno de un repositorio, de su versión
  de runtime y de cómo se arranca actualmente.
- Cuestionario guiado para los escenarios *greenfield* y *brownfield*, incluida
  la elección del medio de ejecución.
- Generación, según el medio elegido, de: definiciones de `docker-compose` y sus
  *overrides* y un `Dockerfile` de desarrollo; o scripts de arranque nativo, un
  archivo de versiones de runtime y un `Procfile` local con notas de instalación
  de servicios del sistema operativo. En ambos casos, archivos `.env` de ejemplo
  y locales y un documento explicativo `ENVIRONMENT.md`.
- Parametrización de imágenes, versiones y variantes (alpine/slim/otras) y de
  los límites de recursos (memoria/CPU) de cada servicio en contenedor, o de las
  versiones de cada servicio nativo, con un default razonable y la posibilidad
  de ajustarlo por variables de entorno o por el archivo de versiones.
- Determinación de la estrategia de conexión por dependencia: reutilización,
  conexión externa, creación (en Docker o nativa) o simulación.
- Configuración de simuladores para servicios externos (HTTP, colas de mensajes y
  similares), como contenedor o como proceso nativo.
- Verificación final mediante comprobaciones de salud y confirmación del arranque
  de la aplicación, con el comando del medio elegido.

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
  análogos, susceptibles de conexión real o de simulación.

## 5. Comportamiento del asistente guiado

### 5.1. Escenario *greenfield* (proyecto de nueva creación)

El agente formula preguntas orientadas a determinar el entorno necesario. Los
ejes de indagación son, entre otros:

1. **Estructura del repositorio.** Determinar si se trata de un *monorepo* que
   agrupa varios servicios, paquetes o interfaces, o de un repositorio único
   correspondiente a un solo servicio (*multirepo*). En el primer caso, se
   identifican los servicios previstos y su tecnología; en el segundo, se
   identifican los microservicios externos con los que la aplicación se
   comunicará y el mecanismo de comunicación (HTTP, gRPC o eventos).
2. **Tipo de aplicación.** *Backend*, *frontend*, proceso de trabajo o por lotes,
   herramienta de línea de comandos, biblioteca o aplicación integral; lenguaje y
   *framework* principal, gestor de paquetes y versión del entorno de ejecución.
   Medio de ejecución previsto para la propia aplicación: en contenedor o con el
   runtime nativo en el sistema anfitrión.
3. **Persistencia.** Necesidad de una o varias bases de datos, su tipo y su
   justificación; existencia de migraciones o de datos de inicialización y la
   herramienta empleada.
4. **Caché.** Necesidad de una capa de caché y su finalidad (sesiones,
   limitación de tasa, colas de trabajo u otras).
5. **Mensajería y eventos.** Publicación o consumo de eventos, *broker* previsto
   y patrón de integración (publicación-suscripción, colas de trabajo,
   *event sourcing*).
6. **Archivos y almacenamiento.** Carga o entrega de archivos y el mecanismo
   previsto (Amazon S3, MinIO o almacenamiento local).
7. **Integraciones externas.** Conexión con APIs de terceros, autenticación
   externa, servicios de pago o de notificación (correo electrónico, SMS).
8. **Configuración y secretos.** Mecanismo de provisión de variables de entorno
   (archivos `.env`, servidor de configuración u otros).
9. **Puertos y red.** Puertos expuestos por cada servicio, evitando colisiones
   con los servicios ya en ejecución en el equipo.

A partir de las respuestas, y según el medio de ejecución elegido, el agente
propone: una definición base de `env/docker-compose.yml`; o un conjunto de
scripts de arranque nativo con su archivo de versiones de runtime y sus notas de
instalación. En ambos casos lo acompaña de un documento `env/ENVIRONMENT.md`.
Para cada servicio nuevo, formula las preguntas de configuración necesarias
(nombre de la base de datos, credenciales de desarrollo, volumen o directorio de
datos persistente, puerto en el equipo anfitrión, entre otras); el detalle
técnico (versión de la imagen o del paquete, variante, memoria) lo resuelve el
propio agente. Solo si se decide crear algún servicio en Docker o instalar algo
nativo, el agente inspecciona antes la máquina (sección 2.7) para evitar
colisiones de puertos y comprobar lo ya instalado; si en esa inspección aparece
un contenedor de dependencias compartido (sección 2.6), lo ofrece como opción de
reutilización. Antes de generar los archivos, presenta el plan completo y ofrece
ajustarlo.

### 5.2. Escenario *brownfield* (proyecto preexistente)

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
   resumen del stack tecnológico y la relación de dependencias detectadas, con
   indicación de la evidencia (archivo y línea) y distinción entre los
   hallazgos confirmados y los inferidos.
3. **Cómo arranca la app y estrategia por dependencia.** El agente pregunta
   primero cómo se quiere levantar la aplicación (comando, contenedor propio o
   en el host). Después, para cada dependencia, consulta:
   - Si el recurso ya está disponible en la máquina: un contenedor Docker en
     ejecución —incluido un contenedor de dependencias compartido si la persona
     mantiene uno (sección 2.6)—, en cuyo caso se ofrece la conexión mediante la
     detección de su nombre, red, puerto y credenciales cuando sea posible y la
     creación de un espacio lógico propio (*schema*, base numerada, *virtual
     host*, *bucket* u otro) sin afectar a lo que ya contiene; o un servicio
     instalado en el sistema operativo, en cuyo caso se ofrece dirigir la
     aplicación a `localhost`. **Recién en este punto** —si la persona elige
     reutilizar un recurso local, crear uno desde cero (en Docker o nativo) o
     depender de una versión de runtime concreta— el agente inspecciona la
     máquina (sección 2.7); si todas las dependencias se resuelven por conexión
     externa o simulación y la app corre con un runtime ya instalado, esa
     inspección no llega a ejecutarse.
   - Si se desea la conexión a una instancia externa (*staging* o nube), en cuyo
     caso se solicitan el *host*, el puerto y las credenciales, que se almacenan
     en `env/.env.local`.
   - Si se desea la creación del recurso desde cero, se ofrece hacerlo **en
     Docker** —incorporándolo a un archivo `env/docker-compose.override.yml` o
     `env/docker-compose.dev.yml`, sin alterar la definición existente— **o de
     forma nativa** —instalándolo con el gestor de paquetes del sistema
     operativo o un binario oficial, con las notas correspondientes en `env/`—.
     Cuando ambas variantes son viables se presentan las dos. En cualquier caso
     se formulan las preguntas de configuración pertinentes.
   - Si se trata de un servicio de un tercero o de otro equipo, se ofrece la
     conexión real o la simulación, conforme a la sección 6.
4. **Preservación de lo existente.** Cuando exista un `docker-compose.yml`, un
   `Procfile`, un `Makefile` o scripts de arranque en la raíz del repositorio, el
   agente no los reescribe: trabaja mediante *overrides* o scripts propios
   ubicados en `env/` (los *overrides* de Compose se combinan con `-f` explícito
   al arrancar; los scripts de `env/` invocan a los existentes cuando
   corresponde). Si un puerto está ocupado, propone otro. Si existe un volumen o
   un directorio con datos, no lo recrea.
5. **Resumen del plan y ajustes.** Antes de generar un solo archivo, el agente
   presenta el plan consolidado (servicios, estrategia, imágenes, puertos,
   memoria, archivos a crear en `env/`) y pregunta si algo se quiere
   cambiar o personalizar.
6. **Cierre.** El agente genera o actualiza el documento
   `env/ENVIRONMENT.md`, documenta el comando de arranque, ejecuta una
   comprobación de salud e informa de las tareas pendientes.

## 6. Estrategia de simulación para dependencias externas

Cuando la aplicación se conecta a un servicio externo —API de un tercero,
microservicio de otro equipo o proveedor de nube—, el agente ofrece las
siguientes opciones:

- **Conexión real.** Configuración de credenciales y puntos de acceso reales en
  el archivo `env/.env.local`.
- **Simulación** (*mock* o *stub*), según la naturaleza del servicio:
  - Servicios HTTP/REST/gRPC: puesta en marcha de un servidor de simulación
    dentro de la definición de Compose (WireMock, Mockoon, Prism a partir de una
    especificación OpenAPI, o un *stub* propio), con respuestas de ejemplo y la
    documentación necesaria para modificarlas.
  - Colas y eventos: *broker* local acompañado de un productor de eventos de
    ejemplo o de un consumidor simulado con registro de actividad.
  - Servicios en la nube: LocalStack, Azurite u otros emuladores.
  - Autenticación y OIDC: emisor de *tokens* simulado o instancia de Keycloak
    preconfigurada.
- **Modo mixto.** Combinación de servicios reales y simulados, seleccionable por
  dependencia.

La estrategia adoptada se registra en el documento `env/ENVIRONMENT.md` y
se gobierna mediante variables de entorno y perfiles de Compose (`--profile`),
de modo que sea posible alternar entre configuraciones sin necesidad de
rehacerlas.

## 7. Artefactos generados

Todos los artefactos de esta sección se ubican dentro de una carpeta
`env/` en la raíz del proyecto (véase la sección 2.8) y esa carpeta se
agrega íntegramente a `.gitignore`: ninguno de estos archivos se versiona.

Según el medio de ejecución elegido, algunos de los siguientes:

- **Camino Docker:** `env/docker-compose.yml` en el escenario *greenfield*, o
  `env/docker-compose.override.yml` y `env/docker-compose.dev.yml`
  en el escenario *brownfield* (sin tocar un `docker-compose.yml` preexistente
  fuera de `env/`).
- **Camino nativo:** `env/.tool-versions` (o `.nvmrc`/`.python-version`
  equivalente) con la versión de runtime; `env/Procfile` local para orquestar
  los procesos de la app; `env/INSTALL.md` con los comandos exactos para
  instalar cada servicio del sistema operativo (brew/apt/winget) y arrancarlo;
  `env/scripts/` con el arranque, el apagado y los logs.
- `env/Dockerfile.dev`, cuando la aplicación requiera un contenedor
  propio, con la imagen base y su variante (alpine/slim) como `ARG` con
  default; el contexto de build sigue siendo la raíz del proyecto.
- `env/.env.example` y `env/.env.local`.
- Alta de la línea `env/` en `.gitignore` (creándolo si no existe).
- Scripts de conveniencia (`env/scripts/dev-up`,
  `env/scripts/dev-down`, `env/scripts/dev-logs`) o los *targets*
  equivalentes en `env/Makefile` o `env/Taskfile`, que arman el comando
  completo del medio elegido: el `docker compose` con los `-f` que correspondan,
  o el arranque nativo (seleccionar versión de runtime, levantar los servicios
  del SO, `foreman`/`overmind start` sobre el `env/Procfile`).
- Configuración de los simuladores (directorios `env/mocks/`,
  `env/wiremock/` o `env/stubs/`).
- `env/ENVIRONMENT.md`: inventario de servicios, modo de conexión,
  variables de entorno, puertos, procedimientos de arranque y de detención,
  estrategia adoptada para cada dependencia (real, creada, reutilizada o
  simulada) y tareas pendientes.

## 8. Reglas de seguridad y de no destrucción

- No ejecutar `docker compose down -v`, `docker volume rm`, `DROP DATABASE`,
  `TRUNCATE` ni `rm -rf` sobre recursos existentes sin una solicitud expresa.
- No desinstalar, detener de forma permanente ni reconfigurar un servicio que ya
  estaba instalado en el sistema operativo.
- No instalar software en la máquina (servicios, versiones de runtime) sin
  autorización expresa y sin haber mostrado antes el comando exacto.
- No sobrescribir un archivo existente sin presentar el *diff* y obtener
  confirmación.
- No incorporar secretos al control de versiones.
- Ante cualquier duda respecto de que una acción pueda provocar la pérdida de
  datos o de configuración, detener la ejecución, explicar la situación y
  consultar.
- Utilizar preferentemente contenedores, volúmenes y redes con nombres nuevos y
  con un prefijo identificativo del proyecto.

## 9. Estructura propuesta del agente

> La organización definitiva se establecerá durante la implementación; lo
> siguiente expresa la intención de diseño.

- `AGENT.md`: identidad, idioma, principios y criterios de enrutamiento hacia
  cada skill.
- `skills/detect-environment/`: análisis del repositorio e informe de
  dependencias (*brownfield*).
- `skills/greenfield-wizard/`: cuestionario para proyectos de nueva creación.
- `skills/brownfield-wizard/`: cuestionario de determinación de estrategia por
  dependencia.
- `skills/inspect-local-resources/`: detección de contenedores Docker, servicios
  del sistema operativo, gestores de paquetes, versiones de runtime y puertos
  ocupados, susceptibles de reutilización, incluida la detección de un contenedor
  de dependencias compartido cuando la persona mantiene uno.
- `skills/compose-builder/`: materialización del camino Docker — generación y
  actualización de definiciones de Compose y de sus *overrides* sin alterar lo
  existente.
- `skills/native-setup/`: materialización del camino nativo — scripts de
  arranque, archivo de versiones de runtime, `Procfile` local y notas de
  instalación de servicios del sistema operativo.
- `skills/service-recipes/`: recetas de configuración por tipo de servicio
  (PostgreSQL, Redis, Kafka, MinIO, entre otros), con las preguntas y los
  artefactos correspondientes.
- `skills/external-mocks/`: decisión entre conexión real y simulación para
  dependencias externas.
- `skills/verify-environment/`: comprobaciones de salud y arranque de prueba.
- `skills/document-environment/`: generación y actualización de `ENVIRONMENT.md`.
- `adapters/`: correspondencias opcionales con los formatos nativos de cada
  asistente (skills de Claude Code y otros), que remiten a estos mismos
  documentos.

## 10. Criterios de éxito

- En un proyecto *brownfield* no conocido previamente, el agente deja la
  aplicación en condiciones de ejecutarse con un único comando en una sola
  sesión, sin haber alterado datos ni configuración preexistentes.
- En un proyecto *greenfield*, el agente produce un entorno coherente con las
  respuestas del cuestionario y debidamente documentado.
- En todos los casos, la persona usuaria ha podido elegir el medio de ejecución
  de la aplicación y, para cada dependencia, entre reutilizar, conectar, crear
  (en Docker o nativa) o simular, sin que el agente empujara una opción.
- El agente puede invocarse nuevamente para incorporar un componente adicional
  sin necesidad de rehacer la configuración previa.
- Cuando la persona mantiene un contenedor de dependencias compartido, el agente
  lo detecta y ofrece conectar el proyecto mediante un espacio lógico aislado,
  sin duplicar instancias ni afectar lo que ese contenedor ya contiene; nunca
  propone crear uno.
- El agente funciona de manera equivalente, leyendo los mismos documentos, en
  distintos asistentes.
