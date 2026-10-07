# Contexto de diseño del agente envinit

Este documento explica para qué existe el agente y por qué funciona como
funciona. Las reglas de comportamiento no están aquí: viven en las specs de
`openspec/specs/` y se implementan en `agent/`.

## Para qué existe

`envinit` ayuda a cualquier persona, con o sin perfil técnico, a levantar una
aplicación y sus dependencias en su máquina local. Lo usan desarrolladores, pero
también personas de producto, QA o soporte que necesitan ver la aplicación
funcionando sin saber de Docker ni de variables de entorno.

## Cómo trabaja, en una línea por paso

1. Analiza el proyecto, sin revisar todavía qué tiene instalado la persona.
2. Pregunta cómo levantar cada proyecto y qué hacer con cada dependencia.
3. Decide solo los detalles técnicos de Docker.
4. Muestra un resumen completo y espera la confirmación.
5. Prepara Docker, crea los archivos en `env-local/`, verifica que funcionan,
   apaga todo y entrega el comando para arrancar.

## Decisiones de diseño

- **La persona decide el qué, el agente decide el cómo.** La persona elige cómo
  corre cada cosa (Docker, nativo, servicio existente, real o mock). Los
  detalles técnicos de Docker los decide el agente y se muestran en el resumen
  final, donde se pueden cambiar. Así el wizard no le pregunta a alguien no
  técnico por imágenes o puertos.
- **Una pregunta por mensaje.** Quien responde puede no ser técnico. Varias
  preguntas juntas generan respuestas incompletas.
- **Nada se crea antes de confirmar.** El resumen final es el único punto de
  aprobación antes de escribir archivos.
- **Todo en `env-local/`, fuera de git.** El entorno es personal. El proyecto
  original no se modifica: solo se agrega `env-local/` al `.gitignore`.
- **Solo WireMock para mocks.** Una única herramienta, con mappings que salen de
  lo que el código realmente consume, es más predecible que elegir una distinta
  por servicio.
- **Verificar y apagar.** El agente prueba que el entorno arranca usando los
  mismos scripts que va a usar la persona, y lo deja apagado. La persona arranca
  con el comando que recibe.
- **Datos solo donde el agente es dueño.** Migraciones y datos de prueba se
  ofrecen solo para bases que el agente crea con Docker. Las bases reales son
  responsabilidad de la persona.

## Cómo está organizado el agente

Cada regla vive en un solo archivo, y cada archivo corresponde a una spec:

| Archivo en `agent/` | Spec |
|---|---|
| `AGENT.md` | `agent-conduct` |
| `skills/envinit-scan` | `project-scan` |
| `skills/envinit-wizard` | `setup-wizard` |
| `skills/envinit-mocks` | `service-mocks` |
| `skills/envinit-docker` | `docker-services` |
| `skills/envinit-build` | `environment-files` |

Para cambiar un comportamiento, primero se cambia la spec con OpenSpec y después
el archivo que le corresponde. Si una regla parece necesitar repetirse en otro
archivo, va en `AGENT.md` y los demás no la mencionan.

## Fuera de alcance

Despliegue a producción, CI/CD, secretos de producción, instalar runtimes o
servicios en el sistema operativo, y migrar datos de negocio.
