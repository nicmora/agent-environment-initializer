<#
.SYNOPSIS
    Instala, actualiza o desinstala el agente envinit en un proyecto.

.DESCRIPTION
    Copia el agente envinit (AGENT.md, el adaptador de la herramienta y las
    skills envinit-*) a la carpeta .claude/ u .opencode/ del proyecto. Solo
    toca archivos del agente: el resto del proyecto, incluida la carpeta
    local/, queda intacto. También quita la versión anterior (env-initializer)
    si la encuentra.

    Compatible con Windows PowerShell 5.1 y PowerShell 7+.

.PARAMETER Tool
    claude (Claude Code) u opencode (OpenCode). Si falta y la terminal es
    interactiva, se pregunta.

.PARAMETER Target
    Raíz del proyecto donde se instala. Debe existir.

.PARAMETER Uninstall
    Quita el agente del proyecto en lugar de instalarlo.

.EXAMPLE
    .\scripts\install.ps1 -Tool claude -Target C:\proyectos\mi-app

.EXAMPLE
    .\scripts\install.ps1 -Tool opencode -Target C:\proyectos\mi-app -Uninstall
#>
[CmdletBinding()]
param(
    [string]$Tool,
    [string]$Target,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$AgentSrc = Join-Path (Split-Path -Parent $PSScriptRoot) 'agent'

# Skills de la versión anterior, cuando el agente se llamaba env-initializer.
$LegacySkills = @(
    'detect-environment', 'plan-environment', 'compose-builder', 'native-setup',
    'service-recipes', 'external-mocks', 'verify-environment', 'document-environment'
)

$script:RemovedLegacy = @()
$script:RemovedAny = $false

function Fail([string]$Message) {
    [Console]::Error.WriteLine("Error: $Message")
    exit 1
}

function Test-Interactive {
    if ([Console]::IsInputRedirected) { return $false }
    foreach ($arg in [Environment]::GetCommandLineArgs()) {
        if ($arg -like '-NonI*') { return $false }
    }
    return $true
}

# Borra una ruta si existe. Devuelve $true si borró algo.
function Remove-AgentPath([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        $script:RemovedAny = $true
        return $true
    }
    return $false
}

function Remove-Legacy {
    if (Remove-AgentPath (Join-Path $ToolDir 'env-initializer')) {
        $script:RemovedLegacy += "$ToolDirName/env-initializer/"
    }
    if (Remove-AgentPath (Join-Path $ToolDir 'agents\env-initializer.md')) {
        $script:RemovedLegacy += "$ToolDirName/agents/env-initializer.md"
    }
    foreach ($skill in $LegacySkills) {
        if (Remove-AgentPath (Join-Path $ToolDir "skills\$skill")) {
            $script:RemovedLegacy += "$ToolDirName/skills/$skill/"
        }
    }
}

function Remove-Current {
    [void](Remove-AgentPath (Join-Path $ToolDir 'envinit'))
    [void](Remove-AgentPath (Join-Path $ToolDir 'agents\envinit.md'))
    $skillsDir = Join-Path $ToolDir 'skills'
    if (Test-Path -LiteralPath $skillsDir) {
        foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Filter 'envinit-*') {
            [void](Remove-AgentPath $skill.FullName)
        }
    }
}

# --- Validaciones (antes de escribir nada) ------------------------------------

if (-not (Test-Path -LiteralPath $AgentSrc -PathType Container)) {
    Fail "no se encontró la carpeta del agente en $AgentSrc."
}

if (-not $Target) { Fail 'falta -Target: indica la ruta del proyecto.' }
if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
    Fail "el proyecto '$Target' no existe o no es una carpeta."
}
$Target = (Resolve-Path -LiteralPath $Target).ProviderPath

if (-not $Tool) {
    if (Test-Interactive) {
        Write-Host '¿Para qué herramienta?'
        Write-Host '  1) claude    (Claude Code)'
        Write-Host '  2) opencode  (OpenCode)'
        $answer = Read-Host 'Elige 1 o 2'
        switch ($answer) {
            { $_ -in '1', 'claude' } { $Tool = 'claude' }
            { $_ -in '2', 'opencode' } { $Tool = 'opencode' }
            default { Fail "opción no válida: '$answer'." }
        }
    } else {
        Fail 'falta -Tool: indica claude u opencode.'
    }
}

switch ($Tool) {
    'claude'   { $ToolDirName = '.claude';   $Adapter = 'claude-code' }
    'opencode' { $ToolDirName = '.opencode'; $Adapter = 'opencode' }
    default    { Fail "herramienta no válida: '$Tool' (usa claude u opencode)." }
}

$ToolDir = Join-Path $Target $ToolDirName

# --- Desinstalar --------------------------------------------------------------

if ($Uninstall) {
    Remove-Legacy
    Remove-Current
    Write-Host ''
    if ($script:RemovedAny) {
        Write-Host 'Listo: se quitó el agente envinit.'
    } else {
        Write-Host 'No había nada para quitar: el agente envinit no estaba instalado.'
    }
    Write-Host "  Herramienta: $Tool"
    Write-Host "  Proyecto:    $Target"
    Write-Host ''
    Write-Host 'La carpeta local/ del proyecto (tu entorno) no se tocó.'
    exit 0
}

# --- Instalar -----------------------------------------------------------------

Remove-Legacy
Remove-Current

foreach ($dir in 'envinit', 'agents', 'skills') {
    New-Item -ItemType Directory -Force -Path (Join-Path $ToolDir $dir) | Out-Null
}
Copy-Item -LiteralPath (Join-Path $AgentSrc 'AGENT.md') -Destination (Join-Path $ToolDir 'envinit\AGENT.md')
Copy-Item -LiteralPath (Join-Path $AgentSrc "adapters\$Adapter\envinit.md") -Destination (Join-Path $ToolDir 'agents\envinit.md')
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $AgentSrc 'skills') -Directory -Filter 'envinit-*') {
    Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $ToolDir 'skills') -Recurse
}

Write-Host ''
Write-Host 'Listo: se instaló el agente envinit.'
Write-Host "  Herramienta: $Tool"
Write-Host "  Proyecto:    $Target"
Write-Host "  Archivos en: $ToolDir"
if ($script:RemovedLegacy.Count -gt 0) {
    Write-Host ''
    Write-Host 'Se quitó la versión anterior (env-initializer):'
    foreach ($item in $script:RemovedLegacy) { Write-Host "  $item" }
}
Write-Host ''
if ($Tool -eq 'claude') {
    Write-Host 'Para usarlo: abre Claude Code en la raíz del proyecto y escribe @envinit.'
} else {
    Write-Host 'Para usarlo: abre opencode en la raíz del proyecto y presiona Tab hasta que aparezca envinit.'
}
