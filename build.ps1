# CosmoBlast build script — produces a real Atari 2600 .bin ROM
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$bb = Join-Path $root "tools\bB\bB"
$src = Join-Path $root "src\cosmoblast.bas"
$outDir = Join-Path $root "bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$wasm = Get-Command wasmtime -ErrorAction SilentlyContinue
if (-not $wasm) {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [System.Environment]::GetEnvironmentVariable("Path","User")
  $wasm = Get-Command wasmtime -ErrorAction SilentlyContinue
}
if (-not $wasm) { throw "wasmtime not found. Install: winget install BytecodeAlliance.Wasmtime.Portable" }

$env:bB = $bb
Push-Location $outDir
try {
  Copy-Item $src -Destination ".\cosmoblast.bas" -Force
  Remove-Item ".\cosmoblast.bas.bin", ".\cosmoblast.bin" -ErrorAction SilentlyContinue
  & cmd /c "`"$bb\2600bas.bat`" cosmoblast.bas"
  if (-not (Test-Path ".\cosmoblast.bas.bin")) {
    throw "Build failed - cosmoblast.bas.bin was not created."
  }
  $size = (Get-Item ".\cosmoblast.bas.bin").Length
  if ($size -ne 4096) {
    throw "Build failed - ROM too small ($size bytes). Check assembler errors above."
  }
  Copy-Item ".\cosmoblast.bas.bin" ".\cosmoblast.bin" -Force
  Copy-Item $src (Join-Path $root "src\last_good.bas") -Force
  Write-Host ""
  Write-Host ("OK: bin\cosmoblast.bin (" + $size + " bytes)")
  Write-Host "Open that file in the Stella emulator."
} finally {
  Pop-Location
}
