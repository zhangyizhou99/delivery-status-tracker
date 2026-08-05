function Test-PostgresBinDirectory {
    param([string]$Path)

    return (
        $Path -and
        (Test-Path -LiteralPath (Join-Path $Path 'psql.exe') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path 'pg_isready.exe') -PathType Leaf)
    )
}

function Resolve-PostgresBinCandidate {
    param([string]$Path)

    if (-not $Path) {
        return $null
    }

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    foreach ($candidate in @($expandedPath, (Join-Path $expandedPath 'bin'))) {
        if (Test-PostgresBinDirectory -Path $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Get-PostgresMajorVersion {
    param([string]$BinDirectory)

    if (-not (Test-PostgresBinDirectory -Path $BinDirectory)) {
        return $null
    }

    $versionOutput = @(& (Join-Path $BinDirectory 'psql.exe') --version 2>$null)
    if ($LASTEXITCODE -ne 0 -or $versionOutput.Count -eq 0) {
        return $null
    }

    $versionMatch = [regex]::Match([string]$versionOutput[-1], '\b(?<major>\d+)(?:\.\d+)?\b')
    if (-not $versionMatch.Success) {
        return $null
    }

    return [int]$versionMatch.Groups['major'].Value
}

function Test-SupportedPostgresMajorVersion {
    param([Nullable[int]]$MajorVersion)

    return $null -ne $MajorVersion -and $MajorVersion -ge 14 -and $MajorVersion -le 18
}

function Assert-SupportedPostgresBinDirectory {
    param([string]$BinDirectory)

    $majorVersion = Get-PostgresMajorVersion -BinDirectory $BinDirectory
    if (-not (Test-SupportedPostgresMajorVersion -MajorVersion $majorVersion)) {
        $foundVersion = if ($null -ne $majorVersion) { $majorVersion } else { 'unknown' }
        throw "PostgreSQL 14 through 18 tools are required; found $foundVersion under $BinDirectory."
    }

    return $majorVersion
}

function Get-PostgresServerMajorVersion {
    param(
        [string]$PsqlExecutable,
        [string]$ServerHost = '127.0.0.1',
        [int]$Port = 5432,
        [string]$Username = 'tracker',
        [string]$Database = 'tracker'
    )

    $versionOutput = @(
        & $PsqlExecutable `
            -h $ServerHost `
            -p $Port `
            -U $Username `
            -d $Database `
            -X `
            -v ON_ERROR_STOP=1 `
            -Atq `
            -c 'SHOW server_version_num' 2>$null
    )
    if ($LASTEXITCODE -ne 0 -or $versionOutput.Count -eq 0) {
        return $null
    }

    $versionNumber = 0
    if (-not [int]::TryParse($versionOutput[-1].Trim(), [ref]$versionNumber)) {
        return $null
    }

    return [int][Math]::Floor($versionNumber / 10000)
}

function Assert-SupportedPostgresServer {
    param([string]$PsqlExecutable)

    $majorVersion = Get-PostgresServerMajorVersion -PsqlExecutable $PsqlExecutable
    if ($null -eq $majorVersion) {
        throw 'Could not inspect the PostgreSQL server version with the tracker account. Run setup and verify the local database credentials.'
    }
    if (-not (Test-SupportedPostgresMajorVersion -MajorVersion $majorVersion)) {
        throw "PostgreSQL server version 14 through 18 is required; found $majorVersion."
    }

    return $majorVersion
}

function Get-RegisteredPostgresInstallations {
    $registryRoots = @(
        'HKLM:\SOFTWARE\PostgreSQL\Installations',
        'HKLM:\SOFTWARE\WOW6432Node\PostgreSQL\Installations'
    )

    foreach ($registryRoot in $registryRoots) {
        if (-not (Test-Path -LiteralPath $registryRoot)) {
            continue
        }

        foreach ($installationKey in Get-ChildItem -LiteralPath $registryRoot -ErrorAction SilentlyContinue) {
            $properties = Get-ItemProperty -LiteralPath $installationKey.PSPath
            $baseDirectoryProperty = $properties.PSObject.Properties['Base Directory']
            $versionProperty = $properties.PSObject.Properties['Version']
            $serviceProperty = $properties.PSObject.Properties['Service ID']
            if (-not $baseDirectoryProperty -or -not $versionProperty) {
                continue
            }

            [pscustomobject]@{
                BinDirectory = Join-Path ([string]$baseDirectoryProperty.Value) 'bin'
                ServiceName = if ($serviceProperty) { [string]$serviceProperty.Value } else { $null }
                Version = [string]$versionProperty.Value
            }
        }
    }
}

function Resolve-PostgresBinDirectory {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        $resolvedPath = Resolve-PostgresBinCandidate -Path $RequestedPath
        if (-not $resolvedPath) {
            throw "PostgreSQL tools were not found under: $RequestedPath"
        }

        $null = Assert-SupportedPostgresBinDirectory -BinDirectory $resolvedPath
        return $resolvedPath
    }

    $unsupportedVersions = @()
    $psqlCommand = Get-Command 'psql.exe' -ErrorAction SilentlyContinue
    if ($psqlCommand) {
        $pathDirectory = Resolve-PostgresBinCandidate -Path (Split-Path -Parent $psqlCommand.Source)
        if ($pathDirectory) {
            $pathMajorVersion = Get-PostgresMajorVersion -BinDirectory $pathDirectory
            if (Test-SupportedPostgresMajorVersion -MajorVersion $pathMajorVersion) {
                return $pathDirectory
            }
            if ($null -ne $pathMajorVersion) {
                $unsupportedVersions += $pathMajorVersion
            }
        }
    }

    $registeredCandidates = @(
        Get-RegisteredPostgresInstallations |
            ForEach-Object {
                $binDirectory = Resolve-PostgresBinCandidate -Path $_.BinDirectory
                if ($binDirectory) {
                    $majorVersion = Get-PostgresMajorVersion -BinDirectory $binDirectory
                    if (Test-SupportedPostgresMajorVersion -MajorVersion $majorVersion) {
                        [pscustomobject]@{
                            BinDirectory = $binDirectory
                            MajorVersion = $majorVersion
                        }
                    }
                    elseif ($null -ne $majorVersion) {
                        $unsupportedVersions += $majorVersion
                    }
                }
            } |
            Sort-Object -Property MajorVersion -Descending
    )
    if ($registeredCandidates.Count -gt 0) {
        return $registeredCandidates[0].BinDirectory
    }

    $detectedText = if ($unsupportedVersions.Count -gt 0) {
        " Detected unsupported major versions: $(@($unsupportedVersions | Select-Object -Unique) -join ', ')."
    }
    else {
        ''
    }
    throw "PostgreSQL 14 through 18 tools were not found.$detectedText Add a compatible bin directory to PATH, set POSTGRES_BIN, or pass -PostgresBin."
}

function Resolve-PostgresServiceName {
    param(
        [string]$RequestedName,
        [string]$BinDirectory
    )

    if ($RequestedName) {
        $requestedService = Get-Service -Name $RequestedName -ErrorAction SilentlyContinue
        if (-not $requestedService) {
            throw "PostgreSQL Windows service was not found: $RequestedName"
        }

        return $requestedService.Name
    }

    $registeredServiceNames = @(
        Get-RegisteredPostgresInstallations |
            Where-Object {
                $registeredBin = Resolve-PostgresBinCandidate -Path $_.BinDirectory
                $registeredBin -and
                    $_.ServiceName -and
                    [string]::Equals(
                        $registeredBin,
                        $BinDirectory,
                        [StringComparison]::OrdinalIgnoreCase
                    )
            } |
            ForEach-Object { $_.ServiceName } |
            Select-Object -Unique
    )
    if ($registeredServiceNames.Count -eq 1) {
        return $registeredServiceNames[0]
    }

    $postgresServices = @(Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue)
    $selectedMajorVersion = Get-PostgresMajorVersion -BinDirectory $BinDirectory
    $versionPattern = "(^|[^0-9])$selectedMajorVersion([^0-9]|$)"
    $versionServices = @($postgresServices | Where-Object { $_.Name -match $versionPattern })
    if ($versionServices.Count -eq 1) {
        return $versionServices[0].Name
    }
    if ($postgresServices.Count -eq 1) {
        return $postgresServices[0].Name
    }

    throw 'PostgreSQL is not ready and its Windows service could not be selected. Start it manually, set POSTGRES_SERVICE, or pass -PostgresService.'
}