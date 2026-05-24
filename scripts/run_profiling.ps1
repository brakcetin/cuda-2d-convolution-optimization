param(
    [string]$OutputDir = "results\profiling",
    [switch]$SkipExport,
    [switch]$ContinueOnError
)

$ErrorActionPreference = "Stop"

function Find-BenchmarkExecutable {
    $candidates = @(
        ".\build\Release\convolution_benchmark.exe",
        ".\build\convolution_benchmark.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "Could not find convolution_benchmark executable. Run scripts/configure_release.ps1 and scripts/build_release.ps1 first."
}

function Restore-OfficialResults {
    $copies = @(
        @{ Source = "results\timing_results_gtx1650_official.csv"; Destination = "results\timing_results.csv" },
        @{ Source = "results\correctness_results_gtx1650_official.csv"; Destination = "results\correctness_results.csv" },
        @{ Source = "results\summary_best_versions_gtx1650_official.csv"; Destination = "results\summary_best_versions.csv" }
    )

    foreach ($copy in $copies) {
        if (Test-Path $copy.Source) {
            Copy-Item $copy.Source $copy.Destination -Force
        }
    }
}

$ncu = Get-Command ncu -ErrorAction SilentlyContinue
if (-not $ncu) {
    throw "Nsight Compute CLI (ncu) was not found on PATH."
}

$benchmarkExe = Find-BenchmarkExecutable
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$cases = @(
    @{
        Name = "separable_4096_gaussian_11_32x8"
        Args = @("--image-sizes", "4096",
                 "--filter-sizes", "11",
                 "--filter-types", "gaussian",
                 "--block-sizes", "32x8",
                 "--repeats", "5",
                 "--warmups", "1",
                 "--versions", "cuda_separable")
    },
    @{
        Name = "shared_constant_4096_sobel_11_32x16"
        Args = @("--image-sizes", "4096",
                 "--filter-sizes", "11",
                 "--filter-types", "sobel",
                 "--block-sizes", "32x16",
                 "--repeats", "5",
                 "--warmups", "1",
                 "--versions", "cuda_shared_constant_filter")
    },
    @{
        Name = "direct_compare_1024_sobel_7"
        Args = @("--image-sizes", "1024",
                 "--filter-sizes", "7",
                 "--filter-types", "sobel",
                 "--block-sizes", "16x16,32x8",
                 "--repeats", "3",
                 "--warmups", "1",
                 "--versions", "cuda_naive_global_memory,cuda_shared_memory_tiled,cuda_shared_constant_filter,cuda_multi_output,cuda_register_tiled")
    }
)

Write-Host "Using Nsight Compute: $($ncu.Source)"
Write-Host "Using benchmark executable: $benchmarkExe"
Write-Host "Writing profiling logs to: $OutputDir"

try {
    foreach ($case in $cases) {
        $logFile = Join-Path $OutputDir "$($case.Name).txt"
        $exportBase = Join-Path $OutputDir $case.Name

        $ncuArgs = @("--set", "full",
                    "--target-processes", "all",
                    "--log-file", $logFile)

        if (-not $SkipExport) {
            $ncuArgs += @("--export", $exportBase, "--force-overwrite")
        }

        $ncuArgs += $benchmarkExe
        $ncuArgs += $case.Args

        Write-Host ""
        Write-Host "Profiling case: $($case.Name)"
        & ncu @ncuArgs
        if ($LASTEXITCODE -ne 0) {
            $message = "ncu failed for case $($case.Name) with exit code $LASTEXITCODE."
            if ($ContinueOnError) {
                Write-Warning $message
            } else {
                throw $message
            }
        }
    }
}
finally {
    Restore-OfficialResults
    Write-Host ""
    Write-Host "Official GTX 1650 CSV files restored after profiling."
}
