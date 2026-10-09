# Nicominecith X11 Control
Neu gestaltete Oberfläche (Qt Quick) für die Attack Shark X11 – Linux, Windows, Android.
Basiert auf dem Reverse-Engineering von iago-fragnan/attack-shark-x11-linux (unoffiziell, nicht mit Attack Shark verbunden).

## Builds
Repo auf GitHub pushen → Actions → Artefakte: Linux-Binary, Windows-Ordner, APK.
Lokal: `cmake -B build && cmake --build build` (Qt 6.5+, Linux: `libusb-1.0-0-dev`).

## Hinweise
- **Linux:** udev-Regel für Zugriff ohne root: `SUBSYSTEM=="usb", ATTR{idVendor}=="1d57", MODE="0666"`.
- **Windows:** Interface 2 der Maus braucht den WinUSB-Treiber (z. B. mit Zadig) – sonst kein Zugriff.
- **Android:** Maus per OTG-Adapter/USB-C anstecken, USB-Erlaubnis bestätigen, oben auf den Status tippen. Funk-Dongle/Kabel nötig.
- **Branding/Farben:** alles in `qml/Theme.qml`.
