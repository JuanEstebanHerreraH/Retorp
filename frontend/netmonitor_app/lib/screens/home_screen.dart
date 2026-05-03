// screens/home_screen.dart - Pantalla principal

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';
import '../widgets/dispositivo_card.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timerLatencia;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RedProvider>().verificarConexion();
    });
    _timerLatencia = Timer.periodic(const Duration(seconds: 30), (_) {
      final p = context.read<RedProvider>();
      if (!p.estaEscaneando && p.dispositivos.isNotEmpty) {
        p.refrescarLatencias();
      }
    });
  }

  @override
  void dispose() {
    _timerLatencia?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RedProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.iniciarEscaneo(),
          color: NetMonitorTema.azulElectrico,
          backgroundColor: NetMonitorTema.fondoCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _CabeceraHome(provider: provider)),
              SliverToBoxAdapter(child: _BotonEscaneo(provider: provider)),

              if (provider.mensajeError != null)
                SliverToBoxAdapter(
                  child: _TarjetaError(
                    mensaje: provider.mensajeError!,
                    onDismiss: provider.limpiarError,
                  ),
                ),

              if (provider.estaEscaneando)
                SliverToBoxAdapter(child: _SkeletonEscaneo()),

              if (!provider.estaEscaneando && provider.dispositivos.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.devices, size: 13,
                            color: NetMonitorTema.textoTerciario),
                        const SizedBox(width: 5),
                        Text('${provider.dispositivos.length} dispositivos',
                            style: const TextStyle(
                                color: NetMonitorTema.textoTerciario,
                                fontSize: 12)),
                        const Spacer(),
                        if (provider.refrescandoLatencia)
                          const Row(children: [
                            SizedBox(
                              width: 10, height: 10,
                              child: CircularProgressIndicator(
                                  color: NetMonitorTema.azulElectrico,
                                  strokeWidth: 1.5),
                            ),
                            SizedBox(width: 5),
                            Text('Actualizando...',
                                style: TextStyle(
                                    color: NetMonitorTema.textoTerciario,
                                    fontSize: 11)),
                          ])
                        else
                          GestureDetector(
                            onTap: provider.refrescarLatencias,
                            child: const Row(children: [
                              Icon(Icons.refresh,
                                  size: 13,
                                  color: NetMonitorTema.azulElectrico),
                              SizedBox(width: 3),
                              Text('Actualizar ms',
                                  style: TextStyle(
                                      color: NetMonitorTema.azulElectrico,
                                      fontSize: 11)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                ),

              if (!provider.estaEscaneando && provider.dispositivos.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => DispositivoCard(
                        dispositivo: provider.dispositivos[i], indice: i),
                    childCount: provider.dispositivos.length,
                  ),
                ),

              if (!provider.estaEscaneando && provider.dispositivos.isEmpty)
                SliverFillRemaining(
                  child: _EstadoVacio(
                      servidorConectado: provider.servidorConectado),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Cabecera ──────────────────────────────────────────────────────────────────

class _CabeceraHome extends StatelessWidget {
  final RedProvider provider;
  const _CabeceraHome({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Red Local',
                      style: TextStyle(
                          color: NetMonitorTema.textoTerciario, fontSize: 13)),
                  Text('Escaneo de Red',
                      style: TextStyle(
                          color: NetMonitorTema.textoPrimario,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              IndicadorConexion(conectado: provider.servidorConectado),
            ],
          ),

          // Alerta de intrusos — sin animación de shake, solo borde estático
          if (provider.totalAlertas > 0)
            GestureDetector(
              onTap: () => _mostrarAlertas(context, provider),
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: NetMonitorTema.rojoAlerta.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: NetMonitorTema.rojoAlerta.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: NetMonitorTema.rojoAlerta, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${provider.totalAlertas} dispositivo(s) desconocido(s)',
                        style: const TextStyle(
                            color: NetMonitorTema.rojoAlerta,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: NetMonitorTema.rojoAlerta, size: 17),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarAlertas(BuildContext context, RedProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NetMonitorTema.fondoSecundario,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        maxChildSize: 0.8,
        minChildSize: 0.2,
        builder: (_, sc) => _ModalAlertas(
            alertas: provider.alertas,
            onLeer: provider.marcarAlertasLeidas,
            scrollController: sc),
      ),
    );
  }
}

class _BotonEscaneo extends StatelessWidget {
  final RedProvider provider;
  const _BotonEscaneo({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: provider.estaEscaneando ? null : provider.iniciarEscaneo,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: provider.estaEscaneando
                ? null
                : const LinearGradient(
                    colors: [NetMonitorTema.azulElectrico, Color(0xFF0055EE)]),
            color: provider.estaEscaneando ? NetMonitorTema.fondoCard : null,
            borderRadius: BorderRadius.circular(14),
            border: provider.estaEscaneando
                ? Border.all(color: NetMonitorTema.bordeCard)
                : null,
            boxShadow: provider.estaEscaneando
                ? []
                : NetMonitorTema.sombraBotonAzul,
          ),
          child: Center(
            child: provider.estaEscaneando
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            color: NetMonitorTema.azulElectrico,
                            strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Escaneando...',
                          style: TextStyle(
                              color: NetMonitorTema.textoSecundario,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radar, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Escanear Red Local',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonEscaneo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: NetMonitorTema.fondoCard,
      highlightColor: NetMonitorTema.fondoCardHover,
      child: Column(
        children: List.generate(5, (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          height: 76,
          decoration: BoxDecoration(
            color: NetMonitorTema.fondoCard,
            borderRadius: BorderRadius.circular(16),
          ),
        )),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool servidorConectado;
  const _EstadoVacio({required this.servidorConectado});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              servidorConectado ? Icons.radar : Icons.cloud_off,
              size: 72,
              color: NetMonitorTema.textoTerciario.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              servidorConectado ? 'Listo para escanear' : 'Backend desconectado',
              style: const TextStyle(
                  color: NetMonitorTema.textoSecundario,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              servidorConectado
                  ? 'Toca "Escanear Red Local"\npara ver los dispositivos.'
                  : 'Abre el archivo start.bat\nantes de usar la app.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: NetMonitorTema.textoTerciario, fontSize: 14),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _TarjetaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onDismiss;
  const _TarjetaError({required this.mensaje, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NetMonitorTema.rojoAlerta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NetMonitorTema.rojoAlerta.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: NetMonitorTema.rojoAlerta, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje,
                style: const TextStyle(
                    color: NetMonitorTema.rojoAlerta, fontSize: 13)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close,
                color: NetMonitorTema.rojoAlerta, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ModalAlertas extends StatelessWidget {
  final List<dynamic> alertas;
  final VoidCallback onLeer;
  final ScrollController scrollController;
  const _ModalAlertas(
      {required this.alertas,
      required this.onLeer,
      required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: NetMonitorTema.bordeCard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  color: NetMonitorTema.rojoAlerta, size: 20),
              const SizedBox(width: 8),
              const Text('Dispositivos Desconocidos',
                  style: TextStyle(
                      color: NetMonitorTema.textoPrimario,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  onLeer();
                  Navigator.pop(context);
                },
                child: const Text('Marcar leídas',
                    style: TextStyle(color: NetMonitorTema.azulElectrico)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              itemCount: alertas.length,
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NetMonitorTema.rojoAlerta.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: NetMonitorTema.rojoAlerta.withOpacity(0.25)),
                ),
                child: Text(alertas[i].mensaje ?? 'Alerta',
                    style: const TextStyle(
                        color: NetMonitorTema.textoSecundario, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
