---
name: envinit-docker
description: Pasos 3 y 5 del agente envinit. Decide sin preguntar nombres, puertos, red, imágenes, volúmenes y healthchecks de todo lo que corre en Docker; y, con el resumen confirmado, verifica que Docker esté encendido, reusa imágenes ya descargadas y resuelve puertos ocupados. Usar cuando algo del plan corre en Docker.
---

# envinit-docker

Esta skill tiene dos partes. El wizard usa las **decisiones** antes del resumen
final. La **preparación** se hace después de que la persona confirma el resumen.

## Parte 1: decisiones

Para cada cosa que corre en Docker (aplicaciones, dependencias y mocks), decide
sin preguntar:

- **Prefijo.** El nombre del proyecto en minúsculas, sin espacios (de su
  manifiesto o de la carpeta raíz).
- **Nombre del contenedor.** `<prefijo>-<servicio>`, por ejemplo
  `tienda-postgres`.
- **Red.** Una sola red, `<prefijo>-net`, compartida por todos los contenedores.
- **Puerto en la máquina.** El que indique el proyecto, si lo indica. Si no, el
  estándar de la tecnología (5432 para PostgreSQL, 6379 para Redis, 8080 para
  WireMock, etc.). Si dos contenedores quedan con el mismo, usa el siguiente
  número para el segundo.
- **Imagen.** La imagen oficial de la tecnología:
  - Si el proyecto fija una versión, respétala.
  - Si no, la última versión estable.
  - El tag siempre lleva número de versión, nunca `latest`.
  - Prioriza la variante más chica que funcione: `alpine`, después `slim`,
    después la completa.
  - Para mocks, `wiremock/wiremock` con tag numerado.
- **Volúmenes.** Un volumen nombrado para cada servicio que guarda datos (bases
  de datos, colas, almacenamiento), con el prefijo en el nombre.
- **Healthcheck.** Para cada contenedor, un chequeo que confirme que está listo
  (por ejemplo `pg_isready` para PostgreSQL o `redis-cli ping` para Redis), con
  un comando que exista dentro de la imagen.
- **Variables.** Las que la imagen necesita para arrancar (usuario, contraseña,
  nombre de la base). Para bases nuevas, genera credenciales de desarrollo.
- **Aplicaciones en Docker.** Si el proyecto tiene `Dockerfile`, se usa tal
  cual. Si no tiene, se crea uno en `env-local/`, con una imagen base que siga
  las mismas reglas de imagen.

Devuelve estas decisiones al wizard para el resumen final.

## Parte 2: preparación

Con el resumen confirmado, antes de crear archivos:

### Docker encendido

1. Ejecuta `docker info`. Si responde, Docker está encendido.
2. Si no responde, pregunta si la persona quiere encenderlo.
   - **Acepta:** en Windows y macOS, abre Docker Desktop. En Linux, ejecuta
     `systemctl start docker`. Si necesita permisos de administrador que no
     tienes, explica a la persona cómo encenderlo y espera a que lo haga.
     Después espera a que `docker info` responda y sigue.
   - **No acepta:** sigue sin Docker. Avisa a `envinit-build` que Docker quedó
     apagado. Salta la revisión de imágenes.

### Imágenes descargadas

1. Lista las imágenes con `docker image ls`.
2. Para cada contenedor, busca una imagen descargada de la misma tecnología con
   una versión compatible con el proyecto: la misma versión mayor, o la que pide
   el proyecto si fija una. No uses tags `latest` ni sin número.
3. Si hay varias, elige la variante más chica y después la versión más nueva.
4. Si una reemplaza a la del resumen, úsala.

### Puertos ocupados

Revisa si cada puerto elegido está en uso en la máquina. En Windows, usa
`Get-NetTCPConnection -State Listen -LocalPort <puerto>`. En macOS o Linux, usa
`lsof -iTCP:<puerto> -sTCP:LISTEN`. Si está ocupado, usa el siguiente puerto
libre.

### Aviso

Si cambiaste alguna imagen o algún puerto, avisa en un solo mensaje qué cambió y
por qué ("uso PostgreSQL 15.4 porque ya está descargada", "uso el puerto 5433
porque el 5432 está ocupado"). No es una pregunta: después de avisar, sigue.

## Siguiente paso

Pasa a `envinit-build` con las decisiones finales y el estado de Docker.
