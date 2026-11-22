# Launch CosmoBlast with a held joystick direction and screenshot the Stella window.
# Usage: .\tools\snap.ps1 -Hold RF -Out bin\snap_right.png
param([string]$Hold = "F", [string]$Out = "bin\snap.png", [int]$Wait = 4, [string[]]$Extra = @())
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "bin"

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class SnapWin {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@

$p = Start-Process "C:\Program Files\Stella\Stella.exe" -WorkingDirectory $bin `
  -ArgumentList (@("-lc","Joystick","-rc","Joystick","-holdjoy0",$Hold) + $Extra + @("cosmoblast.bin")) -PassThru
Start-Sleep -Seconds $Wait
$p.Refresh()
$h = $p.MainWindowHandle
[void][SnapWin]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 300
$r = New-Object SnapWin+RECT
[void][SnapWin]::GetWindowRect($h, [ref]$r)
$bmp = New-Object System.Drawing.Bitmap ($r.R - $r.L), ($r.B - $r.T)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
$outPath = Join-Path $root $Out
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Stop-Process -Id $p.Id -Force
Write-Host "saved $outPath"
