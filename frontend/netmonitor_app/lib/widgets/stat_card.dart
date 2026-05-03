// widgets/stat_card.dart - Tarjeta de estadística para el panel de NetMonitor

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/tema.dart';

class StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? subtitulo;
  final IconData icono;
  final Color? colorIcono;
  final Color? colorValor;
  final int indice;

  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    required this.icono,
    this.colorIcono,
    this.colorValor,
    this.indice = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorI = colorIcono ?? NetMonitorTema.azulElectrico;
    final colorV = colorValor ?? NetMonitorTema.textoPrimario;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NetMonitorTema.fondoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NetMonitorTema.bordeCard, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorI.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: colorI, size: 22),
          ),
          const SizedBox(height: 14),

          // Valor grande
          Text(
            valor,
            style: TextStyle(
              color: colorV,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Título
          Text(
            titulo,
            style: const TextStyle(
              color: NetMonitorTema.textoSecundario,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Subtítulo opcional
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: const TextStyle(
                color: NetMonitorTema.textoTerciario,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: indice * 100))
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms);
  }
}


/// Widget de indicador de conexión al servidor
class IndicadorConexion extends StatelessWidget {
  final bool conectado;
  const IndicadorConexion({super.key, required this.conectado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (conectado ? NetMonitorTema.verdeActivo : NetMonitorTema.rojoAlerta)
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: conectado ? NetMonitorTema.verdeActivo : NetMonitorTema.rojoAlerta,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: conectado ? NetMonitorTema.verdeActivo : NetMonitorTema.rojoAlerta,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (conectado ? NetMonitorTema.verdeActivo : NetMonitorTema.rojoAlerta)
                      .withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            conectado ? 'Servidor activo' : 'Sin conexión',
            style: TextStyle(
              color: conectado ? NetMonitorTema.verdeActivo : NetMonitorTema.rojoAlerta,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


/// Barra de latencia visual
class BarraLatencia extends StatelessWidget {
  final double? latenciaMs;
  const BarraLatencia({super.key, this.latenciaMs});

  @override
  Widget build(BuildContext context) {
    final color = NetMonitorTema.colorLatencia(latenciaMs);
    final porcentaje = latenciaMs == null
        ? 0.0
        : (1.0 - (latenciaMs! / 500.0)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latencia',
              style: const TextStyle(
                color: NetMonitorTema.textoSecundario,
                fontSize: 12,
              ),
            ),
            Text(
              NetMonitorTema.textoLatencia(latenciaMs),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: NetMonitorTema.bordeCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
