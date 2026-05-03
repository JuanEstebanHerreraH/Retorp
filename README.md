# Retorp — Monitoreo de Red Local

<div align="center">
  <img src="frontend/netmonitor_app/assets/icon.png" width="100" style="border-radius:20px"/>
  <br/><br/>
  <b>Retorp</b> · Monitoreo de red local · v1.0.0
</div>

---

## 👤 Para usuarios finales

**Retorp** muestra todos los dispositivos conectados a tu red WiFi (teléfonos, TVs, computadoras) y te avisa si hay intrusos. No necesita internet.

### Cómo usar
1. Abre `start.bat` → déjalo abierto
2. Abre la app **Retorp**
3. Toca **Escanear Red Local**

---

## 🧑‍💻 Para desarrolladores

### Requisitos
- Python 3.10+ con "Add to PATH" marcado
- Flutter SDK 3.x
- Nmap (https://nmap.org)

### Ejecutar en desarrollo
```bash
# Terminal 1 - Backend
cd backend
python -m pip install -r requirements.txt
python main.py

# Terminal 2 - Frontend
cd frontend/netmonitor_app
flutter pub get
flutter create --platforms=windows .
flutter run -d windows
```

---

## 📦 Generar el instalador / ejecutable

### Paso 1 — Compilar (doble clic en build_release.bat)
O manualmente:
```bash
cd frontend/netmonitor_app
flutter create --platforms=windows .
flutter build windows --release
```

El `.exe` queda en:
```
frontend/netmonitor_app/build/windows/x64/runner/Release/retorp.exe
```

### Paso 2 — Distribuir como ZIP
Comprime **toda** la carpeta `Release\` y compártela. El usuario extrae y ejecuta `retorp.exe`.

```
Release\
├── retorp.exe          ← Ejecutable principal
├── flutter_windows.dll ← Necesaria
├── data\               ← NO borrar (assets, fuentes)
└── *.dll               ← NO borrar
```

### Paso 3 — Crear instalador profesional (opcional)
1. Descarga **Inno Setup**: https://jrsoftware.org/isinfo.php
2. Abre el archivo `installer/retorp_installer.iss`
3. Menú → **Build → Compile**
4. El instalador se genera en `dist/RetorpSetup_v1.0.0.exe`

---

## 🌐 API del backend

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Estado del servidor |
| POST | `/escanear` | Escaneo completo de red |
| GET | `/dispositivos` | Lista de dispositivos |
| GET | `/ping/{ip}` | Ping a una IP |
| GET | `/dispositivos/{ip}/puertos` | Puertos abiertos |
| GET | `/historial` | Historial de escaneos |
| DELETE | `/historial/{id}` | Borrar un escaneo |
| DELETE | `/historial` | Borrar todo el historial |
| GET | `/estadisticas` | Estadísticas de la red |
| GET | `/alertas` | Alertas de intrusos |
