## 1. Limpieza

- [x] 1.1 Borrar `agent/AGENT.md`, `agent/adapters/claude-code/envinit.md`, `agent/adapters/opencode/envinit.md` y las ocho carpetas `agent/skills/envinit-*`, y verificar que `agent/` queda sin archivos

## 2. Núcleo del agente

- [x] 2.1 Escribir `agent/AGENT.md` con objetivo, comunicación, cómo preguntar (con el selector de cada herramienta), límites y el flujo con la skill de cada paso, y verificar que cada requirement de `agent-conduct` tiene una regla correspondiente y que ninguna regla aparece dos veces
- [x] 2.2 Escribir los dos adaptadores con solo el frontmatter de cada herramienta y la indicación de leer `.claude/envinit/AGENT.md` u `.opencode/envinit/AGENT.md`, y verificar que no contienen reglas

## 3. Skills

- [x] 3.1 Escribir `envinit-scan` según `project-scan`, y verificar que cubre cada requirement y que no repite reglas de comunicación ni límites de `AGENT.md`
- [x] 3.2 Escribir `envinit-wizard` según `setup-wizard`, y verificar lo mismo que en 3.1
- [x] 3.3 Escribir `envinit-mocks` según `service-mocks`, y verificar lo mismo que en 3.1
- [x] 3.4 Escribir `envinit-docker` según `docker-services` y las decisiones 4, 5 y 9 del design, y verificar lo mismo que en 3.1
- [x] 3.5 Escribir `envinit-build` según `environment-files` y las decisiones 4 a 8 del design, y verificar lo mismo que en 3.1
- [x] 3.6 Revisar las seis piezas juntas, con la tabla de la decisión 1 del design, y verificar que todas las rutas usan la forma instalada, que cada skill tiene `name` y `description` con prefijo `envinit-`, que el texto usa tuteo sin voseo y que no hay reglas contradictorias ni repetidas

## 4. Instalación y documentación

- [x] 4.1 Cambiar en `scripts/install.sh` y `scripts/install.ps1` los mensajes que nombran `local/` para que nombren `env-local/`, y verificar que `bash -n scripts/install.sh` pasa y que `install.ps1` sigue en UTF-8 con BOM
- [x] 4.2 Reescribir `docs/context.md` como referencia de diseño corta a partir de `agente-entorno-local.md` y de este cambio, sin copiar reglas que ya están en las specs, y verificar que remite a `openspec/specs/` para el comportamiento
- [x] 4.3 Actualizar `README.md` y `docs/INSTALL.md` con las cinco skills, el flujo nuevo y `env-local/`, y verificar con `grep` que no quedan menciones a las skills retiradas ni a `ENVIRONMENT.md`

## 5. Prueba integral

- [x] 5.1 Instalar el agente en un proyecto de prueba que tenía la versión anterior, con `install.sh` y con `install.ps1`, y verificar que quedan solo las cinco skills nuevas y que las skills propias del proyecto siguen intactas
- [x] 5.2 Recorrer el flujo completo en un proyecto de prueba con una base de datos con migraciones, una API externa y la app nativa, y verificar el orden de las preguntas, el resumen final, el mock de WireMock, la verificación con apagado y la entrega del comando y la URL
- [x] 5.3 Recorrer el flujo en un monorepo de prueba con un frontend que consume un backend, con el backend en Docker, y verificar que la forma de arranque se pregunta por proyecto y que la dependencia compartida se pregunta una sola vez
