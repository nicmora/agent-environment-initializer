---
name: envinit-mocks
description: Para servicios externos (APIs de terceros, microservicios de otro equipo, servicios cloud, OIDC), decide entre conexión real y simulación, y monta el mock correspondiente — WireMock/Mockoon/Prism para HTTP, emisor de tokens falso u OIDC, emuladores cloud, consumidores/productores de eventos de ejemplo. Permite modo mixto por dependencia y alternar con perfiles de compose. Usar cuando el usuario dice "mi servicio se conecta a otro externo" / "quiero mockear pagos" / "no puedo levantar el servicio X".
---

# Skill: envinit-mocks

## Decisión por cada servicio externo

Pregunta en lenguaje simple (ver "Cómo comunicarte" en `AGENT.md`), sin nombrar
herramientas de mock salvo que la persona pida el detalle:
1. **Conectarse al servicio real** — necesitas tener las credenciales de
   desarrollo.
2. **Simularlo** — la app funciona sin depender de él; las respuestas son de
   prueba.

Se puede elegir distinto por servicio (**modo mixto**). La elección se controla
con perfiles de compose (`--profile mock`) y/o una variable
(`PAYMENTS_MODE=real|mock`), para poder alternar sin reconfigurar.

**El mock corre como contenedor Docker**, bajo `profiles: ["mock"]` en
`local/docker-compose*.yml`. Todas las herramientas de abajo tienen imagen oficial
(`stoplight/prism`, `wiremock/wiremock`, `mockoon/cli`, `localstack/localstack`,
`ghcr.io/navikt/mock-oauth2-server`).

**Elección de la imagen del mock:** mismo criterio que la infraestructura (ver
"Lo que el agente decide solo" en `AGENT.md` y `envinit-recipes`). Primero
revisa `docker image ls`: si ya hay una imagen descargada de esa herramienta
(p. ej. `wiremock/wiremock:3.9.1-alpine`), úsala. Si no, elige la variante más
chica con tag numerado (p. ej. `wiremock/wiremock:3.x-alpine`), nunca la
genérica ni `latest`. La imagen va por variable con default
(`${PAYMENTS_MOCK_IMAGE:-…}`), como en `envinit-compose`.

Solo si el entorno **no usa Docker en
absoluto** (app nativa y todas las demás dependencias externas), el mock puede
correr como proceso nativo (`npx @stoplight/prism-cli`, WireMock `.jar`) agregado
al `local/Procfile`.

## Conexión real

- Credenciales y endpoints en `local/.env.local`.
- Verifica conectividad (`curl`/ping desde donde corre la app).
- Si es un microservicio propio en otro repo: ofrece clonarlo y sumarlo al
  compose, o apuntar a su instancia de staging.

## Simulación por tipo

### HTTP / REST
- **Con OpenAPI/Swagger disponible** → Prism:
  ```yaml
  payments-mock:
    image: stoplight/prism:4
    command: mock -h 0.0.0.0 /specs/payments.yaml
    volumes: ["local/mocks/payments:/specs:ro"]
    ports: ["4010:4010"]
    profiles: ["mock"]
  ```
- **Sin spec** → WireMock o Mockoon con stubs a mano en `local/mocks/<servicio>/`.
  Documenta cómo agregar/editar respuestas.
- Apunta la variable de la app (`PAYMENTS_BASE_URL`) al mock cuando el perfil
  `mock` está activo.

### gRPC
- WireMock gRPC extension o un stub server generado del `.proto`. Guarda los
  `.proto` en `local/mocks/`.

### Colas / eventos
- Usa el broker local (real, de la pila) + un **productor de eventos de ejemplo**
  (script o pequeño servicio que publica mensajes de muestra) y/o un
  **consumidor simulado** que solo loguea. Guarda los payloads de ejemplo en
  `local/mocks/events/`.

### Servicios cloud (AWS/Azure/GCP)
- LocalStack / Azurite / emuladores. Ver `envinit-recipes`.

### Auth / OIDC
- Emisor de tokens de prueba (p. ej. `oauth2-proxy`/`mock-oauth2-server` de
  navikt, o Keycloak con un realm de dev). Configura `issuer`, `jwks_uri` y un
  set de usuarios de prueba.

## Salida

Tabla:

| Servicio externo | Modo (real/mock) | Cómo se activa | Endpoint | Archivos de stubs |
|---|---|---|---|---|

Handoff a `envinit-compose` (servicios de mock bajo `profiles: ["mock"]`), y a
`envinit-document`. Solo si el entorno no usa Docker, el mock va como entrada
en `local/Procfile` vía `envinit-native`.
