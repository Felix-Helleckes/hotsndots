# Builds HotsNDots.zip for a manual CurseForge upload.
#
# The addon files live at the repo root, but WoW/CurseForge need a zip whose
# top level is a single "HotsNDots" folder. This script stages the shipped
# files into that folder and zips it. Mirrors the ignore list in .pkgmeta.
#
# Usage:  pwsh -File build.ps1     (or right-click > Run with PowerShell)

$ErrorActionPreference = 'Stop'

$root    = $PSScriptRoot
$name    = 'HotsNDots'
$zipPath = Join-Path $root "$name.zip"
$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("hnd_build_" + [Guid]::NewGuid().ToString('N'))
$dest    = Join-Path $staging $name

# Files that ship inside the addon folder
$include = @(
    'HotsNDots.toc',
    'Core.lua',
    'Nameplates.lua',
    'Bars.lua',
    'Minimap.lua',
    'Options.lua',
    'Icon.tga',
    'README.md',
    'CHANGELOG.md',
    'LICENSE'
)

New-Item -ItemType Directory -Path $dest -Force | Out-Null

foreach ($f in $include) {
    $src = Join-Path $root $f
    if (-not (Test-Path $src)) { throw "Missing required file: $f" }
    Copy-Item $src (Join-Path $dest $f) -Force
}

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $dest -DestinationPath $zipPath
Remove-Item $staging -Recurse -Force

$size = (Get-Item $zipPath).Length
Write-Host "Built $zipPath ($size bytes)" -ForegroundColor Green
Write-Host "Top-level folder in zip: $name/" -ForegroundColor Green
