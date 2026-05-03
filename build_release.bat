@echo off
chcp 65001 >nul
title Retorp - Compilar Ejecutable

echo.
echo  ====================================================
echo       Retorp v1.0.0 - Compilar para Windows
echo  ====================================================
echo.

REM Verificar Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no esta instalado.
    echo  Descargalo: https://docs.flutter.dev/get-started/install/windows/desktop
    pause
    exit /b 1
)
echo [OK] Flutter encontrado.

REM Ir a la carpeta del proyecto
cd /d "%~dp0frontend\netmonitor_app"

REM Borrar CMakeLists anteriores (pueden causar errores)
if exist "windows\CMakeLists.txt" del /q "windows\CMakeLists.txt" 2>nul
if exist "windows\runner\CMakeLists.txt" del /q "windows\runner\CMakeLists.txt" 2>nul
if exist "windows\runner\main.cpp" del /q "windows\runner\main.cpp" 2>nul

REM Generar archivos Windows con Flutter
echo [INFO] Generando archivos de Windows...
flutter create --platforms=windows . >nul 2>&1

REM ===== PARCHE CLAVE: cambiar BINARY_NAME de "netmonitor_app" a "retorp" =====
echo [INFO] Aplicando nombre Retorp...
powershell -Command "(Get-Content 'windows\CMakeLists.txt') -replace 'set\(BINARY_NAME \"netmonitor_app\"\)', 'set(BINARY_NAME \"retorp\")' | Set-Content 'windows\CMakeLists.txt'"
powershell -Command "(Get-Content 'windows\runner\main.cpp') -replace 'L\"netmonitor_app\"', 'L\"Retorp\"' | Set-Content 'windows\runner\main.cpp'"
echo [OK] Nombre aplicado: retorp.exe

REM Copiar nuestro icono
if exist "windows\runner\resources\app_icon.ico" (
    echo [INFO] Icono personalizado ya presente.
) else (
    echo [INFO] Copiando icono...
    copy /y "windows\runner\resources\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul 2>&1
)

REM Instalar dependencias
echo [INFO] Instalando dependencias...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Fallo al instalar dependencias.
    pause
    exit /b 1
)

echo.
echo [INFO] Compilando en RELEASE (2-5 minutos)...
echo.
flutter build windows --release

if %errorlevel% neq 0 (
    echo [ERROR] Fallo la compilacion. Ejecuta: flutter doctor
    pause
    exit /b 1
)

echo.
echo  ====================================================
echo  [OK] Listo! El ejecutable esta en:
echo  frontend\netmonitor_app\build\windows\x64\runner\Release\retorp.exe
echo  ====================================================
echo.

explorer "%~dp0frontend\netmonitor_app\build\windows\x64\runner\Release\"
pause
