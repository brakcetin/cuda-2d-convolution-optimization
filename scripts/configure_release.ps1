Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\tool_paths.ps1"

$RepoRoot = Resolve-Path "$PSScriptRoot\.."
Set-Location $RepoRoot

$VsDevCmd = Get-VsDevCmdPath
if ($VsDevCmd) {
    cmd /c "`"$VsDevCmd`" -arch=x64 && cmake -S . -B build -G `"NMake Makefiles`" -DCMAKE_BUILD_TYPE=Release"
} else {
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
}
