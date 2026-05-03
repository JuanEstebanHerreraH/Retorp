// screens/estadisticas_screen.dart - Cards pequeñas y compactas

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';
import '../widgets/dispositivo_card.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RedProvider>().cargarEstadisticas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RedProvider>(
      builder: (context, provider, _) {
        final stats = provider.estadisticas;
        return RefreshIndicator(
          onRefresh: () => provider.cargarEstadisticas(),
          color: NetMonitorTema.azulElectrico,
          backgroundColor: NetMonitorTema.fondoCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Red Local',
                          style: TextStyle(
                              color: NetMonitorTema.textoTerciario, fontSize: 13)),
                      Text('Estadísticas',
                          style: TextStyle(
                              color: NetMonitorTema.textoPrimario,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),

              if (stats != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _MiniCard(
                        titulo: 'Dispositivos',
                        valor: '${stats.totalDispositivos}',
                        icono: Icons.devices,
                        color: NetMonitorTema.azulElectrico,
                      ),
                      _MiniCard(
                        titulo: 'Activos',
                        valor: '${stats.dispositivosActivos}',
                        icono: Icons.wifi,
                        color: NetMonitorTema.verdeActivo,
                      ),
                      _MiniCard(
                        titulo: 'Latencia',
                        valor: stats.promedioLatenciaMs != null
                            ? '${stats.promedioLatenciaMs!.toStringAsFixed(0)}ms'
                            : '—',
                        icono: Icons.speed,
                        color: NetMonitorTema.colorLatencia(stats.promedioLatenciaMs),
                      ),
                      _MiniCard(
                        titulo: 'Intrusos',
                        valor: '${stats.dispositivosNuevos}',
                        icono: Icons.warning_amber,
                        color: stats.dispositivosNuevos > 0
                            ? NetMonitorTema.rojoAlerta
                            : NetMonitorTema.grisInactivo,
                      ),
                      _MiniCard(
                        titulo: 'Escaneos',
                        valor: '${stats.totalEscaneos}',
                        icono: Icons.radar,
                        color: const Color(0xFF7C3AED),
                      ),
                      _MiniCard(
                        titulo: 'Último',
                        valor: stats.ultimoEscaneo != null
                            ? DateFormat('HH:mm').format(stats.ultimoEscaneo!)
                            : '—',
                        subtitulo: stats.ultimoEscaneo != null
                            ? DateFormat('dd/MM').format(stats.ultimoEscaneo!)
                            : null,
                        icono: Icons.access_time,
                        color: NetMonitorTema.textoSecundario,
                      ),
                    ]),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 90, // altura fija — no gigantes
                    ),
                  ),
                ),

              if (provider.dispositivos.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      children: [
                        const Text('Dispositivos en red',
                            style: TextStyle(
                                color: NetMonitorTema.textoSecundario,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: NetMonitorTema.azulElectrico.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${provider.dispositivos.length}',
                              style: const TextStyle(
                                  color: NetMonitorTema.azulElectrico,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DispositivoCard(
                        dispositivo: provider.dispositivos[i], indice: i),
                    childCount: provider.dispositivos.length,
                  ),
                ),
              ],

              if (stats == null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart,
                            size: 60,
                            color: NetMonitorTema.textoTerciario.withOpacity(0.3)),
                        const SizedBox(height: 14),
                        const Text('Sin datos todavía',
                            style: TextStyle(
                                color: NetMonitorTema.textoSecundario,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Realiza un escaneo primero.',
                            style: TextStyle(
                                color: NetMonitorTema.textoTerciario,
                                fontSize: 13)),
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

class _MiniCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData icono;
  final Color color;

  const _MiniCard({
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: NetMonitorTema.fondoCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NetMonitorTema.bordeCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(valor,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1),
                    overflow: TextOverflow.ellipsis),
                Text(titulo,
                    style: const TextStyle(
                        color: NetMonitorTema.textoTerciario,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                if (subtitulo != null)
                  Text(subtitulo!,
                      style: const TextStyle(
                          color: NetMonitorTema.textoTerciario, fontSize: 9),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
