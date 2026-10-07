## MODIFIED Requirements

### Requirement: No tocar archivos ajenos al agente
El script MUST crear, sobrescribir o borrar únicamente estos archivos del agente:
`<dir>/envinit/`, `<dir>/agents/envinit.md` y `<dir>/skills/envinit-*/`, además
de los archivos de la versión antigua definidos en "Limpieza de la versión
antigua". Cualquier otro archivo del proyecto destino MUST quedar intacto,
incluidas otras skills, otros agentes y la carpeta `env-local/` que genera el
agente.

#### Scenario: Proyecto con otras skills y agentes
- **WHEN** se instala en un proyecto cuyo `.claude/skills/` y `.claude/agents/`
  ya contienen skills y agentes propios
- **THEN** esas skills y esos agentes quedan sin cambios después de instalar

#### Scenario: Entorno local ya generado
- **WHEN** se instala, se actualiza o se desinstala en un proyecto que tiene una
  carpeta `env-local/`
- **THEN** la carpeta `env-local/` y su contenido quedan sin cambios
