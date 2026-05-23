param(
    [string]$ImageSizes = "512,1024,2048",
    [string]$FilterSizes = "3,5,7,11",
    [int]$Repeats = 5,
    [int]$Warmups = 1,
    [string]$Versions = "all"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path "$PSScriptRoot\.."
Set-Location $RepoRoot

$Candidates = @(
    ".\build\Release\convolution_benchmark.exe",
    ".\build\convolution_benchmark.exe"
)

$Executable = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Executable) {
    throw "Could not find convolution_benchmark executable. Run scripts/configure_release.ps1 and scripts/build_release.ps1 first."
}

& $Executable `
    --image-sizes $ImageSizes `
    --filter-sizes $FilterSizes `
    --repeats $Repeats `
    --warmups $Warmups `
    --versions $Versions
