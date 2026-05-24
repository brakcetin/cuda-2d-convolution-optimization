# Nsight Compute Profiling Logs

These files record the representative Nsight Compute profiling attempt for the GTX 1650 benchmark project.

## Files

- `separable_4096_gaussian_11_32x8.txt`
- `shared_constant_4096_sobel_11_32x16.txt`
- `direct_compare_1024_sobel_7.txt`

## Result

Nsight Compute successfully launched and attached to the benchmark executable, but detailed GPU performance-counter collection was blocked by NVIDIA driver permissions:

```text
ERR_NVGPUCTRPERM - The user does not have permission to access NVIDIA GPU Performance Counters
```

Because of this, no profiler-derived occupancy, memory-throughput, or warp-state metrics are claimed in the final report yet. The official performance analysis remains based on the committed GTX 1650 CSV benchmark files.

## Re-run Command

After enabling NVIDIA GPU performance-counter access, rerun:

```powershell
.\scripts\run_profiling.ps1
```
