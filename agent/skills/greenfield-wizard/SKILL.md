---
name: env-greenfield-wizard
description: Cuestionario guiado para proyectos nuevos (greenfield) sin dependencias de entorno todavía definidas. Determina forma del repo (monorepo/multirepo), tipo de aplicación, persistencia, caché, mensajería, storage, integraciones externas, configuración y puertos, y deja lista la decisión de estrategia por dependencia. Usar cuando el repo está vacío o casi vacío, o el usuario dice "proyecto nuevo" / "arrancamos de cero".
---

# Skill: greenfield-wizard

## Objetivo

Definir, mediante preguntas, qué entorno necesita un proyecto nuevo, y dejar
planteada la estrategia (reutilizar / externo / crear / simular) por cada
dependencia.

## Procedimiento

Haz las preguntas en bloques cortos, una idea por vez. No abrumes: si una
respuesta cierra un tema, salta el resto de ese bloque.

### Bloque 1 — Estructura del repositorio
- ¿Monorepo (varios servicios/paquetes/frontend) o repo único de un servicio?
- Si es monorepo: ¿qué servicios habrá y en qué lenguaje/framework cada uno?
- Si es repo único: ¿con qué otros microservicios (otros repos) se comunica y
  cómo (HTTP, gRPC, eventos)?

### Bloque 2 — Aplicación
- Tipo: backend / frontend / worker o batch / CLI / librería / full-stack.
- Lenguaje, framework, gestor de paquetes, versión de runtime.
- ¿La app corre en contenedor propio o en el host durante desarrollo?

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
- No preguntes puertos: si alguna dependencia va a crearse en Docker (bloque
  3-7), ejecuta `inspect-local-resources` para saber qué está ocupado y que el
  agente elija el puerto de cada servicio sin preguntarlo (ver `service-recipes`).
  Si todo se resuelve con conexión externa o mock, no hace falta ni este paso.

## Salida

1. Un **resumen del entorno objetivo**: lista de servicios (propios + infra),
   con tipo e imagen/variante/versión/memoria/puerto que decidió el agente
   (ver criterio en `service-recipes` y "Lo que el agente decide solo" en
   `AGENT.md`). Esto no se pregunta dependencia por dependencia: se resuelve y
   se muestra recién en el resumen final del punto 3, con la posibilidad de
   cambiarlo ahí.
2. Para cada dependencia de infra: pregunta si se prefiere **pila compartida**
   (deriva a `shared-infra`) o **instancia dedicada al proyecto**.
3. **Resumen final y ajustes.** Antes del handoff, presenta el plan completo
   (servicios, estrategia, imágenes, puertos, memoria, archivos a crear dentro
   de `env/`) y pregunta si algo se quiere cambiar o personalizar.
4. Handoff a `compose-builder` + `service-recipes` para materializar dentro de
   `env/`, y luego `document-environment`.

## Reglas

- No generes archivos en esta skill; solo deja el plan acordado.
- Propón defaults razonables para no trabar a la persona ("si no tienes
  preferencia, uso Postgres 16").
