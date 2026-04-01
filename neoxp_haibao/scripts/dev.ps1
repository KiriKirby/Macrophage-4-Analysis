param(
    [switch]$SkipInstall,
    [switch]$InspectMain
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")

Set-Location $projectRoot

if (Test-Path Env:ELECTRON_RUN_AS_NODE) {
    Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
}

Write-Host "[dev] project root: $projectRoot"

if (-not $SkipInstall) {
    Write-Host "[dev] npm install"
    npm install
}

$devScript = "dev"
if ($InspectMain) {
    $devScript = "dev:inspect-main"
}

Write-Host "[dev] npm run $devScript"
npm run $devScript
