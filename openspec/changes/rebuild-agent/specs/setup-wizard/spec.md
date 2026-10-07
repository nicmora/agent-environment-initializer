## Purpose

Define las preguntas con las que la persona decide cómo se levanta la aplicación
y cada dependencia, y el resumen final que confirma antes de crear archivos.

## ADDED Requirements

### Requirement: Forma de arranque
El agente SHALL preguntar cómo levantar la aplicación: con Docker o de forma
nativa (runtime o script local). En un monorepo, MUST preguntarlo por cada
proyecto.

#### Scenario: Monorepo con dos proyectos
- **WHEN** el scan encontró un frontend y un backend
- **THEN** el agente pregunta la forma de arranque del frontend y del backend
  en preguntas separadas

### Requirement: Una dependencia por pregunta
El agente SHALL preguntar por cada dependencia por separado y MUST NOT incluir
varias dependencias en la misma pregunta. Una dependencia compartida por varios
proyectos MUST preguntarse una sola vez. Las opciones dependen del tipo:
- Infraestructura (base de datos, cache, cola, almacenamiento): levantarla con
  Docker o conectarse a un servicio existente.
- API o servicio externo: mockearlo o conectarse al servicio real.
- Proyecto del mismo monorepo: levantarlo también o mockearlo.

#### Scenario: Base de datos
- **WHEN** el agente pregunta por una base de datos
- **THEN** las opciones son levantarla con Docker o conectarse a una existente

#### Scenario: API externa
- **WHEN** el agente pregunta por una API de un tercero
- **THEN** las opciones son mockearla o conectarse al servicio real

#### Scenario: Proyecto del mismo monorepo
- **WHEN** el frontend depende del backend del mismo repositorio
- **THEN** las opciones para el backend son levantarlo también o mockearlo

#### Scenario: Dependencia compartida
- **WHEN** dos proyectos del monorepo usan la misma base de datos
- **THEN** el agente pregunta por esa base una sola vez

### Requirement: Datos de conexión
Cuando la persona elige un servicio existente o real, el agente SHALL obtener
sus datos de conexión. Si el proyecto ya los tiene, MUST sugerirlos y pedir
confirmación. Si no los tiene, MUST pedirlos a la persona dato por dato.

#### Scenario: Datos presentes en el proyecto
- **WHEN** la persona elige una base existente y el `.env` del proyecto tiene
  host, puerto y usuario
- **THEN** el agente muestra esos datos, con la contraseña oculta, y pregunta
  si son correctos

#### Scenario: Datos ausentes
- **WHEN** la persona elige una API real y el proyecto no tiene su URL ni su
  clave
- **THEN** el agente pide primero la URL y, después de la respuesta, la clave

### Requirement: Migraciones en bases nuevas
Cuando una base de datos se levanta con Docker y el proyecto tiene migraciones,
el agente SHALL preguntar si se corren. Para bases existentes MUST NOT
preguntarlo.

#### Scenario: Base nueva con migraciones
- **WHEN** la persona elige levantar con Docker una base y el proyecto tiene
  migraciones
- **THEN** el agente pregunta si se corren las migraciones

#### Scenario: Base existente
- **WHEN** la persona elige conectarse a una base existente
- **THEN** el agente no pregunta por migraciones ni por datos de prueba

### Requirement: Datos de prueba en bases nuevas
Cuando una base de datos se levanta con Docker, el agente SHALL preguntar si se
cargan datos de prueba. Si el proyecto tiene scripts que inicializan el esquema
con datos, MUST ofrecer usarlos. Las opciones son usar los scripts del proyecto
(solo si existen), generar datos de prueba realistas o dejar la base vacía.

#### Scenario: Proyecto con scripts de datos
- **WHEN** la base se levanta con Docker y el proyecto tiene un script de datos
  iniciales
- **THEN** las opciones incluyen usar ese script

#### Scenario: Proyecto sin scripts de datos
- **WHEN** la base se levanta con Docker y el proyecto no tiene scripts de datos
- **THEN** las opciones son generar datos de prueba o dejar la base vacía

### Requirement: Resumen final y confirmación
Antes de crear archivos, el agente SHALL mostrar todo lo elegido: forma de
arranque, cada dependencia con su modalidad, contenedores, puertos, imágenes y
archivos a crear. MUST preguntar si la persona está de acuerdo o quiere cambiar
algo. Si quiere cambiar algo, MUST modificar solo ese punto y volver a mostrar
el resumen. MUST NOT crear ningún archivo antes de la confirmación.

#### Scenario: Cambio de un punto
- **WHEN** la persona pide cambiar el puerto de la base de datos en el resumen
- **THEN** el agente cambia solo ese puerto y vuelve a mostrar el resumen
  completo

#### Scenario: Sin confirmación
- **WHEN** la persona todavía no confirmó el resumen final
- **THEN** no existe ningún archivo creado por el agente
