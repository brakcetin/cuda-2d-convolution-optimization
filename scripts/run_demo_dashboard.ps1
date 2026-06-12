param(
    [int]$Port = 5000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$DemoRoot = Join-Path $RepoRoot "demo_app"

if (-not (Test-Path (Join-Path $DemoRoot "server.py"))) {
    throw "Could not find demo_app\server.py."
}

Write-Host "Starting CUDA convolution demo dashboard..."
Write-Host "URL: http://127.0.0.1:$Port"
Write-Host "Press Ctrl+C to stop."

Push-Location $DemoRoot
try {
    $env:FLASK_RUN_PORT = "$Port"
    python server.py
}
finally {
    Pop-Location
}
