function Add-PathIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathToAdd
    )

    if ((Test-Path $PathToAdd) -and ($env:Path -notlike "*$PathToAdd*")) {
        $env:Path = "$PathToAdd;$env:Path"
    }
}

Add-PathIfExists "C:\Program Files\CMake\bin"

$CudaRoot = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA"
if (Test-Path $CudaRoot) {
    $LatestCuda = Get-ChildItem $CudaRoot -Directory |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($LatestCuda) {
        Add-PathIfExists (Join-Path $LatestCuda.FullName "bin")
    }
}

function Get-VsDevCmdPath {
    $VsWhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $VsWhere)) {
        return $null
    }

    $InstallPath = & $VsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if (-not $InstallPath) {
        return $null
    }

    $VsDevCmd = Join-Path $InstallPath "Common7\Tools\VsDevCmd.bat"
    if (Test-Path $VsDevCmd) {
        return $VsDevCmd
    }

    return $null
}
