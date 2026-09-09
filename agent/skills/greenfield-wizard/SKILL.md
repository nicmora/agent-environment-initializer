---
name: greenfield-wizard
description: Cuestionario guiado para proyectos nuevos (greenfield) sin dependencias de entorno todavía definidas. Determina forma del repo (monorepo/multirepo), tipo de aplicación, persistencia, caché, mensajería, storage, integraciones externas, configuración y puertos, y deja lista la decisión de estrategia por dependencia. Usar cuando el repo está vacío o casi vacío, o el usuario dice "proyecto nuevo" / "arrancamos de cero".
---

# Skill: greenfield-wizard

## Objetivo

Definir, mediante preguntas, qué entorno necesita un proyecto nuevo, el medio de
ejecución de la app, y dejar planteada la estrategia (reutilizar / externo /
crear en Docker / instalar nativo / simular) por cada dependencia.

## Procedimiento

Haz las preguntas en bloques cortos, una idea por vez. No abrumes: si una
respuesta cierra un tema, salta el resto de ese bloque. **Presentá las opciones
sin recomendar ninguna**; en cada una explicá qué implica de forma objetiva.

### Bloque 1 — Estructura del repositorio
- ¿Monorepo (varios servicios/paquetes/frontend) o repo único de un servicio?
- Si es monorepo: ¿qué servicios habrá y en qué lenguaje/framework cada uno?
- Si es repo único: ¿con qué otros microservicios (otros repos) se comunica y
  cómo (HTTP, gRPC, eventos)?

### Bloque 2 — Aplicación
- Tipo: backend / frontend / worker o batch / CLI / librería / full-stack.
- Lenguaje, framework, gestor de paquetes, versión de runtime.
- **Medio de ejecución de la app:** ¿en contenedor propio (Docker) o en el host
  con el runtime nativo? Explicá qué implica cada una (Docker aísla pero necesita
  el daemon y descarga imágenes; nativo es más liviano pero depende de la
  versión de runtime instalada y usa tu SO). Si es nativo, ¿usás un gestor de
  versiones (nvm/pyenv/asdf/mise)?

### Bloque 3 — Persistencia
- ¿Necesita base de datos? ¿Cuál (Postgres, MySQL, MongoDB, …) y por qué?
- ¿Una o varias? ¿Multi-tenant?
- ¿Migraciones y seed? ¿Con qué herramienta?

### Bloque 4 — Caché
- ¿Redis / Memcached? ¿Para sesiones, rate limiting, colas, cache de datos?

### Bloque 5 — Mensajería y eventos
- ¿Publica o consume eventos? ¿Broker (RabbitMQ, Kafka, NATS, SQS/SNS, Pub/Sub)?
- ¿Patrón: pub/sub, colas de trabajo, event sourcing?

### Bloque 6 — Archivos / storage
- ¿Sube o sirve archivos? ¿S3/MinIO, GCS, disco local?

### Bloque 7 — Integraciones externas
- ¿APIs de terceros? ¿Auth externo (OIDC/SSO)? ¿Pagos? ¿Email/SMS?
- Para cada una: ¿en desarrollo prefieres conexión real o mock? (deriva a
  `external-mocks`).

### Bloque 8 — Configuración y secretos
- ¿Cómo se cargan las variables? (`.env`, config server, secretos del SO).

### Bloque 9 — Red
- No preguntes puertos: si alguna dependencia va a crearse en Docker o
  instalarse nativa (bloque 3-7), ejecuta `inspect-local-resources` para saber
  qué está ocupado y que el agente elija el puerto de cada servicio sin
  preguntarlo (ver `service-recipes`). Si todo se resuelve con conexión externa
  o mock, no hace falta ni este paso.

### Bloque 10 — Medio de cada dependencia de infra
- Para cada servicio de infra que haya que crear: ¿en **Docker** (un contenedor
  por servicio) o **instalado nativo** en el SO (brew/apt/winget)? Presentá las
  dos con lo que implican; la persona elige. Puede ser distinto por servicio.

## Salida

1. Un **resumen del entorno objetivo**: medio de ejecución de la app, lista de
   servicios (propios + infra) con su medio (Docker / nativo), y el detalle
   técnico que decidió el agente (imagen/variante/versión/memoria/puerto, o
   versión/forma de instalación si es nativo — ver criterio en `service-recipes`
   y "Lo que el agente decide solo" en `AGENT.md`). Esto no se pregunta
   dependencia por dependencia: se resuelve y se muestra recién en el resumen
   final del punto 3.
2. Para cada dependencia de infra que vaya en Docker: si
   `inspect-local-resources` detectó un contenedor de dependencias compartido de
   la persona (un contenedor con varios servicios, o una red de Docker propia
   que los agrupe), ofrecelo como opción de reutilización —con espacio lógico
   aislado y de forma aditiva— frente a crear un contenedor nuevo. **No ofrezcas
   crear una pila compartida ni la priorices**; si no se detectó ninguno, no lo
   menciones.
3. **Resumen final y ajustes.** Antes del handoff, presenta el plan completo
   (medio de ejecución, servicios, estrategia, imágenes o versiones, puertos,
   memoria, archivos a crear dentro de `env/`) y pregunta si algo se quiere
   cambiar o personalizar.
4. Handoff a `compose-builder` (camino Docker) y/o `native-setup` (camino
   nativo), con `service-recipes`, para materializar dentro de `env/`, y luego
   `document-environment`.

## Reglas

- No generes archivos en esta skill; solo deja el plan acordado.
- Lo que le toca decidir a la persona (qué motor de base de datos, si necesita
  caché, qué se mockea) se pregunta sin marcar una opción como recomendada. El
  detalle técnico de cada servicio —imagen, versión/tag, memoria, puerto— **no se
  pregunta**: lo fija el agente con el criterio de `service-recipes` y recién
  aparece en el resumen final del punto 3, donde la persona puede pedir cambiarlo.
