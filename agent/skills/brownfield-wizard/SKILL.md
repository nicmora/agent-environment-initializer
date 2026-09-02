---
name: env-brownfield-wizard
description: Para cada dependencia detectada en un proyecto existente, guía la elección de estrategia — reutilizar un recurso local o la pila compartida, conectar a una instancia externa, crear el servicio desde cero en Docker, o simularlo (mock). Usar después de detect-environment e inspect-local-resources, o cuando el usuario quiere decidir "cómo conecto cada cosa".
---

# Skill: brownfield-wizard

## Requisitos previos

Tener el inventario de `detect-environment` y el estado de máquina de
`inspect-local-resources`. Si faltan, ejecuta esas skills primero.

## Procedimiento

Recorre el inventario **de a una dependencia por vez**: presentas sus hallazgos,
preguntas su estrategia y cierras su configuración (espacio lógico, credenciales,
puerto) antes de pasar a la siguiente. No juntes en una misma pregunta
decisiones de dependencias distintas (la DB y el mock de un servicio externo van
en preguntas separadas).

Para cada dependencia, presenta las opciones y pide una decisión. Orden de
preferencia sugerido (pero la persona elige):

1. **Pila de infraestructura compartida.** ¿Existe o se quiere crear una pila
   compartida del equipo? → deriva a `shared-infra`. Se crea un espacio lógico
   aislado para este servicio (schema/DB, base numerada de Redis, vhost de
   RabbitMQ, topic namespace de Kafka, bucket de MinIO, prefijo de claves).
2. **Recurso ya presente en la máquina.**
   - Contenedor Docker corriendo → conectar a ese: detecta nombre, red, puerto
     publicado y credenciales (de `docker inspect` / variables del contenedor si
     se pueden leer). Configura la app para usar ese host/puerto.
   - Servicio instalado en el SO (Postgres, Redis, etc. en el host) → apunta la
     app a `localhost:<puerto>` y, si hace falta, crea una DB/usuario nuevos
     **sin tocar** lo existente.
   - En ambos casos: **no metas la app en una DB/schema/vhost/bucket existente
     sin preguntar.** Ofrece crear un espacio lógico propio y propón un nombre
     (editable) para él.
3. **Instancia externa** (staging, cloud, otro equipo) → pide host, puerto,
   credenciales y guárdalas en `.env.local`. Verifica conectividad de red.
4. **Crear desde cero en Docker** → deriva a `service-recipes` para las preguntas
   de configuración; el servicio va a `docker-compose.override.yml` o
   `docker-compose.dev.yml` (nunca al compose existente). En `service-recipes`
   se preguntan de forma explícita la variante/imagen base (alpine/slim/full/
   otra), la versión/tag y el presupuesto de memoria (perfil o `mem_limit` +
   `mem_reservation` personalizados); no se aplican defaults en silencio.
5. **Servicio de terceros / de otro equipo** → deriva a `external-mocks`:
   conexión real vs. simulación.

## Manejo de conflictos (no destructivo)

- **Puerto ocupado** → propón otro puerto en el host y ajusta la variable de
  conexión. Nunca mates el proceso que lo usa sin permiso explícito.
- **Nombre de contenedor/volumen/red en uso** → usa un nombre nuevo con prefijo
  del proyecto.
- **Ya existe una DB/schema con ese nombre** → propón un nombre alternativo; no
  la sobrescribas.
- **Versión distinta** entre lo detectado y lo disponible → avisa y deja que la
  persona decida.

## Salida

Una tabla de decisiones:

| Dependencia | Estrategia elegida | Detalle (host/puerto/espacio lógico) | Variables de entorno a setear | Archivo destino |
|---|---|---|---|---|

Los nombres de la columna "Detalle" (DB, schema, usuario, base de Redis, vhost,
bucket, prefijo, puerto host) son **propuestas editables**: muéstralas como
"propuesto: `X`" y confirma con la persona antes del handoff.

Handoff a `compose-builder` (para lo que haya que crear) y a
`document-environment`.
