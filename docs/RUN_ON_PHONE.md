# Run GemEye on the Phone - Full Guide

Short version: [RUN_QUICK.md](RUN_QUICK.md)

## How it works

- The backend runs in Docker on the PC (port 8000).
- The phone reaches it through the **adb connection** (`adb reverse tcp:8000 tcp:8000`), over the USB cable or wireless debugging.
- So **one app file** (`app\build\gemeye.apk`) works on any network. You never need to rebuild for a new IP, open the firewall or use the same Wi-Fi as the venue.
- Backup without adb: in the app, **Settings > API base URL** (tap it) and type the PC IP, e.g. `192.168.1.195`. It needs the same Wi-Fi + firewall rule (0.2).
- The PC and phone both need internet (Firebase login, MongoDB Atlas, AWS S3).

---

## 0. One time only (already done on this PC)

**0.1** Phone: Settings > About device > tap **Build number** 7 times > Developer options > turn on **USB debugging** and **Wireless debugging**.

**0.2** Firewall rule, needed only for the "API base URL" backup (admin PowerShell):
```powershell
New-NetFirewallRule -DisplayName "GemEye local API" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private
```

---

## 1. The launcher (recommended)

Double-click **`Start GemEye Demo.bat`** in the GemEye folder.

| Light | Meaning |
|---|---|
| Green | Ready |
| Amber | Working / warning |
| Red | Problem, the text says what to do |

| Button | What it does |
|---|---|
| **START EVERYTHING** | Docker > backend > database > phone > tunnel > install app (only if changed) > open app |
| **Connect Phone** | USB plugged: switches the phone to Wi-Fi (unplug after). Nothing plugged: tries the last phone IP, then wireless debugging discovery |
| **Pair (no cable)** | Asks for the pairing IP:port and 6-digit code from the phone, then connects |
| **Open App** | Restarts GemEye on the phone (and re-checks the tunnel) |
| **Reinstall App** | Installs `app\build\gemeye.apk` again |
| **API Docs** | Opens http://localhost:8000/docs |
| **Server Log** | Live backend log in a new window |
| **Check Status** | Refreshes all lights |
| **Fix Database** | Copies your public IP and opens MongoDB Atlas (Network Access > Add IP Address > paste) |
| **Stop All** | Removes the tunnel and stops the backend |

The bottom line shows the PC IP for the "API base URL" backup.

---

## 2. Same thing by hand (if the launcher cannot be used)

Start in the GemEye folder:
```powershell
cd C:\Users\sheha\OneDrive\Documents\GitHub\GemEye
```

### 2.1 Docker + backend + database check
```powershell
powershell -ExecutionPolicy Bypass -File .\demo_check.ps1
```

### 2.2 Connect the phone

With the USB cable:
```powershell
adb devices
adb shell ip -f inet addr show wlan0
adb tcpip 5555
adb connect PHONE_IP:5555
```
Unplug the cable.

Without a cable (phone: Wireless debugging > Pair device with pairing code):
```powershell
adb pair PAIR_IP:PAIR_PORT CODE
adb connect PHONE_IP:CONNECT_PORT
```

### 2.3 Tunnel (repeat after every reconnect)
```powershell
adb -s PHONE_IP:5555 reverse tcp:8000 tcp:8000
```

### 2.4 Install + open
```powershell
adb -s PHONE_IP:5555 install -r app\build\gemeye.apk
adb -s PHONE_IP:5555 shell monkey -p com.gemeye.gemeye -c android.intent.category.LAUNCHER 1
```

### 2.5 Server log / test token / stop
```powershell
docker logs -f --tail 20 gemeye-api
```
```powershell
cd backend
docker compose exec api python scripts/get_token.py --email YOUR_EMAIL
cd ..
```
```powershell
adb reverse --remove-all
cd backend
docker compose down
cd ..
```

### 2.6 Rebuild the app (only after changing app code)
```powershell
cd app
flutter build apk --release
Copy-Item build\app\outputs\flutter-apk\app-release.apk build\gemeye.apk
cd ..
```

---

## Viva day checklist

1. Bring the **USB cable**. Test the launcher at home the day before.
2. Connect the PC to internet (venue Wi-Fi or **phone hotspot**).
3. Double-click the launcher, plug the cable, press **START EVERYTHING**.
4. Database red: press **Fix Database**, add the IP in Atlas, press START again.
5. Wi-Fi debugging fails at the venue: keep the **cable plugged**. Everything still works through the cable.
6. Phone app check: **Settings > API base URL** shows `http://127.0.0.1:8000`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Docker red | Open **Docker Desktop**, wait for "Engine running", press START |
| Backend red | **Server Log**, then START again |
| Database red | **Fix Database** (Atlas IP), wait 1 min, START |
| Phone red | Plug the cable, unlock the phone, tap **Allow USB debugging**, press **Connect Phone** |
| `unauthorized` | Unlock the phone and tap **Allow** |
| Tunnel red | Press **Connect Phone** (the adb link dropped) |
| App red / install failed | Unlock the phone, accept the install prompt, **Reinstall App** |
| App says "No connection" | Press **Open App** (re-creates the tunnel) |
| Phone restarted | Plug the cable once, press **Connect Phone** |
| Launcher does not open | Run `powershell -ExecutionPolicy Bypass -File .\launcher\GemEyeLauncher.ps1` |

---

## API Links

On the PC:
- http://localhost:8000/docs
- http://localhost:8000/redoc
- http://localhost:8000/health
- http://localhost:8000/config
- http://localhost:8000/openapi.json

From another device on the same Wi-Fi (replace PC_IP, shown at the bottom of the launcher):
- http://PC_IP:8000/docs
