Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Write-Host "[MISSING] $Name was not found on PATH" -ForegroundColor Red
        return $false
    }

    Write-Host "[OK] $Name -> $($command.Source)" -ForegroundColor Green
    return $true
}

$cmakeOk = Test-Command "cmake"
$nvccOk = Test-Command "nvcc"
$nvidiaSmiOk = Test-Command "nvidia-smi"

if ($cmakeOk) {
    cmake --version
}

if ($nvccOk) {
    nvcc --version
}

if ($nvidiaSmiOk) {
    nvidia-smi
}

if (-not ($cmakeOk -and $nvccOk -and $nvidiaSmiOk)) {
    Write-Host "Environment check failed. Install/configure CMake, CUDA Toolkit, and NVIDIA driver tools before benchmarking." -ForegroundColor Red
    exit 1
}

Write-Host "Environment check passed." -ForegroundColor Green
