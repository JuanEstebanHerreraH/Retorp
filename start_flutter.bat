@echo off
chcp 65001 >nul
title Retorp - Ejecutar App

echo.
echo  ====================================================
echo       Retorp - Ejecutar en modo desarrollo
echo  ====================================================
echo.

REM Verificar Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no esta instalado.
    pause
    exit /b 1
)

cd /d "%~dp0frontend\netmonitor_app"

REM Borrar CMakeLists con nombre incorrecto si existen
if exist "windows\CMakeLists.txt" (
    findstr /c:"netmonitor_app" "windows\CMakeLists.txt" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Limpiando configuracion anterior con nombre incorrecto...
        del /q "windows\CMakeLists.txt" 2>nul
        del /q "windows\runner\CMakeLists.txt" 2>nul
        del /q "windows\runner\main.cpp" 2>nul
    )
)

REM Generar archivos si no existen
if not exist "windows\CMakeLists.txt" (
    echo [INFO] Generando archivos Windows...
    flutter create --platforms=windows . >nul 2>&1

    REM Patch: cambiar nombre binario
    powershell -Command "(Get-Content 'windows\CMakeLists.txt') -replace 'set\(BINARY_NAME \"netmonitor_app\"\)', 'set(BINARY_NAME \"retorp\")' | Set-Content 'windows\CMakeLists.txt'"
    powershell -Command "(Get-Content 'windows\runner\main.cpp') -replace 'L\"netmonitor_app\"', 'L\"Retorp\"' | Set-Content 'windows\runner\main.cpp'"
    echo [OK] Configuracion Windows lista.
)

echo [INFO] Instalando dependencias...
flutter pub get >nul 2>&1

echo [INFO] Abriendo Retorp...
echo [INFO] (Asegurate de que start.bat este abierto en otra ventana)
echo.
flutter run -d windows

pause
