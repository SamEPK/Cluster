# ============================================================
# fix-kubeconfig.ps1
# Patche le kubeconfig pour pointer vers 127.0.0.1 au lieu de
# host.docker.internal (qui ne fonctionne pas depuis bash/PowerShell
# Windows quand il y a un sandbox reseau).
#
# Lance ce script apres chaque k3d cluster start/create.
# ============================================================
param(
    [string]$Cluster = "lottoti"
)

$ErrorActionPreference = "Stop"

$kubeconfig = "$env:USERPROFILE\.kube\config"
if (-not (Test-Path $kubeconfig)) {
    Write-Host "[ERR] Kubeconfig introuvable : $kubeconfig" -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $kubeconfig "$kubeconfig.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force

# Trouver le port API actuel du cluster k3d
$lbContainer = "k3d-$Cluster-serverlb"
$portLine = docker port $lbContainer 6443 2>$null | Select-Object -First 1
if (-not $portLine) {
    Write-Host "[ERR] Container $lbContainer introuvable. Lance le cluster d'abord :" -ForegroundColor Red
    Write-Host "      k3d cluster start $Cluster" -ForegroundColor Yellow
    exit 1
}
$apiPort = ($portLine -split ":")[-1].Trim()
Write-Host "[INFO] API port detecte : $apiPort" -ForegroundColor Cyan

# Patch
$content = Get-Content $kubeconfig -Raw
$content = $content -replace "host\.docker\.internal:\d+", "127.0.0.1:$apiPort"
Set-Content -Path $kubeconfig -Value $content -NoNewline -Encoding UTF8

# Verif
$serverLine = (Get-Content $kubeconfig | Where-Object { $_ -match "127\.0\.0\.1:$apiPort" } | Select-Object -First 1)
Write-Host "[OK]   Patche : $($serverLine.Trim())" -ForegroundColor Green

# Switch context
& kubectl config use-context "k3d-$Cluster" 2>&1 | Out-Null
Write-Host "[OK]   Context actif : k3d-$Cluster" -ForegroundColor Green

# Quick test
$nodes = & kubectl get nodes --no-headers 2>$null
if ($LASTEXITCODE -eq 0 -and $nodes) {
    Write-Host ""
    Write-Host "Cluster Ready :" -ForegroundColor Green
    $nodes | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host "[WARN] kubectl get nodes a echoue. Cluster est-il vraiment up ?" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tu peux maintenant utiliser kubectl normalement :" -ForegroundColor Cyan
Write-Host "  kubectl -n lottoti get all" -ForegroundColor White
Write-Host "  kubectl -n lottoti logs deploy/backend" -ForegroundColor White
