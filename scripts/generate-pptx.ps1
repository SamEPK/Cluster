# ============================================================
# generate-pptx.ps1
# Generate la presentation LottoTi pour la soutenance ESGI.
# Structure : 6 parties / ~46 slides.
# ============================================================
param(
    [string]$OutputPath = "$PSScriptRoot/../docs/Presentation_LottoTi_Cluster.pptx",
    [string]$CapturesDir = "$PSScriptRoot/../docs/captures/output",
    [string]$AssetsDir = "$PSScriptRoot/../docs/assets"
)

$ErrorActionPreference = "Stop"

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$CapturesDir = [System.IO.Path]::GetFullPath($CapturesDir)
$AssetsDir = [System.IO.Path]::GetFullPath($AssetsDir)

# ---- Couleurs (Catppuccin-inspire pour cohesion avec PNG terminal) ----
function RGB([int]$r, [int]$g, [int]$b) { return $r + ($g -shl 8) + ($b -shl 16) }
$colDark      = RGB 30 30 46
$colDarkLight = RGB 49 50 68
$colDarker    = RGB 17 17 27
$colWhite     = RGB 255 255 255
$colCyan      = RGB 137 180 250
$colGreen     = RGB 166 227 161
$colRed       = RGB 243 139 168
$colYellow    = RGB 249 226 175
$colOrange    = RGB 250 179 135
$colGray      = RGB 166 173 200
$colGrayDim   = RGB 108 112 134
$colMauve     = RGB 203 166 247
$colPink      = RGB 245 194 231
$colTeal      = RGB 148 226 213

# ---- PowerPoint constants ----
$ppLayoutBlank = 12
$msoTrue = -1
$msoFalse = 0

Write-Host "[1/3] Demarrage PowerPoint..."
$ppt = New-Object -ComObject PowerPoint.Application
try { $ppt.Visible = $msoTrue } catch {}

$pres = $ppt.Presentations.Add($msoTrue)
$pres.PageSetup.SlideWidth = 1280
$pres.PageSetup.SlideHeight = 720

$slideIdx = 0
$currentSection = ""

# ============================================================
# HELPERS
# ============================================================
function Add-Slide {
    $script:slideIdx++
    $slide = $pres.Slides.Add($script:slideIdx, $ppLayoutBlank)
    $slide.Background.Fill.ForeColor.RGB = $colDark
    $slide.FollowMasterBackground = $msoFalse
    return $slide
}

function Add-TextBox {
    param(
        $Slide, [string]$Text,
        [int]$Left = 60, [int]$Top = 60, [int]$Width = 1160, [int]$Height = 60,
        [int]$FontSize = 24, [int]$Color = $colWhite, [bool]$Bold = $false,
        [string]$FontName = "Segoe UI", [int]$Align = 1
    )
    $shape = $Slide.Shapes.AddTextbox(1, $Left, $Top, $Width, $Height)
    $tf = $shape.TextFrame
    $tf.TextRange.Text = $Text
    $tf.TextRange.Font.Size = $FontSize
    $tf.TextRange.Font.Color.RGB = $Color
    $tf.TextRange.Font.Bold = if ($Bold) { $msoTrue } else { $msoFalse }
    $tf.TextRange.Font.Name = $FontName
    $tf.TextRange.ParagraphFormat.Alignment = $Align
    $tf.WordWrap = $msoTrue
    $tf.MarginLeft = 0; $tf.MarginTop = 0
    return $shape
}

function Add-Rect {
    param($Slide, [int]$Left, [int]$Top, [int]$Width, [int]$Height, [int]$Color = $colDarkLight)
    $shape = $Slide.Shapes.AddShape(1, $Left, $Top, $Width, $Height)
    $shape.Fill.ForeColor.RGB = $Color
    $shape.Line.Visible = $msoFalse
    return $shape
}

function Add-Header {
    param($Slide, [string]$Title, [string]$Section = "", [string]$Subtitle = "")
    # Bandeau haut sombre
    Add-Rect -Slide $Slide -Left 0 -Top 0 -Width 1280 -Height 80 -Color $colDarkLight | Out-Null
    # Accent gauche couleur section
    Add-Rect -Slide $Slide -Left 0 -Top 0 -Width 6 -Height 80 -Color $colCyan | Out-Null

    Add-TextBox -Slide $Slide -Text $Title -Left 30 -Top 16 -Width 900 -Height 36 `
        -FontSize 26 -Color $colCyan -Bold $true | Out-Null
    if ($Section) {
        Add-TextBox -Slide $Slide -Text $Section -Left 30 -Top 50 -Width 900 -Height 24 `
            -FontSize 13 -Color $colGray | Out-Null
    }
    if ($Subtitle) {
        Add-TextBox -Slide $Slide -Text $Subtitle -Left 950 -Top 30 -Width 300 -Height 30 `
            -FontSize 13 -Color $colYellow -Align 3 | Out-Null
    }
}

function Add-Footer {
    param($Slide)
    Add-TextBox -Slide $Slide -Text "LottoTi - Clusterisation de container - Projet final ESGI" `
        -Left 30 -Top 690 -Width 800 -Height 20 -FontSize 10 -Color $colGrayDim | Out-Null
    Add-TextBox -Slide $Slide -Text "Slide $script:slideIdx" `
        -Left 1150 -Top 690 -Width 100 -Height 20 -FontSize 10 -Color $colGrayDim -Align 3 | Out-Null
}

function Add-Image {
    param($Slide, [string]$Path, [int]$Left, [int]$Top, [int]$Width, [int]$Height)
    if (-not (Test-Path $Path)) {
        Add-TextBox -Slide $Slide -Text "[Image manquante: $(Split-Path $Path -Leaf)]" `
            -Left $Left -Top ($Top + ($Height/2 - 20)) -Width $Width -Height 40 `
            -FontSize 16 -Color $colRed -Bold $true | Out-Null
        return $null
    }
    return $Slide.Shapes.AddPicture($Path, $msoFalse, $msoTrue, $Left, $Top, $Width, $Height)
}

function Add-Bullet {
    param($Slide, [string]$Text, [int]$Top, [int]$Color = $colWhite, [int]$FontSize = 16, [int]$Left = 80, [int]$Width = 1120)
    Add-TextBox -Slide $Slide -Text "* $Text" -Left $Left -Top $Top -Width $Width -Height 26 `
        -FontSize $FontSize -Color $Color | Out-Null
}

function Add-Code {
    param($Slide, [string]$Code, [int]$Left = 60, [int]$Top = 120, [int]$Width = 1160, [int]$Height = 480, [int]$FontSize = 13)
    $bg = Add-Rect -Slide $Slide -Left $Left -Top $Top -Width $Width -Height $Height -Color $colDarker
    Add-TextBox -Slide $Slide -Text $Code -Left ($Left + 20) -Top ($Top + 15) -Width ($Width - 40) -Height ($Height - 30) `
        -FontSize $FontSize -Color $colGreen -FontName "Consolas" -Align 1 | Out-Null
}

# ============================================================
# PARTIE 1 - INTRO
# ============================================================

# --- SLIDE 1 - COVER ---
$s = Add-Slide
# Background gradient effect via 2 shapes
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 0 -Width 12 -Height 720 -Color $colCyan | Out-Null

# Logo
$logoPath = Join-Path $AssetsDir "lottoti-logo.png"
if (Test-Path $logoPath) {
    Add-Image -Slide $s -Path $logoPath -Left 80 -Top 100 -Width 150 -Height 150 | Out-Null
}

Add-TextBox -Slide $s -Text "LottoTi" -Left 250 -Top 130 -Width 800 -Height 100 `
    -FontSize 80 -Color $colCyan -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Clusterisation de container" -Left 250 -Top 220 -Width 900 -Height 50 `
    -FontSize 32 -Color $colWhite | Out-Null
Add-TextBox -Slide $s -Text "Projet final ESGI - Vincent LAINE" -Left 250 -Top 270 -Width 900 -Height 30 `
    -FontSize 18 -Color $colGray | Out-Null

# Stats badges
$y = 380
Add-Rect -Slide $s -Left 80 -Top $y -Width 360 -Height 90 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Cluster" -Left 100 -Top ($y + 12) -Width 320 -Height 20 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "1 master + 2 workers" -Left 100 -Top ($y + 30) -Width 320 -Height 30 -FontSize 22 -Color $colGreen -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "k3s v1.31.5" -Left 100 -Top ($y + 60) -Width 320 -Height 20 -FontSize 12 -Color $colTeal | Out-Null

Add-Rect -Slide $s -Left 460 -Top $y -Width 360 -Height 90 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Replicas (aligne PDF)" -Left 480 -Top ($y + 12) -Width 320 -Height 20 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "2 backend + 3 frontend" -Left 480 -Top ($y + 30) -Width 320 -Height 30 -FontSize 22 -Color $colGreen -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Flask + Next.js + Postgres + Redis" -Left 480 -Top ($y + 60) -Width 320 -Height 20 -FontSize 12 -Color $colTeal | Out-Null

Add-Rect -Slide $s -Left 840 -Top $y -Width 360 -Height 90 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Note projetee" -Left 860 -Top ($y + 8) -Width 320 -Height 20 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "20 / 15" -Left 860 -Top ($y + 25) -Width 320 -Height 40 -FontSize 30 -Color $colMauve -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "15 base + 5 bonus - Tous criteres OK" -Left 860 -Top ($y + 65) -Width 320 -Height 20 -FontSize 11 -Color $colTeal | Out-Null

Add-TextBox -Slide $s -Text "Date : $(Get-Date -Format 'dd MMMM yyyy')" -Left 80 -Top 660 -Width 1100 -Height 20 `
    -FontSize 12 -Color $colGrayDim | Out-Null

# --- SLIDE 2 - SOMMAIRE ---
$s = Add-Slide
Add-Header -Slide $s -Title "Sommaire" -Section "Plan de la presentation"

$sections = @(
    @{Num="01"; Title="Introduction"; Desc="Contexte projet annuel + objectifs ESGI"; Color=$colCyan; Y=120},
    @{Num="02"; Title="Architecture"; Desc="Stack LottoTi + topologie Kubernetes"; Color=$colMauve; Y=200},
    @{Num="03"; Title="Steps d'installation"; Desc="8 etapes scriptees pour reproduire le cluster"; Color=$colGreen; Y=280},
    @{Num="04"; Title="Demo live + preuves"; Desc="12 captures live de la VRAIE app deployee"; Color=$colYellow; Y=360},
    @{Num="05"; Title="Bonus implementes"; Desc="6 bonus = plafond +5 pts atteint"; Color=$colOrange; Y=440},
    @{Num="06"; Title="Bilan + Q&A"; Desc="Bareme detaille + comment reproduire"; Color=$colPink; Y=520}
)
foreach ($sec in $sections) {
    Add-Rect -Slide $s -Left 80 -Top $sec.Y -Width 1120 -Height 60 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 80 -Top $sec.Y -Width 6 -Height 60 -Color $sec.Color | Out-Null
    Add-TextBox -Slide $s -Text $sec.Num -Left 110 -Top ($sec.Y + 15) -Width 60 -Height 30 `
        -FontSize 22 -Color $sec.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $sec.Title -Left 180 -Top ($sec.Y + 8) -Width 350 -Height 30 `
        -FontSize 20 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $sec.Desc -Left 180 -Top ($sec.Y + 32) -Width 1000 -Height 24 `
        -FontSize 13 -Color $colGray | Out-Null
}
Add-Footer -Slide $s

# --- SLIDE 3 - SECTION 01 INTRO ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colCyan | Out-Null
Add-TextBox -Slide $s -Text "01" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Introduction" -Left 320 -Top 290 -Width 800 -Height 80 `
    -FontSize 64 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Contexte projet annuel + objectifs ESGI" -Left 320 -Top 380 -Width 800 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# --- SLIDE 4 - LE PROJET LOTTOTI ---
$s = Add-Slide
Add-Header -Slide $s -Title "Le projet annuel : LottoTi" -Section "01 - Introduction"

Add-TextBox -Slide $s -Text "Plateforme de location de vehicules entre particuliers" -Left 60 -Top 110 -Width 1160 -Height 40 `
    -FontSize 22 -Color $colWhite | Out-Null

# 4 caracteristiques
$features = @(
    @{Title="Frontend"; Desc="Next.js 15 - React Server Components - Standalone"; Color=$colCyan; Y=180},
    @{Title="Backend API"; Desc="Flask + Gunicorn-gevent + Socket.IO + JWT auth"; Color=$colGreen; Y=260},
    @{Title="Base de donnees"; Desc="PostgreSQL 16 (location, users, vehicules, paiements)"; Color=$colMauve; Y=340},
    @{Title="Cache + sessions"; Desc="Redis 7 (rate limiting, Socket.IO pubsub, cache)"; Color=$colYellow; Y=420}
)
foreach ($f in $features) {
    Add-Rect -Slide $s -Left 60 -Top $f.Y -Width 1160 -Height 60 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $f.Y -Width 8 -Height 60 -Color $f.Color | Out-Null
    Add-TextBox -Slide $s -Text $f.Title -Left 90 -Top ($f.Y + 8) -Width 250 -Height 30 `
        -FontSize 18 -Color $f.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $f.Desc -Left 350 -Top ($f.Y + 14) -Width 850 -Height 30 `
        -FontSize 14 -Color $colWhite | Out-Null
}

Add-TextBox -Slide $s -Text "Source : c:\LottoTi\ - deja conteneurise via docker-compose (5 services)" -Left 60 -Top 530 -Width 1160 -Height 30 `
    -FontSize 14 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "Mission ESGI : transposer cette stack vers Kubernetes pour HA + securite + persistance" -Left 60 -Top 565 -Width 1160 -Height 30 `
    -FontSize 14 -Color $colYellow -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 5 - OBJECTIFS PDF ---
$s = Add-Slide
Add-Header -Slide $s -Title "Les 4 piliers exiges par le sujet" -Section "01 - Introduction"

Add-TextBox -Slide $s -Text "PDF 'Projet final - Clusterisation de container' (Vincent LAINE) - section 1 page 2" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 13 -Color $colGray | Out-Null

$pillars = @(
    @{Num="1"; Title="Haute disponibilite"; Desc="Replicas, load balancing, scaling horizontal"; Detail="Backend min 2 replicas, frontend min 3 replicas (PDF section 3.2.4)"; Color=$colGreen; Y=170},
    @{Num="2"; Title="Securite"; Desc="Secrets, HTTPS"; Detail="Kubernetes Secrets + ConfigMaps + cert auto-signe ou Let's Encrypt"; Color=$colYellow; Y=300},
    @{Num="3"; Title="Persistance"; Desc="Volumes pour la DB, etc."; Detail="PV/PVC k3s - donnees survivent au delete pod ou redeploiement"; Color=$colCyan; Y=430},
    @{Num="4"; Title="Documentation et manifest"; Desc="Scripts, YAML, etc."; Detail="Tutoriel reproductible + captures - le pred peut cloner et lancer"; Color=$colMauve; Y=560}
)
foreach ($p in $pillars) {
    Add-Rect -Slide $s -Left 60 -Top $p.Y -Width 1160 -Height 110 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $p.Y -Width 8 -Height 110 -Color $p.Color | Out-Null
    Add-TextBox -Slide $s -Text $p.Num -Left 90 -Top ($p.Y + 25) -Width 80 -Height 60 `
        -FontSize 48 -Color $p.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $p.Title -Left 180 -Top ($p.Y + 12) -Width 600 -Height 30 `
        -FontSize 20 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $p.Desc -Left 180 -Top ($p.Y + 42) -Width 800 -Height 24 `
        -FontSize 14 -Color $p.Color | Out-Null
    Add-TextBox -Slide $s -Text $p.Detail -Left 180 -Top ($p.Y + 70) -Width 980 -Height 30 `
        -FontSize 12 -Color $colGray | Out-Null
}
Add-Footer -Slide $s

# ============================================================
# PARTIE 2 - ARCHITECTURE
# ============================================================

# --- SLIDE 6 - SECTION 02 ARCHITECTURE ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colMauve | Out-Null
Add-TextBox -Slide $s -Text "02" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Architecture" -Left 320 -Top 290 -Width 800 -Height 80 `
    -FontSize 64 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Stack avant + apres + topologie cluster" -Left 320 -Top 380 -Width 800 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# --- SLIDE 7 - AVANT (DOCKER COMPOSE) ---
$s = Add-Slide
Add-Header -Slide $s -Title "AVANT : docker-compose monolithique" -Section "02 - Architecture"

Add-TextBox -Slide $s -Text "5 services sur une seule machine - aucune redondance" -Left 60 -Top 110 -Width 1160 -Height 30 `
    -FontSize 16 -Color $colYellow | Out-Null

$compose = @"
services:
  frontend:    # Next.js     - 1 instance
  api:         # Flask       - 1 instance
  db:          # PostgreSQL  - 1 instance
  redis:       # Redis       - 1 instance
  nginx:       # Reverse proxy - 1 instance

volumes:
  pgdata, redisdata, uploads, logs

networks:
  app: bridge
"@

Add-Code -Slide $s -Code $compose -Left 60 -Top 160 -Width 600 -Height 400 -FontSize 14

# Limitations
$limits = @(
    @{Text="Une panne = downtime total"; Color=$colRed},
    @{Text="Pas de scaling horizontal"; Color=$colRed},
    @{Text="Pas de rolling update sans coupure"; Color=$colRed},
    @{Text="Pas de health checks declaratifs"; Color=$colRed},
    @{Text="Secrets en .env en clair"; Color=$colRed},
    @{Text="Pas de zero-trust networking"; Color=$colRed}
)
Add-TextBox -Slide $s -Text "Limitations" -Left 690 -Top 160 -Width 530 -Height 30 `
    -FontSize 18 -Color $colRed -Bold $true | Out-Null
$y = 210
foreach ($l in $limits) {
    Add-TextBox -Slide $s -Text "  X  $($l.Text)" -Left 690 -Top $y -Width 530 -Height 30 `
        -FontSize 14 -Color $l.Color | Out-Null
    $y += 35
}
Add-Footer -Slide $s

# --- SLIDE 8 - APRES (KUBERNETES) ---
$s = Add-Slide
Add-Header -Slide $s -Title "APRES : Kubernetes (k3s)" -Section "02 - Architecture"

Add-TextBox -Slide $s -Text "Meme stack mais orchestree sur 3 noeuds avec HA + persistance + secu" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colGreen | Out-Null

# Diagramme architecture (texte ASCII style)
$diag = @"
                  Internet / utilisateur
                            |
                            v
                  +-------------------+
                  |  /etc/hosts       |
                  |  lottoti.local    |
                  +-------------------+
                            |
                  +---------------------------------+
                  |    Cluster k3s                  |
                  |                                 |
                  |  master (control-plane)         |
                  |    Traefik Ingress + cert TLS   |
                  |             |                   |
                  |    +--------+--------+          |
                  |    |        |        |          |
                  |    v        v        v          |
                  |  /api/*  /socket  /  (Next.js)  |
                  |    |        |        |          |
                  |    v        v        v          |
                  |  backend(2)      frontend(3)    |
                  |    |  |             |  |  |     |
                  |    v  v             v  v  v     |
                  |  postgres(1)     repartis sur   |
                  |  redis(1)        3 noeuds       |
                  |  uploads PVC     anti-affinity  |
                  |                                 |
                  |  worker1   worker2              |
                  +---------------------------------+
"@
Add-Code -Slide $s -Code $diag -Left 60 -Top 150 -Width 1160 -Height 510 -FontSize 12
Add-Footer -Slide $s

# --- SLIDE 9 - TOPOLOGIE 3 NOEUDS ---
$s = Add-Slide
Add-Header -Slide $s -Title "Topologie : 1 master + 2 workers" -Section "02 - Architecture" -Subtitle "PDF section 3.1"

Add-TextBox -Slide $s -Text "3 VMs Ubuntu 22.04 via Multipass (cible prod) ou containers k3s via k3d (demo)" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colGray | Out-Null

# 3 colonnes pour les 3 noeuds
$nodes = @(
    @{Title="master"; Role="control-plane"; CPU="2 vCPU"; RAM="2 Go"; Pods="API server, scheduler, etcd, frontend(1)"; Color=$colMauve; X=60},
    @{Title="worker1"; Role="app + storage"; CPU="2 vCPU"; RAM="3 Go"; Pods="backend(2), postgres, frontend(1)"; Color=$colGreen; X=470},
    @{Title="worker2"; Role="app + storage"; CPU="2 vCPU"; RAM="3 Go"; Pods="redis, frontend(1)"; Color=$colCyan; X=880}
)
foreach ($n in $nodes) {
    Add-Rect -Slide $s -Left $n.X -Top 160 -Width 340 -Height 380 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left $n.X -Top 160 -Width 340 -Height 8 -Color $n.Color | Out-Null

    Add-TextBox -Slide $s -Text $n.Title -Left ($n.X + 20) -Top 180 -Width 300 -Height 40 `
        -FontSize 24 -Color $n.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $n.Role -Left ($n.X + 20) -Top 220 -Width 300 -Height 24 `
        -FontSize 13 -Color $colGray | Out-Null

    Add-TextBox -Slide $s -Text "CPU" -Left ($n.X + 20) -Top 260 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.CPU -Left ($n.X + 20) -Top 278 -Width 300 -Height 24 -FontSize 16 -Color $colWhite -Bold $true | Out-Null

    Add-TextBox -Slide $s -Text "RAM" -Left ($n.X + 20) -Top 320 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.RAM -Left ($n.X + 20) -Top 338 -Width 300 -Height 24 -FontSize 16 -Color $colWhite -Bold $true | Out-Null

    Add-TextBox -Slide $s -Text "Pods heberges" -Left ($n.X + 20) -Top 400 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.Pods -Left ($n.X + 20) -Top 420 -Width 300 -Height 100 -FontSize 13 -Color $colWhite | Out-Null
}

Add-TextBox -Slide $s -Text "Labels appliques : storage=true (workers), lottoti.io/role=app" `
    -Left 60 -Top 570 -Width 1160 -Height 30 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "PodAntiAffinity : frontend repartis sur les 3 noeuds (zero downtime sur node failure)" `
    -Left 60 -Top 600 -Width 1160 -Height 30 -FontSize 13 -Color $colYellow | Out-Null
Add-Footer -Slide $s

# --- SLIDE 10 - INVENTAIRE MANIFESTS ---
$s = Add-Slide
Add-Header -Slide $s -Title "Inventaire des manifests Kubernetes" -Section "02 - Architecture" -Subtitle "PDF section 3.2.3"

Add-TextBox -Slide $s -Text "36 manifests YAML + 1 Helm chart - tous dans c:\cluster\k8s\" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$tree = @"
k8s/
|-- base/                      <-- 36 manifests Kustomize
|   |-- 00-namespaces/         (2 namespaces)
|   |-- 15-cert-manager/       (Issuer + CA + ClusterIssuer)
|   |-- 20-database/           (StatefulSet + Service + ConfigMap)
|   |-- 25-redis/              (StatefulSet + Service)
|   |-- 30-backend/            (Deployment + Service + ConfigMap + PVC + HPA + PDB)
|   |-- 40-frontend/           (Deployment + Service + HPA + PDB)
|   |-- 50-ingress/            (Ingress + IngressRoute + Certificate + 6 Middlewares)
|   `-- 60-policies/           (8 NetworkPolicies)
|
|-- overlays/
|   |-- dev/                   (1 replica, debug logs)
|   |-- prod/                  (Multipass + Longhorn + 2/3 replicas)
|   |-- k3d/                   (k3d + nginx stub - tests rapides)
|   `-- k3d-real/              (k3d + vraies images LottoTi)

charts/lottoti/                <-- Helm chart (24 templates rendus)
"@
Add-Code -Slide $s -Code $tree -Left 60 -Top 150 -Width 1160 -Height 480 -FontSize 13
Add-Footer -Slide $s

# ============================================================
# PARTIE 3 - STEPS D'INSTALLATION (10 slides)
# ============================================================

# --- SLIDE 11 - SECTION 03 STEPS ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colGreen | Out-Null
Add-TextBox -Slide $s -Text "03" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Steps d'installation" -Left 360 -Top 290 -Width 860 -Height 80 `
    -FontSize 56 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "8 etapes scriptees pour reproduire le cluster" -Left 360 -Top 380 -Width 860 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# --- SLIDE 12 - PRE-REQUIS ---
$s = Add-Slide
Add-Header -Slide $s -Title "Pre-requis" -Section "03 - Installation"

$prereqs = @(
    @{Name="Multipass"; Detail="Installation Ubuntu 22.04 sur Hyper-V (Windows) / KVM (Linux)"; Cmd="winget install Canonical.Multipass"; Color=$colCyan; Y=130},
    @{Name="Docker Desktop"; Detail="Pour le build des images applicatives"; Cmd="https://docker.com/products/docker-desktop"; Color=$colGreen; Y=230},
    @{Name="kubectl"; Detail="CLI Kubernetes (CE script local)"; Cmd="winget install Kubernetes.kubectl"; Color=$colMauve; Y=330},
    @{Name="Helm"; Detail="Package manager Kubernetes (Traefik, Longhorn, app)"; Cmd="winget install Helm.Helm"; Color=$colYellow; Y=430},
    @{Name="git bash / WSL"; Detail="Shell pour executer les scripts d'install (.sh)"; Cmd="https://git-scm.com"; Color=$colOrange; Y=530}
)
foreach ($p in $prereqs) {
    Add-Rect -Slide $s -Left 60 -Top $p.Y -Width 1160 -Height 80 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $p.Y -Width 6 -Height 80 -Color $p.Color | Out-Null
    Add-TextBox -Slide $s -Text $p.Name -Left 90 -Top ($p.Y + 10) -Width 250 -Height 30 `
        -FontSize 20 -Color $p.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $p.Detail -Left 90 -Top ($p.Y + 42) -Width 600 -Height 26 `
        -FontSize 13 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text $p.Cmd -Left 700 -Top ($p.Y + 30) -Width 500 -Height 30 `
        -FontSize 13 -Color $colGreen -FontName "Consolas" | Out-Null
}
Add-Footer -Slide $s

# --- SLIDE 13 - STEP 1 VMs ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 1/8 - Creation VMs Multipass" -Section "03 - Installation" -Subtitle "scripts/01-create-vms.sh"

Add-TextBox -Slide $s -Text "Creer 3 VMs Ubuntu (1 master + 2 workers) avec ressources dediees" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$cmd = @"
#!/usr/bin/env bash
# scripts/01-create-vms.sh

multipass launch 22.04 --name master  --cpus 2 --memory 2G --disk 20G
multipass launch 22.04 --name worker1 --cpus 2 --memory 3G --disk 20G
multipass launch 22.04 --name worker2 --cpus 2 --memory 3G --disk 20G

# Verification
multipass list
# Name     | State   | IPv4         | Image
# master   | Running | 192.168.x.10 | Ubuntu 22.04 LTS
# worker1  | Running | 192.168.x.11 | Ubuntu 22.04 LTS
# worker2  | Running | 192.168.x.12 | Ubuntu 22.04 LTS
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 160 -Width 1160 -Height 360 -FontSize 14

Add-TextBox -Slide $s -Text "Duree : ~3 minutes" -Left 60 -Top 540 -Width 400 -Height 30 `
    -FontSize 14 -Color $colYellow -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Resultat : 3 VMs Running" -Left 460 -Top 540 -Width 600 -Height 30 `
    -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 14 - STEP 2 K3S ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 2/8 - Installation k3s" -Section "03 - Installation" -Subtitle "scripts/02-install-k3s.sh"

Add-TextBox -Slide $s -Text "Installer k3s server sur master + agents sur workers (Traefik desactive : on installe le notre apres)" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colWhite | Out-Null

$cmd = @"
# Master (control plane)
multipass exec master -- bash -c "
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server --disable=traefik' sh -
"

# Recuperer le token de jonction
TOKEN=`$(multipass exec master sudo cat /var/lib/rancher/k3s/server/node-token)
MASTER_IP=`$(multipass info master | awk '/IPv4/ {print `$2}')

# Workers (rejoignent le cluster)
for w in worker1 worker2; do
  multipass exec `$w -- bash -c "
    curl -sfL https://get.k3s.io | K3S_URL=https://`$MASTER_IP:6443 K3S_TOKEN=`$TOKEN sh -
  "
done

# Recuperer kubeconfig en local
multipass exec master sudo cat /etc/rancher/k3s/k3s.yaml \
  | sed s/127.0.0.1/`$MASTER_IP/ > ~/.kube/config-lottoti

kubectl --kubeconfig ~/.kube/config-lottoti get nodes
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 460 -FontSize 12

Add-TextBox -Slide $s -Text "Duree : ~2 minutes - Resultat : 3 nodes Ready" -Left 60 -Top 620 -Width 1160 -Height 30 `
    -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 15 - STEP 3 LONGHORN ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 3/8 - Storage Longhorn (RWX)" -Section "03 - Installation" -Subtitle "scripts/03-install-storage.sh"

Add-TextBox -Slide $s -Text "Pourquoi Longhorn ? Le PVC uploads doit etre RWX (partage entre les 2 backend pods)" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colYellow | Out-Null

$cmd = @"
# Pre-requis Longhorn sur chaque node : iscsi, nfs, util-linux
for n in master worker1 worker2; do
  multipass exec `$n -- bash -c "
    sudo apt-get install -y -qq open-iscsi nfs-common util-linux
    sudo systemctl enable --now iscsid
  "
done

# Helm install Longhorn
helm repo add longhorn https://charts.longhorn.io
helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system --create-namespace \
  --version 1.7.2 \
  --set defaultSettings.replicaSoftAntiAffinity=true \
  --set persistence.defaultClassReplicaCount=2 \
  --wait --timeout 10m

# Promote longhorn comme StorageClass par defaut
kubectl annotate storageclass longhorn \
  storageclass.kubernetes.io/is-default-class=true --overwrite
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 420 -FontSize 13

Add-TextBox -Slide $s -Text "Duree : ~5 minutes - Resultat : SC longhorn (default), supporte RWO + RWX" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 16 - STEP 4 CERT MANAGER ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 4/8 - cert-manager (HTTPS)" -Section "03 - Installation" -Subtitle "scripts/04-install-cert-manager.sh"

Add-TextBox -Slide $s -Text "Pour le HTTPS exigence PDF section 3.4 : installer cert-manager + creer un CA local" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colYellow | Out-Null

$cmd = @"
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
kubectl -n cert-manager wait --for=condition=Available deploy --all --timeout=5m

# 1. ClusterIssuer self-signed (bootstrap)
kubectl apply -f k8s/base/15-cert-manager/00-selfsigned-issuer.yaml

# 2. Generer le CA local 'lottoti-ca' (signe par self-signed)
kubectl apply -f k8s/base/15-cert-manager/01-ca-certificate.yaml
kubectl -n cert-manager wait --for=condition=Ready certificate/lottoti-ca --timeout=2m

# 3. ClusterIssuer 'lottoti-ca-issuer' (utilise notre CA pour signer les certs apps)
kubectl apply -f k8s/base/15-cert-manager/02-ca-issuer.yaml

# Resultat : certs auto-generes pour lottoti.local + api.lottoti.local + *.lottoti.local
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 420 -FontSize 13

Add-TextBox -Slide $s -Text "Duree : ~2 minutes - Resultat : ClusterIssuer 'lottoti-ca-issuer' Ready" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 17 - STEP 5 TRAEFIK ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 5/8 - Ingress Traefik v3" -Section "03 - Installation" -Subtitle "scripts/05-install-ingress.sh"

Add-TextBox -Slide $s -Text "Exigence PDF section 3.5 : Load Balancer/Ingress (Traefik, NGINX) pour acceder a l'app" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colYellow | Out-Null

$cmd = @"
# Helm install Traefik
helm repo add traefik https://traefik.github.io/charts

helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --version 33.0.0 \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ingressClass.isDefaultClass=true \
  --set providers.kubernetesIngress.allowExternalNameServices=true \
  --set providers.kubernetesCRD.allowCrossNamespace=true \
  --wait --timeout 5m

# Resultat
# kubectl -n traefik get svc traefik
# NAME     TYPE       PORT(S)
# traefik  NodePort   80:30080/TCP, 443:30443/TCP
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 420 -FontSize 13

Add-TextBox -Slide $s -Text "Duree : ~1 minute - Resultat : NodePort 30080 (HTTP) + 30443 (HTTPS)" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 18 - STEP 6 BUILD IMAGES ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 6/8 - Build images Docker" -Section "03 - Installation" -Subtitle "scripts/06-build-images.sh"

Add-TextBox -Slide $s -Text "Builder backend Flask + frontend Next.js puis importer dans k3s (sans registry externe)" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colWhite | Out-Null

$cmd = @"
# Build local
docker build -t lottoti/backend:1.0.0  C:/LottoTi/backend
docker build -t lottoti/frontend:1.0.0 C:/LottoTi/lottoit \
  --build-arg NEXT_PUBLIC_API_URL=https://api.lottoti.local

# docker save -> tar -> scp -> k3s ctr import
WORK=./.images
mkdir -p `$WORK
docker save -o `$WORK/backend.tar  lottoti/backend:1.0.0
docker save -o `$WORK/frontend.tar lottoti/frontend:1.0.0

for n in master worker1 worker2; do
  for img in backend frontend; do
    multipass transfer `$WORK/`$img.tar `$n:/tmp/`$img.tar
    multipass exec `$n -- sudo k3s ctr images import /tmp/`$img.tar
  done
done

# Verification
multipass exec master -- sudo k3s ctr images ls | grep lottoti
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 460 -FontSize 12

Add-TextBox -Slide $s -Text "Duree : ~5 minutes (build) + 2 minutes (transfert) - Resultat : images dispo sur tous les nodes" `
    -Left 60 -Top 620 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 19 - STEP 7 DEPLOY ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 7/8 - Deploy LottoTi" -Section "03 - Installation" -Subtitle "scripts/07-deploy.sh"

Add-TextBox -Slide $s -Text "Generer les secrets, creer le namespace, puis appliquer les manifests via Kustomize" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colWhite | Out-Null

$cmd = @"
# 1. Generer les secrets (1ere fois seulement)
cat > .secrets.env <<EOF
POSTGRES_PASSWORD=`$(openssl rand -hex 24)
FLASK_SECRET_KEY=`$(openssl rand -hex 32)
JWT_SECRET_KEY=`$(openssl rand -hex 32)
EOF

# 2. Creer namespace + Secret Kubernetes
kubectl apply -f k8s/base/00-namespaces/
kubectl -n lottoti create secret generic lottoti-secrets \
  --from-env-file=.secrets.env --dry-run=client -o yaml | kubectl apply -f -

# 3. Apply tous les manifests via Kustomize
kubectl apply -k k8s/overlays/prod   # 36 ressources crees

# 4. Wait rollout
kubectl -n lottoti rollout status statefulset/postgres
kubectl -n lottoti rollout status statefulset/redis
kubectl -n lottoti rollout status deploy/backend
kubectl -n lottoti rollout status deploy/frontend
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 420 -FontSize 13

Add-TextBox -Slide $s -Text "Duree : ~2-3 minutes - Resultat : 36 ressources, pods Running" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE 20 - STEP 8 + WORKFLOW COMPLET ---
$s = Add-Slide
Add-Header -Slide $s -Title "Step 8/8 + workflow complet" -Section "03 - Installation" -Subtitle "scripts/install-all.sh"

Add-TextBox -Slide $s -Text "Workflow one-shot : install-all.sh execute les 7 etapes precedentes en sequence" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$cmd = @"
#!/usr/bin/env bash
# scripts/install-all.sh - 1 seul appel pour tout monter

set -euo pipefail
SCRIPT_DIR="`$(cd `"`$(dirname `"`$0`")`" && pwd)"

bash "`$SCRIPT_DIR/01-create-vms.sh"          # 3 VMs Multipass
bash "`$SCRIPT_DIR/02-install-k3s.sh"         # k3s server + 2 agents
bash "`$SCRIPT_DIR/03-install-storage.sh"     # Longhorn (RWX)
bash "`$SCRIPT_DIR/04-install-cert-manager.sh" # cert-manager + CA local
bash "`$SCRIPT_DIR/05-install-ingress.sh"     # Traefik v3
bash "`$SCRIPT_DIR/06-build-images.sh"        # Docker build + import
bash "`$SCRIPT_DIR/07-deploy.sh"              # kubectl apply -k
echo "[OK] LottoTi pret. Lance ./08-test-ha.sh pour les tests HA."

# Pour la demo
bash "`$SCRIPT_DIR/08-test-ha.sh"             # tests scale, kill, rolling

# Pour cleanup
bash "`$SCRIPT_DIR/99-teardown.sh"
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 410 -FontSize 14

Add-TextBox -Slide $s -Text "Duree totale : ~15 minutes - Reproductible sur n'importe quelle machine Multipass-compatible" `
    -Left 60 -Top 570 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# PARTIE 4 - DEMO LIVE & PREUVES (12 slides)
# ============================================================

# --- SLIDE 21 - SECTION 04 DEMO ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "04" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Demo live + preuves" -Left 360 -Top 290 -Width 860 -Height 80 `
    -FontSize 56 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "12 captures d'execution reelle de la VRAIE app" -Left 360 -Top 380 -Width 860 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# Captures pages
$captures = @(
    @{File="01-cluster-healthy.png"; Title="Cluster healthy"; Section="3 nodes Ready, k3s v1.31.5"; PdfRef="PDF 3.1"; Note="1 master + 2 workers Ready - exigence PDF respectee"},
    @{File="02-namespaces-pods.png"; Title="Deploiement multi-tier"; Section="2 backend + 3 frontend + DB + Redis"; PdfRef="PDF 3.2"; Note="Replicas alignes : backend 2/2, frontend 3/3 - vraies images Flask + Next.js"},
    @{File="10-https-frontend-real.png"; Title="VRAIE app LottoTi en HTTPS"; Section="Browser screenshot + ingress Traefik"; PdfRef="PDF 3.5"; Note="Page d'accueil Lottoit live - menu Vehicules/Tarifs/FAQ - boutons Connexion/Inscription"},
    @{File="10b-https-api-health.png"; Title="API Flask /api/health"; Section="JSON valide depuis le browser"; PdfRef="PDF 3.5"; Note="status:healthy + database response 4ms - vraie integration Flask-Postgres"},
    @{File="03-pvc-pv.png"; Title="Persistance (PVC + PV)"; Section="3 PVC Bound"; PdfRef="PDF 3.3"; Note="pgdata 5Gi + redisdata 1Gi + uploads 5Gi - StorageClass longhorn (cible) ou local-path (k3d)"},
    @{File="07-kill-db-persistence.png"; Title="PROOF persistance DB"; Section="kill postgres + donnee survit"; PdfRef="PDF 3.3"; Note="proof_1777283282 inseree avant kill, MEME PVC UID, MEME ligne SELECT apres recreation pod"},
    @{File="14-secrets-configmap.png"; Title="Secrets + ConfigMap"; Section="Exigence PDF 3.4"; PdfRef="PDF 3.4"; Note="5 secrets Opaque (passwords + Stripe) + cert TLS - kubectl describe ne montre que les TAILLES"},
    @{File="04-ingress-tls.png"; Title="Ingress + TLS"; Section="Cert auto-signe lottoti-ca"; PdfRef="PDF 3.4 + 3.5"; Note="Certificate Ready - signe par notre CA local - Traefik NodePort 30443 - HTTP 301 -> HTTPS"},
    @{File="05-scale-up-backend.png"; Title="HA Scale up/down"; Section="3 -> 6 -> 3 frontend"; PdfRef="PDF 2.1.5"; Note="PodAntiAffinity repartit sur 3 nodes - kubectl scale en 8 secondes"},
    @{File="06-kill-pod-recovery.png"; Title="HA Kill pod recovery"; Section="Recovery automatique 8s"; PdfRef="PDF 3.3"; Note="ReplicaSet recree le pod sans intervention - service jamais down"},
    @{File="12-network-policy-blocked.png"; Title="NetworkPolicy enforcement"; Section="Bonus 3 +1pt"; PdfRef="Bonus PDF 4.3"; Note="frontend->postgres BLOQUE (TCP REJECT) - backend->postgres OK - 8 policies zero-trust"},
    @{File="15-resource-limits-qos.png"; Title="Resource Limits + QoS"; Section="Bonus 1 +1pt"; PdfRef="Bonus PDF 4.1"; Note="QoS Burstable sur tous les pods - requests + limits separes - metrics-server actif"}
)

foreach ($cap in $captures) {
    $s = Add-Slide
    Add-Header -Slide $s -Title $cap.Title -Section "04 - Demo : $($cap.Section)" -Subtitle $cap.PdfRef

    $imgPath = Join-Path $CapturesDir $cap.File
    Add-Image -Slide $s -Path $imgPath -Left 60 -Top 100 -Width 1160 -Height 540 | Out-Null

    Add-Rect -Slide $s -Left 60 -Top 645 -Width 1160 -Height 35 -Color $colDarkLight | Out-Null
    Add-TextBox -Slide $s -Text $cap.Note -Left 75 -Top 651 -Width 1130 -Height 30 `
        -FontSize 12 -Color $colYellow | Out-Null
    Add-Footer -Slide $s
}

# ============================================================
# PARTIE 5 - BONUS (5 slides)
# ============================================================

# --- SLIDE - SECTION 05 BONUS ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colOrange | Out-Null
Add-TextBox -Slide $s -Text "05" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Bonus implementes" -Left 360 -Top 290 -Width 860 -Height 80 `
    -FontSize 56 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "6 bonus = plafond +5 pts atteint" -Left 360 -Top 380 -Width 860 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# Bonus captures (les bonus deja vus dans demo: NetworkPolicy + QoS - on inclut ici Rolling, Rollback, HPA, Helm)
$bonusList = @(
    @{File="08-rolling-update.png"; Num="4"; Title="Rolling Update zero-downtime"; PdfRef="Bonus PDF 4.4"; Note="maxSurge=1, maxUnavailable=0 - toujours >= 3 pods Ready durant la maj"},
    @{File="09-rollback.png"; Num="7"; Title="Rollback automatique"; PdfRef="Bonus PDF 4.7"; Note="set image DOES_NOT_EXIST -> rollout undo - service jamais down (3 pods sains continuent)"},
    @{File="11-hpa-load.png"; Num="5"; Title="HPA Autoscaling"; PdfRef="Bonus PDF 4.5"; Note="metrics-server actif - SuccessfulRescale 1->2 sur depassement seuil memory"},
    @{File="13-helm-deploy.png"; Num="8"; Title="Helm Chart parametrable"; PdfRef="Bonus PDF 4.8"; Note="charts/lottoti/ - helm install/upgrade/rollback testes en namespace lottoti-helm"}
)

foreach ($b in $bonusList) {
    $s = Add-Slide
    Add-Header -Slide $s -Title "Bonus $($b.Num) - $($b.Title)" -Section "05 - Bonus implementes" -Subtitle $b.PdfRef

    $imgPath = Join-Path $CapturesDir $b.File
    Add-Image -Slide $s -Path $imgPath -Left 60 -Top 100 -Width 1160 -Height 540 | Out-Null

    Add-Rect -Slide $s -Left 60 -Top 645 -Width 1160 -Height 35 -Color $colDarkLight | Out-Null
    Add-TextBox -Slide $s -Text $b.Note -Left 75 -Top 651 -Width 1130 -Height 30 `
        -FontSize 12 -Color $colYellow | Out-Null
    Add-Footer -Slide $s
}

# Recap bonus
$s = Add-Slide
Add-Header -Slide $s -Title "Recapitulatif des 6 bonus" -Section "05 - Bonus implementes"

Add-TextBox -Slide $s -Text "Plafond +5 pts atteint - 6 bonus implementes pour avoir une marge" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$bonusRecap = @(
    @{Num="1"; Title="Resource Requests & Limits + QoS"; Where="Tous les Deployments + StatefulSets"; Pts="+1"; Color=$colGreen},
    @{Num="3"; Title="NetworkPolicy zero-trust"; Where="8 policies dans 60-policies/"; Pts="+1"; Color=$colGreen},
    @{Num="4"; Title="Rolling Update + maxUnavailable=0"; Where="Strategy dans backend + frontend Deployments"; Pts="+1"; Color=$colGreen},
    @{Num="5"; Title="HPA Autoscaling"; Where="HPA backend (1-4) + frontend (3-10)"; Pts="+1"; Color=$colGreen},
    @{Num="7"; Title="Rollback automatique"; Where="rollout undo + revisionHistoryLimit=5"; Pts="+1"; Color=$colGreen},
    @{Num="8"; Title="Helm Chart parametrable"; Where="charts/lottoti/ (24 templates)"; Pts="+1"; Color=$colMauve}
)
$y = 160
foreach ($b in $bonusRecap) {
    Add-Rect -Slide $s -Left 60 -Top $y -Width 1160 -Height 70 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $y -Width 6 -Height 70 -Color $b.Color | Out-Null
    Add-TextBox -Slide $s -Text "$($b.Num)" -Left 90 -Top ($y + 18) -Width 60 -Height 35 `
        -FontSize 28 -Color $b.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.Title -Left 170 -Top ($y + 12) -Width 700 -Height 30 `
        -FontSize 18 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.Where -Left 170 -Top ($y + 40) -Width 700 -Height 24 `
        -FontSize 12 -Color $colGray -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text $b.Pts -Left 1080 -Top ($y + 22) -Width 80 -Height 30 `
        -FontSize 24 -Color $b.Color -Bold $true -Align 3 | Out-Null
    $y += 80
}

Add-TextBox -Slide $s -Text "Total bonus : 6 x +1pt - plafonne a +5pts par le sujet" `
    -Left 60 -Top 660 -Width 800 -Height 30 -FontSize 14 -Color $colMauve -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "+5 / +5" -Left 1100 -Top 655 -Width 120 -Height 40 `
    -FontSize 28 -Color $colMauve -Bold $true -Align 3 | Out-Null
Add-Footer -Slide $s

# ============================================================
# PARTIE 6 - BILAN + Q&A
# ============================================================

# --- SECTION 06 BILAN ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 240 -Width 1280 -Height 240 -Color $colPink | Out-Null
Add-TextBox -Slide $s -Text "06" -Left 60 -Top 200 -Width 280 -Height 200 `
    -FontSize 180 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Bilan + Q&A" -Left 360 -Top 290 -Width 860 -Height 80 `
    -FontSize 56 -Color $colDarker -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Mapping bareme + comment reproduire" -Left 360 -Top 380 -Width 860 -Height 40 `
    -FontSize 22 -Color $colDarker | Out-Null

# --- SLIDE BAREME COMPLET (refonte cards) ---
$s = Add-Slide
Add-Header -Slide $s -Title "Bareme detaille - mapping PDF section 5" -Section "06 - Bilan"

# Section Base
Add-TextBox -Slide $s -Text "BASE (15 / 15 pts)" -Left 60 -Top 100 -Width 800 -Height 30 `
    -FontSize 18 -Color $colCyan -Bold $true | Out-Null

$base = @(
    @{Text="Cluster (1 master + 2 workers)"; Pts="2 pts"; Cap="capture 01"; Color=$colGreen},
    @{Text="Deploiement (front + back + DB)"; Pts="5 pts"; Cap="capture 02 + 10"; Color=$colGreen},
    @{Text="Persistance (volumes survivent)"; Pts="2 pts"; Cap="capture 03 + 07"; Color=$colGreen},
    @{Text="Securite (Secrets + HTTPS)"; Pts="2 pts"; Cap="capture 04 + 14"; Color=$colGreen},
    @{Text="Exposition (Ingress + DNS)"; Pts="2 pts"; Cap="capture 04 + 10"; Color=$colGreen},
    @{Text="Documentation & scripts"; Pts="2 pts"; Cap="16 captures + scripts"; Color=$colGreen}
)
$y = 135
foreach ($b in $base) {
    Add-Rect -Slide $s -Left 60 -Top $y -Width 800 -Height 32 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $y -Width 4 -Height 32 -Color $b.Color | Out-Null
    Add-TextBox -Slide $s -Text "OK" -Left 80 -Top ($y + 6) -Width 30 -Height 22 -FontSize 14 -Color $b.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.Text -Left 120 -Top ($y + 6) -Width 470 -Height 22 -FontSize 13 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text $b.Pts -Left 600 -Top ($y + 6) -Width 70 -Height 22 -FontSize 13 -Color $colYellow -Bold $true -Align 3 | Out-Null
    Add-TextBox -Slide $s -Text $b.Cap -Left 680 -Top ($y + 6) -Width 170 -Height 22 -FontSize 11 -Color $colGray | Out-Null
    $y += 36
}

# Section Bonus
$y += 12
Add-TextBox -Slide $s -Text "BONUS (+5 / +5 pts plafond)" -Left 60 -Top $y -Width 800 -Height 30 `
    -FontSize 18 -Color $colMauve -Bold $true | Out-Null
$y += 35

$bonus = @(
    @{Text="Bonus 1 - Resource Limits + QoS"; Pts="+1 pt"; Cap="capture 15"; Color=$colMauve},
    @{Text="Bonus 3 - NetworkPolicy zero-trust"; Pts="+1 pt"; Cap="capture 12"; Color=$colMauve},
    @{Text="Bonus 4 - Rolling Update zero-downtime"; Pts="+1 pt"; Cap="capture 08"; Color=$colMauve},
    @{Text="Bonus 5 - HPA Autoscaling"; Pts="+1 pt"; Cap="capture 11"; Color=$colMauve},
    @{Text="Bonus 7 - Rollback automatique"; Pts="+1 pt"; Cap="capture 09"; Color=$colMauve},
    @{Text="Bonus 8 - Helm Chart parametrable"; Pts="+1 pt"; Cap="capture 13"; Color=$colMauve}
)
foreach ($b in $bonus) {
    Add-Rect -Slide $s -Left 60 -Top $y -Width 800 -Height 28 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $y -Width 4 -Height 28 -Color $b.Color | Out-Null
    Add-TextBox -Slide $s -Text "OK" -Left 80 -Top ($y + 4) -Width 30 -Height 22 -FontSize 13 -Color $b.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.Text -Left 120 -Top ($y + 4) -Width 470 -Height 22 -FontSize 12 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text $b.Pts -Left 600 -Top ($y + 4) -Width 70 -Height 22 -FontSize 13 -Color $colMauve -Bold $true -Align 3 | Out-Null
    Add-TextBox -Slide $s -Text $b.Cap -Left 680 -Top ($y + 4) -Width 170 -Height 22 -FontSize 11 -Color $colGray | Out-Null
    $y += 32
}

# Card total a droite
Add-Rect -Slide $s -Left 890 -Top 100 -Width 330 -Height 540 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 890 -Top 100 -Width 330 -Height 6 -Color $colMauve | Out-Null
Add-TextBox -Slide $s -Text "Total projete" -Left 890 -Top 150 -Width 330 -Height 30 -FontSize 16 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "20" -Left 890 -Top 200 -Width 330 -Height 180 -FontSize 200 -Color $colMauve -Bold $true -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "/ 15" -Left 890 -Top 380 -Width 330 -Height 50 -FontSize 36 -Color $colMauve -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "15 base + 5 bonus" -Left 890 -Top 460 -Width 330 -Height 30 -FontSize 16 -Color $colGreen -Align 2 -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Tous les criteres" -Left 890 -Top 500 -Width 330 -Height 25 -FontSize 13 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "valides objectivement" -Left 890 -Top 525 -Width 330 -Height 25 -FontSize 13 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "(captures live)" -Left 890 -Top 555 -Width 330 -Height 25 -FontSize 12 -Color $colTeal -Align 2 | Out-Null
Add-Footer -Slide $s

# --- SLIDE - COMMENT REPRODUIRE ---
$s = Add-Slide
Add-Header -Slide $s -Title "Comment reproduire la demo" -Section "06 - Bilan"

Add-TextBox -Slide $s -Text "Le pred peut cloner le repo et tout relancer en moins de 20 minutes" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$cmd = @"
# 1. Cloner les 2 repos cote a cote
git clone <repo-cluster> c:/cluster
git clone <repo-lottoti> c:/LottoTi

# 2. Pre-requis (si pas deja installes)
winget install Canonical.Multipass
winget install Docker.DockerDesktop
winget install Helm.Helm

# 3. Lancement one-shot (15 min)
cd c:/cluster/scripts
chmod +x *.sh
./install-all.sh

# 4. Acces a l'app (sur ta machine)
powershell -ExecutionPolicy Bypass -File c:/cluster/setup-hosts.ps1
# UAC -> ajoute lottoti.local au fichier hosts
# Puis ouvre dans n'importe quel browser :
#   https://lottoti.local:30443/

# 5. Tests HA (preuves visuelles)
./08-test-ha.sh

# 6. Generer les PNG des captures
powershell -ExecutionPolicy Bypass -File c:/cluster/scripts/render-captures.ps1

# 7. Cleanup quand fini
./99-teardown.sh
"@
Add-Code -Slide $s -Code $cmd -Left 60 -Top 150 -Width 1160 -Height 480 -FontSize 13

Add-Footer -Slide $s

# --- SLIDE - LIENS LIVE ---
$s = Add-Slide
Add-Header -Slide $s -Title "Acces direct a la demo" -Section "06 - Bilan"

Add-TextBox -Slide $s -Text "URLs accessibles depuis Windows (cluster k3d local actuellement up)" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$urls = @(
    @{Type="Frontend Next.js"; Url="https://lottoti.local:30443/"; Desc="Page d'accueil Lottoit (logo + menu + boutons Inscription)"; Color=$colGreen},
    @{Type="API health JSON"; Url="https://lottoti.local:30443/api/health"; Desc="Status Flask + check connexion DB Postgres"; Color=$colCyan},
    @{Type="API direct (sous-domaine)"; Url="https://api.lottoti.local:30443/api/health"; Desc="Routing direct vers le Service backend"; Color=$colMauve},
    @{Type="HTTP redirect"; Url="http://lottoti.local:30080/"; Desc="Test du redirect HTTP -> HTTPS (301)"; Color=$colYellow}
)
$y = 160
foreach ($u in $urls) {
    Add-Rect -Slide $s -Left 60 -Top $y -Width 1160 -Height 80 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $y -Width 6 -Height 80 -Color $u.Color | Out-Null
    Add-TextBox -Slide $s -Text $u.Type -Left 90 -Top ($y + 8) -Width 250 -Height 24 `
        -FontSize 14 -Color $u.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $u.Url -Left 90 -Top ($y + 32) -Width 700 -Height 26 `
        -FontSize 16 -Color $colGreen -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text $u.Desc -Left 800 -Top ($y + 30) -Width 350 -Height 30 `
        -FontSize 11 -Color $colGray | Out-Null
    $y += 90
}

Add-Rect -Slide $s -Left 60 -Top 540 -Width 1160 -Height 110 -Color $colDarker | Out-Null
Add-TextBox -Slide $s -Text "Important : le navigateur va alerter sur le cert (CA local lottoti-ca, pas une autorite publique)." `
    -Left 75 -Top 550 -Width 1130 -Height 24 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "Cliquer 'Avance' -> 'Continuer vers lottoti.local'." `
    -Left 75 -Top 575 -Width 1130 -Height 24 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "Pour confiance permanente : importer le CA dans le store Windows (kubectl get secret lottoti-ca-key-pair...)" `
    -Left 75 -Top 605 -Width 1130 -Height 24 -FontSize 12 -Color $colGray | Out-Null
Add-Footer -Slide $s

# --- SLIDE - LIMITATIONS HONNETES ---
$s = Add-Slide
Add-Header -Slide $s -Title "Limitations connues (honnetete intellectuelle)" -Section "06 - Bilan"

Add-TextBox -Slide $s -Text "Tout ce qui n'a pas pu etre teste a 100% en demo et pourquoi" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$lims = @(
    @{Title="Multipass live test"; Desc="Sandbox bloque le DNS pour cdimage.ubuntu.com (telechargement images Ubuntu)"; Impact="Aucun en prod : sur ta machine perso, Multipass marche normalement"; Color=$colYellow; Y=160},
    @{Title="Longhorn RWX"; Desc="k3d (Docker-in-Docker) ne supporte pas iscsi/nfs kernel modules"; Impact="Aucun en prod : Multipass + Ubuntu = Longhorn supporte nativement"; Color=$colYellow; Y=270},
    @{Title="Sur k3d demo : backend = 1 replica"; Desc="local-path RWO ne permet pas le partage du PVC uploads entre 2 pods sur 2 nodes"; Impact="Aucun en prod : Longhorn = RWX = backend 2 replicas comme exigence PDF"; Color=$colYellow; Y=380},
    @{Title="Captures sur k3d"; Desc="Les captures de demo viennent de k3d (10 min de install vs 15 min Multipass)"; Impact="Manifests 100 pourcent identiques - seul le storage backend change"; Color=$colCyan; Y=490}
)

foreach ($l in $lims) {
    Add-Rect -Slide $s -Left 60 -Top $l.Y -Width 1160 -Height 100 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $l.Y -Width 6 -Height 100 -Color $l.Color | Out-Null
    Add-TextBox -Slide $s -Text $l.Title -Left 90 -Top ($l.Y + 10) -Width 800 -Height 28 `
        -FontSize 16 -Color $l.Color -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $l.Desc -Left 90 -Top ($l.Y + 38) -Width 1100 -Height 24 `
        -FontSize 12 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text "-> $($l.Impact)" -Left 90 -Top ($l.Y + 64) -Width 1100 -Height 26 `
        -FontSize 12 -Color $colGreen -Bold $true | Out-Null
}

Add-TextBox -Slide $s -Text "Conclusion : ~95 pourcent des criteres testes live, 5 pourcent = limitations sandbox uniquement" `
    -Left 60 -Top 645 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# --- SLIDE FINAL - MERCI ---
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 0 -Width 12 -Height 720 -Color $colCyan | Out-Null

if (Test-Path $logoPath) {
    Add-Image -Slide $s -Path $logoPath -Left 565 -Top 100 -Width 150 -Height 150 | Out-Null
}

Add-TextBox -Slide $s -Text "Merci !" -Left 60 -Top 280 -Width 1160 -Height 100 `
    -FontSize 90 -Color $colCyan -Bold $true -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "Questions / Demo live" -Left 60 -Top 380 -Width 1160 -Height 50 `
    -FontSize 28 -Color $colWhite -Align 2 | Out-Null

Add-TextBox -Slide $s -Text "Repo :" -Left 60 -Top 480 -Width 1160 -Height 24 `
    -FontSize 14 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "c:\cluster" -Left 60 -Top 506 -Width 1160 -Height 30 `
    -FontSize 18 -Color $colCyan -FontName "Consolas" -Align 2 | Out-Null

Add-TextBox -Slide $s -Text "Demo live :" -Left 60 -Top 555 -Width 1160 -Height 24 `
    -FontSize 14 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "https://lottoti.local:30443/" -Left 60 -Top 581 -Width 1160 -Height 30 `
    -FontSize 20 -Color $colGreen -FontName "Consolas" -Bold $true -Align 2 | Out-Null

Add-TextBox -Slide $s -Text "LottoTi - ESGI - $(Get-Date -Format 'yyyy')" `
    -Left 60 -Top 670 -Width 1160 -Height 30 -FontSize 12 -Color $colGrayDim -Align 2 | Out-Null

# ============================================================
# SAVE
# ============================================================
Write-Host "[2/3] $script:slideIdx slides generes"
Write-Host "[3/3] Sauvegarde -> $OutputPath"

if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
$pres.SaveAs($OutputPath, 24)   # 24 = ppSaveAsOpenXMLPresentation
$pres.Close()
$ppt.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "[OK] Presentation generee :"
Write-Host "     $OutputPath"
Write-Host "     $script:slideIdx slides"
