[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [ValidateRange(1, 65535)]
    [int]$ApiPort = 8000,
    [ValidateRange(1, 65535)]
    [int]$WebPort = 5173,
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
$pgIsReadyExecutable = Join-Path $postgresBinDirectory 'pg_isready.exe'
$psqlExecutable = Join-Path $postgresBinDirectory 'psql.exe'
$apiProcess = $null
$webProcess = $null

function Stop-ProcessTree {
    param([Diagnostics.Process]$Process)

    if ($Process -and -not $Process.HasExited) {
        & taskkill.exe /PID $Process.Id /T /F *> $null
    }
}

function Wait-ForHttpEndpoint {
    param(
        [string]$Uri,
        [Diagnostics.Process]$Process,
        [int]$TimeoutSeconds = 30
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($Process.HasExited) {
            throw "Process $($Process.Id) exited before $Uri became ready."
        }

        try {
            $response = Invoke-WebRequest -Uri $Uri -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                return
            }
        }
        catch {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw
            }
        }

        $null = $Process.WaitForExit(250)
    }

    throw "Timed out waiting for $Uri."
}

if (-not (Test-Path -LiteralPath $venvPythonExecutable) -or -not (Test-Path -LiteralPath (Join-Path $frontendDirectory 'node_modules'))) {
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
$nodeRuntime = Resolve-NodeRuntime -RequestedBin $NodeBin

& $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
if ($LASTEXITCODE -ne 0) {
    $postgresServiceName = Resolve-PostgresServiceName `
        -RequestedName $PostgresService `
        -BinDirectory $postgresBinDirectory
    $postgresWindowsService = Get-Service -Name $postgresServiceName
    if ($postgresWindowsService.Status -ne 'Running') {
        Start-Service -Name $postgresWindowsService.Name
    }

    & $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
    if ($LASTEXITCODE -ne 0) {
        throw 'PostgreSQL is not accepting connections on localhost:5432.'
    }
}

$env:PGPASSWORD = 'tracker'
try {
    $null = Assert-SupportedPostgresServer -PsqlExecutable $psqlExecutable
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

Push-Location $backendDirectory
try {
    & $venvPythonExecutable -m alembic upgrade head
    if ($LASTEXITCODE -ne 0) {
        throw 'Database migration failed.'
    }

    & $venvPythonExecutable -m app.seed
    if ($LASTEXITCODE -ne 0) {
        throw 'Shipment seed failed.'
    }
}
finally {
    Pop-Location
}

$previousApiPort = [Environment]::GetEnvironmentVariable('API_PORT', 'Process')
$previousWebPort = [Environment]::GetEnvironmentVariable('WEB_PORT', 'Process')
$previousViteApiUrl = [Environment]::GetEnvironmentVariable('VITE_API_URL', 'Process')
[Environment]::SetEnvironmentVariable('API_PORT', $ApiPort.ToString(), 'Process')
[Environment]::SetEnvironmentVariable('WEB_PORT', $WebPort.ToString(), 'Process')
[Environment]::SetEnvironmentVariable('VITE_API_URL', "http://localhost:$ApiPort", 'Process')

$apiArguments = @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', $ApiPort.ToString())
if (-not $SmokeTest) {
    $apiArguments += '--reload'
}

$webArguments = @('run', 'dev', '--', '--host', '127.0.0.1', '--port', $WebPort.ToString(), '--strictPort')

try {
    $apiProcess = Start-Process -FilePath $venvPythonExecutable -ArgumentList $apiArguments -WorkingDirectory $backendDirectory -PassThru -NoNewWindow
    Wait-ForHttpEndpoint -Uri "http://127.0.0.1:$ApiPort/api/health" -Process $apiProcess

    $webProcess = Start-Process -FilePath $nodeRuntime.NpmExecutable -ArgumentList $webArguments -WorkingDirectory $frontendDirectory -PassThru -NoNewWindow
    Wait-ForHttpEndpoint -Uri "http://127.0.0.1:$WebPort" -Process $webProcess

    Write-Host "Web UI:   http://localhost:$WebPort" -ForegroundColor Green
    Write-Host "API docs: http://localhost:$ApiPort/docs" -ForegroundColor Green
    Write-Host "Health:   http://localhost:$ApiPort/api/health" -ForegroundColor Green

    if ($SmokeTest) {
        Write-Output 'smoke_test=passed'
        return
    }

    Write-Host 'Press Ctrl+C to stop both services.'
    while (-not $apiProcess.HasExited -and -not $webProcess.HasExited) {
        $null = $apiProcess.WaitForExit(500)
    }

    if ($apiProcess.HasExited) {
        throw "API process exited with code $($apiProcess.ExitCode)."
    }

    throw "Web process exited with code $($webProcess.ExitCode)."
}
finally {
    Stop-ProcessTree -Process $webProcess
    Stop-ProcessTree -Process $apiProcess
    [Environment]::SetEnvironmentVariable('API_PORT', $previousApiPort, 'Process')
    [Environment]::SetEnvironmentVariable('WEB_PORT', $previousWebPort, 'Process')
    [Environment]::SetEnvironmentVariable('VITE_API_URL', $previousViteApiUrl, 'Process')
}