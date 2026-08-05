[CmdletBinding()]
param(
    [string]$PostgresBin = $env:POSTGRES_BIN,
    [string]$PostgresService = $env:POSTGRES_SERVICE,
    [string]$PythonExecutable = $env:PYTHON_EXECUTABLE,
    [string]$NodeBin = $env:NODE_BIN
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'postgres.ps1')
. (Join-Path $PSScriptRoot 'runtime.ps1')
Assert-SupportedPowerShell

$rootDirectory = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $rootDirectory 'backend'
$frontendDirectory = Join-Path $rootDirectory 'frontend'
$venvPythonExecutable = Join-Path $backendDirectory '.venv\Scripts\python.exe'
$postgresBinDirectory = Resolve-PostgresBinDirectory -RequestedPath $PostgresBin
$psqlExecutable = Join-Path $postgresBinDirectory 'psql.exe'
$pgIsReadyExecutable = Join-Path $postgresBinDirectory 'pg_isready.exe'

function Assert-LastExitCode {
    param([string]$Operation)

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

$nodeRuntime = Resolve-NodeRuntime -RequestedBin $NodeBin

& $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
if ($LASTEXITCODE -ne 0) {
    $postgresServiceName = Resolve-PostgresServiceName `
        -RequestedName $PostgresService `
        -BinDirectory $postgresBinDirectory
    $postgresService = Get-Service -Name $postgresServiceName

    if ($postgresService.Status -ne 'Running') {
        Start-Service -Name $postgresService.Name
    }

    & $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
    Assert-LastExitCode 'PostgreSQL readiness check'
}

if (-not (Test-Path -LiteralPath $venvPythonExecutable)) {
    $pythonRuntime = Resolve-PythonRuntime -RequestedExecutable $PythonExecutable
    $venvArguments = @($pythonRuntime.PrefixArguments) + @(
        '-m',
        'venv',
        (Join-Path $backendDirectory '.venv')
    )
    & $pythonRuntime.Executable @venvArguments
    Assert-LastExitCode "Python $($pythonRuntime.Version) virtual environment creation"
}

$venvPythonVersion = Get-PythonRuntimeVersion -Executable $venvPythonExecutable
if (-not (Test-SupportedPythonVersion -Version $venvPythonVersion)) {
    throw "backend/.venv must use Python 3.11 through 3.14; found $venvPythonVersion. Remove backend/.venv and rerun setup."
}

& $venvPythonExecutable -m pip install --disable-pip-version-check -r (Join-Path $backendDirectory 'requirements.txt')
Assert-LastExitCode 'Backend dependency installation'

if (-not (Test-Path -LiteralPath (Join-Path $frontendDirectory 'package-lock.json'))) {
    throw 'frontend/package-lock.json is required for reproducible installation.'
}

& $nodeRuntime.NpmExecutable --prefix $frontendDirectory ci
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

$env:PGPASSWORD = 'tracker'
try {
    $postgresServerMajorVersion = Assert-SupportedPostgresServer -PsqlExecutable $psqlExecutable
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

Write-Host "Setup complete with PostgreSQL $postgresServerMajorVersion, Python $venvPythonVersion, and Node.js $($nodeRuntime.Version)." -ForegroundColor Green