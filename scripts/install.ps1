<#
.SYNOPSIS
    Instala, actualiza o desinstala el agente envinit en un proyecto.

.DESCRIPTION
    Copia el agente envinit (AGENT.md, el adaptador de la herramienta y las
    skills envinit-*) a la carpeta .claude/ u .opencode/ del proyecto, o a las
    dos. Solo toca archivos del agente: el resto del proyecto, incluida la
    carpeta env-local/, queda intacto. También quita la versión anterior
    (env-initializer) si la encuentra.

    Si falta la ruta o la herramienta y la terminal es interactiva, se
    preguntan. Si el script hace alguna pregunta, al final pide confirmación
    antes de escribir. Con -Tool y -Target no pregunta nada.

    Compatible con Windows PowerShell 5.1 y PowerShell 7+.

.PARAMETER Tool
    claude (Claude Code), opencode (OpenCode) o las dos separadas por coma:
    claude,opencode. Si falta y la terminal es interactiva, se muestra una
    lista para marcarlas.

.PARAMETER Target
    Raíz del proyecto donde se instala. Debe existir. Si falta y la terminal
    es interactiva, se pregunta.

.PARAMETER Uninstall
    Quita el agente del proyecto en lugar de instalarlo.

.EXAMPLE
    .\scripts\install.ps1

.EXAMPLE
    .\scripts\install.ps1 -Tool claude -Target C:\proyectos\mi-app

.EXAMPLE
    .\scripts\install.ps1 -Tool claude,opencode -Target C:\proyectos\mi-app

.EXAMPLE
    .\scripts\install.ps1 -Tool opencode -Target C:\proyectos\mi-app -Uninstall
#>
[CmdletBinding()]
param(
    [string[]]$Tool,
    [string]$Target,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).ProviderPath
$AgentSrc = Join-Path $RepoRoot 'agent'

# Skills de la versión anterior, cuando el agente se llamaba env-initializer.
$LegacySkills = @(
    'detect-environment', 'plan-environment', 'compose-builder', 'native-setup',
    'service-recipes', 'external-mocks', 'verify-environment', 'document-environment'
)

$script:WantClaude = $false
$script:WantOpenCode = $false
$script:Asked = $false
$script:Summary = @()

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

# Lee una línea de la terminal. Si la entrada se cierra, termina sin escribir nada.
function Read-Answer([string]$Prompt) {
    $line = Read-Host $Prompt
    if ($null -eq $line) {
        Write-Host ''
        Fail 'se cerró la entrada antes de responder. No se hizo ningún cambio.'
    }
    return $line.Trim()
}

# Limpia una ruta pegada: comillas alrededor y ~ inicial.
function ConvertTo-CleanPath([string]$Path) {
    $p = $Path.Trim()
    if ($p.Length -ge 2 -and (($p[0] -eq '"' -and $p[-1] -eq '"') -or ($p[0] -eq "'" -and $p[-1] -eq "'"))) {
        $p = $p.Substring(1, $p.Length - 2)
    }
    if ($p -eq '~') {
        $p = $HOME
    } elseif ($p.StartsWith('~/') -or $p.StartsWith('~\')) {
        $p = Join-Path $HOME $p.Substring(2)
    }
    return $p
}

# Valida un destino. Devuelve la ruta absoluta en Path, o el motivo en Error.
function Test-Target([string]$Path) {
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return @{ Error = "la carpeta '$Path' no existe." }
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return @{ Error = "'$Path' no es una carpeta." }
    }
    $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath
    if ($resolved.TrimEnd('\', '/') -ieq $RepoRoot.TrimEnd('\', '/')) {
        return @{ Error = "'$Path' es el repositorio del agente. El agente se instala en otro proyecto, no en este repo." }
    }
    return @{ Path = $resolved }
}

function Read-Target {
    Write-Host ''
    while ($true) {
        $answer = Read-Answer 'Ruta del proyecto (puedes pegarla)'
        if (-not $answer) {
            Write-Host '  Escribe o pega la ruta del proyecto.'
            continue
        }
        $check = Test-Target (ConvertTo-CleanPath $answer)
        if ($check.Path) { return $check.Path }
        Write-Host "  No sirve: $($check.Error)"
    }
}

function Get-Mark([bool]$Marked) {
    if ($Marked) { return 'x' } else { return ' ' }
}

function Read-Tools {
    $verb = if ($Uninstall) { 'quitar' } else { 'instalar' }
    while ($true) {
        Write-Host ''
        Write-Host "¿Para qué herramientas quieres $verb envinit?"
        Write-Host "  [$(Get-Mark $script:WantClaude)] 1) Claude Code"
        Write-Host "  [$(Get-Mark $script:WantOpenCode)] 2) OpenCode"
        $answer = Read-Answer 'Escribe un número para marcar o desmarcar, y Enter para continuar'
        switch ($answer) {
            '1' { $script:WantClaude = -not $script:WantClaude }
            '2' { $script:WantOpenCode = -not $script:WantOpenCode }
            '' {
                if ($script:WantClaude -or $script:WantOpenCode) { return }
                Write-Host '  Marca al menos una herramienta para continuar.'
            }
            default { Write-Host "  Opción no válida: '$answer'. Escribe 1, 2 o solo Enter." }
        }
    }
}

# Marca las herramientas indicadas. Cada valor puede ser una lista separada por comas,
# porque powershell -File entrega "claude,opencode" como un solo texto.
function Set-ToolsFromArgs([string[]]$Values) {
    foreach ($value in $Values) {
        foreach ($t in $value.Split(',')) {
            switch ($t.Trim()) {
                'claude' { $script:WantClaude = $true }
                'opencode' { $script:WantOpenCode = $true }
                '' { }
                default { Fail "herramienta no válida: '$($t.Trim())' (usa claude, opencode o claude,opencode)." }
            }
        }
    }
}

function Get-ToolLabel([string]$Name) {
    if ($Name -eq 'claude') { return 'Claude Code' } else { return 'OpenCode' }
}

function Confirm-Action {
    $labels = ($Tools | ForEach-Object { Get-ToolLabel $_ }) -join ', '
    Write-Host ''
    if ($Uninstall) {
        Write-Host 'Voy a quitar el agente envinit de:'
    } else {
        Write-Host 'Voy a instalar el agente envinit en:'
    }
    Write-Host "  Proyecto:     $Target"
    Write-Host "  Herramientas: $labels"
    while ($true) {
        $answer = Read-Answer '¿Continuar? (S/n)'
        if ($answer -in '', 's', 'si', 'sí', 'y', 'yes') { return }
        if ($answer -in 'n', 'no') {
            Write-Host ''
            Write-Host 'No se hizo ningún cambio.'
            exit 0
        }
        Write-Host '  Responde s (sí) o n (no).'
    }
}

function Add-Summary([string]$Line) {
    $script:Summary += $Line
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
    if (Remove-AgentPath (Join-Path $script:ToolDir 'env-initializer')) {
        $script:RemovedLegacy += "$script:ToolDirName/env-initializer/"
    }
    if (Remove-AgentPath (Join-Path $script:ToolDir 'agents\env-initializer.md')) {
        $script:RemovedLegacy += "$script:ToolDirName/agents/env-initializer.md"
    }
    foreach ($skill in $LegacySkills) {
        if (Remove-AgentPath (Join-Path $script:ToolDir "skills\$skill")) {
            $script:RemovedLegacy += "$script:ToolDirName/skills/$skill/"
        }
    }
}

function Remove-Current {
    [void](Remove-AgentPath (Join-Path $script:ToolDir 'envinit'))
    [void](Remove-AgentPath (Join-Path $script:ToolDir 'agents\envinit.md'))
    $skillsDir = Join-Path $script:ToolDir 'skills'
    if (Test-Path -LiteralPath $skillsDir) {
        foreach ($skill in Get-ChildItem -LiteralPath $skillsDir -Filter 'envinit-*') {
            [void](Remove-AgentPath $skill.FullName)
        }
    }
}

# Instala o desinstala el agente para una herramienta y agrega su parte del resumen.
function Invoke-Tool([string]$Name) {
    if ($Name -eq 'claude') {
        $script:ToolDirName = '.claude'; $adapter = 'claude-code'
    } else {
        $script:ToolDirName = '.opencode'; $adapter = 'opencode'
    }
    $script:ToolDir = Join-Path $Target $script:ToolDirName
    $script:RemovedLegacy = @()
    $script:RemovedAny = $false

    Add-Summary ''
    Add-Summary (Get-ToolLabel $Name)

    Remove-Legacy
    if ($Uninstall) {
        Remove-Current
        if ($script:RemovedAny) {
            Add-Summary "  Se quitó el agente de $script:ToolDir"
        } else {
            Add-Summary '  No había nada para quitar: el agente no estaba instalado.'
        }
        return
    }

    Remove-Current
    foreach ($dir in 'envinit', 'agents', 'skills') {
        New-Item -ItemType Directory -Force -Path (Join-Path $script:ToolDir $dir) | Out-Null
    }
    Copy-Item -LiteralPath (Join-Path $AgentSrc 'AGENT.md') -Destination (Join-Path $script:ToolDir 'envinit\AGENT.md')
    Copy-Item -LiteralPath (Join-Path $AgentSrc "adapters\$adapter\envinit.md") -Destination (Join-Path $script:ToolDir 'agents\envinit.md')
    foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $AgentSrc 'skills') -Directory -Filter 'envinit-*') {
        Copy-Item -LiteralPath $skill.FullName -Destination (Join-Path $script:ToolDir 'skills') -Recurse
    }

    Add-Summary "  Archivos en: $script:ToolDir"
    if ($script:RemovedLegacy.Count -gt 0) {
        Add-Summary '  Se quitó la versión anterior (env-initializer):'
        foreach ($item in $script:RemovedLegacy) { Add-Summary "    $item" }
    }
    if ($Name -eq 'claude') {
        Add-Summary '  Para usarlo: abre Claude Code en la raíz del proyecto y escribe @envinit.'
    } else {
        Add-Summary '  Para usarlo: abre opencode en la raíz del proyecto y presiona Tab hasta que aparezca envinit.'
    }
}

# --- Validaciones y preguntas (antes de escribir nada) -------------------------

if (-not (Test-Path -LiteralPath $AgentSrc -PathType Container)) {
    Fail "no se encontró la carpeta del agente en $AgentSrc."
}

if ($Tool) { Set-ToolsFromArgs $Tool }

if ($Target) {
    $check = Test-Target $Target
    if (-not $check.Path) {
        if ($check.Error -like '*repositorio*') { Fail $check.Error }
        Fail "el proyecto '$Target' no existe o no es una carpeta."
    }
    $Target = $check.Path
} elseif (Test-Interactive) {
    $Target = Read-Target
    $script:Asked = $true
} else {
    Fail 'falta -Target: indica la ruta del proyecto.'
}

if (-not $script:WantClaude -and -not $script:WantOpenCode) {
    if (Test-Interactive) {
        Read-Tools
        $script:Asked = $true
    } else {
        Fail 'falta -Tool: indica claude, opencode o claude,opencode.'
    }
}

$Tools = @()
if ($script:WantClaude) { $Tools += 'claude' }
if ($script:WantOpenCode) { $Tools += 'opencode' }

if ($script:Asked) { Confirm-Action }

# --- Instalar o desinstalar ---------------------------------------------------

foreach ($name in $Tools) { Invoke-Tool $name }

Write-Host ''
if ($Uninstall) {
    Write-Host 'Listo: terminó la desinstalación del agente envinit.'
} else {
    Write-Host 'Listo: se instaló el agente envinit.'
}
Write-Host "  Proyecto: $Target"
foreach ($line in $script:Summary) { Write-Host $line }
if ($Uninstall) {
    Write-Host ''
    Write-Host 'La carpeta env-local/ del proyecto (tu entorno) no se tocó.'
}
