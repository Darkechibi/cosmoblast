# Launch CosmoBlast in Stella with joystick ports forced
$ErrorActionPreference = "Stop"
$rom = Join-Path $PSScriptRoot "bin\cosmoblast.bin"
$stella = "C:\Program Files\Stella\Stella.exe"
if (-not (Test-Path $rom)) { throw "Missing ROM: $rom - run .\build.ps1 first" }
if (-not (Test-Path $stella)) { throw "Stella not found at $stella" }

# -lc/-rc Joystick: do not treat ports as paddles
# Click the Stella window, then Space to start, arrows to aim
Start-Process $stella -ArgumentList @(
  "-lc", "Joystick",
  "-rc", "Joystick",
  $rom
)

Write-Host "CosmoBlast launched."
Write-Host "Click Stella window, then: Space=start/fire, Arrows=aim"
Write-Host "See CONTROLS.md to map WASD / Xbox 360 pad."
