[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$rootDirectory = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $rootDirectory 'backend'
$pythonExecutable = Join-Path $backendDirectory '.venv\Scripts\python.exe'

if (-not (Test-Path -LiteralPath $pythonExecutable)) {
    & (Join-Path $PSScriptRoot 'setup.ps1')
}

Push-Location $backendDirectory
try {
    & $pythonExecutable -m alembic upgrade head
    if ($LASTEXITCODE -ne 0) {
        throw 'Database migration failed.'
    }

    & $pythonExecutable -m app.reset
    if ($LASTEXITCODE -ne 0) {
        throw 'Demo data reset failed.'
    }
}
finally {
    Pop-Location
}

Write-Host 'Demo data restored from data/shipments.csv.' -ForegroundColor Green