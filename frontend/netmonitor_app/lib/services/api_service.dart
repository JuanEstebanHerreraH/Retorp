// services/api_service.dart - Servicio para comunicarse con el backend FastAPI

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dispositivo.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000';

  static final ApiService _instancia = ApiService._interno();
  factory ApiService() => _instancia;
  ApiService._interno();

  final http.Client _cliente = http.Client();
  static const Duration _timeout = Duration(seconds: 60);

  // ─── Helper para respuestas tipo Map ───────────────────────────────────────
  Future<Map<String, dynamic>> _get(String ruta) async {
    try {
      final respuesta = await _cliente
          .get(Uri.parse('$_baseUrl$ruta'))
          .timeout(_timeout);
      if (respuesta.statusCode == 200) {
        final decoded = json.decode(utf8.decode(respuesta.bodyBytes));
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      }
      throw ApiException('Error ${respuesta.statusCode}: ${respuesta.body}', respuesta.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error de conexion: $e', 0);
    }
  }

  // ─── Helper para respuestas tipo Lista ─────────────────────────────────────
  Future<List<dynamic>> _getList(String ruta) async {
    try {
      final respuesta = await _cliente
          .get(Uri.parse('$_baseUrl$ruta'))
          .timeout(_timeout);
      if (respuesta.statusCode == 200) {
        final decoded = json.decode(utf8.decode(respuesta.bodyBytes));
        if (decoded is List) return decoded;
        return [];
      }
      throw ApiException('Error ${respuesta.statusCode}: ${respuesta.body}', respuesta.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error de conexion: $e', 0);
    }
  }

  // ─── Helper para POST ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(String ruta, {Map<String, dynamic>? body}) async {
    try {
      final respuesta = await _cliente
          .post(
            Uri.parse('$_baseUrl$ruta'),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      if (respuesta.statusCode == 200) {
        return json.decode(utf8.decode(respuesta.bodyBytes));
      }
      throw ApiException('Error ${respuesta.statusCode}: ${respuesta.body}', respuesta.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error de conexion: $e', 0);
    }
  }

  // ─── Endpoints ─────────────────────────────────────────────────────────────

  Future<bool> verificarConexion() async {
    try {
      await _get('/');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> obtenerEstado() async {
    return await _get('/estado');
  }

  Future<ResultadoEscaneo> iniciarEscaneo() async {
    final datos = await _post('/escanear');
    return ResultadoEscaneo.fromJson(datos);
  }

  // Usa _getList porque /dispositivos devuelve una lista JSON
  Future<List<Dispositivo>> obtenerDispositivos() async {
    final lista = await _getList('/dispositivos');
    return lista.map((d) => Dispositivo.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<List<PuertoInfo>> obtenerPuertos(String ip) async {
    final datos = await _get('/dispositivos/$ip/puertos');
    final puertos = datos['puertos'] as List<dynamic>? ?? [];
    return puertos.map((p) => PuertoInfo.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> ping(String ip) async {
    return await _get('/ping/$ip');
  }

  Future<List<Map<String, dynamic>>> obtenerHistorial({int limite = 20}) async {
    final datos = await _get('/historial?limite=$limite');
    return List<Map<String, dynamic>>.from(datos['escaneos'] ?? []);
  }

  Future<ResultadoEscaneo> obtenerEscaneoHistorial(int id) async {
    final datos = await _get('/historial/$id');
    return ResultadoEscaneo.fromJson(datos);
  }

  Future<EstadisticasRed> obtenerEstadisticas() async {
    final datos = await _get('/estadisticas');
    return EstadisticasRed.fromJson(datos);
  }

  Future<List<AlertaIntrusso>> obtenerAlertas() async {
    final datos = await _get('/alertas');
    final lista = datos['alertas'] as List<dynamic>? ?? [];
    return lista.map((a) => AlertaIntrusso.fromJson(a as Map<String, dynamic>)).toList();
  }

  Future<void> marcarAlertasLeidas() async {
    await _post('/alertas/leer');
  }


  Future<void> borrarEscaneo(int id) async {
    try {
      final respuesta = await _cliente
          .delete(Uri.parse('$_baseUrl/historial/$id'))
          .timeout(_timeout);
      if (respuesta.statusCode != 200) {
        throw ApiException('Error \${respuesta.statusCode}', respuesta.statusCode);
      }
    } catch (e) {
      throw ApiException('Error borrando escaneo: $e', 0);
    }
  }

  Future<void> borrarTodoHistorial() async {
    try {
      final respuesta = await _cliente
          .delete(Uri.parse('$_baseUrl/historial'))
          .timeout(_timeout);
      if (respuesta.statusCode != 200) {
        throw ApiException('Error \${respuesta.statusCode}', respuesta.statusCode);
      }
    } catch (e) {
      throw ApiException('Error borrando historial: $e', 0);
    }
  }

  void dispose() {
    _cliente.close();
  }
}

class ApiException implements Exception {
  final String mensaje;
  final int codigo;
  ApiException(this.mensaje, this.codigo);

  @override
  String toString() => 'ApiException($codigo): $mensaje';

  bool get esErrorConexion => codigo == 0;
  bool get esNoEncontrado => codigo == 404;
  bool get esConflicto => codigo == 409;
}
