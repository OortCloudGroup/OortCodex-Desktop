<#
.SYNOPSIS
    oortcodex-cli 一键安装脚本（PowerShell 入口）

.DESCRIPTION
    校验 Node.js 版本后执行 npm install -g 安装 oortcodex-cli。
    可用变量控制：OORTCODEX_CLI_VERSION（默认 0.0.1）、OORTCODEX_NODE_VERSION（默认 24.14.0）、
    OORTCODEX_CLI_BASE_URL、OORTCODEX_CLI_PKG、OORTCODEX_NODE_MODE。

.EXAMPLE
    .\install-cli.ps1
    .\install-cli.ps1 -Version 0.0.2
    .\install-cli.ps1 -Version 0.0.2 -AutoInstallNode
#>
param(
    [string]$Version = $(if ($env:OORTCODEX_CLI_VERSION) { $env:OORTCODEX_CLI_VERSION } else { '0.0.1' }),
    [string]$NodeVersion = $(if ($env:OORTCODEX_NODE_VERSION) { $env:OORTCODEX_NODE_VERSION } else { '24.14.0' }),
    [string]$ScriptsBase = $(if ($env:OORTCODEX_SCRIPTS_BASE_URL) { $env:OORTCODEX_SCRIPTS_BASE_URL } else { '' }),
    [switch]$AutoInstallNode,
    [switch]$AllowNewerNode,
    [switch]$SkipUrlCheck,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$LogPrefix = '[oortcodex]'

# 统一控制台编码为 UTF-8，保证核心脚本输出的中文不乱码（PowerShell 5.1 默认按 GBK 解码）
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {
    # 部分宿主不支持设置编码，忽略即可
}

# 部分代码托管平台（如 GitCode raw）会拒绝非浏览器 UA，统一使用浏览器 UA 下载
$scriptUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

# 远程脚本源：本地无核心脚本时按序尝试，可用 -ScriptsBase 或 OORTCODEX_SCRIPTS_BASE_URL 指定首选源
$scriptBases = @()
if ($ScriptsBase) { $scriptBases += $ScriptsBase }
$scriptBases += @(
    'https://myoumuamua.com/mystatic/aistudio/scripts/',
    'https://raw.gitcode.com/OortCloudGroup/OortCodex-Desktop/raw/main/scripts/',
    'https://raw.githubusercontent.com/OortCloudGroup/OortCodex-Desktop/main/scripts/',
    'https://cdn.jsdelivr.net/gh/OortCloudGroup/OortCodex-Desktop@main/scripts/'
)

# 从远程源下载核心脚本 install-cli.mjs（排除 HTML 登录页等伪装响应）
function Get-RemoteCoreScript {
    param([string[]]$BaseUrls)

    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

    $targetDir = Join-Path $env:TEMP 'oortcodex-cli-install'
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $target = Join-Path $targetDir 'install-cli.mjs'

    foreach ($base in $BaseUrls) {
        if (-not $base) { continue }
        $url = $base.TrimEnd('/') + '/install-cli.mjs'

        # 每个源最多重试 2 次，应对 GitCode raw 偶发的 403 限流
        foreach ($attempt in 1..2) {
            Write-Host "$LogPrefix 尝试下载（第 $attempt 次）：$url"
            try {
                Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing -TimeoutSec 60 `
                    -UserAgent $scriptUserAgent -ErrorAction Stop
            }
            catch {
                Start-Sleep -Seconds 2
                continue
            }
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                $head = (Get-Content -LiteralPath $target -TotalCount 5 -ErrorAction SilentlyContinue) -join "`n"
                # 排除 HTML 登录页与「暂不支持预览」等伪装响应
                if ($head -and $head -notmatch '<!DOCTYPE html|<html|暂不支持预览') {
                    return $target
                }
            }
            Start-Sleep -Seconds 2
        }
    }
    return $null
}

# 优先使用本地核心脚本；管道执行（irm | iex）时自动从远程获取
$coreScript = ''
if ($PSScriptRoot) {
    $localCore = Join-Path $PSScriptRoot 'install-cli.mjs'
    if (Test-Path -LiteralPath $localCore -PathType Leaf) {
        $coreScript = $localCore
    }
}
if (-not $coreScript) {
    Write-Host "$LogPrefix 本地未找到 install-cli.mjs，尝试从远程获取 ..."
    $coreScript = Get-RemoteCoreScript -BaseUrls $scriptBases
}
if (-not $coreScript) {
    Write-Error "$LogPrefix 无法获取核心脚本，请用 -ScriptsBase 指定脚本所在目录"
    exit 1
}

# 重新加载 PATH，便于 winget/nvm 刚安装完的 Node 立即生效
function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $combined = (@($machinePath, $userPath) | Where-Object { $_ }) -join ';'
    if ($combined) {
        $env:Path = $combined
    }
}

# 输出安装指定版本 Node 的指引
function Show-NodeGuide {
    param([string]$RequiredVersion)

    Write-Host "$LogPrefix 请先安装 Node.js $RequiredVersion："
    Write-Host "  winget install OpenJS.NodeJS --version $RequiredVersion --exact"
    Write-Host "  nvm-windows: nvm install $RequiredVersion && nvm use $RequiredVersion"
    Write-Host "  或手动下载：https://nodejs.org/dist/v$RequiredVersion/"
    Write-Host "$LogPrefix 安装完成后重新执行本脚本，或加 -AutoInstallNode 由脚本自动安装"
}

# 使用 winget 自动安装指定版本 Node
function Install-NodeByWinget {
    param([string]$RequiredVersion)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return $false
    }
    Write-Host "$LogPrefix 使用 winget 安装 Node.js $RequiredVersion ..."
    & winget install OpenJS.NodeJS --version $RequiredVersion --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$LogPrefix winget 安装未完成，退出码 $LASTEXITCODE"
        return $false
    }
    Refresh-Path
    return $true
}

# 步骤一：检查 Node 是否存在
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCommand) {
    Write-Host "$LogPrefix 未检测到 Node.js。"
    if ($AutoInstallNode -and (Install-NodeByWinget -RequiredVersion $NodeVersion)) {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
    }
    if (-not $nodeCommand) {
        Show-NodeGuide -RequiredVersion $NodeVersion
        exit 1
    }
}

# 步骤二：检查 Node 版本
$currentVersion = (& node --version) -replace '^v', ''
Write-Host "$LogPrefix 当前 Node v$currentVersion，要求 $NodeVersion"

$versionMatched = ($currentVersion -eq $NodeVersion)
if (-not $versionMatched -and $AllowNewerNode) {
    $versionMatched = ([version]$currentVersion -ge [version]$NodeVersion)
}

if (-not $versionMatched) {
    Write-Host "$LogPrefix Node 版本不匹配：当前 v$currentVersion，要求 $NodeVersion"
    if ($AutoInstallNode -and (Install-NodeByWinget -RequiredVersion $NodeVersion)) {
        $currentVersion = (& node --version) -replace '^v', ''
        $versionMatched = ($currentVersion -eq $NodeVersion)
        Write-Host "$LogPrefix 安装后 Node 版本：v$currentVersion"
    }
    if (-not $versionMatched) {
        Show-NodeGuide -RequiredVersion $NodeVersion
        Write-Host "$LogPrefix 如需放宽限制，请加 -AllowNewerNode"
        exit 1
    }
}

# 步骤三：调用核心脚本执行安装
$coreArgs = @(
    "--version=$Version",
    "--node-version=$NodeVersion"
)
if ($AllowNewerNode) { $coreArgs += '--allow-newer-node' }
if ($SkipUrlCheck) { $coreArgs += '--skip-url-check' }
if ($DryRun) { $coreArgs += '--dry-run' }

Write-Host "$LogPrefix 安装包：oortcodex-cli@$Version"
& node $coreScript @coreArgs
exit $LASTEXITCODE
