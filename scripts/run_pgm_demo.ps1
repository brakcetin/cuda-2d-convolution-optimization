param(
    [string]$InputPath = "data\sample_input.pgm",
    [string]$OutputPath = "results\demo_output.pgm",
    [string]$FilterType = "sobel",
    [int]$FilterSize = 3,
    [string]$Version = "cuda_shared_constant_filter",
    [string]$BlockSize = "16x16",
    [string]$NormalizeOutput = "true"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\tool_paths.ps1"

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

New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath) | Out-Null

& $Executable `
    --demo-input $InputPath `
    --demo-output $OutputPath `
    --demo-filter-type $FilterType `
    --demo-filter-size $FilterSize `
    --demo-version $Version `
    --demo-block-size $BlockSize `
    --demo-normalize-output $NormalizeOutput
