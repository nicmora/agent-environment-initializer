# service-mocks Specification

## Purpose

Define cómo el agente simula un servicio externo o un proyecto del mismo
monorepo cuando la persona elige mockearlo.

## Requirements

### Requirement: WireMock en Docker
Todo mock SHALL implementarse con WireMock corriendo en Docker, dentro del mismo
entorno que los demás contenedores del proyecto.

#### Scenario: Mock de una API externa
- **WHEN** la persona elige mockear la API de pagos
- **THEN** el entorno incluye un contenedor de WireMock para esa API

### Requirement: Mappings basados en el uso real
El agente SHALL crear los mappings de WireMock a partir de los endpoints que el
proyecto realmente consume, con el método, la ruta y la forma de respuesta que
el código espera.

#### Scenario: Endpoints consumidos
- **WHEN** el código llama a `GET /customers/{id}` y `POST /payments`
- **THEN** existen mappings para esos dos endpoints y para ningún otro

### Requirement: Datos de prueba coherentes
Las respuestas de los mocks SHALL contener datos de prueba realistas y
coherentes entre sí.

#### Scenario: Identificadores consistentes
- **WHEN** un mapping devuelve un cliente con id `42` y otro devuelve pagos de
  clientes
- **THEN** los pagos que corresponden a ese cliente usan el id `42`

### Requirement: La aplicación apunta al mock
Cuando una dependencia se mockea, la variable de entorno con la que la
aplicación se conecta a ella SHALL apuntar a la URL del mock.

#### Scenario: Variable de conexión
- **WHEN** la API de pagos está mockeada y la app la lee de `PAYMENTS_URL`
- **THEN** el archivo de variables de `env-local/` define `PAYMENTS_URL` con la
  URL del contenedor de WireMock
