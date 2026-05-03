"""
database.py - Gestión de base de datos SQLite con aiosqlite para NetMonitor
"""

import aiosqlite
import json
from datetime import datetime
from typing import List, Optional
from models import Dispositivo, ResultadoEscaneo

# Ruta del archivo de base de datos
DB_PATH = "netmonitor.db"


async def inicializar_db():
    """Crea las tablas necesarias si no existen."""
    async with aiosqlite.connect(DB_PATH) as db:
        # Tabla de escaneos
        await db.execute("""
            CREATE TABLE IF NOT EXISTS escaneos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                fecha_hora TEXT NOT NULL,
                total_dispositivos INTEGER NOT NULL,
                promedio_latencia_ms REAL,
                dispositivos_nuevos INTEGER DEFAULT 0,
                dispositivos_json TEXT NOT NULL
            )
        """)

        # Tabla de dispositivos conocidos (para detectar intrusos)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS dispositivos_conocidos (
                mac TEXT PRIMARY KEY,
                ip TEXT,
                nombre TEXT,
                fabricante TEXT,
                primera_vez_visto TEXT NOT NULL,
                ultima_vez_visto TEXT NOT NULL
            )
        """)

        # Tabla de alertas de intrusos
        await db.execute("""
            CREATE TABLE IF NOT EXISTS alertas (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                ip TEXT NOT NULL,
                mac TEXT NOT NULL,
                fecha_hora TEXT NOT NULL,
                mensaje TEXT NOT NULL,
                leida INTEGER DEFAULT 0
            )
        """)

        await db.commit()
    print("✅ Base de datos inicializada correctamente.")


async def guardar_escaneo(resultado: ResultadoEscaneo) -> int:
    """Guarda un resultado de escaneo en la base de datos."""
    dispositivos_json = json.dumps(
        [d.dict() for d in resultado.dispositivos],
        default=str
    )

    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            """
            INSERT INTO escaneos
                (fecha_hora, total_dispositivos, promedio_latencia_ms, dispositivos_nuevos, dispositivos_json)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                resultado.fecha_hora.isoformat(),
                resultado.total_dispositivos,
                resultado.promedio_latencia_ms,
                resultado.dispositivos_nuevos,
                dispositivos_json,
            )
        )
        await db.commit()
        return cursor.lastrowid


async def obtener_historial_escaneos(limite: int = 20) -> List[dict]:
    """Obtiene los últimos N escaneos del historial."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            """
            SELECT id, fecha_hora, total_dispositivos, promedio_latencia_ms, dispositivos_nuevos
            FROM escaneos
            ORDER BY fecha_hora DESC
            LIMIT ?
            """,
            (limite,)
        )
        filas = await cursor.fetchall()
        return [dict(f) for f in filas]


async def obtener_escaneo_por_id(escaneo_id: int) -> Optional[dict]:
    """Obtiene un escaneo específico con todos sus dispositivos."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM escaneos WHERE id = ?",
            (escaneo_id,)
        )
        fila = await cursor.fetchone()
        if fila:
            resultado = dict(fila)
            resultado["dispositivos"] = json.loads(resultado["dispositivos_json"])
            return resultado
        return None


async def registrar_dispositivo_conocido(dispositivo: Dispositivo):
    """Registra o actualiza un dispositivo en la lista de conocidos."""
    ahora = datetime.now().isoformat()
    async with aiosqlite.connect(DB_PATH) as db:
        # Verificar si ya existe
        cursor = await db.execute(
            "SELECT mac FROM dispositivos_conocidos WHERE mac = ?",
            (dispositivo.mac,)
        )
        existe = await cursor.fetchone()

        if existe:
            # Actualizar última vez visto
            await db.execute(
                "UPDATE dispositivos_conocidos SET ip = ?, ultima_vez_visto = ? WHERE mac = ?",
                (dispositivo.ip, ahora, dispositivo.mac)
            )
        else:
            # Insertar nuevo dispositivo
            await db.execute(
                """
                INSERT INTO dispositivos_conocidos
                    (mac, ip, nombre, fabricante, primera_vez_visto, ultima_vez_visto)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (dispositivo.mac, dispositivo.ip, dispositivo.nombre,
                 dispositivo.fabricante, ahora, ahora)
            )
        await db.commit()


async def es_dispositivo_conocido(mac: str) -> bool:
    """Verifica si un dispositivo (por MAC) ya fue visto antes."""
    if not mac or mac == "Desconocida":
        return True  # Sin MAC no podemos determinar, asumimos conocido
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            "SELECT mac FROM dispositivos_conocidos WHERE mac = ?",
            (mac,)
        )
        return await cursor.fetchone() is not None


async def guardar_alerta(ip: str, mac: str, mensaje: str):
    """Guarda una alerta de dispositivo desconocido."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO alertas (ip, mac, fecha_hora, mensaje) VALUES (?, ?, ?, ?)",
            (ip, mac, datetime.now().isoformat(), mensaje)
        )
        await db.commit()


async def obtener_alertas_no_leidas() -> List[dict]:
    """Obtiene todas las alertas que no han sido leídas."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM alertas WHERE leida = 0 ORDER BY fecha_hora DESC"
        )
        filas = await cursor.fetchall()
        return [dict(f) for f in filas]


async def marcar_alertas_leidas():
    """Marca todas las alertas como leídas."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("UPDATE alertas SET leida = 1 WHERE leida = 0")
        await db.commit()


async def obtener_estadisticas() -> dict:
    """Calcula estadísticas generales de la red."""
    async with aiosqlite.connect(DB_PATH) as db:
        # Total de escaneos
        cursor = await db.execute("SELECT COUNT(*) FROM escaneos")
        total_escaneos = (await cursor.fetchone())[0]

        # Último escaneo
        cursor = await db.execute(
            "SELECT fecha_hora, total_dispositivos, promedio_latencia_ms, dispositivos_nuevos FROM escaneos ORDER BY fecha_hora DESC LIMIT 1"
        )
        ultimo = await cursor.fetchone()

        # Total dispositivos conocidos
        cursor = await db.execute("SELECT COUNT(*) FROM dispositivos_conocidos")
        total_conocidos = (await cursor.fetchone())[0]

        return {
            "total_escaneos": total_escaneos,
            "total_dispositivos_conocidos": total_conocidos,
            "ultimo_escaneo": {
                "fecha_hora": ultimo[0] if ultimo else None,
                "total_dispositivos": ultimo[1] if ultimo else 0,
                "promedio_latencia_ms": ultimo[2] if ultimo else None,
                "dispositivos_nuevos": ultimo[3] if ultimo else 0,
            } if ultimo else None
        }


async def borrar_escaneo(escaneo_id: int) -> bool:
    """Borra un escaneo específico del historial por su ID."""
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            "DELETE FROM escaneos WHERE id = ?", (escaneo_id,)
        )
        await db.commit()
        return cursor.rowcount > 0


async def borrar_todo_historial() -> int:
    """Borra todos los registros del historial. Devuelve cantidad borrada."""
    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute("SELECT COUNT(*) FROM escaneos")
        total = (await cursor.fetchone())[0]
        await db.execute("DELETE FROM escaneos")
        await db.commit()
        return total
