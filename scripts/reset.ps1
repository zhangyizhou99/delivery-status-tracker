[CmdletBinding()]
param(
    [string]$PostgresBin = $env:POSTGRES_BIN,
    [string]$PostgresService = $env:POSTGRES_SERVICE,
    [string]$PythonExecutable = $env:PYTHON_EXECUTABLE,
    [string]$NodeBin = $env:NODE_BIN
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'runtime.ps1')
Assert-SupportedPowerShell

$rootDirectory = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $rootDirectory 'backend'
$venvPythonExecutable = Join-Path $backendDirectory '.venv\Scripts\python.exe'

if (-not (Test-Path -LiteralPath $venvPythonExecutable)) {
    $setupParameters = @{}
    if ($PostgresBin) {
        $setupParameters['PostgresBin'] = $PostgresBin
    }
    if ($PostgresService) {
        $setupParameters['PostgresService'] = $PostgresService
    }
    if ($PythonExecutable) {
        $setupParameters['PythonExecutable'] = $PythonExecutable
    }
    if ($NodeBin) {
        $setupParameters['NodeBin'] = $NodeBin
    }
    & (Join-Path $PSScriptRoot 'setup.ps1') @setupParameters
}

$venvPythonVersion = Get-PythonRuntimeVersion -Executable $venvPythonExecutable
if (-not (Test-SupportedPythonVersion -Version $venvPythonVersion)) {
    throw "backend/.venv must use Python 3.11 through 3.14; found $venvPythonVersion. Remove backend/.venv and rerun setup."
}

Push-Location $backendDirectory
try {
    & $venvPythonExecutable -m alembic upgrade head
    if ($LASTEXITCODE -ne 0) {
        throw 'Database migration failed.'
    }

    & $venvPythonExecutable -m app.reset
    if ($LASTEXITCODE -ne 0) {
        throw 'Demo data reset failed.'
    }
}
finally {
    Pop-Location
}

Write-Host 'Demo data restored from data/shipments.csv.' -ForegroundColor Green