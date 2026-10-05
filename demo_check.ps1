# GemEye demo check: starts Docker and the backend, then prints what is ready.
# Run from the GemEye folder:
#   powershell -ExecutionPolicy Bypass -File .\demo_check.ps1

$root = $PSScriptRoot

# 1. Docker
docker info --format "{{.ServerVersion}}" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Starting Docker Desktop..."
    Start-Process "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe"
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep -Seconds 5
        docker info --format "{{.ServerVersion}}" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { break }
    }
}
docker info --format "{{.ServerVersion}}" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Docker is not running. Open Docker Desktop and run this again."; exit 1 }
Write-Host "[OK]   Docker"

# 2. Backend
Push-Location (Join-Path $root "backend")
docker compose up -d 2>$null | Out-Null
Pop-Location
$health = $null
for ($i = 0; $i -lt 24; $i++) {
    try { $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -TimeoutSec 3; break } catch { Start-Sleep -Seconds 5 }
}
if ($null -eq $health -or -not $health.models_loaded) { Write-Host "[FAIL] Backend not healthy. Run: docker logs --tail 30 gemeye-api"; exit 1 }
Write-Host "[OK]   Backend running, model $($health.model_version)"

# 3. Database (MongoDB Atlas)
$code = 0
try { $code = (Invoke-WebRequest -Uri "http://localhost:8000/config" -UseBasicParsing -TimeoutSec 10).StatusCode } catch { $code = 503 }
$publicIp = try { (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5) } catch { "unknown (no internet?)" }
if ($code -eq 200) {
    Write-Host "[OK]   Database connected"
} else {
    Write-Host "[FAIL] Database not reachable. Add this public IP in MongoDB Atlas > Network Access: $publicIp"
    Write-Host "       Then run: docker restart gemeye-api   and run this script again."
}

# 4. Network
$pcIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "WiFi" -ErrorAction SilentlyContinue).IPAddress
$net = (Get-NetConnectionProfile -InterfaceAlias "WiFi" -ErrorAction SilentlyContinue)
Write-Host "[INFO] Wi-Fi: $($net.Name) ($($net.NetworkCategory))   PC IP: $pcIp   Public IP: $publicIp"
if ($net -and $net.NetworkCategory -ne "Private") { Write-Host "[WARN] Network is not Private; the firewall rule only allows Private networks." }
if (-not (Get-NetFirewallRule -DisplayName "GemEye local API" -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Firewall rule missing (only needed for the in-app API base URL backup)."
}

# 5. Phone
Write-Host "[INFO] Phones connected to adb:"
adb devices | Select-Object -Skip 1 | Where-Object { $_.Trim() } | ForEach-Object { Write-Host "       $_" }

Write-Host ""
Write-Host "API docs: http://${pcIp}:8000/docs"
