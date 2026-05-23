Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\tool_paths.ps1"

$RepoRoot = Resolve-Path "$PSScriptRoot\.."
Set-Location $RepoRoot

$VsDevCmd = Get-VsDevCmdPath
if ($VsDevCmd) {
    cmd /c "`"$VsDevCmd`" -arch=x64 && cmake --build build --config Release"
} else {
    cmake --build build --config Release
}
