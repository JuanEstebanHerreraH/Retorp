// services/red_provider.dart - Estado global con soporte de renombrado y latencia en vivo

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dispositivo.dart';
import 'api_service.dart';

enum EstadoEscaneo { inactivo, escaneando, completado, error }

class RedProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  EstadoEscaneo _estadoEscaneo = EstadoEscaneo.inactivo;
  List<Dispositivo> _dispositivos = [];
  EstadisticasRed? _estadisticas;
  List<Map<String, dynamic>> _historial = [];
  List<AlertaIntrusso> _alertas = [];
  String? _mensajeError;
  bool _servidorConectado = false;
  ResultadoEscaneo? _ultimoResultado;
  bool _refrescandoLatencia = false;

  // Mapa IP → nombre personalizado
  Map<String, String> _nombresPersonalizados = {};

  // ─── Getters ──────────────────────────────────────────────────────────────
  EstadoEscaneo get estadoEscaneo => _estadoEscaneo;
  List<Dispositivo> get dispositivos => _dispositivos;
  EstadisticasRed? get estadisticas => _estadisticas;
  List<Map<String, dynamic>> get historial => _historial;
  List<AlertaIntrusso> get alertas => _alertas;
  String? get mensajeError => _mensajeError;
  bool get servidorConectado => _servidorConectado;
  ResultadoEscaneo? get ultimoResultado => _ultimoResultado;
  bool get estaEscaneando => _estadoEscaneo == EstadoEscaneo.escaneando;
  bool get refrescandoLatencia => _refrescandoLatencia;
  int get totalAlertas => _alertas.length;
  Map<String, String> get nombresPersonalizados => _nombresPersonalizados;

  RedProvider() {
    _cargarNombresGuardados();
  }

  // ─── Nombres personalizados ────────────────────────────────────────────────
  Future<void> _cargarNombresGuardados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('nombre_'));
      for (final key in keys) {
        final ip = key.replaceFirst('nombre_', '');
        _nombresPersonalizados[ip] = prefs.getString(key) ?? '';
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> renombrarDispositivo(String ip, String nuevoNombre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (nuevoNombre.trim().isEmpty) {
        await prefs.remove('nombre_$ip');
        _nombresPersonalizados.remove(ip);
      } else {
        await prefs.setString('nombre_$ip', nuevoNombre.trim());
        _nombresPersonalizados[ip] = nuevoNombre.trim();
      }
      notifyListeners();
    } catch (_) {}
  }

  String nombreMostrado(Dispositivo d) {
    if (_nombresPersonalizados.containsKey(d.ip)) {
      return _nombresPersonalizados[d.ip]!;
    }
    return d.nombre;
  }

  // ─── Verificar conexión ────────────────────────────────────────────────────
  Future<void> verificarConexion() async {
    _servidorConectado = await _api.verificarConexion();
    notifyListeners();
  }

  // ─── Escaneo completo ──────────────────────────────────────────────────────
  Future<void> iniciarEscaneo() async {
    if (_estadoEscaneo == EstadoEscaneo.escaneando) return;
    _estadoEscaneo = EstadoEscaneo.escaneando;
    _mensajeError = null;
    notifyListeners();

    try {
      final resultado = await _api.iniciarEscaneo();
      _ultimoResultado = resultado;
      _dispositivos = resultado.dispositivos;
      _estadoEscaneo = EstadoEscaneo.completado;
      await cargarEstadisticas();
      await cargarAlertas();
      // Auto-recargar historial cuando termina un escaneo
      await cargarHistorial();
    } on ApiException catch (e) {
      _estadoEscaneo = EstadoEscaneo.error;
      if (e.esConflicto) {
        _mensajeError = 'Ya hay un escaneo en progreso. Espera...';
      } else if (e.esErrorConexion) {
        _mensajeError = 'No se puede conectar al servidor. ¿Está ejecutándose el start.bat?';
        _servidorConectado = false;
      } else {
        _mensajeError = e.mensaje;
      }
    } catch (e) {
      _estadoEscaneo = EstadoEscaneo.error;
      _mensajeError = 'Error inesperado: $e';
    }
    notifyListeners();
  }

  // ─── Refrescar latencias ───────────────────────────────────────────────────
  Future<void> refrescarLatencias() async {
    if (_dispositivos.isEmpty || _refrescandoLatencia) return;
    _refrescandoLatencia = true;
    notifyListeners();

    final futures = _dispositivos.map((d) => _api.ping(d.ip));
    final resultados = await Future.wait(futures, eagerError: false);

    for (int i = 0; i < _dispositivos.length; i++) {
      try {
        final res = resultados[i];
        final nuevaLatencia = res['latencia_ms']?.toDouble();
        _dispositivos[i] = Dispositivo(
          ip: _dispositivos[i].ip,
          mac: _dispositivos[i].mac,
          nombre: _dispositivos[i].nombre,
          latenciaMs: nuevaLatencia,
          estado: nuevaLatencia != null ? 'activo' : 'inactivo',
          fabricante: _dispositivos[i].fabricante,
          esNuevo: _dispositivos[i].esNuevo,
          puertosAbiertos: _dispositivos[i].puertosAbiertos,
        );
      } catch (_) {}
    }

    _refrescandoLatencia = false;
    notifyListeners();
  }

  // ─── Estadísticas ──────────────────────────────────────────────────────────
  Future<void> cargarEstadisticas() async {
    try {
      _estadisticas = await _api.obtenerEstadisticas();
      notifyListeners();
    } catch (_) {}
  }

  // ─── Historial ─────────────────────────────────────────────────────────────
  Future<void> cargarHistorial() async {
    try {
      _historial = await _api.obtenerHistorial();
      notifyListeners();
    } on ApiException catch (e) {
      _mensajeError = e.mensaje;
      notifyListeners();
    }
  }

  // ─── Alertas ───────────────────────────────────────────────────────────────
  Future<void> cargarAlertas() async {
    try {
      _alertas = await _api.obtenerAlertas();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> marcarAlertasLeidas() async {
    try {
      await _api.marcarAlertasLeidas();
      _alertas = [];
      notifyListeners();
    } catch (_) {}
  }

  // ─── Ping individual ───────────────────────────────────────────────────────
  Future<double?> ping(String ip) async {
    try {
      final resultado = await _api.ping(ip);
      return resultado['latencia_ms']?.toDouble();
    } catch (_) {
      return null;
    }
  }

  // ─── Puertos ───────────────────────────────────────────────────────────────
  Future<List<PuertoInfo>> obtenerPuertos(String ip) async {
    return await _api.obtenerPuertos(ip);
  }


  // ─── Borrar historial ─────────────────────────────────────────────────────
  Future<void> borrarEscaneo(int id) async {
    try {
      await _api.borrarEscaneo(id);
      _historial.removeWhere((e) => e['id'] == id);
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al borrar: $e';
      notifyListeners();
    }
  }

  Future<void> borrarTodoHistorial() async {
    try {
      await _api.borrarTodoHistorial();
      _historial = [];
      notifyListeners();
    } catch (e) {
      _mensajeError = 'Error al borrar historial: $e';
      notifyListeners();
    }
  }

  void limpiarError() {
    _mensajeError = null;
    if (_estadoEscaneo == EstadoEscaneo.error) {
      _estadoEscaneo = EstadoEscaneo.inactivo;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
