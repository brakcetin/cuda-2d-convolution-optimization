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

function Get-MagickCommand {
    $PathCommand = Get-Command magick -ErrorAction SilentlyContinue
    if ($PathCommand) {
        return $PathCommand.Source
    }

    $KnownPath = "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe"
    if (Test-Path $KnownPath) {
        return $KnownPath
    }

    $Installed = Get-ChildItem "C:\Program Files" -Directory -Filter "ImageMagick*" -ErrorAction SilentlyContinue |
        ForEach-Object {
            Get-ChildItem $_.FullName -Filter "magick.exe" -ErrorAction SilentlyContinue
        } |
        Select-Object -First 1

    if ($Installed) {
        return $Installed.FullName
    }

    return $null
}

$Magick = Get-MagickCommand
if ($Magick) {
    Write-Host "Using ImageMagick: $Magick"
    foreach ($Image in $Images) {
        $InputPath = Join-Path $InputDir $Image.Input
        $OutputPath = Join-Path $InputDir $Image.Output
        & $Magick "$InputPath" -colorspace Gray -resize "${Size}x${Size}" "$OutputPath"
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
    image = Image.open(src).convert("L")
    image.thumbnail((size, size), Image.Resampling.LANCZOS)
    image.save(dst)
    print(f"{src} -> {dst} ({image.width}x{image.height}, aspect ratio preserved)")
"@

$PythonScript | python -
