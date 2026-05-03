"""
scanner.py - Lógica de escaneo de red para NetMonitor
Usa scapy para ARP, psutil para info del sistema, y python-nmap para puertos.
"""

import asyncio
import socket
import subprocess
import platform
import psutil
import nmap
from datetime import datetime
from typing import List, Optional, Tuple
from models import Dispositivo, ResultadoEscaneo, PuertosDispositivo

# ─── Utilidades de red ────────────────────────────────────────────────────────

def obtener_ip_local() -> str:
    """Obtiene la IP local de esta máquina."""
    try:
        # Conectar a una IP externa (sin enviar datos) para conocer la interfaz activa
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


def obtener_rango_red() -> str:
    """
    Calcula el rango de red en formato CIDR (ej: 192.168.1.0/24)
    basado en la IP local y máscara de subred.
    """
    ip_local = obtener_ip_local()
    interfaces = psutil.net_if_addrs()

    for nombre_iface, lista_addrs in interfaces.items():
        for addr in lista_addrs:
            if addr.family == socket.AF_INET and addr.address == ip_local:
                # Calcular la red a partir de la máscara
                ip_parts = [int(x) for x in ip_local.split(".")]
                mask_parts = [int(x) for x in addr.netmask.split(".")]
                network_parts = [ip_parts[i] & mask_parts[i] for i in range(4)]
                # Contar bits de la máscara (CIDR)
                cidr = sum(bin(parte).count("1") for parte in mask_parts)
                network = ".".join(str(p) for p in network_parts)
                return f"{network}/{cidr}"

    # Fallback: asumir /24
    partes = ip_local.rsplit(".", 1)
    return f"{partes[0]}.0/24"


# ─── Ping ─────────────────────────────────────────────────────────────────────

async def ping_dispositivo(ip: str) -> Optional[float]:
    """
    Realiza un ping a una IP y devuelve la latencia en milisegundos.
    Devuelve None si el dispositivo no responde.
    """
    try:
        sistema = platform.system().lower()
        if sistema == "windows":
            comando = ["ping", "-n", "1", "-w", "1000", ip]
        else:
            comando = ["ping", "-c", "1", "-W", "1", ip]

        proceso = await asyncio.create_subprocess_exec(
            *comando,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, _ = await asyncio.wait_for(proceso.communicate(), timeout=3.0)
        salida = stdout.decode("utf-8", errors="ignore")

        # Extraer tiempo de respuesta
        if "time=" in salida or "tiempo=" in salida.lower():
            for parte in salida.split():
                if "time=" in parte.lower() or "tiempo=" in parte.lower():
                    valor = parte.split("=")[-1].replace("ms", "").strip()
                    try:
                        return float(valor)
                    except ValueError:
                        pass
            # Intento alternativo: buscar número antes de "ms"
            import re
            match = re.search(r'[Tt]ime[<=](\d+\.?\d*)\s*ms', salida)
            if match:
                return float(match.group(1))
        return None
    except (asyncio.TimeoutError, Exception):
        return None


# ─── ARP Scan con Scapy ───────────────────────────────────────────────────────

def escanear_arp(rango_red: str) -> List[Tuple[str, str]]:
    """
    Escanea la red usando ARP para descubrir dispositivos.
    Devuelve lista de tuplas (ip, mac).
    Requiere permisos de administrador/root.
    """
    dispositivos = []
    try:
        from scapy.all import ARP, Ether, srp

        # Crear paquete ARP broadcast
        paquete = Ether(dst="ff:ff:ff:ff:ff:ff") / ARP(pdst=rango_red)
        # Enviar y recibir respuestas (timeout=2 segundos)
        resultado, _ = srp(paquete, timeout=2, verbose=False)

        for enviado, recibido in resultado:
            dispositivos.append((recibido.psrc, recibido.hwsrc))

    except PermissionError:
        print("⚠️ Sin permisos para ARP scan. Usando método alternativo.")
    except ImportError:
        print("⚠️ Scapy no disponible. Usando método alternativo.")
    except Exception as e:
        print(f"⚠️ Error en ARP scan: {e}")

    return dispositivos


def escanear_nmap_basico(rango_red: str) -> List[Tuple[str, str, str]]:
    """
    Escaneo con nmap como alternativa/complemento al ARP.
    Devuelve lista de (ip, mac, nombre_host).
    """
    dispositivos = []
    try:
        nm = nmap.PortScanner()
        # Escaneo de ping (-sn) para descubrir hosts sin escanear puertos
        nm.scan(hosts=rango_red, arguments="-sn --max-retries 1 --host-timeout 2s")

        for host in nm.all_hosts():
            mac = "Desconocida"
            nombre = host

            # Obtener MAC si está disponible
            if "addresses" in nm[host]:
                if "mac" in nm[host]["addresses"]:
                    mac = nm[host]["addresses"]["mac"]

            # Obtener nombre de host
            if "hostnames" in nm[host] and nm[host]["hostnames"]:
                for h in nm[host]["hostnames"]:
                    if h.get("name"):
                        nombre = h["name"]
                        break

            # Obtener fabricante de la MAC
            fabricante = ""
            if "vendor" in nm[host] and mac in nm[host]["vendor"]:
                fabricante = nm[host]["vendor"][mac]

            dispositivos.append((host, mac, nombre, fabricante))

    except nmap.PortScannerError:
        print("⚠️ nmap no encontrado. Instálalo desde https://nmap.org")
    except Exception as e:
        print(f"⚠️ Error en escaneo nmap: {e}")

    return dispositivos


# ─── Escaneo de puertos ───────────────────────────────────────────────────────

async def escanear_puertos(ip: str) -> PuertosDispositivo:
    """
    Escanea los puertos más comunes de un dispositivo específico.
    Devuelve lista de puertos abiertos con su servicio.
    """
    puertos_info = []
    try:
        nm = nmap.PortScanner()
        # Escanear puertos comunes (-F = fast scan, top 100 ports)
        nm.scan(ip, arguments="-F --max-retries 1 --host-timeout 10s")

        if ip in nm.all_hosts():
            for proto in nm[ip].all_protocols():
                puertos = nm[ip][proto].keys()
                for puerto in sorted(puertos):
                    estado = nm[ip][proto][puerto]["state"]
                    if estado == "open":
                        servicio = nm[ip][proto][puerto].get("name", "desconocido")
                        version = nm[ip][proto][puerto].get("version", "")
                        puertos_info.append({
                            "puerto": puerto,
                            "protocolo": proto,
                            "servicio": servicio,
                            "version": version,
                            "estado": estado,
                        })

    except Exception as e:
        print(f"⚠️ Error escaneando puertos de {ip}: {e}")

    return PuertosDispositivo(ip=ip, puertos=puertos_info)


# ─── Función principal de escaneo ─────────────────────────────────────────────

async def escanear_red_completo() -> ResultadoEscaneo:
    """
    Realiza un escaneo completo de la red local.
    Combina ARP + nmap + ping para máxima cobertura.
    """
    print(f"🔍 Iniciando escaneo de red... {datetime.now().strftime('%H:%M:%S')}")
    rango_red = obtener_rango_red()
    print(f"📡 Rango de red detectado: {rango_red}")

    # Paso 1: Escaneo ARP para descubrir dispositivos
    dispositivos_arp = escanear_arp(rango_red)
    macs_encontradas = {ip: mac for ip, mac in dispositivos_arp}

    # Paso 2: Escaneo nmap para más info
    dispositivos_nmap = escanear_nmap_basico(rango_red)

    # Paso 3: Combinar resultados
    dispositivos_combinados = {}

    # Procesar resultados de nmap
    for item in dispositivos_nmap:
        ip = item[0]
        mac = item[1] if len(item) > 1 else macs_encontradas.get(ip, "Desconocida")
        nombre = item[2] if len(item) > 2 else "Dispositivo desconocido"
        fabricante = item[3] if len(item) > 3 else ""

        # Si ARP encontró la MAC, usarla (más confiable)
        if ip in macs_encontradas and macs_encontradas[ip] != "Desconocida":
            mac = macs_encontradas[ip]

        dispositivos_combinados[ip] = Dispositivo(
            ip=ip,
            mac=mac,
            nombre=nombre if nombre != ip else "Dispositivo desconocido",
            fabricante=fabricante,
            estado="activo",
        )

    # Agregar dispositivos de ARP que no estén en nmap
    for ip, mac in macs_encontradas.items():
        if ip not in dispositivos_combinados:
            nombre_host = obtener_nombre_host(ip)
            dispositivos_combinados[ip] = Dispositivo(
                ip=ip,
                mac=mac,
                nombre=nombre_host,
                estado="activo",
            )

    # Siempre incluir la IP local
    ip_local = obtener_ip_local()
    # Marcar el dispositivo propio (el que ejecuta el backend)
    if ip_local in dispositivos_combinados:
        d = dispositivos_combinados[ip_local]
        dispositivos_combinados[ip_local] = Dispositivo(
            ip=d.ip, mac=d.mac,
            nombre=socket.gethostname() + " (Este equipo)",
            estado="activo", fabricante=d.fabricante,
            es_propio=True,
        )
    else:
        dispositivos_combinados[ip_local] = Dispositivo(
            ip=ip_local,
            mac="local",
            nombre=socket.gethostname() + " (Este equipo)",
            estado="activo",
            es_propio=True,
        )

    lista_dispositivos = list(dispositivos_combinados.values())

    # Paso 4: Ping en paralelo para medir latencia
    print(f"📊 Midiendo latencia de {len(lista_dispositivos)} dispositivos...")
    tareas_ping = [ping_dispositivo(d.ip) for d in lista_dispositivos]
    latencias = await asyncio.gather(*tareas_ping, return_exceptions=True)

    latencias_validas = []
    for i, latencia in enumerate(latencias):
        if isinstance(latencia, float) and latencia is not None:
            lista_dispositivos[i].latencia_ms = latencia
            latencias_validas.append(latencia)
        elif isinstance(latencia, Exception):
            lista_dispositivos[i].latencia_ms = None

    # Calcular promedio de latencia
    promedio_latencia = (
        sum(latencias_validas) / len(latencias_validas)
        if latencias_validas else None
    )

    print(f"✅ Escaneo completado. {len(lista_dispositivos)} dispositivos encontrados.")

    return ResultadoEscaneo(
        fecha_hora=datetime.now(),
        dispositivos=lista_dispositivos,
        total_dispositivos=len(lista_dispositivos),
        promedio_latencia_ms=promedio_latencia,
        dispositivos_nuevos=0,  # Se calculará en main.py con la DB
    )


def obtener_nombre_host(ip: str) -> str:
    """Intenta resolver el nombre de host de una IP."""
    try:
        nombre = socket.gethostbyaddr(ip)[0]
        return nombre
    except Exception:
        return f"Dispositivo ({ip.split('.')[-1]})"


async def obtener_info_sistema() -> dict:
    """
    Obtiene información del sistema donde corre el backend.
    CPU, RAM, interfaces de red activas.
    """
    try:
        cpu_porcentaje = psutil.cpu_percent(interval=0.5)
        ram = psutil.virtual_memory()
        interfaces = {}

        for nombre, addrs in psutil.net_if_addrs().items():
            for addr in addrs:
                if addr.family == socket.AF_INET:
                    interfaces[nombre] = addr.address

        return {
            "cpu_porcentaje": cpu_porcentaje,
            "ram_total_gb": round(ram.total / (1024**3), 2),
            "ram_usada_gb": round(ram.used / (1024**3), 2),
            "ram_porcentaje": ram.percent,
            "interfaces_red": interfaces,
            "ip_local": obtener_ip_local(),
            "rango_red": obtener_rango_red(),
            "hostname": socket.gethostname(),
        }
    except Exception as e:
        return {"error": str(e)}
