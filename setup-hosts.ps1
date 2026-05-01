# ============================================================
# setup-hosts.ps1
# Ajoute lottoti.local et api.lottoti.local au fichier hosts.
# Necessite des droits admin (UAC). Auto-elevation si non admin.
# ============================================================

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$entries = @(
    "127.0.0.1`tlottoti.local"
    "127.0.0.1`tapi.lottoti.local"
)

# Verif admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Pas en mode admin. Relance avec UAC..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit 0
}

Write-Host "[OK] Mode administrateur" -ForegroundColor Green

# Lecture hosts
$content = Get-Content $hostsPath -Raw -ErrorAction Stop

# Ajout entries si absentes
$modified = $false
foreach ($entry in $entries) {
    $domain = ($entry -split "`t")[1]
    if ($content -notmatch "^[^#]*\b$([regex]::Escape($domain))\b") {
        Add-Content -Path $hostsPath -Value $entry -Encoding ASCII
        Write-Host "[ADD] $entry" -ForegroundColor Cyan
        $modified = $true
    } else {
        Write-Host "[SKIP] $domain deja present" -ForegroundColor Gray
    }
}

# Flush DNS cache pour appliquer immediatement
ipconfig /flushdns | Out-Null
Write-Host "[OK] DNS cache flushe" -ForegroundColor Green

Write-Host ""
Write-Host "Entrees actuelles:" -ForegroundColor Cyan
Get-Content $hostsPath | Where-Object { $_ -match "lottoti" } | ForEach-Object { Write-Host "  $_" -ForegroundColor White }

Write-Host ""
Write-Host "Tu peux maintenant ouvrir dans n'importe quel navigateur :" -ForegroundColor Green
Write-Host "  https://lottoti.local:30443/" -ForegroundColor Yellow
Write-Host "  https://lottoti.local:30443/api/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "Le navigateur va alerter sur le cert auto-signe (CA local)." -ForegroundColor Gray
Write-Host "Clique 'Avance' -> 'Continuer vers lottoti.local'." -ForegroundColor Gray
Write-Host ""
Write-Host "Appuie sur Entree pour fermer..." -ForegroundColor Gray
Read-Host
