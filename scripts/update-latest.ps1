param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$ExePath = "G:\lanjian\nginx\html_88_56\OortCloud AI Studio.exe",

    [string]$JsonPath = "latest.json"
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path (Get-Location) $Path
}

try {
    $resolvedExePath = Resolve-ProjectPath -Path $ExePath
    $resolvedJsonPath = Resolve-ProjectPath -Path $JsonPath

    if (-not (Test-Path -LiteralPath $resolvedExePath -PathType Leaf)) {
        throw "exe 文件不存在：$resolvedExePath"
    }

    if (-not (Test-Path -LiteralPath $resolvedJsonPath -PathType Leaf)) {
        throw "latest.json 文件不存在：$resolvedJsonPath"
    }

    $latest = Get-Content -Raw -LiteralPath $resolvedJsonPath | ConvertFrom-Json
    $sha1Hash = (Get-FileHash -LiteralPath $resolvedExePath -Algorithm SHA1).Hash.ToLower()
    $sha256Hash = (Get-FileHash -LiteralPath $resolvedExePath -Algorithm SHA256).Hash.ToLower()
    $timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $productVersion = "$Version.0"

    # 更新发布信息字段
    $latest.url = $latest.url -replace "/download/v[^/]+/", "/download/v$Version/"
    $latest.name = $Version
    $latest.version = $Version
    $latest.productVersion = $productVersion
    $latest.hash = $sha1Hash
    $latest.timestamp = $timestamp
    $latest.sha256hash = $sha256Hash

    $json = $latest | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($resolvedJsonPath, $json, [System.Text.UTF8Encoding]::new($false))

    Write-Host "更新完成：$resolvedJsonPath"
    Write-Host "版本号：$Version"
    Write-Host "productVersion：$productVersion"
    Write-Host "SHA1：$sha1Hash"
    Write-Host "SHA256：$sha256Hash"
    Write-Host "时间戳：$timestamp"
}
catch {
    Write-Error "更新 latest.json 失败：$($_.Exception.Message)"
    exit 1
}
