# Builds the WinStock app from src/app.html:
#  - index.html  : installable web app (PWA) for phones
#  - artifact.html : same app as a page fragment for the claude.ai preview
# Also draws the app icons once (PNG) if they are missing.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$app = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/app.html')

$head = @'
<!doctype html>
<html lang="de" class="standalone">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>WinStock</title>
<meta name="theme-color" content="#0A0E13">
<meta name="description" content="Dein Erfolgs-Depot: Erfolge sammeln, Punkte wachsen sehen, stolz sein.">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" sizes="192x192" href="icon-192.png">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="WinStock">
</head>
<body>
'@
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $root 'index.html'), $head + $app + "`n</body>`n</html>`n", $utf8)
[IO.File]::WriteAllText((Join-Path $root 'artifact.html'), $app, $utf8)

Add-Type -AssemblyName System.Drawing
function New-Icon([int]$size, [string]$file, [double]$inset) {
  $path = Join-Path $root $file
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.Clear([System.Drawing.Color]::FromArgb(255, 10, 14, 19))
  $rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 20, 30, 42)), ([System.Drawing.Color]::FromArgb(255, 10, 14, 19)), 90
  $g.FillRectangle($bg, $rect)
  $s = $size * (1 - 2 * $inset); $o = $size * $inset
  function P([double]$x, [double]$y) { New-Object System.Drawing.PointF ([float]($o + $x * $s)), ([float]($o + $y * $s)) }
  # area under the curve
  $pts = @((P 0.12 0.74), (P 0.36 0.52), (P 0.54 0.64), (P 0.86 0.28))
  $area = New-Object System.Drawing.Drawing2D.GraphicsPath
  $area.AddLines([System.Drawing.PointF[]]($pts + @((P 0.86 0.88), (P 0.12 0.88))))
  $area.CloseFigure()
  $ab = New-Object System.Drawing.Drawing2D.LinearGradientBrush ((P 0 0.28)), ((P 0 0.9)), ([System.Drawing.Color]::FromArgb(110, 43, 214, 123)), ([System.Drawing.Color]::FromArgb(0, 43, 214, 123))
  $g.FillPath($ab, $area)
  # line
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 43, 214, 123)), ([float]($s * 0.075))
  $pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
  $g.DrawLines($pen, [System.Drawing.PointF[]]$pts)
  # gold star dot at the peak
  $r = $s * 0.085; $c = P 0.86 0.28
  $gold = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 194, 61))
  $g.FillEllipse($gold, [float]($c.X - $r), [float]($c.Y - $r), [float](2 * $r), [float](2 * $r))
  $g.Dispose(); $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
}
if (-not (Test-Path (Join-Path $root 'icon-512.png'))) {
  New-Icon 192 'icon-192.png' 0.08
  New-Icon 512 'icon-512.png' 0.08
  New-Icon 512 'icon-maskable-512.png' 0.2
  New-Icon 180 'apple-touch-icon.png' 0.1
}
Write-Output 'Build fertig.'
