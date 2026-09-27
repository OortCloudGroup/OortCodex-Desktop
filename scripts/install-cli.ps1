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

$coreScript = Join-Path $PSScriptRoot 'install-cli.mjs'

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

if (-not (Test-Path -LiteralPath $coreScript -PathType Leaf)) {
    Write-Error "$LogPrefix 找不到核心脚本：$coreScript"
    exit 1
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
