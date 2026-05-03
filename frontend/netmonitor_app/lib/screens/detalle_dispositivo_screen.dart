// screens/detalle_dispositivo_screen.dart - Detalle con ping en vivo, gráfico y renombrado

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/dispositivo.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';
import '../widgets/stat_card.dart';
import '../widgets/dispositivo_card.dart';

class DetalleDispositivoScreen extends StatefulWidget {
  final Dispositivo dispositivo;
  const DetalleDispositivoScreen({super.key, required this.dispositivo});

  @override
  State<DetalleDispositivoScreen> createState() => _DetalleDispositivoScreenState();
}

class _DetalleDispositivoScreenState extends State<DetalleDispositivoScreen> {
  List<PuertoInfo>? _puertos;
  bool _cargandoPuertos = false;
  double? _latenciaActual;
  bool _haciendoPing = false;
  final List<double?> _historialPings = [];
  Timer? _pingTimer;

  @override
  void initState() {
    super.initState();
    _latenciaActual = widget.dispositivo.latenciaMs;
    if (_latenciaActual != null) _historialPings.add(_latenciaActual);
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _hacerPing() async {
    if (_haciendoPing) return;
    setState(() => _haciendoPing = true);
    final latencia = await context.read<RedProvider>().ping(widget.dispositivo.ip);
    if (mounted) {
      setState(() {
        _latenciaActual = latencia;
        _haciendoPing = false;
        _historialPings.add(latencia);
        if (_historialPings.length > 8) _historialPings.removeAt(0);
      });
    }
  }

  void _togglePingContinuo() {
    if (_pingTimer != null) {
      _pingTimer?.cancel();
      _pingTimer = null;
    } else {
      _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _hacerPing());
      _hacerPing();
    }
    setState(() {});
  }

  Future<void> _cargarPuertos() async {
    setState(() => _cargandoPuertos = true);
    try {
      final puertos = await context.read<RedProvider>().obtenerPuertos(widget.dispositivo.ip);
      setState(() => _puertos = puertos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: NetMonitorTema.rojoAlerta,
        ));
      }
    } finally {
      if (mounted) setState(() => _cargandoPuertos = false);
    }
  }

  void _copiar(String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copiado'),
      duration: Duration(seconds: 1),
      backgroundColor: NetMonitorTema.verdeActivo,
    ));
  }

  Future<void> _mostrarDialogoRenombrar(BuildContext context) async {
    final provider = context.read<RedProvider>();
    final nombreActual = provider.nombreMostrado(widget.dispositivo);
    final ctrl = TextEditingController(
      text: nombreActual == 'Dispositivo desconocido' ? '' : nombreActual,
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NetMonitorTema.fondoCard,
        title: const Text('Cambiar nombre',
            style: TextStyle(color: NetMonitorTema.textoPrimario, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: NetMonitorTema.textoPrimario),
          decoration: InputDecoration(
            hintText: 'Ej: TV sala, Laptop mamá...',
            hintStyle: const TextStyle(color: NetMonitorTema.textoTerciario),
            filled: true,
            fillColor: NetMonitorTema.fondoSecundario,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: NetMonitorTema.bordeCard),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: NetMonitorTema.bordeCard),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: NetMonitorTema.textoTerciario)),
          ),
          if (provider.nombresPersonalizados.containsKey(widget.dispositivo.ip))
            TextButton(
              onPressed: () {
                provider.renombrarDispositivo(widget.dispositivo.ip, '');
                Navigator.pop(ctx);
              },
              child: const Text('Quitar nombre',
                  style: TextStyle(color: NetMonitorTema.rojoAlerta)),
            ),
          TextButton(
            onPressed: () {
              provider.renombrarDispositivo(widget.dispositivo.ip, ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar',
                style: TextStyle(
                    color: NetMonitorTema.azulElectrico,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispositivo;
    final colorLatencia = NetMonitorTema.colorLatencia(_latenciaActual);
    final tipo = identificarDispositivo(d);
    final pingActivo = _pingTimer != null;

    return Consumer<RedProvider>(
      builder: (context, provider, _) {
        final nombreMostrado = provider.nombreMostrado(d);

        return Scaffold(
          backgroundColor: NetMonitorTema.fondoPrincipal,
          appBar: AppBar(
            title: Text(tipo.tipo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            backgroundColor: NetMonitorTema.fondoSecundario,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ─── Header ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NetMonitorTema.fondoCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NetMonitorTema.bordeCard),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: tipo.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(tipo.icono, color: tipo.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombreMostrado == 'Dispositivo desconocido'
                                        ? (d.fabricante?.isNotEmpty == true
                                            ? d.fabricante!
                                            : d.ip)
                                        : nombreMostrado,
                                    style: const TextStyle(
                                        color: NetMonitorTema.textoPrimario,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Botón renombrar
                                GestureDetector(
                                  onTap: () => _mostrarDialogoRenombrar(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: NetMonitorTema.azulElectrico.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(Icons.edit_outlined,
                                        color: NetMonitorTema.azulElectrico, size: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _copiar(d.ip),
                              child: Row(
                                children: [
                                  Text(d.ip,
                                      style: const TextStyle(
                                          color: NetMonitorTema.azulClaro,
                                          fontSize: 13,
                                          fontFamily: 'monospace')),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.copy,
                                      size: 11, color: NetMonitorTema.textoTerciario),
                                ],
                              ),
                            ),
                            if (provider.nombresPersonalizados.containsKey(d.ip))
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Nombre original: ${d.nombre}',
                                    style: const TextStyle(
                                        color: NetMonitorTema.textoTerciario, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                      // Indicador latencia
                      Column(
                        children: [
                          Container(
                            width: 11, height: 11,
                            decoration: BoxDecoration(
                              color: colorLatencia,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: colorLatencia.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _latenciaActual != null
                                ? '${_latenciaActual!.toStringAsFixed(0)}ms'
                                : '—',
                            style: TextStyle(
                                color: colorLatencia,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.06),
                const SizedBox(height: 12),

                // ─── Barra de latencia ────────────────────────────────────
                BarraLatencia(latenciaMs: _latenciaActual),
                const SizedBox(height: 10),

                // ─── Gráfico de pings (altura fija, sin overflow) ─────────
                if (_historialPings.isNotEmpty)
                  _GraficoPings(historial: _historialPings),
                const SizedBox(height: 12),

                // ─── Botones ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _BotonAccion(
                        label: _haciendoPing ? 'Midiendo...' : 'Hacer Ping',
                        icono: Icons.wifi_tethering,
                        color: NetMonitorTema.azulElectrico,
                        onTap: _haciendoPing ? null : _hacerPing,
                        cargando: _haciendoPing,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _BotonEnVivo(activo: pingActivo, onTap: _togglePingContinuo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BotonAccion(
                        label: _cargandoPuertos ? 'Escaneando...' : 'Ver Puertos',
                        icono: Icons.dns_outlined,
                        color: const Color(0xFF7C3AED),
                        onTap: _cargandoPuertos ? null : _cargarPuertos,
                        cargando: _cargandoPuertos,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ─── Info técnica ─────────────────────────────────────────
                _SeccionTitulo('Información técnica'),
                const SizedBox(height: 8),
                _SeccionInfo(items: [
                  _InfoItem('Dirección IP', d.ip, onTap: () => _copiar(d.ip)),
                  _InfoItem(
                    'MAC',
                    d.mac != 'Desconocida' && d.mac != 'local'
                        ? d.mac.toUpperCase()
                        : 'No disponible',
                    onTap: d.mac != 'Desconocida' && d.mac != 'local'
                        ? () => _copiar(d.mac)
                        : null,
                  ),
                  if (d.fabricante != null && d.fabricante!.isNotEmpty)
                    _InfoItem('Fabricante', d.fabricante!),
                  _InfoItem('Tipo detectado', tipo.tipo),
                  _InfoItem(
                    'Estado',
                    _latenciaActual != null ? 'En línea' : 'Sin respuesta',
                    valorColor: _latenciaActual != null
                        ? NetMonitorTema.verdeActivo
                        : NetMonitorTema.grisInactivo,
                  ),
                ]),
                const SizedBox(height: 18),

                // ─── Puertos ──────────────────────────────────────────────
                if (_cargandoPuertos) ...[
                  _SeccionTitulo('Puertos abiertos'),
                  const SizedBox(height: 12),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                            color: NetMonitorTema.azulElectrico, strokeWidth: 2),
                        SizedBox(height: 10),
                        Text('Escaneando puertos...',
                            style: TextStyle(
                                color: NetMonitorTema.textoTerciario, fontSize: 13)),
                      ],
                    ),
                  ),
                ],

                if (_puertos != null) ...[
                  _SeccionTitulo('Puertos abiertos (${_puertos!.length})'),
                  const SizedBox(height: 8),
                  if (_puertos!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NetMonitorTema.fondoCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NetMonitorTema.bordeCard),
                      ),
                      child: const Center(
                        child: Text('No se encontraron puertos abiertos',
                            style: TextStyle(
                                color: NetMonitorTema.textoTerciario, fontSize: 13)),
                      ),
                    )
                  else
                    ...(_puertos!.asMap().entries
                        .map((e) => _FilaPuerto(puerto: e.value, indice: e.key))),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Gráfico sin overflow ─────────────────────────────────────────────────────

class _GraficoPings extends StatelessWidget {
  final List<double?> historial;
  const _GraficoPings({required this.historial});

  @override
  Widget build(BuildContext context) {
    final validValues = historial.where((v) => v != null).toList();
    final maxVal = validValues.isEmpty ? 1.0 :
        validValues.fold<double>(1.0, (prev, v) => v! > prev ? v : prev);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: NetMonitorTema.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NetMonitorTema.bordeCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de pings',
              style: TextStyle(
                  color: NetMonitorTema.textoTerciario,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          // Altura fija para evitar overflow
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: historial.map((val) {
                final pct = val != null ? (val / maxVal).clamp(0.05, 1.0) : 0.0;
                final color = NetMonitorTema.colorLatencia(val);
                final barHeight = val != null ? (36 * pct).clamp(4.0, 36.0) : 4.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (val != null)
                          Text(
                            val.toStringAsFixed(0),
                            style: TextStyle(
                                color: color,
                                fontSize: 8,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: val != null
                                ? color.withOpacity(0.85)
                                : NetMonitorTema.grisInactivo.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón En Vivo ────────────────────────────────────────────────────────────

class _BotonEnVivo extends StatelessWidget {
  final bool activo;
  final VoidCallback onTap;
  const _BotonEnVivo({required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? NetMonitorTema.verdeActivo : NetMonitorTema.textoSecundario;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(activo ? 0.6 : 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  activo ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  color: color, size: 16,
                ),
                const SizedBox(width: 5),
                Text('En vivo',
                    style: TextStyle(
                        color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            if (activo) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: 40, height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: NetMonitorTema.bordeCard,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  const _SeccionTitulo(this.titulo);
  @override
  Widget build(BuildContext context) => Text(titulo,
      style: const TextStyle(
          color: NetMonitorTema.textoSecundario,
          fontSize: 12,
          fontWeight: FontWeight.w600));
}

class _SeccionInfo extends StatelessWidget {
  final List<_InfoItem> items;
  const _SeccionInfo({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NetMonitorTema.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NetMonitorTema.bordeCard),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < items.length - 1)
                const Divider(height: 1, color: NetMonitorTema.bordeCard, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String valor;
  final VoidCallback? onTap;
  final Color? valorColor;
  const _InfoItem(this.label, this.valor, {this.onTap, this.valorColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: NetMonitorTema.textoSecundario, fontSize: 13)),
            Row(
              children: [
                Text(valor,
                    style: TextStyle(
                        color: valorColor ?? NetMonitorTema.textoPrimario,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace')),
                if (onTap != null) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.copy,
                      size: 12, color: NetMonitorTema.textoTerciario),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;
  final bool cargando;
  const _BotonAccion({
    required this.label, required this.icono, required this.color,
    this.onTap, this.cargando = false,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(onTap == null ? 0.04 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(onTap == null ? 0.15 : 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(color: color, strokeWidth: 2))
            else
              Icon(icono,
                  color: onTap == null ? color.withOpacity(0.35) : color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? color.withOpacity(0.35) : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _FilaPuerto extends StatelessWidget {
  final PuertoInfo puerto;
  final int indice;
  const _FilaPuerto({required this.puerto, required this.indice});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NetMonitorTema.fondoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NetMonitorTema.bordeCard),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: NetMonitorTema.azulElectrico.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${puerto.puerto}',
                style: const TextStyle(
                    color: NetMonitorTema.azulElectrico,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(puerto.servicio.toUpperCase(),
                style: const TextStyle(
                    color: NetMonitorTema.textoPrimario,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: NetMonitorTema.verdeActivo.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('OPEN',
                style: TextStyle(
                    color: NetMonitorTema.verdeActivo,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: indice * 35)).fadeIn();
  }
}
