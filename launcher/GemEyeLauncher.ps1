# GemEye Demo Launcher: one window to start the backend and run the app on the phone.
# Start it with "Start GemEye Demo.bat" in the GemEye folder.
#
# The phone reaches the server through the adb connection (adb reverse tcp:8000),
# over USB or wireless debugging, so the PC IP, firewall and Wi-Fi isolation do
# not matter. Without adb, set the PC address in the app: Settings > API base URL.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root "backend"
$Apk = Join-Path $Root "app\build\gemeye.apk"
$StateFile = Join-Path $PSScriptRoot ".launcher_state.json"
$Pkg = "com.gemeye.gemeye"
$Port = 8000

# ---------- state ----------
$State = @{ phoneIp = ""; installedHash = @{} }
if (Test-Path $StateFile) {
    try {
        $j = Get-Content $StateFile -Raw | ConvertFrom-Json
        if ($j.phoneIp) { $State.phoneIp = $j.phoneIp }
        if ($j.installedHash) { $j.installedHash.PSObject.Properties | ForEach-Object { $State.installedHash[$_.Name] = $_.Value } }
    } catch {}
}
function Save-State { try { $State | ConvertTo-Json | Set-Content -Encoding utf8 $StateFile } catch {} }

# ---------- adb path ----------
$Adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $Adb) {
    $cand = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $cand) { $Adb = $cand }
}

# ---------- UI ----------
$Blue = [System.Drawing.ColorTranslator]::FromHtml("#1B3A8C")
$Green = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
$Amber = [System.Drawing.ColorTranslator]::FromHtml("#F59E0B")
$Red = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
$Grey = [System.Drawing.ColorTranslator]::FromHtml("#A0A4B8")
$TextDark = [System.Drawing.ColorTranslator]::FromHtml("#1A1D2E")

$form = New-Object System.Windows.Forms.Form
$form.Text = "GemEye Demo Launcher"
$form.Size = New-Object System.Drawing.Size(560, 640)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = "GemEye Demo Launcher"
$title.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$title.ForeColor = $Blue
$title.Location = New-Object System.Drawing.Point(16, 10)
$title.AutoSize = $true
$form.Controls.Add($title)

$Rows = [ordered]@{}
$y = 52
foreach ($name in @("Docker", "Backend", "Database", "Phone", "Tunnel", "App")) {
    $dot = New-Object System.Windows.Forms.Label
    $dot.Text = [char]0x25CF
    $dot.Font = New-Object System.Drawing.Font("Segoe UI", 13)
    $dot.ForeColor = $Grey
    $dot.Location = New-Object System.Drawing.Point(16, ($y - 4))
    $dot.AutoSize = $true
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $name
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    $lbl.ForeColor = $TextDark
    $lbl.Location = New-Object System.Drawing.Point(40, $y)
    $lbl.Size = New-Object System.Drawing.Size(80, 22)
    $val = New-Object System.Windows.Forms.Label
    $val.Text = "-"
    $val.ForeColor = $TextDark
    $val.Location = New-Object System.Drawing.Point(124, $y)
    $val.Size = New-Object System.Drawing.Size(410, 22)
    $form.Controls.AddRange(@($dot, $lbl, $val))
    $Rows[$name] = @{ dot = $dot; val = $val }
    $y += 28
}

$info = New-Object System.Windows.Forms.Label
$info.Location = New-Object System.Drawing.Point(16, ($y + 2))
$info.Size = New-Object System.Drawing.Size(520, 22)
$info.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#6B7089")
$form.Controls.Add($info)
$y += 30

function New-Btn($text, $x, $yy, $w, $primary) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $yy)
    $b.Size = New-Object System.Drawing.Size($w, 38)
    $b.FlatStyle = "Flat"
    if ($primary) {
        $b.BackColor = $Blue; $b.ForeColor = [System.Drawing.Color]::White
        $b.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 11)
        $b.FlatAppearance.BorderSize = 0
    } else {
        $b.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#EEF1FA"); $b.ForeColor = $Blue
        $b.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml("#E5E7F0")
    }
    $form.Controls.Add($b)
    return $b
}

$btnGo = New-Btn "START EVERYTHING" 16 $y 512 $true
$y += 46
$btnConnect = New-Btn "Connect Phone" 16 $y 168 $false
$btnPair = New-Btn "Pair (no cable)" 188 $y 168 $false
$btnOpen = New-Btn "Open App" 360 $y 168 $false
$y += 44
$btnInstall = New-Btn "Reinstall App" 16 $y 168 $false
$btnDocs = New-Btn "API Docs" 188 $y 168 $false
$btnLog = New-Btn "Server Log" 360 $y 168 $false
$y += 44
$btnCheck = New-Btn "Check Status" 16 $y 168 $false
$btnDb = New-Btn "Fix Database" 188 $y 168 $false
$btnStop = New-Btn "Stop All" 360 $y 168 $false
$y += 48

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = "Vertical"
$log.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#F7F8FC")
$log.Font = New-Object System.Drawing.Font("Consolas", 9)
$log.Location = New-Object System.Drawing.Point(16, $y)
$log.Size = New-Object System.Drawing.Size(512, (590 - $y))
$form.Controls.Add($log)

$AllButtons = @($btnGo, $btnConnect, $btnPair, $btnOpen, $btnInstall, $btnDocs, $btnLog, $btnCheck, $btnDb, $btnStop)

# ---------- helpers ----------
function Log($msg) {
    $log.AppendText("$(Get-Date -Format HH:mm:ss)  $msg`r`n")
    [System.Windows.Forms.Application]::DoEvents()
}
function Wait($seconds) {
    $end = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $end) { Start-Sleep -Milliseconds 100; [System.Windows.Forms.Application]::DoEvents() }
}
function Set-Row($name, $level, $text) {
    $c = switch ($level) { "ok" { $Green } "warn" { $Amber } "fail" { $Red } default { $Grey } }
    $Rows[$name].dot.ForeColor = $c
    $Rows[$name].val.Text = $text
    [System.Windows.Forms.Application]::DoEvents()
}
function Run($exe, [string[]]$argList, [int]$timeoutSec = 60) {
    # Runs a program without freezing the window; returns @{code; out}.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.Arguments = ($argList | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $end = (Get-Date).AddSeconds($timeoutSec)
    while (-not $p.HasExited -and (Get-Date) -lt $end) { Start-Sleep -Milliseconds 100; [System.Windows.Forms.Application]::DoEvents() }
    if (-not $p.HasExited) { try { $p.Kill() } catch {}; return @{ code = -1; out = "timed out" } }
    return @{ code = $p.ExitCode; out = ($outTask.Result + $errTask.Result).Trim() }
}
function AdbRun([string[]]$a, [int]$t = 30) { if (-not $Adb) { return @{ code = -1; out = "adb not found" } }; return Run $Adb $a $t }
function Busy($on) {
    foreach ($b in $AllButtons) { $b.Enabled = -not $on }
    $form.Cursor = if ($on) { "WaitCursor" } else { "Default" }
    [System.Windows.Forms.Application]::DoEvents()
}
function Http-Code($url, $t = 5) {
    try { return (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec $t).StatusCode }
    catch { if ($_.Exception.Response) { return [int]$_.Exception.Response.StatusCode } return 0 }
}
function PcIp {
    $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceAlias -notmatch 'vEthernet|Loopback|WSL|VirtualBox|VMware' -and $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } |
        Select-Object -First 1
    if ($ip) { return $ip.IPAddress } return ""
}

# ---------- steps ----------
function Ensure-Docker {
    $r = Run "docker" @("info", "--format", "{{.ServerVersion}}") 20
    if ($r.code -eq 0) { Set-Row "Docker" "ok" "Running"; return $true }
    Set-Row "Docker" "warn" "Starting Docker Desktop (up to 2 min)..."
    Log "Starting Docker Desktop"
    $exe = Join-Path $env:LOCALAPPDATA "Programs\DockerDesktop\Docker Desktop.exe"
    if (-not (Test-Path $exe)) { $exe = "C:\Program Files\Docker\Docker\Docker Desktop.exe" }
    if (Test-Path $exe) { Start-Process $exe } else { Set-Row "Docker" "fail" "Docker Desktop not found. Start it manually."; return $false }
    for ($i = 0; $i -lt 30; $i++) {
        Wait 4
        $r = Run "docker" @("info", "--format", "{{.ServerVersion}}") 20
        if ($r.code -eq 0) { Set-Row "Docker" "ok" "Running"; return $true }
    }
    Set-Row "Docker" "fail" "Not running. Open Docker Desktop, wait for 'Engine running', press START again."
    return $false
}

function Ensure-Backend {
    if ((Http-Code "http://localhost:$Port/health" 3) -ne 200) {
        Set-Row "Backend" "warn" "Starting (models load in ~30 s)..."
        Log "docker compose up -d"
        Push-Location $Backend
        $r = Run "docker" @("compose", "up", "-d") 300
        Pop-Location
        if ($r.code -ne 0) { Log $r.out; Set-Row "Backend" "fail" "docker compose failed (see log)"; return $false }
    }
    for ($i = 0; $i -lt 30; $i++) {
        try {
            $h = Invoke-RestMethod -Uri "http://localhost:$Port/health" -TimeoutSec 3
            if ($h.models_loaded) { Set-Row "Backend" "ok" "Healthy, model $($h.model_version)"; return $true }
        } catch {}
        Wait 3
    }
    Set-Row "Backend" "fail" "Not healthy. Press 'Server Log' to see why."
    return $false
}

function Check-Database {
    $code = Http-Code "http://localhost:$Port/config" 15
    if ($code -eq 200) { Set-Row "Database" "ok" "Connected"; return $true }
    Log "Database check returned $code; restarting the server once"
    Run "docker" @("restart", "gemeye-api") 60 | Out-Null
    for ($i = 0; $i -lt 20; $i++) { Wait 3; if ((Http-Code "http://localhost:$Port/health" 3) -eq 200) { break } }
    if ((Http-Code "http://localhost:$Port/config" 15) -eq 200) { Set-Row "Database" "ok" "Connected"; return $true }
    $pub = try { Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5 } catch { "" }
    if (-not $pub) { Set-Row "Database" "fail" "No internet on the PC."; return $false }
    Set-Row "Database" "fail" "Blocked. Press 'Fix Database' (add IP $pub in Atlas)."
    return $false
}

function Get-Devices {
    $r = AdbRun @("devices") 15
    $list = @()
    foreach ($line in ($r.out -split "`n")) {
        $p = $line.Trim() -split "\s+"
        if ($p.Count -ge 2 -and $p[0] -ne "List") { $list += @{ serial = $p[0]; state = $p[1]; wifi = ($p[0] -match ':\d+$') } }
    }
    return $list
}

function Connect-Phone {
    if (-not $Adb) { Set-Row "Phone" "fail" "adb not found. Install Android platform-tools."; return $null }
    AdbRun @("start-server") 20 | Out-Null
    $devs = Get-Devices
    $unauth = $devs | Where-Object { $_.state -eq "unauthorized" }
    if ($unauth) { Set-Row "Phone" "warn" "Unlock the phone and tap 'Allow USB debugging', then press again." }
    $ready = @($devs | Where-Object { $_.state -eq "device" })
    $wifi = $ready | Where-Object { $_.wifi } | Select-Object -First 1
    $usb = $ready | Where-Object { -not $_.wifi } | Select-Object -First 1

    # USB present: switch it to wireless so the cable can be removed.
    if ($usb -and -not $wifi) {
        $ipOut = (AdbRun @("-s", $usb.serial, "shell", "ip -f inet addr show wlan0") 15).out
        $m = [regex]::Match($ipOut, 'inet (\d+\.\d+\.\d+\.\d+)')
        if ($m.Success) {
            $ip = $m.Groups[1].Value
            Log "Phone on USB, Wi-Fi IP $ip. Switching to wireless"
            AdbRun @("-s", $usb.serial, "tcpip", "5555") 20 | Out-Null
            Wait 3
            $c = AdbRun @("connect", "${ip}:5555") 15
            Log $c.out
            if ($c.out -match "connected to") { $State.phoneIp = $ip; Save-State; $wifi = @{ serial = "${ip}:5555"; wifi = $true } }
        } else { Log "Phone Wi-Fi is off; using the USB cable" }
    }
    # Nothing ready: try the last phone IP, then mDNS (wireless debugging).
    if (-not $wifi -and -not $usb) {
        if ($State.phoneIp) {
            Log "Trying last phone IP $($State.phoneIp):5555"
            $c = AdbRun @("connect", "$($State.phoneIp):5555") 10
            if ($c.out -match "connected to") { $wifi = @{ serial = "$($State.phoneIp):5555"; wifi = $true } }
        }
        if (-not $wifi) {
            $md = (AdbRun @("mdns", "services") 10).out
            $mm = [regex]::Match($md, '_adb-tls-connect\._tcp\.?\s+(\d+\.\d+\.\d+\.\d+:\d+)')
            if ($mm.Success) {
                Log "Found wireless debugging at $($mm.Groups[1].Value)"
                $c = AdbRun @("connect", $mm.Groups[1].Value) 10
                if ($c.out -match "connected to") { $wifi = @{ serial = $mm.Groups[1].Value; wifi = $true } }
            }
        }
    }
    $target = if ($wifi) { $wifi } elseif ($usb) { $usb } else { $null }
    if (-not $target) {
        Set-Row "Phone" "fail" "Not found. Plug the USB cable (or use 'Pair') and press again."
        return $null
    }
    if ($target.wifi) { $State.phoneIp = ($target.serial -replace ':\d+$', ''); Save-State }
    $model = (AdbRun @("-s", $target.serial, "shell", "getprop ro.product.model") 10).out
    $how = if ($target.wifi) { "Wi-Fi" } else { "USB cable" }
    Set-Row "Phone" "ok" "$model via $how ($($target.serial))"
    if ($target.wifi -and $usb) { Log "Wireless ready. You can unplug the cable." }
    return $target.serial
}

function Ensure-Tunnel($serial) {
    AdbRun @("-s", $serial, "reverse", "tcp:$Port", "tcp:$Port") 15 | Out-Null
    $probe = "(printf 'GET /health HTTP/1.0\r\n\r\n'; sleep 2) | nc 127.0.0.1 $Port"
    $r = AdbRun @("-s", $serial, "shell", $probe) 15
    if ($r.out -match '200 OK') { Set-Row "Tunnel" "ok" "Phone reaches the server (127.0.0.1:$Port)"; return $true }
    Set-Row "Tunnel" "fail" "Phone cannot reach the server. Press 'Connect Phone' again."
    return $false
}

function Ensure-App($serial, [bool]$force) {
    if (-not (Test-Path $Apk)) { Set-Row "App" "fail" "app\build\gemeye.apk missing (see docs\RUN_ON_PHONE.md)"; return $false }
    $hash = (Get-FileHash $Apk -Algorithm SHA256).Hash
    $installed = (AdbRun @("-s", $serial, "shell", "pm path $Pkg") 15).out -match "package:"
    $key = ($serial -replace ':\d+$', '')
    if (-not $force -and $installed -and $State.installedHash[$key] -eq $hash) { Set-Row "App" "ok" "Installed (latest)"; return $true }
    Set-Row "App" "warn" "Installing (about 30 s)..."
    Log "Installing gemeye.apk"
    $r = AdbRun @("-s", $serial, "install", "-r", $Apk) 240
    if ($r.out -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match") {
        $ans = [System.Windows.Forms.MessageBox]::Show("The installed app was signed differently. Uninstall it and install again? (You will need to sign in again.)", "GemEye", "YesNo", "Question")
        if ($ans -eq "Yes") { AdbRun @("-s", $serial, "uninstall", $Pkg) 60 | Out-Null; $r = AdbRun @("-s", $serial, "install", $Apk) 240 }
    }
    if ($r.out -match "Success") {
        $State.installedHash[$key] = $hash; Save-State
        Set-Row "App" "ok" "Installed"; return $true
    }
    Log $r.out
    Set-Row "App" "fail" "Install failed (see log). Unlock the phone and allow the install."
    return $false
}

function Open-App($serial) {
    AdbRun @("-s", $serial, "shell", "am force-stop $Pkg") 10 | Out-Null
    $r = AdbRun @("-s", $serial, "shell", "monkey -p $Pkg -c android.intent.category.LAUNCHER 1") 20
    if ($r.out -match "Events injected: 1") { Set-Row "App" "ok" "Running on the phone"; Log "App opened" } else { Log $r.out }
}

function Update-Info {
    $net = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -First 1
    $info.Text = "PC IP: $(PcIp)   Network: $($net.Name)   Direct mode: type http://$(PcIp):$Port in app Settings"
}

# ---------- actions ----------
$btnGo.Add_Click({
    Busy $true
    try {
        Update-Info
        Log "=== START EVERYTHING ==="
        if (-not (Ensure-Docker)) { return }
        if (-not (Ensure-Backend)) { return }
        Check-Database | Out-Null
        $s = Connect-Phone
        if (-not $s) { return }
        if (-not (Ensure-Tunnel $s)) { return }
        if (-not (Ensure-App $s $false)) { return }
        Open-App $s
        Log "=== READY ==="
    } finally { Busy $false }
})

$btnConnect.Add_Click({
    Busy $true
    try { $s = Connect-Phone; if ($s) { Ensure-Tunnel $s | Out-Null } } finally { Busy $false }
})

$btnPair.Add_Click({
    Add-Type -AssemblyName Microsoft.VisualBasic
    [System.Windows.Forms.MessageBox]::Show("On the phone: Developer options > Wireless debugging > 'Pair device with pairing code'. Keep that screen open.", "Pair") | Out-Null
    $addr = [Microsoft.VisualBasic.Interaction]::InputBox("Pairing IP:port shown in the pop-up (e.g. 192.168.1.196:37123)", "Pair 1/3")
    if (-not $addr) { return }
    $code = [Microsoft.VisualBasic.Interaction]::InputBox("6-digit pairing code", "Pair 2/3")
    if (-not $code) { return }
    Busy $true
    try {
        $r = AdbRun @("pair", $addr.Trim(), $code.Trim()) 30
        Log $r.out
        if ($r.out -notmatch "Successfully paired") { Set-Row "Phone" "fail" "Pairing failed. Check the code and try again."; return }
        Wait 2
        $md = (AdbRun @("mdns", "services") 10).out
        $mm = [regex]::Match($md, '_adb-tls-connect\._tcp\.?\s+(\d+\.\d+\.\d+\.\d+:\d+)')
        $conn = if ($mm.Success) { $mm.Groups[1].Value } else { [Microsoft.VisualBasic.Interaction]::InputBox("IP:port under 'IP address & Port' on the Wireless debugging screen", "Pair 3/3") }
        if (-not $conn) { return }
        $c = AdbRun @("connect", $conn.Trim()) 15
        Log $c.out
        if ($c.out -match "connected to") {
            $State.phoneIp = ($conn.Trim() -replace ':\d+$', ''); Save-State
            Set-Row "Phone" "ok" "Wi-Fi ($($conn.Trim()))"
            Ensure-Tunnel $conn.Trim() | Out-Null
        }
    } finally { Busy $false }
})

function Current-Serial {
    $d = @(Get-Devices | Where-Object { $_.state -eq "device" })
    $w = $d | Where-Object { $_.wifi } | Select-Object -First 1
    if ($w) { return $w.serial }
    if ($d.Count -gt 0) { return $d[0].serial }
    return $null
}

$btnOpen.Add_Click({
    Busy $true
    try { $s = Current-Serial; if ($s) { Ensure-Tunnel $s | Out-Null; Open-App $s } else { Set-Row "Phone" "fail" "No phone. Press 'Connect Phone'." } } finally { Busy $false }
})

$btnInstall.Add_Click({
    Busy $true
    try { $s = Current-Serial; if ($s) { Ensure-App $s $true | Out-Null } else { Set-Row "Phone" "fail" "No phone. Press 'Connect Phone'." } } finally { Busy $false }
})

$btnDocs.Add_Click({ Start-Process "http://localhost:$Port/docs" })

$btnLog.Add_Click({ Start-Process powershell -ArgumentList "-NoExit", "-Command", "docker logs -f --tail 40 gemeye-api" })

$btnCheck.Add_Click({
    Busy $true
    try {
        Update-Info
        $r = Run "docker" @("info", "--format", "{{.ServerVersion}}") 15
        if ($r.code -eq 0) { Set-Row "Docker" "ok" "Running" } else { Set-Row "Docker" "fail" "Not running" }
        try { $h = Invoke-RestMethod "http://localhost:$Port/health" -TimeoutSec 3; Set-Row "Backend" "ok" "Healthy, model $($h.model_version)" } catch { Set-Row "Backend" "fail" "Not running" }
        if ((Http-Code "http://localhost:$Port/config" 10) -eq 200) { Set-Row "Database" "ok" "Connected" } else { Set-Row "Database" "fail" "Not connected" }
        $s = Current-Serial
        if ($s) { Set-Row "Phone" "ok" $s; Ensure-Tunnel $s | Out-Null } else { Set-Row "Phone" "fail" "Not connected"; Set-Row "Tunnel" "idle" "-" }
    } finally { Busy $false }
})

$btnDb.Add_Click({
    $pub = try { Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5 } catch { "" }
    if (-not $pub) { [System.Windows.Forms.MessageBox]::Show("The PC has no internet connection.", "Database") | Out-Null; return }
    Set-Clipboard -Value $pub
    [System.Windows.Forms.MessageBox]::Show("Your public IP $pub is copied.`n`nIn MongoDB Atlas: Security > Network Access > Add IP Address > paste > Confirm.`nWait until it shows Active, then press START EVERYTHING.", "Fix Database") | Out-Null
    Start-Process "https://cloud.mongodb.com/"
})

$btnStop.Add_Click({
    Busy $true
    try {
        Log "Stopping"
        $s = Current-Serial
        if ($s) { AdbRun @("-s", $s, "reverse", "--remove-all") 10 | Out-Null }
        Push-Location $Backend; Run "docker" @("compose", "down") 120 | Out-Null; Pop-Location
        foreach ($k in @($Rows.Keys)) { Set-Row $k "idle" "-" }
        Log "Stopped"
    } finally { Busy $false }
})

$form.Add_Shown({
    Update-Info
    if (-not $Adb) { Log "adb not found: install Android SDK platform-tools" }
    Log "Press START EVERYTHING."
})

[void]$form.ShowDialog()
