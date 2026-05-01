# ============================================================
# render-captures.ps1
# Convertit les fichiers .txt de docs/captures/output/
# en PNG style terminal pour servir de preuves visuelles.
# ============================================================
param(
    [string]$InputDir = "$PSScriptRoot/../docs/captures/output",
    [string]$OutputDir = "$PSScriptRoot/../docs/captures/output"
)

Add-Type -AssemblyName System.Drawing

$bgColor = [System.Drawing.Color]::FromArgb(255, 30, 30, 46)        # dark slate
$fgColor = [System.Drawing.Color]::FromArgb(255, 205, 214, 244)     # light text
$headerColor = [System.Drawing.Color]::FromArgb(255, 137, 180, 250) # cyan
$cmdColor = [System.Drawing.Color]::FromArgb(255, 166, 227, 161)    # green
$okColor = [System.Drawing.Color]::FromArgb(255, 166, 227, 161)
$errColor = [System.Drawing.Color]::FromArgb(255, 243, 139, 168)    # red

$font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular)
$boldFont = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)

$padding = 24
$lineHeight = 18
$maxWidth = 1400

$txtFiles = Get-ChildItem $InputDir -Filter "*.txt" -ErrorAction SilentlyContinue
if (-not $txtFiles) {
    Write-Host "Aucun fichier .txt dans $InputDir"
    exit 1
}

foreach ($file in $txtFiles) {
    $lines = Get-Content $file.FullName
    $height = ($lines.Count + 4) * $lineHeight + 2 * $padding
    if ($height -lt 200) { $height = 200 }

    $bmp = New-Object System.Drawing.Bitmap($maxWidth, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $g.Clear($bgColor)

    # Bandeau d'entete
    $headerBg = [System.Drawing.Color]::FromArgb(255, 49, 50, 68)
    $headerBrush = New-Object System.Drawing.SolidBrush($headerBg)
    $g.FillRectangle($headerBrush, 0, 0, $maxWidth, 32)
    $g.DrawString("LottoTi - Cluster k3d - $($file.BaseName)", $boldFont,
        (New-Object System.Drawing.SolidBrush($headerColor)), 12, 8)

    $y = 36 + $padding
    foreach ($line in $lines) {
        $color = $fgColor
        if ($line -match '^=====') {
            $color = $headerColor
        } elseif ($line -match '^\$\s' -or $line -match '^\$') {
            $color = $cmdColor
        } elseif ($line -match 'SUCCESS|>>|Bound|Ready|Running|deployed|succeeded|AUTORISE|BLOQUE') {
            $color = $okColor
        } elseif ($line -match 'Error|error|FAIL|failed|failed|Connection refused|ImagePullBackOff|denied') {
            $color = $errColor
        }
        $brush = New-Object System.Drawing.SolidBrush($color)
        $g.DrawString($line, $font, $brush, $padding, $y)
        $brush.Dispose()
        $y += $lineHeight
    }

    # Footer
    $g.DrawString("Genere le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')", $font,
        (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 88, 91, 112))),
        $padding, $height - 22)

    $outPath = Join-Path $OutputDir "$($file.BaseName).png"
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "[OK] $outPath"
}

$headerBrush.Dispose()
$font.Dispose()
$boldFont.Dispose()
Write-Host "`nDone. $($txtFiles.Count) PNG(s) generees dans $OutputDir"
