# Hammer a CosmoBlast ROM with random rapid keyboard input and watch for freezes.
# Usage: .\tools\fuzz.ps1 -Rom release\CosmoBlast_v1.2.a26 -Minutes 4 -Every 10
param([string]$Rom = "release\CosmoBlast_v1.2.a26", [int]$Minutes = 4, [int]$Every = 10, [string]$Prefix = "fuzz")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "bin"
$romPath = Join-Path $root $Rom

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FuzzWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
}
"@

# virtual key, scan code, extended flag
$keys = @{
  U = @(0x26, 0x48, 1); R = @(0x27, 0x4D, 1); D = @(0x28, 0x50, 1); L = @(0x25, 0x4B, 1); F = @(0x20, 0x39, 0)
}
$down = @{}
function Key($k, [bool]$press) {
  $v = $keys[$k]
  $flags = [uint32]$v[2]
  if (-not $press) { $flags = $flags -bor 2 }
  [FuzzWin]::keybd_event([byte]$v[0], [byte]$v[1], $flags, [UIntPtr]::Zero)
  $down[$k] = $press
}
function SetHeld([string[]]$set) {
  foreach ($k in "U", "R", "D", "L") {
    $want = $set -contains $k
    if ($down[$k] -ne $want) { Key $k $want }
  }
}

function Grab($h, $path) {
  $r = New-Object FuzzWin+RECT
  [void][FuzzWin]::GetWindowRect($h, [ref]$r)
  $bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}

function Same($a, $b) {
  $x = [System.Drawing.Bitmap]::FromFile($a); $y = [System.Drawing.Bitmap]::FromFile($b)
  $same = $true
  for ($py = 40; $py -lt $x.Height - 20 -and $same; $py += 5) {
    for ($px = 10; $px -lt $x.Width - 10; $px += 5) {
      if ($x.GetPixel($px, $py) -ne $y.GetPixel($px, $py)) { $same = $false; break }
    }
  }
  $x.Dispose(); $y.Dispose()
  return $same
}

$p = Start-Process "C:\Program Files\Stella\Stella.exe" -ArgumentList "`"$romPath`"" -PassThru
Start-Sleep -Seconds 3
$p.Refresh(); $h = $p.MainWindowHandle
$rng = New-Object System.Random
$dirs = "U", "R", "D", "L"
$diags = @(@("U", "R"), @("R", "D"), @("D", "L"), @("L", "U"))
$end = (Get-Date).AddMinutes($Minutes)
$nextCheck = (Get-Date).AddSeconds($Every)
$nextFire = Get-Date
$i = 0; $presses = 0; $freezes = 0
while ((Get-Date) -lt $end) {
  if ($p.HasExited) { Write-Host "Stella exited"; break }
  [void][FuzzWin]::SetForegroundWindow($h)
  if ((Get-Date) -ge $nextFire) {
    Key "F" $true; Start-Sleep -Milliseconds 40; Key "F" $false
    $nextFire = (Get-Date).AddSeconds(4)
  }
  $roll = $rng.Next(100)
  if ($roll -lt 55) { SetHeld @($dirs[$rng.Next(4)]) }
  elseif ($roll -lt 85) { SetHeld $diags[$rng.Next(4)] }
  else { SetHeld @() }
  $presses++
  Start-Sleep -Milliseconds ($rng.Next(10, 120))
  if ((Get-Date) -ge $nextCheck) {
    SetHeld @()
    $a = Join-Path $bin ("{0}_{1}a.png" -f $Prefix, $i); $b = Join-Path $bin ("{0}_{1}b.png" -f $Prefix, $i)
    Grab $h $a; Start-Sleep -Milliseconds 1000; Grab $h $b
    $frozen = Same $a $b
    if ($frozen) { $freezes++ }
    Write-Host ("{0}: {1} after {2} inputs" -f $i, $(if ($frozen) { "IDENTICAL (possible freeze)" } else { "moving" }), $presses)
    $i++
    $nextCheck = (Get-Date).AddSeconds($Every)
  }
}
SetHeld @()
Write-Host ("done: {0} random inputs, {1} identical checks" -f $presses, $freezes)
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
