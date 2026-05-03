"""
main.py - Servidor FastAPI principal de NetMonitor
Sin pydantic - compatible con Python 3.14+
"""

from datetime import datetime
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

import database
import scanner
from models import Dispositivo, ResultadoEscaneo, PuertosDispositivo

# ─── Estado global ─────────────────────────────────────────────────────────────
ultimo_escaneo: Optional[ResultadoEscaneo] = None
escaneo_en_progreso: bool = False

# ─── App FastAPI ───────────────────────────────────────────────────────────────
app = FastAPI(
    title="NetMonitor API",
    description="API REST para monitoreo de red local",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def al_iniciar():
    print("Iniciando NetMonitor Backend...")
    await database.inicializar_db()
    print("Backend listo en http://localhost:8000")


# ─── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/")
async def raiz():
    return {"mensaje": "NetMonitor API activa", "version": "1.0.0", "docs": "/docs"}


@app.get("/estado")
async def estado_servidor():
    info = await scanner.obtener_info_sistema()
    return {
        "servidor": "activo",
        "escaneo_en_progreso": escaneo_en_progreso,
        "ultimo_escaneo": ultimo_escaneo.fecha_hora.isoformat() if ultimo_escaneo else None,
        "sistema": info,
    }


@app.post("/escanear")
async def iniciar_escaneo():
    global ultimo_escaneo, escaneo_en_progreso

    if escaneo_en_progreso:
        raise HTTPException(status_code=409, detail="Ya hay un escaneo en progreso.")

    escaneo_en_progreso = True
    try:
        resultado = await scanner.escanear_red_completo()

        dispositivos_nuevos = 0
        for dispositivo in resultado.dispositivos:
            es_conocido = await database.es_dispositivo_conocido(dispositivo.mac)
            if not es_conocido:
                dispositivo.es_nuevo = True
                dispositivos_nuevos += 1
                await database.guardar_alerta(
                    ip=dispositivo.ip,
                    mac=dispositivo.mac,
                    mensaje=f"Dispositivo desconocido: {dispositivo.ip} ({dispositivo.mac})"
                )
            await database.registrar_dispositivo_conocido(dispositivo)

        resultado.dispositivos_nuevos = dispositivos_nuevos
        resultado.id = await database.guardar_escaneo(resultado)
        ultimo_escaneo = resultado

        return resultado.dict()

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")
    finally:
        escaneo_en_progreso = False


@app.get("/dispositivos")
async def obtener_dispositivos():
    if ultimo_escaneo is None:
        return []
    return [d.dict() for d in ultimo_escaneo.dispositivos]


@app.get("/dispositivos/{ip}/puertos")
async def obtener_puertos(ip: str):
    try:
        resultado = await scanner.escanear_puertos(ip)
        return resultado.dict()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/ping/{ip}")
async def ping_ip(ip: str):
    latencia = await scanner.ping_dispositivo(ip)
    return {
        "ip": ip,
        "latencia_ms": latencia,
        "estado": "activo" if latencia is not None else "inactivo",
        "fecha_hora": datetime.now().isoformat(),
    }


@app.get("/historial")
async def obtener_historial(limite: int = 20):
    try:
        historial = await database.obtener_historial_escaneos(limite)
        return {"escaneos": historial, "total": len(historial)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/historial/{escaneo_id}")
async def obtener_escaneo_historial(escaneo_id: int):
    resultado = await database.obtener_escaneo_por_id(escaneo_id)
    if not resultado:
        raise HTTPException(status_code=404, detail="Escaneo no encontrado")
    return resultado


@app.get("/estadisticas")
async def obtener_estadisticas():
    try:
        stats_db = await database.obtener_estadisticas()

        if ultimo_escaneo:
            dispositivos_activos = sum(1 for d in ultimo_escaneo.dispositivos if d.estado == "activo")
            latencias = [d.latencia_ms for d in ultimo_escaneo.dispositivos if d.latencia_ms is not None]
            promedio = sum(latencias) / len(latencias) if latencias else None
        else:
            dispositivos_activos = 0
            promedio = None

        return {
            "total_dispositivos": stats_db.get("total_dispositivos_conocidos", 0),
            "dispositivos_activos": dispositivos_activos,
            "promedio_latencia_ms": round(promedio, 2) if promedio else None,
            "dispositivos_nuevos": ultimo_escaneo.dispositivos_nuevos if ultimo_escaneo else 0,
            "total_escaneos": stats_db.get("total_escaneos", 0),
            "ultimo_escaneo": stats_db.get("ultimo_escaneo"),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/alertas")
async def obtener_alertas():
    try:
        alertas = await database.obtener_alertas_no_leidas()
        return {"alertas": alertas, "total": len(alertas)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/alertas/leer")
async def marcar_alertas_leidas():
    await database.marcar_alertas_leidas()
    return {"mensaje": "Alertas marcadas como leidas"}



@app.delete("/historial/{escaneo_id}")
async def borrar_escaneo(escaneo_id: int):
    """Borra un escaneo específico del historial."""
    borrado = await database.borrar_escaneo(escaneo_id)
    if not borrado:
        raise HTTPException(status_code=404, detail="Escaneo no encontrado")
    return {"mensaje": f"Escaneo #{escaneo_id} borrado correctamente"}


@app.delete("/historial")
async def borrar_todo_historial():
    """Borra todo el historial de escaneos."""
    total = await database.borrar_todo_historial()
    return {"mensaje": f"Historial borrado: {total} registros eliminados", "total": total}

# ─── Inicio ────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False, log_level="info")
