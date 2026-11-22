# Play CosmoBlast by reading the Stella window: shoot the closest red target on a firing lane.
# Logs freezes (identical frames 1 s apart) and a narrow (half-size) base, saving screenshots.
# Usage: .\tools\bot.ps1 -Rom release\CosmoBlast_v1.2.a26 -Minutes 5
param([string]$Rom = "release\CosmoBlast_v1.2.a26", [int]$Minutes = 5, [string]$Prefix = "bot")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$bin = Join-Path $root "bin"
$romPath = Join-Path $root $Rom

Add-Type -ReferencedAssemblies System.Drawing @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Collections.Generic;
public class CosmoBot {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);

  static readonly byte[] VK = { 0x26, 0x27, 0x28, 0x25 };   // up right down left
  static readonly byte[] SC = { 0x48, 0x4D, 0x50, 0x4B };
  static void Key(int d, bool down) { keybd_event(VK[d], SC[d], (uint)(1 | (down ? 0 : 2)), UIntPtr.Zero); }
  static void Fire() { keybd_event(0x20, 0x39, 0, UIntPtr.Zero); System.Threading.Thread.Sleep(40); keybd_event(0x20, 0x39, 2, UIntPtr.Zero); }

  static Bitmap Grab(IntPtr h) {
    RECT r; GetWindowRect(h, out r);
    var bmp = new Bitmap(r.R - r.L, r.B - r.T, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(bmp)) g.CopyFromScreen(r.L, r.T, 0, 0, bmp.Size);
    return bmp;
  }

  static byte[] Pixels(Bitmap b, out int stride) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    stride = d.Stride; var buf = new byte[stride * b.Height];
    Marshal.Copy(d.Scan0, buf, 0, buf.Length); b.UnlockBits(d); return buf;
  }

  static long Hash(byte[] p, int stride, int w, int h) {
    long s = 17;
    for (int y = 40; y < h - 20; y += 4) for (int x = 10; x < w - 10; x += 4) { int i = y * stride + x * 4; s = s * 31 + p[i] + p[i + 1] * 7 + p[i + 2] * 13; }
    return s;
  }

  public static string Run(IntPtr h, int seconds, string outDir, string prefix) {
    var log = new List<string>();
    int cx = 512, cy = 320;
    var end = DateTime.Now.AddSeconds(seconds);
    var nextFire = DateTime.Now; var nextCheck = DateTime.Now.AddSeconds(8);
    int held = -1, shots = 0, checks = 0, freezes = 0, narrow = 0, n = 0;
    DateTime pressedAt = DateTime.Now;
    while (DateTime.Now < end) {
      SetForegroundWindow(h);
      if (DateTime.Now >= nextFire) { Fire(); nextFire = DateTime.Now.AddSeconds(3); }
      int best = -1, bestDist = 9999, w, hgt, stride; byte[] p;
      using (var b = Grab(h)) { w = b.Width; hgt = b.Height; p = Pixels(b, out stride); }
      for (int y = 40; y < 600; y += 2) {
        for (int x = 10; x < w - 10; x += 2) {
          int i = y * stride + x * 4;
          int bl = p[i], gr = p[i + 1], rd = p[i + 2];
          if (Math.Abs(rd - 194) > 8 || Math.Abs(gr - 61) > 8 || Math.Abs(bl - 60) > 8) continue;
          int dx = x - cx, dy = y - cy, dir = -1, dist = 0;
          if (Math.Abs(dx) < 34) { dir = dy < 0 ? 0 : 2; dist = Math.Abs(dy); }
          else if (Math.Abs(dy) < 28) { dir = dx > 0 ? 1 : 3; dist = Math.Abs(dx); }
          if (dir >= 0 && dist < bestDist) { bestDist = dist; best = dir; }
        }
      }
      // tap the target's direction: each new press fires a burst
      if (held >= 0 && (best != held || (DateTime.Now - pressedAt).TotalMilliseconds > 70)) { Key(held, false); held = -1; System.Threading.Thread.Sleep(20); }
      else if (held < 0 && best >= 0) { Key(best, true); held = best; pressedAt = DateTime.Now; shots++; }
      if (DateTime.Now >= nextCheck) {
        if (held >= 0) { Key(held, false); held = -1; }
        string a = System.IO.Path.Combine(outDir, prefix + "_" + n + "a.png"), bb = System.IO.Path.Combine(outDir, prefix + "_" + n + "b.png");
        long h1, h2; int baseW = 0;
        using (var b1 = Grab(h)) { int s1; var p1 = Pixels(b1, out s1); h1 = Hash(p1, s1, b1.Width, b1.Height);
          for (int x = 440; x < 590; x++) { int i = cy * s1 + x * 4; if (p1[i] + p1[i + 1] + p1[i + 2] > 60) baseW++; }
          b1.Save(a, ImageFormat.Png); }
        System.Threading.Thread.Sleep(1000);
        using (var b2 = Grab(h)) { int s2; var p2 = Pixels(b2, out s2); h2 = Hash(p2, s2, b2.Width, b2.Height); b2.Save(bb, ImageFormat.Png); }
        checks++;
        string note = "moving";
        if (h1 == h2) { freezes++; note = "IDENTICAL (possible freeze)"; }
        if (baseW > 0 && baseW < 45) { narrow++; note += ", NARROW BASE " + baseW + "px"; }
        log.Add(n + ": " + note + " (shots so far " + shots + ")");
        n++; nextCheck = DateTime.Now.AddSeconds(10);
      }
      System.Threading.Thread.Sleep(5);
    }
    if (held >= 0) Key(held, false);
    log.Add("done: " + shots + " aimed shots, " + checks + " checks, " + freezes + " identical, " + narrow + " narrow-base");
    return string.Join("\n", log);
  }
}
"@

$p = Start-Process "C:\Program Files\Stella\Stella.exe" -ArgumentList "`"$romPath`"" -PassThru
Start-Sleep -Seconds 3
$p.Refresh()
[CosmoBot]::Run($p.MainWindowHandle, $Minutes * 60, $bin, $Prefix)
if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
