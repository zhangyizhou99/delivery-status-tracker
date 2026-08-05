function Assert-SupportedPowerShell {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'These scripts currently support Windows only.'
    }
    if ($PSVersionTable.PSVersion -lt [version]'5.1') {
        throw "PowerShell 5.1 or newer is required; found $($PSVersionTable.PSVersion)."
    }
}

function Resolve-ExecutablePath {
    param([string]$Value)

    if (-not $Value) {
        return $null
    }

    $expandedValue = [Environment]::ExpandEnvironmentVariables($Value)
    if (Test-Path -LiteralPath $expandedValue -PathType Leaf) {
        return (Resolve-Path -LiteralPath $expandedValue).Path
    }

    $command = Get-Command $expandedValue -ErrorAction SilentlyContinue
    if ($command -and $command.Source) {
        return $command.Source
    }

    return $null
}

function Get-PythonRuntimeVersion {
    param(
        [string]$Executable,
        [string[]]$PrefixArguments = @()
    )

    $versionOutput = @(
        & $Executable @PrefixArguments -c 'import sys; print(*sys.version_info[:3])' 2>$null
    )
    if ($LASTEXITCODE -ne 0 -or $versionOutput.Count -eq 0) {
        return $null
    }

    $versionParts = @($versionOutput[-1].Trim() -split '\s+')
    if ($versionParts.Count -ne 3) {
        return $null
    }

    try {
        return [version]::new(
            [int]$versionParts[0],
            [int]$versionParts[1],
            [int]$versionParts[2]
        )
    }
    catch {
        return $null
    }
}

function Test-SupportedPythonVersion {
    param([version]$Version)

    return (
        $Version -and
        $Version.Major -eq 3 -and
        $Version.Minor -ge 11 -and
        $Version.Minor -le 14
    )
}

function Resolve-PythonRuntime {
    param([string]$RequestedExecutable)

    $candidates = @()
    if ($RequestedExecutable) {
        $resolvedExecutable = Resolve-ExecutablePath -Value $RequestedExecutable
        if (-not $resolvedExecutable) {
            throw "Python executable was not found: $RequestedExecutable"
        }

        if ((Split-Path -Leaf $resolvedExecutable) -ieq 'py.exe') {
            foreach ($minorVersion in 14..11) {
                $candidates += [pscustomobject]@{
                    Executable = $resolvedExecutable
                    PrefixArguments = @("-3.$minorVersion")
                }
            }
        }
        else {
            $candidates += [pscustomobject]@{
                Executable = $resolvedExecutable
                PrefixArguments = @()
            }
        }
    }
    else {
        $pythonLauncher = Resolve-ExecutablePath -Value 'py.exe'
        if ($pythonLauncher) {
            foreach ($minorVersion in 14..11) {
                $candidates += [pscustomobject]@{
                    Executable = $pythonLauncher
                    PrefixArguments = @("-3.$minorVersion")
                }
            }
        }

        foreach ($commandName in @(
            'python.exe',
            'python3.exe',
            'python3.14.exe',
            'python3.13.exe',
            'python3.12.exe',
            'python3.11.exe'
        )) {
            $pythonExecutable = Resolve-ExecutablePath -Value $commandName
            if ($pythonExecutable) {
                $candidates += [pscustomobject]@{
                    Executable = $pythonExecutable
                    PrefixArguments = @()
                }
            }
        }
    }

    $seenCandidates = @{}
    $unsupportedVersions = @()
    foreach ($candidate in $candidates) {
        $candidateKey = "$($candidate.Executable)|$($candidate.PrefixArguments -join ' ')"
        if ($seenCandidates.ContainsKey($candidateKey)) {
            continue
        }
        $seenCandidates[$candidateKey] = $true

        $version = Get-PythonRuntimeVersion `
            -Executable $candidate.Executable `
            -PrefixArguments $candidate.PrefixArguments
        if (Test-SupportedPythonVersion -Version $version) {
            return [pscustomobject]@{
                Executable = $candidate.Executable
                PrefixArguments = [string[]]$candidate.PrefixArguments
                Version = $version
            }
        }
        if ($version) {
            $unsupportedVersions += $version.ToString()
        }
    }

    $detectedText = if ($unsupportedVersions.Count -gt 0) {
        " Detected unsupported versions: $($unsupportedVersions -join ', ')."
    }
    else {
        ''
    }
    throw "Python 3.11 through 3.14 was not found.$detectedText Add Python to PATH, set PYTHON_EXECUTABLE, or pass -PythonExecutable."
}

function Get-NodeRuntimeVersion {
    param([string]$Executable)

    $versionOutput = @(& $Executable --version 2>$null)
    if ($LASTEXITCODE -ne 0 -or $versionOutput.Count -eq 0) {
        return $null
    }

    $versionText = $versionOutput[-1].Trim().TrimStart('v')
    try {
        return [version]$versionText
    }
    catch {
        return $null
    }
}

function Test-SupportedNodeVersion {
    param([version]$Version)

    if (-not $Version) {
        return $false
    }
    if ($Version.Major -eq 20) {
        return $Version -ge [version]'20.19.0'
    }

    return $Version -ge [version]'22.12.0'
}

function Resolve-NodeBinCandidate {
    param([string]$Path)

    if (-not $Path) {
        return $null
    }

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    foreach ($candidate in @($expandedPath, (Join-Path $expandedPath 'bin'))) {
        $nodeExecutable = Join-Path $candidate 'node.exe'
        $npmExecutable = Join-Path $candidate 'npm.cmd'
        if (
            (Test-Path -LiteralPath $nodeExecutable -PathType Leaf) -and
            (Test-Path -LiteralPath $npmExecutable -PathType Leaf)
        ) {
            return [pscustomobject]@{
                NodeExecutable = (Resolve-Path -LiteralPath $nodeExecutable).Path
                NpmExecutable = (Resolve-Path -LiteralPath $npmExecutable).Path
            }
        }
    }

    return $null
}

function Resolve-NodeRuntime {
    param([string]$RequestedBin)

    if ($RequestedBin) {
        $candidate = Resolve-NodeBinCandidate -Path $RequestedBin
        if (-not $candidate) {
            throw "Node.js and npm were not found under: $RequestedBin"
        }
    }
    else {
        $nodeCommand = Get-Command 'node.exe' -ErrorAction SilentlyContinue
        $npmCommand = Get-Command 'npm.cmd' -ErrorAction SilentlyContinue
        if (-not $nodeCommand -or -not $npmCommand) {
            throw 'Node.js and npm were not found. Add them to PATH, set NODE_BIN, or pass -NodeBin.'
        }

        $candidate = [pscustomobject]@{
            NodeExecutable = $nodeCommand.Source
            NpmExecutable = $npmCommand.Source
        }
    }

    $version = Get-NodeRuntimeVersion -Executable $candidate.NodeExecutable
    if (-not (Test-SupportedNodeVersion -Version $version)) {
        $foundVersion = if ($version) { $version.ToString() } else { 'unknown' }
        throw "Node.js ^20.19.0 or >=22.12.0 is required by Vite 8; found $foundVersion."
    }

    return [pscustomobject]@{
        NodeExecutable = $candidate.NodeExecutable
        NpmExecutable = $candidate.NpmExecutable
        Version = $version
    }
}