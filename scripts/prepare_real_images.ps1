param(
    [string]$InputDir = "data\real_images",
    [int]$Size = 1024
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path "$PSScriptRoot\.."
Set-Location $RepoRoot

$Images = @(
    @{ Input = "building.png"; Output = "building_${Size}.pgm" },
    @{ Input = "portrait.jpg"; Output = "portrait_${Size}.pgm" },
    @{ Input = "texture.png"; Output = "texture_${Size}.pgm" }
)

$Magick = Get-Command magick -ErrorAction SilentlyContinue
if ($Magick) {
    foreach ($Image in $Images) {
        $InputPath = Join-Path $InputDir $Image.Input
        $OutputPath = Join-Path $InputDir $Image.Output
        & magick "$InputPath" -colorspace Gray -resize "${Size}x${Size}!" "$OutputPath"
        Write-Host "$InputPath -> $OutputPath"
    }
    exit 0
}

Write-Host "ImageMagick was not found on PATH. Falling back to Python/Pillow."

$PythonScript = @"
from pathlib import Path
from PIL import Image

root = Path(r"$InputDir")
size = $Size
conversions = [
    ("building.png", f"building_{size}.pgm"),
    ("portrait.jpg", f"portrait_{size}.pgm"),
    ("texture.png", f"texture_{size}.pgm"),
]

for src_name, dst_name in conversions:
    src = root / src_name
    dst = root / dst_name
    image = Image.open(src).convert("L").resize((size, size), Image.Resampling.LANCZOS)
    image.save(dst)
    print(f"{src} -> {dst} ({size}x{size})")
"@

$PythonScript | python -
