param(
    [Parameter(Mandatory = $true)]
    [string]$RuntimeFolder
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runtime = (Resolve-Path -LiteralPath $RuntimeFolder).Path
$required = @(
    'ReShade64.dll',
    'ReShade64.json',
    'standalone-dlssnr.addon64',
    'nvngx.dll',
    'nvngx_dlss.dll'
)
$optional = @('nvngx_dlssnr.dll')

foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $runtime $name) -PathType Leaf)) {
        throw "Missing required runtime file: $name"
    }
}

$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'nvidia-dlss'
$archive = Join-Path $dist 'forza-reimagined-dlss-local.zip'
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$textFiles = @(
    'mod.json',
    'README.md',
    'ReShade.ini',
    'ReShadePreset.ini',
    'ReShade64.json',
    'LICENSE',
    'NOTICE',
    'THIRD_PARTY_NOTICES.md'
)
foreach ($name in $textFiles) {
    Copy-Item -LiteralPath (Join-Path $root $name) -Destination $stage -Force
}
foreach ($name in $required + $optional) {
    $source = Join-Path $runtime $name
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        Copy-Item -LiteralPath $source -Destination $stage -Force
    }
}
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'shaders') | Out-Null
if (Test-Path -LiteralPath $archive) {
    Remove-Item -LiteralPath $archive
}
Compress-Archive -Path $stage -DestinationPath $archive -CompressionLevel Optimal
Write-Output $archive
