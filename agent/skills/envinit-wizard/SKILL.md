---
name: envinit-wizard
description: Pasos 2 y 4 del agente envinit. Pregunta cómo levantar cada proyecto y qué hacer con cada dependencia (Docker, servicio existente, real o mock), pide los datos de conexión, pregunta por migraciones y datos de prueba, y muestra el resumen final para confirmar antes de crear archivos. Usar después de envinit-scan.
---

# envinit-wizard

## Entrada

El inventario de `envinit-scan`: proyectos, dependencias, datos de conexión
encontrados, migraciones y scripts de datos.

## Preguntas

### 1. Qué proyectos se levantan y cómo

Recorre los proyectos. Para cada uno:

- Si otro proyecto del repositorio lo consume, pregunta primero si se levanta
  también o se mockea. Si se mockea, no le preguntes la forma de arranque.
- Si se levanta, pregunta cómo:
  1. Con Docker: corre dentro de un contenedor, no necesita tener instalado el
     lenguaje en la máquina.
  2. Nativa: corre con el runtime o los scripts instalados en la máquina.

Si hay un solo proyecto, solo preguntas la forma de arranque.

### 2. Cada dependencia, de a una

Pregunta por cada dependencia por separado, nunca varias en la misma pregunta.
Una dependencia que usan varios proyectos se pregunta una sola vez. Las opciones
dependen del tipo:

| Tipo | Opciones |
|---|---|
| Infraestructura (base de datos, cache, cola, almacenamiento) | 1. Levantarla con Docker. 2. Conectarse a un servicio existente. |
| API o servicio externo | 1. Mockearlo: se simula con respuestas de prueba. 2. Conectarse al servicio real. |

Los proyectos del mismo repositorio ya se resolvieron en el punto 1.

Termina las preguntas de una dependencia antes de pasar a la siguiente:

- **Servicio existente o real:** consigue los datos de conexión.
  - Si el inventario tiene datos para esa dependencia, muéstralos y pregunta si
    son correctos.
  - Si no los tiene, pide cada dato en una pregunta separada (por ejemplo host,
    después puerto, después usuario, después contraseña).
- **Base de datos con Docker:**
  - Si el proyecto tiene migraciones, pregunta si se corren.
  - Pregunta si se cargan datos de prueba, con estas opciones:
    1. Usar los scripts de datos del proyecto (solo si existen).
    2. Generar datos de prueba.
    3. Dejar la base vacía.
- **Mock:** no hay más preguntas.

## Antes del resumen

Si algo corre en Docker, pasa a `envinit-docker` (decisiones) y vuelve con sus
resultados para armar el resumen.

## Resumen final

Muestra todo lo elegido:

- Forma de arranque de cada proyecto, o que se mockea.
- Cada dependencia con su modalidad: Docker, servicio existente, real o mock.
- Para cada contenedor: nombre, puerto e imagen.
- Para servicios existentes o reales: los datos de conexión.
- Migraciones y datos de prueba elegidos. Si eligió datos de prueba sin correr
  las migraciones, avisa que pueden fallar porque las tablas no existen.
- La lista de archivos que se van a crear en `env-local/`.

Pregunta:

1. Está bien, continuar.
2. Quiero cambiar algo.

Si quiere cambiar algo, pregunta qué, cambia solo ese punto y vuelve a mostrar
el resumen completo. No crees ningún archivo hasta que elija continuar.

## Siguiente paso

Si algo corre en Docker, pasa a `envinit-docker` (preparación). Si no, pasa a
`envinit-build`.
