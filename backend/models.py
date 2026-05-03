"""
models.py - Modelos de datos para NetMonitor
Usa dataclasses de Python puro (sin pydantic) - compatible con Python 3.14+
"""

from dataclasses import dataclass, field, asdict
from typing import Optional, List
from datetime import datetime


@dataclass
class Dispositivo:
    ip: str
    mac: str = "Desconocida"
    nombre: str = "Dispositivo desconocido"
    latencia_ms: Optional[float] = None
    estado: str = "activo"
    fabricante: Optional[str] = None
    es_nuevo: bool = False
    puertos_abiertos: List[int] = field(default_factory=list)
    es_propio: bool = False

    def dict(self):
        return asdict(self)


@dataclass
class ResultadoEscaneo:
    fecha_hora: datetime
    dispositivos: List[Dispositivo]
    total_dispositivos: int
    id: Optional[int] = None
    promedio_latencia_ms: Optional[float] = None
    dispositivos_nuevos: int = 0

    def dict(self):
        return {
            "id": self.id,
            "fecha_hora": self.fecha_hora.isoformat(),
            "total_dispositivos": self.total_dispositivos,
            "promedio_latencia_ms": self.promedio_latencia_ms,
            "dispositivos_nuevos": self.dispositivos_nuevos,
            "dispositivos": [d.dict() for d in self.dispositivos],
        }


@dataclass
class PuertosDispositivo:
    ip: str
    puertos: List[dict] = field(default_factory=list)

    def dict(self):
        return {"ip": self.ip, "puertos": self.puertos}
