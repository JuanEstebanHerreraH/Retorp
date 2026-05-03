@echo off
chcp 65001 >nul
title NetMonitor - Backend

echo.
echo  ====================================================
echo       Retorp v1.0.0 - Monitoreo de red local
echo  ====================================================
echo.

REM Verificar Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python no esta instalado.
    echo  Ve a https://www.python.org y descargalo.
    echo  Marca "Add Python to PATH" al instalar.
    pause
    exit /b 1
)

echo [INFO] Version de Python:
python --version

REM Ir al backend
cd /d "%~dp0backend"

echo.
echo [INFO] Instalando dependencias (solo la primera vez tarda)...
echo.

python -m pip install --upgrade pip --quiet --no-warn-script-location 2>nul

echo  - Instalando FastAPI...
python -m pip install "fastapi==0.100.1" "starlette==0.27.0" "anyio==3.7.1" --quiet --no-warn-script-location
if %errorlevel% neq 0 goto error

echo  - Instalando servidor web...
python -m pip install "uvicorn==0.23.2" "websockets==11.0.3" --quiet --no-warn-script-location
if %errorlevel% neq 0 goto error

echo  - Instalando herramientas del sistema...
python -m pip install "psutil==5.9.8" --quiet --no-warn-script-location
if %errorlevel% neq 0 goto error

echo  - Instalando base de datos...
python -m pip install "aiosqlite==0.19.0" "python-multipart==0.0.9" --quiet --no-warn-script-location
if %errorlevel% neq 0 goto error

echo  - Instalando escaner de red (nmap)...
python -m pip install "python-nmap==0.7.1" --quiet --no-warn-script-location
if %errorlevel% neq 0 (
    echo  [AVISO] nmap no se instalo. Instala nmap desde https://nmap.org
)

echo  - Instalando scapy...
python -m pip install "scapy==2.5.0" --quiet --no-warn-script-location
if %errorlevel% neq 0 (
    echo  [AVISO] Scapy no se instalo. Escaneo ARP no disponible.
)

echo.
echo  ====================================================
echo  [OK] Dependencias instaladas correctamente
echo  [OK] Abriendo servidor en http://localhost:8000
echo  [OK] Deja esta ventana ABIERTA mientras usas la app
echo  [OK] Para cerrar: presiona Ctrl+C
echo  ====================================================
echo.

python main.py
goto fin

:error
echo.
echo [ERROR] Fallo al instalar dependencias.
echo  Intenta: clic derecho en start.bat - "Ejecutar como administrador"
echo.
pause
exit /b 1

:fin
pause
