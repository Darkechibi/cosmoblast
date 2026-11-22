# Run CosmoBlast for a long time in one Stella session and take periodic screenshot pairs.
# A pair 1 second apart that is pixel-identical during play suggests a freeze.
# Usage: .\tools\soak.ps1 -Hold F -Minutes 3 -Every 20
param([string]$Hold = "F", [int]$Minutes = 3, [int]$Every = 20, [string]$Prefix = "soak")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "bin"

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SoakWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@

function Grab($h, $path) {
  [void][SoakWin]::SetForegroundWindow($h)
  Start-Sleep -Milliseconds 200
  $r = New-Object SoakWin+RECT
  [void][SoakWin]::GetWindowRect($h, [ref]$r)
  $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

function Same($a, $b) {
  $x = [System.Drawing.Bitmap]::FromFile($a); $y = [System.Drawing.Bitmap]::FromFile($b)
  $same = $true
  for ($py = 40; $py -lt $x.Height - 20 -and $same; $py += 7) {
    for ($px = 10; $px -lt $x.Width - 10; $px += 7) {
      if ($x.GetPixel($px, $py) -ne $y.GetPixel($px, $py)) { $same = $false; break }
    }
  }
  $x.Dispose(); $y.Dispose()
  return $same
}

$p = Start-Process "C:\Program Files\Stella\Stella.exe" -WorkingDirectory $bin `
  -ArgumentList "-lc","Joystick","-rc","Joystick","-holdjoy0",$Hold,"cosmoblast.bin" -PassThru
Start-Sleep -Seconds 3
$p.Refresh(); $h = $p.MainWindowHandle
$end = (Get-Date).AddMinutes($Minutes); $i = 0
while ((Get-Date) -lt $end) {
  Start-Sleep -Seconds $Every
  if ($p.HasExited) { Write-Host "Stella exited"; break }
  $a = Join-Path $bin ("{0}_{1}a.png" -f $Prefix, $i); $b = Join-Path $bin ("{0}_{1}b.png" -f $Prefix, $i)
  Grab $h $a; Start-Sleep -Seconds 1; Grab $h $b
  Write-Host ("{0}: {1}" -f $i, $(if (Same $a $b) { "IDENTICAL (possible freeze)" } else { "moving" }))
  $i++
}
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
