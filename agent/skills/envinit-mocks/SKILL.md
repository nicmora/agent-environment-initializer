---
name: envinit-mocks
description: Parte del paso 6 del agente envinit. Simula con WireMock en Docker cada servicio externo o proyecto del mismo repositorio que la persona eligió mockear, con mappings basados en los endpoints que el proyecto consume y datos de prueba coherentes. La usa envinit-build al crear los archivos.
---

# envinit-mocks

## Entrada

Las dependencias que la persona eligió mockear, y para cada una el nombre de
contenedor, el puerto y la imagen de WireMock que decidió `envinit-docker`.

## 1. Encontrar los endpoints que se consumen

Para cada servicio mockeado, busca en el código del proyecto que lo consume:

- Las llamadas a ese servicio: cliente HTTP, cliente generado, Feign, Retrofit,
  `fetch`, `axios` u otro, a partir de la variable con su URL base.
- Para cada llamada: método, ruta, parámetros y cuerpo que se envía.
- La forma de la respuesta que el código espera: los campos que lee y sus tipos,
  según los modelos, DTOs o tipos del proyecto.

Si el repositorio tiene una especificación OpenAPI del servicio, úsala para
completar las respuestas, pero crea mappings solo para los endpoints que el
código llama. Si el servicio mockeado es otro proyecto del mismo repositorio,
usa sus controladores o rutas como referencia de las respuestas.

## 2. Crear los mappings

Por cada servicio, en `env-local/wiremock/<servicio>/`:

- `mappings/`: un archivo JSON por endpoint, con el método y la ruta. Usa
  `urlPathPattern` para las rutas con parámetros.
- `__files/`: los cuerpos de respuesta largos, referenciados con
  `bodyFileName`.

## 3. Datos de prueba

- Realistas: nombres, correos, montos, fechas y estados con forma real, nunca
  `test1` ni `foo`.
- Coherentes entre sí: el mismo identificador representa siempre la misma
  entidad. Si un endpoint devuelve el cliente `42`, los pagos de ese cliente
  usan `42`.
- Suficientes para usar la aplicación: listas con varios elementos y al menos
  un caso para cada estado que el código distingue.

## 4. Contenedor y conexión

- Un contenedor de WireMock por servicio, con la carpeta
  `./wiremock/<servicio>` montada en `/home/wiremock`.
- La variable de entorno con que la aplicación lee la URL del servicio apunta al
  mock: `http://<contenedor>:8080` si la app corre en Docker, o
  `http://localhost:<puerto>` si corre nativa.

## Siguiente paso

Vuelve a `envinit-build` con los archivos creados, el servicio para el compose y
las variables para el archivo de entorno.
