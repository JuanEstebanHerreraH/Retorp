// widgets/dispositivo_card.dart - Card con badge "Este equipo" y nombres personalizados

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/dispositivo.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';
import '../screens/detalle_dispositivo_screen.dart';

// ─── Identificador de tipo ─────────────────────────────────────────────────────

class TipoDispositivo {
  final IconData icono;
  final String tipo;
  final Color color;
  const TipoDispositivo(this.icono, this.tipo, this.color);
}

TipoDispositivo identificarDispositivo(Dispositivo d) {
  // Propio siempre primero
  if (d.esPropio || d.mac == 'local' ||
      d.nombre.toLowerCase().contains('este equipo')) {
    return const TipoDispositivo(
        Icons.computer, 'Este equipo', NetMonitorTema.azulElectrico);
  }

  final nombre = d.nombre.toLowerCase();
  final fab = (d.fabricante ?? '').toLowerCase();

  if (nombre.contains('router') || nombre.contains('gateway')) {
    return const TipoDispositivo(Icons.router, 'Router', Color(0xFF7C3AED));
  }
  if (nombre.contains('iphone') || nombre.contains('ipad')) {
    return const TipoDispositivo(
        Icons.phone_iphone, 'iPhone/iPad', Color(0xFF9CA3AF));
  }
  if (nombre.contains('android') || nombre.contains('samsung') ||
      nombre.contains('xiaomi') || nombre.contains('pixel')) {
    return const TipoDispositivo(
        Icons.smartphone, 'Android', Color(0xFF3DDC84));
  }
  if (nombre.contains('macbook') || nombre.contains('imac')) {
    return const TipoDispositivo(Icons.laptop_mac, 'Mac', Color(0xFF9CA3AF));
  }
  if (nombre.contains('laptop') || nombre.contains('notebook')) {
    return const TipoDispositivo(
        Icons.laptop, 'PC/Laptop', NetMonitorTema.azulElectrico);
  }
  if (nombre.contains('tv') || nombre.contains('smart-tv') ||
      nombre.contains('roku')) {
    return const TipoDispositivo(Icons.tv, 'Smart TV', Color(0xFF0EA5E9));
  }

  // Por fabricante
  if (fab.contains('apple')) {
    return const TipoDispositivo(
        Icons.phone_iphone, 'Apple', Color(0xFF9CA3AF));
  }
  if (fab.contains('samsung')) {
    return const TipoDispositivo(
        Icons.smartphone, 'Samsung', Color(0xFF1428A0));
  }
  if (fab.contains('huawei')) {
    final last = int.tryParse(d.ip.split('.').last) ?? 99;
    if (last == 1 || last == 254 || last == 2) {
      return const TipoDispositivo(
          Icons.router, 'Router Huawei', Color(0xFFCF0A2C));
    }
    return const TipoDispositivo(
        Icons.smartphone, 'Huawei', Color(0xFFCF0A2C));
  }
  if (fab.contains('xiaomi') || fab.contains('mi ')) {
    return const TipoDispositivo(
        Icons.smartphone, 'Xiaomi', Color(0xFFFF6900));
  }
  if (fab.contains('roku')) {
    return const TipoDispositivo(Icons.tv, 'Roku TV', Color(0xFF6C2BD9));
  }
  if (fab.contains('amazon') || fab.contains('fire')) {
    return const TipoDispositivo(Icons.tv, 'Amazon Fire', Color(0xFFFF9900));
  }
  if (fab.contains('nintendo')) {
    return const TipoDispositivo(
        Icons.sports_esports, 'Nintendo', Color(0xFFE4000F));
  }
  if (fab.contains('sony')) {
    return const TipoDispositivo(
        Icons.sports_esports, 'PlayStation', Color(0xFF003087));
  }
  if (fab.contains('vantiva') || fab.contains('technicolor') ||
      fab.contains('tp-link') || fab.contains('netgear') ||
      fab.contains('d-link') || fab.contains('zyxel') ||
      fab.contains('cloud network')) {
    return const TipoDispositivo(
        Icons.router, 'Router/Módem', Color(0xFF7C3AED));
  }
  if (fab.contains('intel') || fab.contains('dell') || fab.contains('hp ') ||
      fab.contains('lenovo') || fab.contains('acer') || fab.contains('asus')) {
    return const TipoDispositivo(
        Icons.laptop, 'PC/Laptop', NetMonitorTema.azulElectrico);
  }
  if (fab.contains('gaoshengda') ||
      fab.contains('espressif') ||
      fab.contains('tuya')) {
    return const TipoDispositivo(
        Icons.lightbulb_outline, 'Disp. IoT', Color(0xFFF59E0B));
  }
  if (fab.contains('hikvision') || fab.contains('dahua')) {
    return const TipoDispositivo(Icons.videocam, 'Cámara IP', Color(0xFFDC2626));
  }
  if (fab.contains('sonos') || fab.contains('bose')) {
    return const TipoDispositivo(Icons.speaker, 'Parlante', Color(0xFF059669));
  }

  final lastOctet = int.tryParse(d.ip.split('.').last) ?? 99;
  if (lastOctet == 1 || lastOctet == 254) {
    return const TipoDispositivo(Icons.router, 'Router', Color(0xFF7C3AED));
  }

  return const TipoDispositivo(
      Icons.devices_other, 'Desconocido', NetMonitorTema.grisInactivo);
}

// ─── Card ──────────────────────────────────────────────────────────────────────

class DispositivoCard extends StatelessWidget {
  final Dispositivo dispositivo;
  final int indice;
  const DispositivoCard(
      {super.key, required this.dispositivo, required this.indice});

  @override
  Widget build(BuildContext context) {
    return Consumer<RedProvider>(
      builder: (context, provider, _) {
        final colorLatencia =
            NetMonitorTema.colorLatencia(dispositivo.latenciaMs);
        final tipo = identificarDispositivo(dispositivo);
        final nombreMostrado = provider.nombreMostrado(dispositivo);
        final esPropio = dispositivo.esPropio || dispositivo.mac == 'local';

        String displayName;
        if (nombreMostrado != 'Dispositivo desconocido' &&
            nombreMostrado.isNotEmpty) {
          displayName = nombreMostrado;
        } else if (dispositivo.fabricante != null &&
            dispositivo.fabricante!.isNotEmpty) {
          displayName = dispositivo.fabricante!;
        } else {
          displayName = dispositivo.ip;
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    DetalleDispositivoScreen(dispositivo: dispositivo)),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              // Dispositivo propio: borde y fondo destacado
              color: esPropio
                  ? NetMonitorTema.azulElectrico.withOpacity(0.06)
                  : NetMonitorTema.fondoCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: esPropio
                    ? NetMonitorTema.azulElectrico.withOpacity(0.55)
                    : dispositivo.esNuevo
                        ? NetMonitorTema.rojoAlerta.withOpacity(0.55)
                        : NetMonitorTema.bordeCard,
                width: esPropio || dispositivo.esNuevo ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: esPropio
                      ? NetMonitorTema.azulElectrico.withOpacity(0.12)
                      : Colors.black.withOpacity(0.15),
                  blurRadius: esPropio ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icono
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tipo.color.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tipo.color.withOpacity(0.25)),
                    ),
                    child: Icon(tipo.icono, color: tipo.color, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Row(
                          children: [
                            // Badge "Este equipo" con estrella
                            if (esPropio)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    NetMonitorTema.azulElectrico,
                                    Color(0xFF00C6A0),
                                  ]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.white, size: 9),
                                    SizedBox(width: 3),
                                    Text('TU EQUIPO',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3)),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tipo.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(tipo.tipo,
                                    style: TextStyle(
                                        color: tipo.color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            if (dispositivo.esNuevo) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: NetMonitorTema.rojoAlerta
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      color: NetMonitorTema.rojoAlerta,
                                      width: 1),
                                ),
                                child: const Text('NUEVO',
                                    style: TextStyle(
                                        color: NetMonitorTema.rojoAlerta,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                            if (provider.nombresPersonalizados
                                .containsKey(dispositivo.ip)) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  size: 10,
                                  color: NetMonitorTema.azulElectrico),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayName,
                          style: TextStyle(
                            color: esPropio
                                ? NetMonitorTema.textoPrimario
                                : NetMonitorTema.textoPrimario,
                            fontSize: 14,
                            fontWeight: esPropio
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          dispositivo.ip,
                          style: TextStyle(
                            color: esPropio
                                ? NetMonitorTema.azulElectrico
                                : NetMonitorTema.azulClaro,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: esPropio
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Latencia
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorLatencia,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: colorLatencia.withOpacity(0.5),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dispositivo.latenciaMs != null
                            ? '${dispositivo.latenciaMs!.toStringAsFixed(0)}ms'
                            : '—',
                        style: TextStyle(
                            color: colorLatencia,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: NetMonitorTema.textoTerciario, size: 16),
                ],
              ),
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: indice * 60))
            .fadeIn(duration: 300.ms)
            .slideX(
                begin: 0.06,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOut);
      },
    );
  }
}
