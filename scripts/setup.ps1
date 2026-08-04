[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$rootDirectory = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $rootDirectory 'backend'
$frontendDirectory = Join-Path $rootDirectory 'frontend'
$pythonExecutable = Join-Path $backendDirectory '.venv\Scripts\python.exe'
$postgresBinDirectory = 'C:\Program Files\PostgreSQL\16\bin'
$psqlExecutable = Join-Path $postgresBinDirectory 'psql.exe'
$pgIsReadyExecutable = Join-Path $postgresBinDirectory 'pg_isready.exe'

function Assert-LastExitCode {
    param([string]$Operation)

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

foreach ($path in @($psqlExecutable, $pgIsReadyExecutable)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required PostgreSQL 16 tool was not found: $path"
    }
}

$pythonLauncher = Get-Command 'py.exe' -ErrorAction SilentlyContinue
if (-not $pythonLauncher) {
    throw 'Python Launcher is required. Install Python 3.12 and ensure py.exe is available.'
}

$nodeExecutable = Get-Command 'node.exe' -ErrorAction SilentlyContinue
$npmExecutable = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
if (-not $nodeExecutable -or -not $npmExecutable) {
    throw 'Node.js and npm are required.'
}

& $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
if ($LASTEXITCODE -ne 0) {
    $postgresService = Get-Service -Name 'postgresql-x64-16' -ErrorAction SilentlyContinue
    if (-not $postgresService) {
        throw 'The PostgreSQL 16 Windows service was not found.'
    }

    if ($postgresService.Status -ne 'Running') {
        Start-Service -Name $postgresService.Name
    }

    & $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
    Assert-LastExitCode 'PostgreSQL readiness check'
}

if (-not (Test-Path -LiteralPath $pythonExecutable)) {
    & $pythonLauncher.Source -3.12 -m venv (Join-Path $backendDirectory '.venv')
    Assert-LastExitCode 'Python 3.12 virtual environment creation'
}

& $pythonExecutable -m pip install --disable-pip-version-check -r (Join-Path $backendDirectory 'requirements.txt')
Assert-LastExitCode 'Backend dependency installation'

if (-not (Test-Path -LiteralPath (Join-Path $frontendDirectory 'package-lock.json'))) {
    throw 'frontend/package-lock.json is required for reproducible installation.'
}

& $npmExecutable.Source --prefix $frontendDirectory ci
Assert-LastExitCode 'Frontend dependency installation'

$applicationConnectionReady = $false
$env:PGPASSWORD = 'tracker'
try {
    & $psqlExecutable -h '127.0.0.1' -p 5432 -U 'tracker' -d 'tracker' -v ON_ERROR_STOP=1 -Atc 'SELECT 1' *> $null
    $applicationConnectionReady = $LASTEXITCODE -eq 0
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

if (-not $applicationConnectionReady) {
    Write-Host 'The local application databases need administrator initialization.' -ForegroundColor Yellow
    $securePassword = Read-Host 'Enter the PostgreSQL postgres password' -AsSecureString
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

    try {
        $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
        $roleSql = @"
DO `$`$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'tracker') THEN
        CREATE ROLE tracker LOGIN PASSWORD 'tracker';
    ELSE
        ALTER ROLE tracker WITH LOGIN PASSWORD 'tracker';
    END IF;
END
`$`$;
"@
        & $psqlExecutable -h '127.0.0.1' -p 5432 -U 'postgres' -d 'postgres' -v ON_ERROR_STOP=1 -c $roleSql
        Assert-LastExitCode 'Application role initialization'

        $existingDatabases = @(
            & $psqlExecutable -h '127.0.0.1' -p 5432 -U 'postgres' -d 'postgres' -v ON_ERROR_STOP=1 -Atc "SELECT datname FROM pg_database WHERE datname IN ('tracker', 'tracker_test')"
        )
        Assert-LastExitCode 'Application database inspection'

        foreach ($databaseName in @('tracker', 'tracker_test')) {
            if ($existingDatabases -notcontains $databaseName) {
                & $psqlExecutable -h '127.0.0.1' -p 5432 -U 'postgres' -d 'postgres' -v ON_ERROR_STOP=1 -c "CREATE DATABASE $databaseName OWNER tracker"
                Assert-LastExitCode "Database creation: $databaseName"
            }
        }
    }
    finally {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
}

Write-Host 'Setup complete.' -ForegroundColor Green