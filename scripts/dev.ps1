[CmdletBinding()]
param(
    [switch]$SmokeTest,
    [ValidateRange(1, 65535)]
    [int]$ApiPort = 8000,
    [ValidateRange(1, 65535)]
    [int]$WebPort = 5173
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$rootDirectory = Split-Path -Parent $PSScriptRoot
$backendDirectory = Join-Path $rootDirectory 'backend'
$frontendDirectory = Join-Path $rootDirectory 'frontend'
$pythonExecutable = Join-Path $backendDirectory '.venv\Scripts\python.exe'
$pgIsReadyExecutable = 'C:\Program Files\PostgreSQL\16\bin\pg_isready.exe'
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

if (-not (Test-Path -LiteralPath $pythonExecutable) -or -not (Test-Path -LiteralPath (Join-Path $frontendDirectory 'node_modules'))) {
    & (Join-Path $PSScriptRoot 'setup.ps1')
}

if (-not (Test-Path -LiteralPath $pgIsReadyExecutable)) {
    throw "PostgreSQL 16 readiness tool was not found: $pgIsReadyExecutable"
}

& $pgIsReadyExecutable -h '127.0.0.1' -p 5432 -q
if ($LASTEXITCODE -ne 0) {
    throw 'PostgreSQL is not accepting connections on localhost:5432. Run ./scripts/setup.ps1 first.'
}

$npmExecutable = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
if (-not $npmExecutable) {
    throw 'npm.cmd was not found.'
}

Push-Location $backendDirectory
try {
    & $pythonExecutable -m alembic upgrade head
    if ($LASTEXITCODE -ne 0) {
        throw 'Database migration failed.'
    }

    & $pythonExecutable -m app.seed
    if ($LASTEXITCODE -ne 0) {
        throw 'Shipment seed failed.'
    }
}
finally {
    Pop-Location
}

$env:API_PORT = $ApiPort.ToString()
$env:WEB_PORT = $WebPort.ToString()
$env:VITE_API_URL = "http://localhost:$ApiPort"

$apiArguments = @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', $ApiPort.ToString())
if (-not $SmokeTest) {
    $apiArguments += '--reload'
}

$webArguments = @('run', 'dev', '--', '--host', '127.0.0.1', '--port', $WebPort.ToString(), '--strictPort')

try {
    $apiProcess = Start-Process -FilePath $pythonExecutable -ArgumentList $apiArguments -WorkingDirectory $backendDirectory -PassThru -NoNewWindow
    Wait-ForHttpEndpoint -Uri "http://127.0.0.1:$ApiPort/api/health" -Process $apiProcess

    $webProcess = Start-Process -FilePath $npmExecutable.Source -ArgumentList $webArguments -WorkingDirectory $frontendDirectory -PassThru -NoNewWindow
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
}