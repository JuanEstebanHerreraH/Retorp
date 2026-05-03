#!/usr/bin/env bash
# start.sh - Script de inicio para NetMonitor en Linux/macOS

set -e

# Colores para la terminal
AZUL='\033[0;34m'
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NC='\033[0m' # Sin color

echo ""
echo -e "${AZUL}╔═══════════════════════════════════════╗${NC}"
echo -e "${AZUL}║       NetMonitor - Backend v1.0       ║${NC}"
echo -e "${AZUL}║    Monitoreo de red local con Python  ║${NC}"
echo -e "${AZUL}╚═══════════════════════════════════════╝${NC}"
echo ""

# Verificar Python 3
if ! command -v python3 &>/dev/null; then
    echo -e "${ROJO}[ERROR] Python 3 no está instalado.${NC}"
    echo "        Instálalo con: sudo apt install python3 python3-pip  (Ubuntu/Debian)"
    echo "        O descárgalo desde: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VER=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo -e "${VERDE}[OK] Python $PYTHON_VER encontrado.${NC}"

# Verificar nmap
if ! command -v nmap &>/dev/null; then
    echo -e "${AMARILLO}[AVISO] nmap no está instalado. Algunas funciones pueden no estar disponibles.${NC}"
    echo "        Instálalo con: sudo apt install nmap  (Ubuntu/Debian)"
    echo "        O: brew install nmap  (macOS)"
else
    echo -e "${VERDE}[OK] nmap encontrado.${NC}"
fi

# Ir a la carpeta del backend
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/backend"

# Crear entorno virtual si no existe (opcional pero recomendado)
if [ ! -d ".venv" ]; then
    echo -e "${AZUL}[INFO] Creando entorno virtual Python...${NC}"
    python3 -m venv .venv
fi

# Activar entorno virtual
source .venv/bin/activate

# Instalar dependencias
echo -e "${AZUL}[INFO] Instalando/verificando dependencias...${NC}"
pip install -r requirements.txt --quiet

echo ""
echo -e "${VERDE}[OK] Dependencias listas.${NC}"
echo -e "${AZUL}[INFO] Iniciando servidor NetMonitor en http://localhost:8000${NC}"
echo -e "${AMARILLO}       Nota: En Linux, puede ser necesario ejecutar con sudo para el escaneo ARP.${NC}"
echo -e "${AZUL}[INFO] Presiona Ctrl+C para detener el servidor.${NC}"
echo ""

# Iniciar el servidor
# En Linux, usar sudo si se necesitan permisos de red
if [[ "$EUID" -ne 0 ]] && [[ "$(uname)" == "Linux" ]]; then
    echo -e "${AMARILLO}[AVISO] Para el escaneo ARP completo, ejecuta con: sudo bash start.sh${NC}"
fi

python3 main.py
