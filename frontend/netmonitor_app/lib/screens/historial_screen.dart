// screens/historial_screen.dart - Historial con borrado individual y total

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    await context.read<RedProvider>().cargarHistorial();
    if (mounted) setState(() => _cargando = false);
  }

  String _fecha(String? s) {
    if (s == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy  HH:mm:ss').format(DateTime.parse(s));
    } catch (_) {
      return s;
    }
  }

  Future<void> _confirmarBorrarTodo(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NetMonitorTema.fondoCard,
        title: const Text('Borrar todo el historial',
            style: TextStyle(color: NetMonitorTema.textoPrimario, fontSize: 16)),
        content: const Text(
            '¿Estás seguro? Se eliminarán todos los registros de escaneos anteriores.',
            style: TextStyle(color: NetMonitorTema.textoSecundario, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: NetMonitorTema.textoTerciario)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar todo',
                style: TextStyle(
                    color: NetMonitorTema.rojoAlerta, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<RedProvider>().borrarTodoHistorial();
    }
  }

  Future<void> _borrarEscaneo(BuildContext context, int id, int indice) async {
    await context.read<RedProvider>().borrarEscaneo(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registro eliminado'),
        duration: Duration(seconds: 2),
        backgroundColor: NetMonitorTema.verdeActivo,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RedProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: _cargar,
          color: NetMonitorTema.azulElectrico,
          backgroundColor: NetMonitorTema.fondoCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ─── Cabecera ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Retorp',
                              style: TextStyle(
                                  color: NetMonitorTema.textoTerciario, fontSize: 13)),
                          Text('Historial',
                              style: TextStyle(
                                  color: NetMonitorTema.textoPrimario,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Spacer(),
                      // Botón borrar todo
                      if (provider.historial.isNotEmpty)
                        GestureDetector(
                          onTap: () => _confirmarBorrarTodo(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: NetMonitorTema.rojoAlerta.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: NetMonitorTema.rojoAlerta.withOpacity(0.4)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.delete_sweep_outlined,
                                    color: NetMonitorTema.rojoAlerta, size: 16),
                                SizedBox(width: 5),
                                Text('Borrar todo',
                                    style: TextStyle(
                                        color: NetMonitorTema.rojoAlerta,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ─── Cargando ──────────────────────────────────────────────
              if (_cargando)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: NetMonitorTema.azulElectrico, strokeWidth: 2),
                    ),
                  ),
                ),

              // ─── Lista ─────────────────────────────────────────────────
              if (!_cargando && provider.historial.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = provider.historial[i];
                      final id = e['id'] as int? ?? i;
                      return _TarjetaHistorial(
                        escaneo: e,
                        indice: i,
                        formatFecha: _fecha,
                        onBorrar: () => _borrarEscaneo(context, id, i),
                      );
                    },
                    childCount: provider.historial.length,
                  ),
                ),

              // ─── Vacío ─────────────────────────────────────────────────
              if (!_cargando && provider.historial.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64,
                            color: NetMonitorTema.textoTerciario.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('Sin historial',
                            style: TextStyle(
                                color: NetMonitorTema.textoSecundario,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Haz un escaneo y aparecerá aquí.',
                            style: TextStyle(
                                color: NetMonitorTema.textoTerciario,
                                fontSize: 13)),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh,
                              color: NetMonitorTema.azulElectrico),
                          label: const Text('Recargar',
                              style: TextStyle(
                                  color: NetMonitorTema.azulElectrico)),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Tarjeta con deslizamiento para borrar ────────────────────────────────────

class _TarjetaHistorial extends StatelessWidget {
  final Map<String, dynamic> escaneo;
  final int indice;
  final String Function(String?) formatFecha;
  final VoidCallback onBorrar;

  const _TarjetaHistorial({
    required this.escaneo,
    required this.indice,
    required this.formatFecha,
    required this.onBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final totalDisp = escaneo['total_dispositivos'] ?? 0;
    final latencia = escaneo['promedio_latencia_ms'];
    final nuevos = escaneo['dispositivos_nuevos'] ?? 0;
    final id = escaneo['id'] ?? (indice + 1);
    final colorLatencia = NetMonitorTema.colorLatencia(latencia?.toDouble());

    // Dismissible para deslizar y borrar
    return Dismissible(
      key: Key('escaneo_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: NetMonitorTema.rojoAlerta.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NetMonitorTema.rojoAlerta.withOpacity(0.4)),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: NetMonitorTema.rojoAlerta, size: 24),
            SizedBox(height: 4),
            Text('Borrar',
                style: TextStyle(
                    color: NetMonitorTema.rojoAlerta,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: NetMonitorTema.fondoCard,
            title: const Text('Borrar registro',
                style: TextStyle(color: NetMonitorTema.textoPrimario, fontSize: 15)),
            content: Text('¿Borrar el escaneo #$id?',
                style: const TextStyle(
                    color: NetMonitorTema.textoSecundario, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: NetMonitorTema.textoTerciario)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Borrar',
                    style: TextStyle(
                        color: NetMonitorTema.rojoAlerta,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onBorrar(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: NetMonitorTema.fondoCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: nuevos > 0
                ? NetMonitorTema.rojoAlerta.withOpacity(0.35)
                : NetMonitorTema.bordeCard,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NetMonitorTema.azulElectrico.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('#$id',
                        style: const TextStyle(
                            color: NetMonitorTema.azulElectrico,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formatFecha(escaneo['fecha_hora']),
                      style: const TextStyle(
                          color: NetMonitorTema.textoPrimario,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (nuevos > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: NetMonitorTema.rojoAlerta.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: NetMonitorTema.rojoAlerta),
                      ),
                      child: Text('$nuevos intruso${nuevos > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: NetMonitorTema.rojoAlerta,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  // Botón de borrar explícito (además del swipe)
                  GestureDetector(
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: NetMonitorTema.fondoCard,
                          title: const Text('Borrar registro',
                              style: TextStyle(
                                  color: NetMonitorTema.textoPrimario,
                                  fontSize: 15)),
                          content: Text('¿Borrar el escaneo #$id?',
                              style: const TextStyle(
                                  color: NetMonitorTema.textoSecundario,
                                  fontSize: 13)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      color: NetMonitorTema.textoTerciario)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Borrar',
                                  style: TextStyle(
                                      color: NetMonitorTema.rojoAlerta,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) onBorrar();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.delete_outline,
                          color: NetMonitorTema.textoTerciario.withOpacity(0.6),
                          size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: NetMonitorTema.bordeCard),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Metrica(
                    icono: Icons.devices,
                    valor: '$totalDisp dispositivos',
                    color: NetMonitorTema.azulElectrico,
                  ),
                  const SizedBox(width: 16),
                  _Metrica(
                    icono: Icons.speed,
                    valor: latencia != null
                        ? '~${latencia.toStringAsFixed(0)}ms prom.'
                        : 'Sin latencia',
                    color: colorLatencia,
                  ),
                  const Spacer(),
                  const Text('← desliza para borrar',
                      style: TextStyle(
                          color: NetMonitorTema.textoTerciario,
                          fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: indice * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 280.ms);
  }
}

class _Metrica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final Color color;
  const _Metrica({required this.icono, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 13, color: color),
        const SizedBox(width: 5),
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
