# ============================================================
# generate-pptx-short.ps1 - Version courte 15 slides
# Pour soutenance / oral classique
# ============================================================
param(
    [string]$OutputPath = "$PSScriptRoot/../docs/Presentation_LottoTi_Short.pptx",
    [string]$CapturesDir = "$PSScriptRoot/../docs/captures/output",
    [string]$AssetsDir = "$PSScriptRoot/../docs/assets"
)

$ErrorActionPreference = "Stop"
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$CapturesDir = [System.IO.Path]::GetFullPath($CapturesDir)
$AssetsDir = [System.IO.Path]::GetFullPath($AssetsDir)

# ---- Couleurs ----
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
    param($Slide, [string]$Text, [int]$Left=60, [int]$Top=60, [int]$Width=1160, [int]$Height=60,
        [int]$FontSize=24, [int]$Color=$colWhite, [bool]$Bold=$false,
        [string]$FontName="Segoe UI", [int]$Align=1)
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
    param($Slide, [int]$Left, [int]$Top, [int]$Width, [int]$Height, [int]$Color=$colDarkLight)
    $shape = $Slide.Shapes.AddShape(1, $Left, $Top, $Width, $Height)
    $shape.Fill.ForeColor.RGB = $Color
    $shape.Line.Visible = $msoFalse
    return $shape
}
function Add-Header {
    param($Slide, [string]$Title, [string]$Subtitle="")
    Add-Rect -Slide $Slide -Left 0 -Top 0 -Width 1280 -Height 80 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $Slide -Left 0 -Top 0 -Width 6 -Height 80 -Color $colCyan | Out-Null
    Add-TextBox -Slide $Slide -Text $Title -Left 30 -Top 16 -Width 1100 -Height 40 `
        -FontSize 28 -Color $colCyan -Bold $true | Out-Null
    if ($Subtitle) {
        Add-TextBox -Slide $Slide -Text $Subtitle -Left 30 -Top 50 -Width 1100 -Height 24 `
            -FontSize 14 -Color $colGray | Out-Null
    }
}
function Add-Footer {
    param($Slide)
    Add-TextBox -Slide $Slide -Text "LottoTi - Clusterisation de container - ESGI" `
        -Left 30 -Top 690 -Width 800 -Height 20 -FontSize 10 -Color $colGrayDim | Out-Null
    Add-TextBox -Slide $Slide -Text "$script:slideIdx / 15" `
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
function Add-Code {
    param($Slide, [string]$Code, [int]$Left=60, [int]$Top=120, [int]$Width=1160, [int]$Height=480, [int]$FontSize=13)
    Add-Rect -Slide $Slide -Left $Left -Top $Top -Width $Width -Height $Height -Color $colDarker | Out-Null
    Add-TextBox -Slide $Slide -Text $Code -Left ($Left+20) -Top ($Top+15) -Width ($Width-40) -Height ($Height-30) `
        -FontSize $FontSize -Color $colGreen -FontName "Consolas" | Out-Null
}

# ============================================================
# SLIDE 1 - COVER
# ============================================================
$s = Add-Slide
Add-Rect -Slide $s -Left 0 -Top 0 -Width 1280 -Height 720 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 0 -Top 0 -Width 12 -Height 720 -Color $colCyan | Out-Null

$logoPath = Join-Path $AssetsDir "lottoti-logo.png"
if (Test-Path $logoPath) {
    Add-Image -Slide $s -Path $logoPath -Left 80 -Top 130 -Width 130 -Height 130 | Out-Null
}

Add-TextBox -Slide $s -Text "LottoTi" -Left 230 -Top 150 -Width 800 -Height 100 `
    -FontSize 70 -Color $colCyan -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Clusterisation de container" -Left 230 -Top 230 -Width 900 -Height 50 `
    -FontSize 28 -Color $colWhite | Out-Null
Add-TextBox -Slide $s -Text "Projet final ESGI" -Left 230 -Top 280 -Width 900 -Height 30 `
    -FontSize 16 -Color $colGray | Out-Null

# Stats badges (3 cards)
$y = 400
Add-Rect -Slide $s -Left 80 -Top $y -Width 360 -Height 100 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Cluster" -Left 100 -Top ($y+15) -Width 320 -Height 22 -FontSize 13 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "1 master + 2 workers" -Left 100 -Top ($y+38) -Width 320 -Height 32 -FontSize 22 -Color $colGreen -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "k3s v1.31.5" -Left 100 -Top ($y+72) -Width 320 -Height 22 -FontSize 13 -Color $colTeal | Out-Null

Add-Rect -Slide $s -Left 460 -Top $y -Width 360 -Height 100 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Replicas (PDF)" -Left 480 -Top ($y+15) -Width 320 -Height 22 -FontSize 13 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "2 backend + 3 frontend" -Left 480 -Top ($y+38) -Width 320 -Height 32 -FontSize 22 -Color $colGreen -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Flask + Next.js + PG + Redis" -Left 480 -Top ($y+72) -Width 320 -Height 22 -FontSize 13 -Color $colTeal | Out-Null

Add-Rect -Slide $s -Left 840 -Top $y -Width 360 -Height 100 -Color $colDarkLight | Out-Null
Add-TextBox -Slide $s -Text "Note projetee" -Left 860 -Top ($y+15) -Width 320 -Height 22 -FontSize 13 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "20 / 15" -Left 860 -Top ($y+33) -Width 320 -Height 50 -FontSize 36 -Color $colMauve -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "15 base + 5 bonus" -Left 860 -Top ($y+78) -Width 320 -Height 22 -FontSize 13 -Color $colTeal | Out-Null

Add-TextBox -Slide $s -Text "Date : $(Get-Date -Format 'dd MMMM yyyy')" -Left 80 -Top 660 -Width 1100 -Height 20 `
    -FontSize 12 -Color $colGrayDim | Out-Null

# ============================================================
# SLIDE 2 - SOMMAIRE
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Sommaire" -Subtitle "Plan de la presentation"

$plan = @(
    @{N="01"; T="Le projet LottoTi"; D="Stack applicative existante (docker-compose)"; C=$colCyan; Y=130},
    @{N="02"; T="Architecture cluster"; D="Diagramme d'ensemble + topologie 3 noeuds"; C=$colMauve; Y=210},
    @{N="03"; T="Steps d'installation"; D="8 etapes scriptees pour reproduire le cluster"; C=$colGreen; Y=290},
    @{N="04"; T="Securite"; D="Secrets, HTTPS, NetworkPolicy zero-trust"; C=$colYellow; Y=370},
    @{N="05"; T="Persistance"; D="PVC + StatefulSets - donnees survivent"; C=$colOrange; Y=450},
    @{N="06"; T="Haute disponibilite + Bonus + Bilan"; D="Replicas, HPA, Rolling, Rollback - Note 20/15"; C=$colPink; Y=530}
)
foreach ($p in $plan) {
    Add-Rect -Slide $s -Left 80 -Top $p.Y -Width 1120 -Height 60 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 80 -Top $p.Y -Width 6 -Height 60 -Color $p.C | Out-Null
    Add-TextBox -Slide $s -Text $p.N -Left 110 -Top ($p.Y+15) -Width 70 -Height 30 -FontSize 22 -Color $p.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $p.T -Left 190 -Top ($p.Y+8) -Width 400 -Height 30 -FontSize 18 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $p.D -Left 190 -Top ($p.Y+34) -Width 1000 -Height 24 -FontSize 13 -Color $colGray | Out-Null
}
Add-Footer -Slide $s

# ============================================================
# SLIDE 3 - LE PROJET LOTTOTI
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Le projet LottoTi" -Subtitle "Plateforme de location de vehicules entre particuliers"

Add-TextBox -Slide $s -Text "Stack applicative deja conteneurisee (docker-compose) - 5 services" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$stack = @(
    @{T="Frontend"; D="Next.js 15 (standalone) - port 3000 - SSR React"; C=$colCyan; Y=170},
    @{T="Backend"; D="Flask + Gunicorn-gevent + Socket.IO - port 5000"; C=$colGreen; Y=250},
    @{T="Database"; D="PostgreSQL 16 (alpine) - port 5432 - users, vehicules, paiements"; C=$colMauve; Y=330},
    @{T="Cache"; D="Redis 7 (alpine) - port 6379 - sessions, rate limiting, pubsub"; C=$colYellow; Y=410},
    @{T="Reverse proxy"; D="Nginx (compose) - remplace par Ingress Traefik en cluster"; C=$colOrange; Y=490}
)
foreach ($svc in $stack) {
    Add-Rect -Slide $s -Left 60 -Top $svc.Y -Width 1160 -Height 60 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $svc.Y -Width 8 -Height 60 -Color $svc.C | Out-Null
    Add-TextBox -Slide $s -Text $svc.T -Left 90 -Top ($svc.Y+18) -Width 200 -Height 30 -FontSize 18 -Color $svc.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $svc.D -Left 310 -Top ($svc.Y+18) -Width 880 -Height 30 -FontSize 14 -Color $colWhite | Out-Null
}

Add-TextBox -Slide $s -Text "Mission ESGI : transposer cette stack vers Kubernetes pour HA + securite + persistance" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 14 -Color $colYellow -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 4 - DIAGRAMME ARCHITECTURE
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Architecture cluster Kubernetes" -Subtitle "Vue d'ensemble - flux des requetes"

$diag = @"
                          UTILISATEUR
                       https://lottoti.local
                                |
                                | port 30443 (NodePort)
                                v
   +============================================================+
   ||                       CLUSTER k3s                         ||
   ||                                                           ||
   ||   +---------------------------------------------------+   ||
   ||   |  TRAEFIK (Ingress controller, namespace traefik)  |   ||
   ||   |  - termine TLS (cert lottoti-ca)                  |   ||
   ||   |  - rate limit + security headers                  |   ||
   ||   +---------------------------------------------------+   ||
   ||                          |                                ||
   ||              +-----------+-----------+                    ||
   ||              v /api/*                v /*                 ||
   ||                                                           ||
   ||   +----------------+         +----------------+           ||
   ||   | Service backend|         | Service frontend|          ||
   ||   |   :5000        |         |   :3000         |          ||
   ||   +----------------+         +----------------+           ||
   ||      |   |  (LB)                |   |   |  (LB)           ||
   ||      v   v                      v   v   v                 ||
   ||   +----+----+                +----+----+----+             ||
   ||   |Pod1|Pod2|                |Pod1|Pod2|Pod3|             ||
   ||   |API |API |                |FE1 |FE2 |FE3 |             ||
   ||   +----+----+                +----+----+----+             ||
   ||      |  |                                                 ||
   ||      v  v                                                 ||
   ||   +----------+    +----------+    +-----------------+     ||
   ||   | postgres | -> | PVC 5Gi  |    | NetworkPolicies |     ||
   ||   | StatefulSet|  | longhorn |    | zero-trust (8)  |     ||
   ||   +----------+    +----------+    +-----------------+     ||
   ||   | redis    | -> | PVC 1Gi  |    | Secrets +       |     ||
   ||   +----------+    +----------+    | ConfigMaps      |     ||
   ||                                   +-----------------+     ||
   +============================================================+
"@
Add-Code -Slide $s -Code $diag -Left 60 -Top 110 -Width 1160 -Height 560 -FontSize 12
Add-Footer -Slide $s

# ============================================================
# SLIDE 5 - TOPOLOGIE 3 NOEUDS
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Topologie : 3 noeuds (1 master + 2 workers)" -Subtitle "Exigence PDF section 3.1"

Add-TextBox -Slide $s -Text "3 VMs Ubuntu 22.04 via Multipass - cluster k3s v1.31.5" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colGray | Out-Null

$nodes = @(
    @{T="master"; R="control-plane"; CPU="2 vCPU"; RAM="2 Go"; P="API server, scheduler, etcd, frontend(1)"; C=$colMauve; X=60},
    @{T="worker1"; R="app + storage"; CPU="2 vCPU"; RAM="3 Go"; P="backend(2), postgres, frontend(1)"; C=$colGreen; X=470},
    @{T="worker2"; R="app + storage"; CPU="2 vCPU"; RAM="3 Go"; P="redis, frontend(1)"; C=$colCyan; X=880}
)
foreach ($n in $nodes) {
    Add-Rect -Slide $s -Left $n.X -Top 160 -Width 340 -Height 380 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left $n.X -Top 160 -Width 340 -Height 8 -Color $n.C | Out-Null
    Add-TextBox -Slide $s -Text $n.T -Left ($n.X+20) -Top 180 -Width 300 -Height 40 -FontSize 24 -Color $n.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $n.R -Left ($n.X+20) -Top 220 -Width 300 -Height 24 -FontSize 13 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text "CPU" -Left ($n.X+20) -Top 260 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.CPU -Left ($n.X+20) -Top 278 -Width 300 -Height 24 -FontSize 16 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text "RAM" -Left ($n.X+20) -Top 320 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.RAM -Left ($n.X+20) -Top 338 -Width 300 -Height 24 -FontSize 16 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text "Pods" -Left ($n.X+20) -Top 400 -Width 300 -Height 20 -FontSize 11 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text $n.P -Left ($n.X+20) -Top 420 -Width 300 -Height 100 -FontSize 13 -Color $colWhite | Out-Null
}

Add-TextBox -Slide $s -Text "PodAntiAffinity : frontend repartis sur les 3 nodes (resilience aux pannes)" `
    -Left 60 -Top 580 -Width 1160 -Height 30 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "Labels appliques : storage=true, lottoti.io/role=app" `
    -Left 60 -Top 610 -Width 1160 -Height 30 -FontSize 13 -Color $colGray | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 6 - STEPS D'INSTALLATION (resume)
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Steps d'installation" -Subtitle "8 etapes scriptees - install-all.sh (~15 min)"

$steps = @(
    @{N="1"; T="Creation 3 VMs Multipass"; F="01-create-vms.sh"; D="Ubuntu 22.04 - master + worker1 + worker2"; C=$colCyan; Y=120},
    @{N="2"; T="Installation k3s"; F="02-install-k3s.sh"; D="server sur master + agents sur workers"; C=$colGreen; Y=180},
    @{N="3"; T="Installation Longhorn"; F="03-install-storage.sh"; D="Storage RWX pour le PVC uploads"; C=$colMauve; Y=240},
    @{N="4"; T="Installation cert-manager"; F="04-install-cert-manager.sh"; D="Generation CA local + ClusterIssuer"; C=$colYellow; Y=300},
    @{N="5"; T="Installation Traefik Ingress"; F="05-install-ingress.sh"; D="Helm chart - NodePort 30443/30080"; C=$colOrange; Y=360},
    @{N="6"; T="Build & import images"; F="06-build-images.sh"; D="docker build + k3s ctr import sur les 3 nodes"; C=$colTeal; Y=420},
    @{N="7"; T="Deploy LottoTi"; F="07-deploy.sh"; D="kubectl apply -k - 36 manifests Kustomize"; C=$colPink; Y=480},
    @{N="8"; T="Tests HA"; F="08-test-ha.sh"; D="kill pods, scale, rolling update + captures"; C=$colRed; Y=540}
)
foreach ($st in $steps) {
    Add-Rect -Slide $s -Left 60 -Top $st.Y -Width 1160 -Height 50 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $st.Y -Width 6 -Height 50 -Color $st.C | Out-Null
    Add-TextBox -Slide $s -Text $st.N -Left 80 -Top ($st.Y+10) -Width 40 -Height 30 -FontSize 22 -Color $st.C -Bold $true -Align 2 | Out-Null
    Add-TextBox -Slide $s -Text $st.T -Left 140 -Top ($st.Y+8) -Width 400 -Height 24 -FontSize 16 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $st.F -Left 140 -Top ($st.Y+28) -Width 250 -Height 20 -FontSize 11 -Color $colGreen -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text $st.D -Left 560 -Top ($st.Y+15) -Width 640 -Height 24 -FontSize 12 -Color $colGray | Out-Null
}

Add-TextBox -Slide $s -Text "Resultat : cluster k3s + LottoTi up - https://lottoti.local:30443/" `
    -Left 60 -Top 610 -Width 1160 -Height 30 -FontSize 14 -Color $colGreen -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 7 - SECURITE : SECRETS & CONFIGMAPS
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Securite : Secrets & ConfigMaps" -Subtitle "PDF section 3.4 - separation valeurs sensibles vs config"

# 2 colonnes Secret vs ConfigMap
# Colonne Secret (gauche)
Add-Rect -Slide $s -Left 60 -Top 120 -Width 580 -Height 470 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 60 -Top 120 -Width 580 -Height 8 -Color $colRed | Out-Null
Add-TextBox -Slide $s -Text "SECRET" -Left 80 -Top 140 -Width 540 -Height 30 -FontSize 18 -Color $colRed -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Donnees sensibles - chiffrees dans etcd" -Left 80 -Top 170 -Width 540 -Height 22 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "lottoti-secrets (5 cles Opaque):" -Left 80 -Top 210 -Width 540 -Height 24 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
$secretKeys = @(
    "POSTGRES_PASSWORD",
    "FLASK_SECRET_KEY",
    "JWT_SECRET_KEY",
    "STRIPE_SECRET_KEY",
    "STRIPE_WEBHOOK_SECRET"
)
$y = 245
foreach ($k in $secretKeys) {
    Add-TextBox -Slide $s -Text "  - $k" -Left 80 -Top $y -Width 540 -Height 24 -FontSize 13 -Color $colYellow -FontName "Consolas" | Out-Null
    $y += 28
}
Add-TextBox -Slide $s -Text "lottoti-tls (kubernetes.io/tls):" -Left 80 -Top 400 -Width 540 -Height 24 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "  - tls.crt + tls.key (cert HTTPS)" -Left 80 -Top 425 -Width 540 -Height 24 -FontSize 13 -Color $colYellow -FontName "Consolas" | Out-Null
Add-TextBox -Slide $s -Text "kubectl describe secret ne montre" -Left 80 -Top 480 -Width 540 -Height 22 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "que les TAILLES (jamais les valeurs)" -Left 80 -Top 502 -Width 540 -Height 22 -FontSize 12 -Color $colGray | Out-Null

# Colonne ConfigMap (droite)
Add-Rect -Slide $s -Left 660 -Top 120 -Width 560 -Height 470 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 660 -Top 120 -Width 560 -Height 8 -Color $colCyan | Out-Null
Add-TextBox -Slide $s -Text "CONFIGMAP" -Left 680 -Top 140 -Width 520 -Height 30 -FontSize 18 -Color $colCyan -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Variables non sensibles - en clair" -Left 680 -Top 170 -Width 520 -Height 22 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "backend-config (7 cles):" -Left 680 -Top 210 -Width 520 -Height 24 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
$cmKeys = @(
    "FLASK_ENV=production",
    "PORT=5000",
    "LOG_LEVEL=info",
    "FRONTEND_URL=https://lottoti.local",
    "CORS_ORIGINS=https://lottoti.local"
)
$y = 245
foreach ($k in $cmKeys) {
    Add-TextBox -Slide $s -Text "  - $k" -Left 680 -Top $y -Width 520 -Height 24 -FontSize 12 -Color $colGreen -FontName "Consolas" | Out-Null
    $y += 28
}
Add-TextBox -Slide $s -Text "postgres-config:" -Left 680 -Top 400 -Width 520 -Height 24 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "  - POSTGRES_DB, POSTGRES_USER" -Left 680 -Top 425 -Width 520 -Height 24 -FontSize 12 -Color $colGreen -FontName "Consolas" | Out-Null
Add-TextBox -Slide $s -Text "  - postgresql.conf (tuning DB)" -Left 680 -Top 450 -Width 520 -Height 24 -FontSize 12 -Color $colGreen -FontName "Consolas" | Out-Null
Add-TextBox -Slide $s -Text "Injectes dans les pods via" -Left 680 -Top 502 -Width 520 -Height 22 -FontSize 12 -Color $colGray | Out-Null
Add-TextBox -Slide $s -Text "envFrom: configMapRef" -Left 680 -Top 522 -Width 520 -Height 22 -FontSize 12 -Color $colGray -FontName "Consolas" | Out-Null

Add-TextBox -Slide $s -Text "Regle d'or : si la valeur etait fuitee, est-ce un probleme ? -> Secret. Sinon -> ConfigMap." `
    -Left 60 -Top 615 -Width 1160 -Height 30 -FontSize 13 -Color $colYellow -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 8 - SECURITE : HTTPS + CERT-MANAGER + INGRESS
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Securite : HTTPS + Ingress" -Subtitle "PDF section 3.4 et 3.5 - cert-manager genere automatiquement le cert TLS"

# Diagramme du flux cert
$flow = @"
   selfsigned-bootstrap (ClusterIssuer)
            |
            | signe
            v
   lottoti-ca (Certificate)               <-- notre Autorite de Certification locale
            |
            | devient un
            v
   lottoti-ca-issuer (ClusterIssuer)
            |
            | signe
            v
   lottoti-tls (Certificate)              <-- cert pour lottoti.local
            |
            | utilise par
            v
   Ingress (Traefik)                      <-- termine TLS sur :443
            |
            | route HTTPS
            v
   Services backend / frontend
"@
Add-Code -Slide $s -Code $flow -Left 60 -Top 110 -Width 720 -Height 460 -FontSize 13

# Card a droite : routes Ingress
Add-Rect -Slide $s -Left 800 -Top 110 -Width 420 -Height 460 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 800 -Top 110 -Width 420 -Height 8 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "Routes Ingress" -Left 820 -Top 130 -Width 380 -Height 30 -FontSize 18 -Color $colYellow -Bold $true | Out-Null

$routes = @(
    @{P="/api/health"; T="backend"; R="ratelimit-health (1/s)"; C=$colCyan},
    @{P="/api/auth"; T="backend"; R="ratelimit-auth (5/s)"; C=$colRed},
    @{P="/api/*"; T="backend"; R="ratelimit-api (30/s)"; C=$colGreen},
    @{P="/socket.io"; T="backend"; R="WebSocket"; C=$colMauve},
    @{P="/*"; T="frontend"; R="Next.js SSR"; C=$colTeal}
)
$y = 175
foreach ($r in $routes) {
    Add-TextBox -Slide $s -Text $r.P -Left 820 -Top $y -Width 140 -Height 24 -FontSize 13 -Color $r.C -Bold $true -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text "-> $($r.T)" -Left 970 -Top $y -Width 100 -Height 24 -FontSize 13 -Color $colWhite -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text $r.R -Left 820 -Top ($y+22) -Width 380 -Height 22 -FontSize 11 -Color $colGray | Out-Null
    $y += 60
}

Add-TextBox -Slide $s -Text "Securite :" -Left 820 -Top 480 -Width 380 -Height 22 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "+ HTTP -> HTTPS redirect 301" -Left 820 -Top 502 -Width 380 -Height 22 -FontSize 12 -Color $colGreen | Out-Null
Add-TextBox -Slide $s -Text "+ HSTS, CSP, X-Frame-Options" -Left 820 -Top 522 -Width 380 -Height 22 -FontSize 12 -Color $colGreen | Out-Null
Add-TextBox -Slide $s -Text "+ Renouvelement auto 30j avant" -Left 820 -Top 542 -Width 380 -Height 22 -FontSize 12 -Color $colGreen | Out-Null

Add-TextBox -Slide $s -Text "Demo live : https://lottoti.local:30443/ -> Lottoit en HTTPS, cert signe par lottoti-ca" `
    -Left 60 -Top 615 -Width 1160 -Height 30 -FontSize 13 -Color $colYellow -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 9 - SECURITE : NETWORKPOLICY ZERO-TRUST
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Securite : NetworkPolicy zero-trust" -Subtitle "Bonus 3 (+1 pt) - 8 policies"

Add-TextBox -Slide $s -Text "Approche : default-deny + allow explicite. Si un pod est compromis, il ne peut atteindre QUE ce qui est autorise." `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 14 -Color $colWhite | Out-Null

# Diagramme matriciel
$matrix = @"
                                            DESTINATION
                |  postgres  |   redis   |  backend  | frontend  | DNS  | Internet
   ============================================================================
   frontend     |   BLOQUE   |  BLOQUE   |    OK     |    -      |  OK  |  HTTPS
   backend      |    OK 5432 |  OK 6379  |    -      |   BLOQUE  |  OK  |  HTTPS
   postgres     |    -       |  BLOQUE   |  BLOQUE   |   BLOQUE  |  OK  |  BLOQUE
   redis        |   BLOQUE   |    -      |  BLOQUE   |   BLOQUE  |  OK  |  BLOQUE
   traefik (ns) |   BLOQUE   |  BLOQUE   |   OK 5000 |   OK 3000 |  OK  |  -

      OK = trafic autorise par une NetworkPolicy
      BLOQUE = TCP REJECT (default-deny + pas de policy explicite)
"@
Add-Code -Slide $s -Code $matrix -Left 60 -Top 160 -Width 1160 -Height 280 -FontSize 13

# Resultats tests (en bloc unique pour eviter le bug d'affichage multi-textbox)
Add-TextBox -Slide $s -Text "Tests d'enforcement (live) :" -Left 60 -Top 460 -Width 1160 -Height 30 -FontSize 16 -Color $colYellow -Bold $true | Out-Null

$testsBlock = @"
   frontend -> postgres:5432   [BLOQUE - TCP REJECT]
   backend  -> postgres:5432   [OK - Connection succeeded]
   default ns -> backend:5000  [BLOQUE - Connection refused]
   frontend -> redis:6379      [BLOQUE - NetworkPolicy zero-trust]
"@
Add-Code -Slide $s -Code $testsBlock -Left 60 -Top 495 -Width 1160 -Height 145 -FontSize 14
Add-Footer -Slide $s

# ============================================================
# SLIDE 10 - PERSISTANCE : PVC + STATEFULSETS
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Persistance : PVC + StatefulSets" -Subtitle "PDF section 3.3 - donnees survivent aux redeploiements"

# 3 PVC
Add-TextBox -Slide $s -Text "3 PersistentVolumeClaim provisionnes par Longhorn" `
    -Left 60 -Top 110 -Width 1160 -Height 30 -FontSize 16 -Color $colWhite | Out-Null

$pvcs = @(
    @{N="pgdata-postgres-0"; S="5 Gi"; M="RWO"; U="Donnees Postgres"; C=$colMauve; Y=160},
    @{N="redisdata-redis-0"; S="1 Gi"; M="RWO"; U="AOF Redis (persistance)"; C=$colYellow; Y=230},
    @{N="uploads"; S="5 Gi"; M="RWX"; U="Photos uploadees (partage 2 backend)"; C=$colCyan; Y=300}
)
foreach ($pvc in $pvcs) {
    Add-Rect -Slide $s -Left 60 -Top $pvc.Y -Width 1160 -Height 50 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $pvc.Y -Width 6 -Height 50 -Color $pvc.C | Out-Null
    Add-TextBox -Slide $s -Text $pvc.N -Left 90 -Top ($pvc.Y+13) -Width 320 -Height 24 -FontSize 16 -Color $pvc.C -Bold $true -FontName "Consolas" | Out-Null
    Add-TextBox -Slide $s -Text $pvc.S -Left 430 -Top ($pvc.Y+13) -Width 100 -Height 24 -FontSize 14 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $pvc.M -Left 560 -Top ($pvc.Y+13) -Width 80 -Height 24 -FontSize 14 -Color $colYellow | Out-Null
    Add-TextBox -Slide $s -Text $pvc.U -Left 660 -Top ($pvc.Y+13) -Width 540 -Height 24 -FontSize 13 -Color $colGray | Out-Null
}

# Test live demo
Add-Rect -Slide $s -Left 60 -Top 380 -Width 1160 -Height 250 -Color $colDarker | Out-Null
Add-TextBox -Slide $s -Text "TEST LIVE : la donnee survit au kill du pod" -Left 80 -Top 395 -Width 1100 -Height 30 `
    -FontSize 16 -Color $colGreen -Bold $true | Out-Null

$test = @"
1. INSERT INTO persistence_test (marker) VALUES ('proof_1777283282');
2. PVC pgdata-postgres-0 -> volume = pvc-64fbba8e-fa93-49f7-aeed-03138a8a8abe
3. kubectl delete pod postgres-0 --grace-period=0 --force          [NUKE]
4. Pod recreate par le StatefulSet en ~13 secondes (memes labels, meme PVC)
5. SELECT * FROM persistence_test;  ->  proof_1777283282 TOUJOURS LA
6. PVC volume = pvc-64fbba8e-fa93-49f7-aeed-03138a8a8abe   [IDENTIQUE]

   Verdict : la persistance fonctionne objectivement
"@
Add-TextBox -Slide $s -Text $test -Left 80 -Top 425 -Width 1100 -Height 200 `
    -FontSize 13 -Color $colYellow -FontName "Consolas" | Out-Null

Add-TextBox -Slide $s -Text "(Voir capture 07-kill-db-persistence.png pour la sortie kubectl reelle)" `
    -Left 60 -Top 645 -Width 1160 -Height 25 -FontSize 12 -Color $colGray | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 11 - HA : REPLICAS + ROLLING UPDATE
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Haute Dispo : Replicas + Rolling Update" -Subtitle "Bonus 4 (+1 pt) - zero downtime"

# 2 cards
# Replicas
Add-Rect -Slide $s -Left 60 -Top 110 -Width 580 -Height 270 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 60 -Top 110 -Width 580 -Height 8 -Color $colGreen | Out-Null
Add-TextBox -Slide $s -Text "Replicas (PDF section 3.2.4)" -Left 80 -Top 130 -Width 540 -Height 30 -FontSize 18 -Color $colGreen -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "backend Deployment : replicas: 2" -Left 80 -Top 175 -Width 540 -Height 26 -FontSize 14 -Color $colWhite -FontName "Consolas" | Out-Null
Add-TextBox -Slide $s -Text "frontend Deployment : replicas: 3" -Left 80 -Top 205 -Width 540 -Height 26 -FontSize 14 -Color $colWhite -FontName "Consolas" | Out-Null
Add-TextBox -Slide $s -Text "PodAntiAffinity : repartit sur les 3 nodes" -Left 80 -Top 245 -Width 540 -Height 24 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "PodDisruptionBudget : minAvailable=2 frontend, =1 backend" `
    -Left 80 -Top 270 -Width 540 -Height 24 -FontSize 13 -Color $colYellow | Out-Null
Add-TextBox -Slide $s -Text "Resilience : si un node tombe, les autres prennent le relais" `
    -Left 80 -Top 320 -Width 540 -Height 24 -FontSize 13 -Color $colGray | Out-Null

# Rolling Update
Add-Rect -Slide $s -Left 660 -Top 110 -Width 560 -Height 270 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 660 -Top 110 -Width 560 -Height 8 -Color $colMauve | Out-Null
Add-TextBox -Slide $s -Text "Rolling Update strategy" -Left 680 -Top 130 -Width 520 -Height 30 -FontSize 18 -Color $colMauve -Bold $true | Out-Null

$rolling = @"
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # +1 pod en plus
    maxUnavailable: 0    # JAMAIS moins
"@
Add-TextBox -Slide $s -Text $rolling -Left 680 -Top 170 -Width 520 -Height 130 `
    -FontSize 12 -Color $colGreen -FontName "Consolas" | Out-Null

Add-TextBox -Slide $s -Text "= Toujours >= 3 frontend Ready durant la maj" -Left 680 -Top 320 -Width 520 -Height 24 `
    -FontSize 13 -Color $colYellow -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "= Service jamais down" -Left 680 -Top 345 -Width 520 -Height 24 `
    -FontSize 13 -Color $colYellow -Bold $true | Out-Null

# Capture
$cap = Join-Path $CapturesDir "08-rolling-update.png"
if (Test-Path $cap) {
    Add-Image -Slide $s -Path $cap -Left 60 -Top 400 -Width 1160 -Height 250 | Out-Null
}
Add-Footer -Slide $s

# ============================================================
# SLIDE 12 - HA : HPA + KILL POD RECOVERY
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Haute Dispo : HPA + auto-healing" -Subtitle "Bonus 5 (+1 pt) - autoscaling + recovery automatique"

# 2 cards
Add-Rect -Slide $s -Left 60 -Top 110 -Width 580 -Height 240 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 60 -Top 110 -Width 580 -Height 8 -Color $colCyan | Out-Null
Add-TextBox -Slide $s -Text "HPA (HorizontalPodAutoscaler)" -Left 80 -Top 130 -Width 540 -Height 30 -FontSize 18 -Color $colCyan -Bold $true | Out-Null
$hpa = @"
backend HPA  : 2 -> 8 replicas
frontend HPA : 3 -> 10 replicas

Metriques :
  - CPU > 70% -> scale up
  - Memory > 80% -> scale up

Test live :
  -> SuccessfulRescale 1 -> 2
"@
Add-TextBox -Slide $s -Text $hpa -Left 80 -Top 165 -Width 540 -Height 180 `
    -FontSize 13 -Color $colWhite -FontName "Consolas" | Out-Null

# Recovery
Add-Rect -Slide $s -Left 660 -Top 110 -Width 560 -Height 240 -Color $colDarkLight | Out-Null
Add-Rect -Slide $s -Left 660 -Top 110 -Width 560 -Height 8 -Color $colOrange | Out-Null
Add-TextBox -Slide $s -Text "Auto-healing (kill pod recovery)" -Left 680 -Top 130 -Width 520 -Height 30 -FontSize 18 -Color $colOrange -Bold $true | Out-Null
$recovery = @"
1. kubectl delete pod frontend-X --force
2. ReplicaSet detecte le manque (-1 vs spec)
3. Cree un nouveau pod automatiquement
4. ~8 secondes -> nouveau pod Running

Pas d'intervention humaine.
Service jamais down (les 2 autres
pods continuent de servir).
"@
Add-TextBox -Slide $s -Text $recovery -Left 680 -Top 165 -Width 520 -Height 180 `
    -FontSize 13 -Color $colWhite -FontName "Consolas" | Out-Null

# Capture
$cap = Join-Path $CapturesDir "11-hpa-load.png"
if (Test-Path $cap) {
    Add-Image -Slide $s -Path $cap -Left 60 -Top 370 -Width 1160 -Height 280 | Out-Null
}
Add-Footer -Slide $s

# ============================================================
# SLIDE 13 - BONUS IMPLEMENTES
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Bonus implementes (6 / +5 plafond)" -Subtitle "PDF section 4 - une marge prise pour la securite"

$bonuses = @(
    @{N="1"; T="Resource Requests + Limits + QoS"; D="Burstable sur tous les pods - protege le cluster"; C=$colGreen; Y=120},
    @{N="3"; T="NetworkPolicy zero-trust"; D="8 policies - default-deny + allow explicite"; C=$colMauve; Y=200},
    @{N="4"; T="Rolling Update zero-downtime"; D="maxSurge=1 maxUnavailable=0 - service jamais down"; C=$colCyan; Y=280},
    @{N="5"; T="HPA autoscaling"; D="2 -> 8 (backend), 3 -> 10 (frontend) - CPU + memory"; C=$colYellow; Y=360},
    @{N="7"; T="Rollback automatique"; D="rollout undo - testes avec image cassee"; C=$colOrange; Y=440},
    @{N="8"; T="Helm Chart parametrable"; D="charts/lottoti/ - install + upgrade + rollback testes"; C=$colPink; Y=520}
)
foreach ($b in $bonuses) {
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 1160 -Height 70 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 6 -Height 70 -Color $b.C | Out-Null
    Add-TextBox -Slide $s -Text "$($b.N)" -Left 80 -Top ($b.Y+18) -Width 60 -Height 35 -FontSize 28 -Color $b.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.T -Left 160 -Top ($b.Y+12) -Width 700 -Height 30 -FontSize 17 -Color $colWhite -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.D -Left 160 -Top ($b.Y+40) -Width 800 -Height 24 -FontSize 13 -Color $colGray | Out-Null
    Add-TextBox -Slide $s -Text "+1 pt" -Left 1080 -Top ($b.Y+22) -Width 80 -Height 30 -FontSize 18 -Color $b.C -Bold $true -Align 3 | Out-Null
}

Add-TextBox -Slide $s -Text "6 bonus x +1 pt = +6 pts -> plafonne a +5 pts par le sujet -> resultat +5/5" `
    -Left 60 -Top 615 -Width 1160 -Height 30 -FontSize 14 -Color $colMauve -Bold $true | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 14 - BILAN BAREME
# ============================================================
$s = Add-Slide
Add-Header -Slide $s -Title "Bilan bareme" -Subtitle "Mapping PDF section 5 - tous criteres valides objectivement"

# Section Base
Add-TextBox -Slide $s -Text "BASE (15 / 15 pts)" -Left 60 -Top 100 -Width 800 -Height 30 `
    -FontSize 18 -Color $colCyan -Bold $true | Out-Null

$base = @(
    @{T="Cluster (1 master + 2 workers)"; P="2 pts"; Cap="capture 01"; C=$colGreen; Y=135},
    @{T="Deploiement (front + back + DB)"; P="5 pts"; Cap="capture 02 + 10"; C=$colGreen; Y=171},
    @{T="Persistance (volumes survivent)"; P="2 pts"; Cap="capture 03 + 07"; C=$colGreen; Y=207},
    @{T="Securite (Secrets + HTTPS)"; P="2 pts"; Cap="capture 04 + 14"; C=$colGreen; Y=243},
    @{T="Exposition (Ingress + DNS)"; P="2 pts"; Cap="capture 04 + 10"; C=$colGreen; Y=279},
    @{T="Documentation & scripts"; P="2 pts"; Cap="16 captures + scripts"; C=$colGreen; Y=315}
)
foreach ($b in $base) {
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 800 -Height 32 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 4 -Height 32 -Color $b.C | Out-Null
    Add-TextBox -Slide $s -Text "OK" -Left 80 -Top ($b.Y+6) -Width 30 -Height 22 -FontSize 14 -Color $b.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.T -Left 120 -Top ($b.Y+6) -Width 470 -Height 22 -FontSize 13 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text $b.P -Left 600 -Top ($b.Y+6) -Width 70 -Height 22 -FontSize 13 -Color $colYellow -Bold $true -Align 3 | Out-Null
    Add-TextBox -Slide $s -Text $b.Cap -Left 680 -Top ($b.Y+6) -Width 170 -Height 22 -FontSize 11 -Color $colGray | Out-Null
}

# Section Bonus
Add-TextBox -Slide $s -Text "BONUS (+5 / +5 pts plafond)" -Left 60 -Top 365 -Width 800 -Height 30 `
    -FontSize 18 -Color $colMauve -Bold $true | Out-Null

$bonusList = @(
    @{T="Bonus 1 - Resource Limits + QoS"; P="+1 pt"; Cap="capture 15"; C=$colMauve; Y=400},
    @{T="Bonus 3 - NetworkPolicy zero-trust"; P="+1 pt"; Cap="capture 12"; C=$colMauve; Y=432},
    @{T="Bonus 4 - Rolling Update zero-downtime"; P="+1 pt"; Cap="capture 08"; C=$colMauve; Y=464},
    @{T="Bonus 5 - HPA Autoscaling"; P="+1 pt"; Cap="capture 11"; C=$colMauve; Y=496},
    @{T="Bonus 7 - Rollback automatique"; P="+1 pt"; Cap="capture 09"; C=$colMauve; Y=528},
    @{T="Bonus 8 - Helm Chart parametrable"; P="+1 pt"; Cap="capture 13"; C=$colMauve; Y=560}
)
foreach ($b in $bonusList) {
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 800 -Height 28 -Color $colDarkLight | Out-Null
    Add-Rect -Slide $s -Left 60 -Top $b.Y -Width 4 -Height 28 -Color $b.C | Out-Null
    Add-TextBox -Slide $s -Text "OK" -Left 80 -Top ($b.Y+4) -Width 30 -Height 22 -FontSize 13 -Color $b.C -Bold $true | Out-Null
    Add-TextBox -Slide $s -Text $b.T -Left 120 -Top ($b.Y+4) -Width 470 -Height 22 -FontSize 12 -Color $colWhite | Out-Null
    Add-TextBox -Slide $s -Text $b.P -Left 600 -Top ($b.Y+4) -Width 70 -Height 22 -FontSize 13 -Color $b.C -Bold $true -Align 3 | Out-Null
    Add-TextBox -Slide $s -Text $b.Cap -Left 680 -Top ($b.Y+4) -Width 170 -Height 22 -FontSize 11 -Color $colGray | Out-Null
}

# Card total
Add-Rect -Slide $s -Left 890 -Top 100 -Width 330 -Height 540 -Color $colDarker | Out-Null
Add-Rect -Slide $s -Left 890 -Top 100 -Width 330 -Height 6 -Color $colMauve | Out-Null
Add-TextBox -Slide $s -Text "Total projete" -Left 890 -Top 150 -Width 330 -Height 30 -FontSize 16 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "20" -Left 890 -Top 200 -Width 330 -Height 180 -FontSize 200 -Color $colMauve -Bold $true -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "/ 15" -Left 890 -Top 380 -Width 330 -Height 50 -FontSize 36 -Color $colMauve -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "15 base + 5 bonus" -Left 890 -Top 460 -Width 330 -Height 30 -FontSize 16 -Color $colGreen -Align 2 -Bold $true | Out-Null
Add-TextBox -Slide $s -Text "Tous les criteres" -Left 890 -Top 500 -Width 330 -Height 25 -FontSize 13 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "valides objectivement" -Left 890 -Top 525 -Width 330 -Height 25 -FontSize 13 -Color $colGray -Align 2 | Out-Null
Add-Footer -Slide $s

# ============================================================
# SLIDE 15 - MERCI
# ============================================================
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

Add-TextBox -Slide $s -Text "Demo en direct :" -Left 60 -Top 480 -Width 1160 -Height 24 `
    -FontSize 14 -Color $colGray -Align 2 | Out-Null
Add-TextBox -Slide $s -Text "https://lottoti.local:30443/" -Left 60 -Top 506 -Width 1160 -Height 30 `
    -FontSize 22 -Color $colGreen -FontName "Consolas" -Bold $true -Align 2 | Out-Null

Add-TextBox -Slide $s -Text "Repo + documentation : c:\cluster" -Left 60 -Top 555 -Width 1160 -Height 24 `
    -FontSize 14 -Color $colGray -Align 2 | Out-Null

Add-TextBox -Slide $s -Text "LottoTi - ESGI - $(Get-Date -Format 'yyyy')" `
    -Left 60 -Top 670 -Width 1160 -Height 30 -FontSize 12 -Color $colGrayDim -Align 2 | Out-Null

# ============================================================
# SAVE
# ============================================================
Write-Host "[2/3] $script:slideIdx slides generes"
Write-Host "[3/3] Sauvegarde -> $OutputPath"

if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
$pres.SaveAs($OutputPath, 24)
$pres.Close()
$ppt.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

Write-Host ""
Write-Host "[OK] Presentation courte generee :"
Write-Host "     $OutputPath"
Write-Host "     $script:slideIdx slides"
