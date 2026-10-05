# GemEye Quick Run

1. Double-click `Start GemEye Demo.bat` (GemEye folder)

2. Plug the USB cable (first time after a phone restart only)

3. Press **START EVERYTHING**

4. Unplug the cable

---

Without the launcher:

1.
```powershell
cd C:\Users\sheha\OneDrive\Documents\GitHub\GemEye
```

2.
```powershell
powershell -ExecutionPolicy Bypass -File .\demo_check.ps1
```

3. (USB cable plugged in)
```powershell
adb shell ip -f inet addr show wlan0
```

4.
```powershell
adb tcpip 5555
```

5.
```powershell
adb connect PHONE_IP:5555
```

6.
```powershell
adb -s PHONE_IP:5555 reverse tcp:8000 tcp:8000
```

7.
```powershell
adb -s PHONE_IP:5555 install -r app\build\gemeye.apk
```

8.
```powershell
adb -s PHONE_IP:5555 shell monkey -p com.gemeye.gemeye -c android.intent.category.LAUNCHER 1
```

---

http://localhost:8000/docs
