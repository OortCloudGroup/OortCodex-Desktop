# oortcodex-cli one-click installer (PowerShell entry point)
#
# Editing rules for this file:
#   1. This script deliberately does NOT use a `param()` block. Reason: a UTF-8 BOM at the very
#      start of the file breaks `param()` when the script is piped in with `irm <url> | iex`,
#      because static hosts usually return application/octet-stream and PowerShell 5.1 then
#      decodes the bytes one by one, turning the BOM into three visible characters in front of
#      `param`. `param()` must be the first statement, so the whole script fails to parse
#      ("The assignment expression is not valid"). Parsing $args by hand makes the script
#      BOM-tolerant: a copy that accidentally carries a BOM still runs.
#      All Chinese user-facing messages are printed by install-cli.mjs (Node reads UTF-8).
#   2. Never call `exit` unconditionally: with `irm | iex` it would close the user's shell.
#      The exit code is only returned when the script runs from a file ($PSCommandPath).
#
# Usage:
#   .\install-cli.ps1
#   .\install-cli.ps1 -Version 0.0.2
#   irm https://myoumuamua.com/mystatic/aistudio/scripts/install-cli.ps1 | iex

# Force UTF-8 console output so the Chinese messages from install-cli.mjs are not garbled
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {
    # Some hosts do not allow changing the encoding, ignore it
}

# Defaults: environment variables first, then built-in values
$OortVersion = if ($env:OORTCODEX_CLI_VERSION) { $env:OORTCODEX_CLI_VERSION } else { '0.0.1' }
$OortNodeVersion = if ($env:OORTCODEX_NODE_VERSION) { $env:OORTCODEX_NODE_VERSION } else { '24.14.0' }
$OortScriptsBase = if ($env:OORTCODEX_SCRIPTS_BASE_URL) { $env:OORTCODEX_SCRIPTS_BASE_URL } else { '' }
$OortCache = if ($env:OORTCODEX_NPM_CACHE) { $env:OORTCODEX_NPM_CACHE } else { '' }
$OortAutoInstallNode = $false
$OortAllowNewerNode = $false
$OortSkipUrlCheck = $false
$OortDryRun = $false

# Manual argument parsing (see rule 1 above: no `param()` block on purpose)
# Accepts both "--version 0.0.2" and "--version=0.0.2"
for ($i = 0; $i -lt $args.Count; $i++) {
    $raw = [string]$args[$i]
    $name = $raw
    $value = ''
    $eqIndex = $raw.IndexOf('=')
    if ($eqIndex -gt 0) {
        $name = $raw.Substring(0, $eqIndex)
        $value = $raw.Substring($eqIndex + 1)
    }
    if (-not $value) {
        if (($i + 1) -lt $args.Count) {
            $candidate = [string]$args[$i + 1]
            if ($candidate -notmatch '^-') {
                $value = $candidate
                $i++
            }
        }
    }
    switch ($name) {
        '--version' { if ($value) { $OortVersion = $value } }
        '-Version' { if ($value) { $OortVersion = $value } }
        '--node-version' { if ($value) { $OortNodeVersion = $value } }
        '-NodeVersion' { if ($value) { $OortNodeVersion = $value } }
        '--scripts-base' { if ($value) { $OortScriptsBase = $value } }
        '-ScriptsBase' { if ($value) { $OortScriptsBase = $value } }
        '--cache' { if ($value) { $OortCache = $value } }
        '-Cache' { if ($value) { $OortCache = $value } }
        '--auto-install-node' { $OortAutoInstallNode = $true }
        '-AutoInstallNode' { $OortAutoInstallNode = $true }
        '--allow-newer-node' { $OortAllowNewerNode = $true }
        '-AllowNewerNode' { $OortAllowNewerNode = $true }
        '--skip-url-check' { $OortSkipUrlCheck = $true }
        '-SkipUrlCheck' { $OortSkipUrlCheck = $true }
        '--dry-run' { $OortDryRun = $true }
        '-DryRun' { $OortDryRun = $true }
        default {
            if ($raw) { Write-Host "[oortcodex] ignoring unknown argument: $raw" }
        }
    }
}

# Browser UA: some code hosts (e.g. GitCode raw) reject non-browser agents
$scriptUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

# Download install-cli.mjs from remote sources, skipping HTML pages and error text
function Get-RemoteCoreScript {
    param(
        [string[]]$BaseUrls,
        [string]$UserAgent,
        [string]$LogPrefix
    )

    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

    $targetDir = Join-Path $env:TEMP 'oortcodex-cli-install'
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $target = Join-Path $targetDir 'install-cli.mjs'

    foreach ($base in $BaseUrls) {
        if (-not $base) { continue }
        $url = $base.TrimEnd('/') + '/install-cli.mjs'

        # Retry each source twice: GitCode raw returns 403 occasionally (rate limiting)
        foreach ($attempt in 1..2) {
            Write-Host "$LogPrefix downloading core script (attempt $attempt): $url"
            try {
                Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing -TimeoutSec 60 `
                    -UserAgent $UserAgent -ErrorAction Stop
            }
            catch {
                Start-Sleep -Seconds 2
                continue
            }
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $head = (Get-Content -LiteralPath $target -TotalCount 5 -ErrorAction SilentlyContinue) -join "`n"
                if ($head -and $head -notmatch '<!DOCTYPE html|<html') {
                    return $target
                }
            }
            Start-Sleep -Seconds 2
        }
    }
    return $null
}

# Reload PATH so a Node installed by winget becomes visible immediately
function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $combined = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'
    if ($combined) {
        $env:Path = $combined
    }
}

# Print how to install the required Node version (used when Node is missing, core script cannot run yet)
function Show-NodeGuide {
    param([string]$RequiredVersion, [string]$LogPrefix)

    Write-Host "$LogPrefix Node.js $RequiredVersion is required. Install it first:"
    Write-Host "  winget install OpenJS.NodeJS --version $RequiredVersion --exact"
    Write-Host "  nvm-windows: nvm install $RequiredVersion && nvm use $RequiredVersion"
    Write-Host "  or download: https://nodejs.org/dist/v$RequiredVersion/"
    Write-Host "$LogPrefix Re-run this script afterwards, or pass -AutoInstallNode."
}

# Install the given Node version with winget
function Install-NodeByWinget {
    param([string]$RequiredVersion, [string]$LogPrefix)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "$LogPrefix winget is not available."
        return $false
    }
    Write-Host "$LogPrefix installing Node.js $RequiredVersion with winget ..."
    # Pipe stdout to Out-Host: native stdout must not leak into the function return value
    & winget install OpenJS.NodeJS --version $RequiredVersion --exact --accept-package-agreements --accept-source-agreements | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$LogPrefix winget exited with code $LASTEXITCODE."
        return $false
    }
    Refresh-Path
    return $true
}

# Main flow: locate the core script, make sure Node exists, then let the core script do the rest
function Invoke-OortCodexInstall {
    # Do NOT set $ErrorActionPreference = 'Stop' here: in PowerShell 5.1 a native command
    # writing to stderr then raises a terminating error and the node exit code is lost.
    # Call that must abort (Invoke-WebRequest) already carry -ErrorAction Stop.
    $LogPrefix = '[oortcodex]'

    # Script sources: custom one first, then the static host, then backups
    $bases = @()
    if ($OortScriptsBase) { $bases += $OortScriptsBase }
    $bases += @(
        'https://myoumuamua.com/mystatic/aistudio/scripts/',
        'https://raw.gitcode.com/OortCloudGroup/OortCodex-Desktop/raw/main/scripts/',
        'https://raw.githubusercontent.com/OortCloudGroup/OortCodex-Desktop/main/scripts/',
        'https://cdn.jsdelivr.net/gh/OortCloudGroup/OortCodex-Desktop@main/scripts/'
    )

    # Step 1: locate install-cli.mjs, locally first; remote fetch when piped (irm | iex)
    $coreScript = ''
    if ($PSScriptRoot) {
        $localCore = Join-Path $PSScriptRoot 'install-cli.mjs'
        if (Test-Path -LiteralPath $localCore -PathType Leaf) {
            $coreScript = $localCore
        }
    }
    if (-not $coreScript) {
        Write-Host "$LogPrefix install-cli.mjs not found locally, fetching from remote ..."
        $coreScript = Get-RemoteCoreScript -BaseUrls $bases -UserAgent $scriptUserAgent -LogPrefix $LogPrefix
    }
    if (-not $coreScript) {
        Write-Host "$LogPrefix failed to fetch install-cli.mjs from all sources."
        Write-Host "$LogPrefix use -ScriptsBase <url> or set OORTCODEX_SCRIPTS_BASE_URL."
        return 1
    }

    # Step 2: make sure Node exists
    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    if (-not $nodeCommand) {
        Write-Host "$LogPrefix Node.js not found."
        if ($OortAutoInstallNode -and (Install-NodeByWinget -RequiredVersion $OortNodeVersion -LogPrefix $LogPrefix)) {
            $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
        }
        if (-not $nodeCommand) {
            Show-NodeGuide -RequiredVersion $OortNodeVersion -LogPrefix $LogPrefix
            return 1
        }
    }

    # Step 3: with -AutoInstallNode, upgrade Node when it does not match.
    # The version check itself is done by the core script, which prints guidance in Chinese.
    if ($OortAutoInstallNode) {
        $currentVersion = (& node --version) -replace '^v', ''
        $matched = ($currentVersion -eq $OortNodeVersion)
        if (-not $matched -and $OortAllowNewerNode) {
            $matched = ([version]$currentVersion -ge [version]$OortNodeVersion)
        }
        if (-not $matched) {
            Write-Host "$LogPrefix Node v$currentVersion found, v$OortNodeVersion required; upgrading ..."
            if (Install-NodeByWinget -RequiredVersion $OortNodeVersion -LogPrefix $LogPrefix) {
                Refresh-Path
            }
        }
    }

    # Step 4: run the core script
    $coreArgs = @(
        "--version=$OortVersion",
        "--node-version=$OortNodeVersion"
    )
    if ($OortCache) { $coreArgs += "--cache=$OortCache" }
    if ($OortAllowNewerNode) { $coreArgs += '--allow-newer-node' }
    if ($OortSkipUrlCheck) { $coreArgs += '--skip-url-check' }
    if ($OortDryRun) { $coreArgs += '--dry-run' }

    Write-Host "$LogPrefix package: oortcodex-cli@$OortVersion"
    # Pipe stdout to Out-Host so it does not leak into the function return value
    # (otherwise the exit code becomes an array and `exit` reports 0).
    # stderr is left alone: merging it with 2>&1 would turn it into error records with extra noise.
    & node $coreScript @coreArgs | Out-Host
    return $LASTEXITCODE
}

$exitCode = Invoke-OortCodexInstall

# Only exit when running from a script file; with `irm | iex` exit would close the user's shell
if ($PSCommandPath) {
    exit $exitCode
}
