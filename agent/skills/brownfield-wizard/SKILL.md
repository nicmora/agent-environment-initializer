---
name: env-brownfield-wizard
description: Para cada dependencia detectada en un proyecto existente, guía la elección de estrategia — reutilizar un recurso local o la pila compartida, conectar a una instancia externa, crear el servicio desde cero en Docker, o simularlo (mock). Usar después de detect-environment e inspect-local-resources, o cuando el usuario quiere decidir "cómo conecto cada cosa".
---

# Skill: brownfield-wizard

## Requisitos previos

Tener el inventario de `detect-environment` y el estado de máquina de
`inspect-local-resources`. Si faltan, corré esas skills primero.

## Procedimiento

Para **cada dependencia** del inventario, presentá las opciones y pedí una
decisión. Orden de preferencia sugerido (pero la persona elige):

1. **Pila de infraestructura compartida.** ¿Existe o querés crear una pila
   compartida del equipo? → deriva a `shared-infra`. Se crea un espacio lógico
   aislado para este servicio (schema/DB, base numerada de Redis, vhost de
   RabbitMQ, topic namespace de Kafka, bucket de MinIO, prefijo de claves).
2. **Recurso ya presente en la máquina.**
   - Contenedor Docker corriendo → conectar a ese: detectá nombre, red, puerto
     publicado y credenciales (de `docker inspect` / variables del contenedor si
     se pueden leer). Configurá la app para usar ese host/puerto.
   - Servicio instalado en el SO (Postgres, Redis, etc. en el host) → apuntar la
     app a `localhost:<puerto>` y, si hace falta, crear una DB/usuario nuevos
     **sin tocar** lo existente.
3. **Instancia externa** (staging, cloud, otro equipo) → pedí host, puerto,
   credenciales y guardalas en `.env.local`. Verificá conectividad de red.
4. **Crear desde cero en Docker** → deriva a `service-recipes` para las preguntas
   de configuración; el servicio va a `docker-compose.override.yml` o
   `docker-compose.dev.yml` (nunca al compose existente).
5. **Servicio de terceros / de otro equipo** → deriva a `external-mocks`:
   conexión real vs. simulación.

## Manejo de conflictos (no destructivo)

- **Puerto ocupado** → proponé otro puerto en el host y ajustá la variable de
  conexión. Nunca mates el proceso que lo usa sin permiso explícito.
- **Nombre de contenedor/volumen/red en uso** → usá un nombre nuevo con prefijo
  del proyecto.
- **Ya existe una DB/schema con ese nombre** → proponé un nombre alternativo; no
  la sobrescribas.
- **Versión distinta** entre lo detectado y lo disponible → avisá y dejá que la
  persona decida.

## Salida

Una tabla de decisiones:

| Dependencia | Estrategia elegida | Detalle (host/puerto/espacio lógico) | Variables de entorno a setear | Archivo destino |
|---|---|---|---|---|

Handoff a `compose-builder` (para lo que haya que crear) y a
`document-environment`.
