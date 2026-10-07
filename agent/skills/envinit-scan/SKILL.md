---
name: envinit-scan
description: Paso 1 del agente envinit. Analiza los archivos del proyecto (lenguaje, runtime, scripts de arranque, puertos, configuración, variables de entorno y dependencias, incluidos los monorepos) y muestra un resumen breve. Usar al empezar, antes de cualquier pregunta.
---

# envinit-scan

## Qué haces

Analizas el proyecto y armas un inventario que usan los pasos siguientes.
Después muestras un resumen breve.

Solo lees archivos del proyecto. En este paso no ejecutes comandos que consulten
herramientas de la máquina (`docker`, `node --version`, `java -version` y
similares): eso se revisa más adelante, si hace falta.

## Qué buscar

1. **Proyectos.** Si el repositorio tiene varios proyectos (workspaces de
   `package.json`, `pnpm-workspace.yaml`, módulos de Maven o Gradle, `go.work`,
   o carpetas con su propio manifiesto), trata cada uno por separado.
2. **Por cada proyecto:**
   - Lenguaje, runtime y su versión declarada (`.nvmrc`, `engines`,
     `.python-version`, `pom.xml`, `go.mod`, `.tool-versions`, etc.).
   - Gestor de dependencias (npm, pnpm, yarn, Maven, Gradle, pip, Poetry, etc.).
   - Scripts y comandos de arranque (`package.json`, `Makefile`, README).
   - Puertos en los que escucha.
   - Archivos de configuración: `.env`, `.env.example`, `application.yml`,
     `docker-compose*.yml`, `Dockerfile` y similares.
   - Variables de entorno que lee el código.
3. **Dependencias de cada proyecto**, con el tipo de cada una:
   - Infraestructura: bases de datos, caches, colas, almacenamiento.
   - APIs o servicios externos.
   - Otro proyecto del mismo repositorio, cuando uno lo consume (llamadas HTTP a
     su puerto, proxy de desarrollo, dependencia de paquete del workspace).
4. **Para cada dependencia, lo que el wizard va a necesitar:**
   - Versión, si el proyecto la fija (en un compose existente, en un driver o en
     la configuración).
   - Datos de conexión presentes en el proyecto (host, puerto, usuario, URL), y
     el nombre de la variable de entorno con que la app la lee.
   - Para bases de datos: si el proyecto tiene migraciones y con qué comando se
     corren, y si tiene scripts que cargan datos iniciales.

Una dependencia que usan varios proyectos se registra una sola vez, con la lista
de proyectos que la usan.

## Resumen

Muestra en pocas líneas:

- Qué es la aplicación, en una o dos frases.
- Qué proyectos tiene, si son varios, y cuál usa a cuál.
- Qué dependencias necesita, una por línea y en palabras simples ("una base de
  datos PostgreSQL", "la API de pagos de Stripe").

Si no tiene dependencias, dilo ("no necesita otros servicios") y sigue con la
pregunta de la forma de arranque.

## Siguiente paso

Pasa a `envinit-wizard` con el inventario.
