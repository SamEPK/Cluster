# ============================================================
# launch-lottoti.ps1
# Lance Chrome directement sur la vraie app LottoTi
# Pas besoin de modifier le fichier hosts.
# ============================================================

$cluster = "lottoti.local"
$port = 30443

# Verif Chrome installe
$chromeExe = $null
$paths = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        $chromeExe = $p
        break
    }
}

if (-not $chromeExe) {
    Write-Host "Chrome introuvable. Edge ?" -ForegroundColor Yellow
    $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    if (Test-Path $edge) {
        $chromeExe = $edge
    } else {
        Write-Host "Aucun navigateur Chromium trouve." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host "  LAUNCHING LottoTi via Chrome dedicated profile" -ForegroundColor Cyan
Write-Host "  ===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Browser : $chromeExe" -ForegroundColor Gray
Write-Host "  URL     : https://$cluster`:$port/" -ForegroundColor Green
Write-Host "  API     : https://$cluster`:$port/api/health" -ForegroundColor Green
Write-Host ""
Write-Host "  Ce profil Chrome est dedie a LottoTi (sans toucher hosts)" -ForegroundColor Gray
Write-Host "  Cert auto-signe par CA local accepte automatiquement." -ForegroundColor Gray
Write-Host ""

# Profil dedie pour ne pas polluer le profil Chrome principal
$profileDir = "$env:LOCALAPPDATA\LottoTi-Chrome-Profile"
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

# Verif que le cluster repond
$test = $null
try {
    Add-Type -TypeDefinition @"
using System.Net;
using System.Net.Security;
public class CertOverride {
    public static bool Validate(object s, System.Security.Cryptography.X509Certificates.X509Certificate c, System.Security.Cryptography.X509Certificates.X509Chain ch, System.Net.Security.SslPolicyErrors e) { return true; }
}
"@ -ErrorAction SilentlyContinue
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [CertOverride]::Validate
} catch {}

try {
    $test = Invoke-WebRequest -Uri "https://127.0.0.1:$port/" -Headers @{"Host"="$cluster"} -SkipCertificateCheck -TimeoutSec 5 -UseBasicParsing
    Write-Host "  [OK] Cluster repond - HTTP $($test.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Cluster ne repond pas ($($_.Exception.Message))" -ForegroundColor Yellow
    Write-Host "  Verifie que k3d cluster 'lottoti' tourne (k3d cluster list)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Lancement..." -ForegroundColor Cyan

# Lancer Chrome avec :
#  - --host-resolver-rules : map lottoti.local -> 127.0.0.1 SANS modifier hosts
#  - --ignore-certificate-errors : accepte le CA self-signed
#  - --user-data-dir : profil dedie
$chromeArgs = @(
    "--user-data-dir=$profileDir"
    "--host-resolver-rules=`"MAP $cluster 127.0.0.1, MAP api.$cluster 127.0.0.1`""
    "--ignore-certificate-errors"
    "--no-first-run"
    "--no-default-browser-check"
    "--new-window"
    "https://$cluster`:$port/"
)

Start-Process -FilePath $chromeExe -ArgumentList $chromeArgs

Start-Sleep -Seconds 1
Write-Host ""
Write-Host "  Chrome lance avec mapping DNS local pour $cluster" -ForegroundColor Green
Write-Host "  Si tu veux fermer le profil dedie : ferme la fenetre Chrome" -ForegroundColor Gray
Write-Host ""
