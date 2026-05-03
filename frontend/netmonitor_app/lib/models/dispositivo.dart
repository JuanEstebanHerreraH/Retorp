// models/dispositivo.dart - Modelos de datos para el frontend Flutter

class Dispositivo {
  final String ip;
  final String mac;
  final String nombre;
  final double? latenciaMs;
  final String estado;
  final String? fabricante;
  final bool esNuevo;
  final bool esPropio;
  final List<int> puertosAbiertos;

  Dispositivo({
    required this.ip,
    this.mac = 'Desconocida',
    this.nombre = 'Dispositivo desconocido',
    this.latenciaMs,
    this.estado = 'activo',
    this.fabricante,
    this.esNuevo = false,
    this.esPropio = false,
    this.puertosAbiertos = const [],
  });

  factory Dispositivo.fromJson(Map<String, dynamic> json) {
    return Dispositivo(
      ip: json['ip'] ?? '',
      mac: json['mac'] ?? 'Desconocida',
      nombre: json['nombre'] ?? 'Dispositivo desconocido',
      latenciaMs: json['latencia_ms']?.toDouble(),
      estado: json['estado'] ?? 'activo',
      fabricante: json['fabricante'],
      esNuevo: json['es_nuevo'] ?? false,
      esPropio: json['es_propio'] ?? false,
      puertosAbiertos: List<int>.from(json['puertos_abiertos'] ?? []),
    );
  }

  /// Devuelve el color de estado basado en latencia
  EstadoLatencia get estadoLatencia {
    if (latenciaMs == null) return EstadoLatencia.sinRespuesta;
    if (latenciaMs! < 20) return EstadoLatencia.excelente;
    if (latenciaMs! < 80) return EstadoLatencia.buena;
    if (latenciaMs! < 200) return EstadoLatencia.regular;
    return EstadoLatencia.mala;
  }
}

enum EstadoLatencia {
  excelente,  // < 20ms  → verde brillante
  buena,      // < 80ms  → verde
  regular,    // < 200ms → amarillo
  mala,       // > 200ms → rojo
  sinRespuesta,          // sin ping → gris
}


class ResultadoEscaneo {
  final int? id;
  final DateTime fechaHora;
  final List<Dispositivo> dispositivos;
  final int totalDispositivos;
  final double? promedioLatenciaMs;
  final int dispositivosNuevos;

  ResultadoEscaneo({
    this.id,
    required this.fechaHora,
    required this.dispositivos,
    required this.totalDispositivos,
    this.promedioLatenciaMs,
    this.dispositivosNuevos = 0,
  });

  factory ResultadoEscaneo.fromJson(Map<String, dynamic> json) {
    return ResultadoEscaneo(
      id: json['id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      dispositivos: (json['dispositivos'] as List<dynamic>?)
              ?.map((d) => Dispositivo.fromJson(d))
              .toList() ??
          [],
      totalDispositivos: json['total_dispositivos'] ?? 0,
      promedioLatenciaMs: json['promedio_latencia_ms']?.toDouble(),
      dispositivosNuevos: json['dispositivos_nuevos'] ?? 0,
    );
  }
}


class EstadisticasRed {
  final int totalDispositivos;
  final int dispositivosActivos;
  final double? promedioLatenciaMs;
  final int dispositivosNuevos;
  final int totalEscaneos;
  final DateTime? ultimoEscaneo;

  EstadisticasRed({
    required this.totalDispositivos,
    required this.dispositivosActivos,
    this.promedioLatenciaMs,
    required this.dispositivosNuevos,
    required this.totalEscaneos,
    this.ultimoEscaneo,
  });

  factory EstadisticasRed.fromJson(Map<String, dynamic> json) {
    final ultimoData = json['ultimo_escaneo'];
    DateTime? ultimoEscaneo;
    if (ultimoData != null && ultimoData['fecha_hora'] != null) {
      ultimoEscaneo = DateTime.tryParse(ultimoData['fecha_hora']);
    }

    return EstadisticasRed(
      totalDispositivos: json['total_dispositivos'] ?? 0,
      dispositivosActivos: json['dispositivos_activos'] ?? 0,
      promedioLatenciaMs: json['promedio_latencia_ms']?.toDouble(),
      dispositivosNuevos: json['dispositivos_nuevos'] ?? 0,
      totalEscaneos: json['total_escaneos'] ?? 0,
      ultimoEscaneo: ultimoEscaneo,
    );
  }
}


class PuertoInfo {
  final int puerto;
  final String protocolo;
  final String servicio;
  final String version;
  final String estado;

  PuertoInfo({
    required this.puerto,
    required this.protocolo,
    required this.servicio,
    required this.version,
    required this.estado,
  });

  factory PuertoInfo.fromJson(Map<String, dynamic> json) {
    return PuertoInfo(
      puerto: json['puerto'] ?? 0,
      protocolo: json['protocolo'] ?? 'tcp',
      servicio: json['servicio'] ?? 'desconocido',
      version: json['version'] ?? '',
      estado: json['estado'] ?? 'open',
    );
  }
}


class AlertaIntrusso {
  final int id;
  final String ip;
  final String mac;
  final DateTime fechaHora;
  final String mensaje;

  AlertaIntrusso({
    required this.id,
    required this.ip,
    required this.mac,
    required this.fechaHora,
    required this.mensaje,
  });

  factory AlertaIntrusso.fromJson(Map<String, dynamic> json) {
    return AlertaIntrusso(
      id: json['id'] ?? 0,
      ip: json['ip'] ?? '',
      mac: json['mac'] ?? '',
      fechaHora: DateTime.parse(json['fecha_hora']),
      mensaje: json['mensaje'] ?? '',
    );
  }
}
