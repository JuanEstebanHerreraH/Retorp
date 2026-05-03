// screens/ayuda_screen.dart - Guía de uso para usuarios finales

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/tema.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NetMonitor',
                    style: TextStyle(color: NetMonitorTema.textoTerciario, fontSize: 13)),
                const Text('Guía de uso',
                    style: TextStyle(
                        color: NetMonitorTema.textoPrimario,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildListDelegate([
            // ─── Requisito importante ──────────────────────────────────────
            _TarjetaAviso(
              icono: Icons.info_outline,
              color: NetMonitorTema.azulElectrico,
              titulo: 'Antes de empezar',
              contenido:
                  'Esta app necesita que el servidor esté corriendo en tu PC. '
                  'Abre el archivo start.bat antes de usar la aplicación y '
                  'déjalo abierto mientras la usas. No necesitas internet — '
                  'todo funciona en tu red local (WiFi o cable).',
            ),

            _TarjetaAviso(
              icono: Icons.wifi_off,
              color: NetMonitorTema.amarilloLatencia,
              titulo: '¿No necesita internet?',
              contenido:
                  'Correcto. NetMonitor trabaja solo en tu red local. '
                  'No sube ni descarga datos de internet. Solo necesitas '
                  'que tu PC esté conectada al mismo WiFi o router que '
                  'los dispositivos que quieres ver.',
            ),

            const _Separador('¿Cómo usar cada pantalla?'),

            _TarjetaPaso(
              numero: '1',
              titulo: 'Pantalla Escaneo',
              icono: Icons.radar,
              color: NetMonitorTema.azulElectrico,
              pasos: [
                'Toca el botón azul "Escanear Red Local"',
                'Espera unos segundos mientras busca dispositivos',
                'Verás una lista con todos los aparatos conectados',
                'El punto de color indica la velocidad de respuesta:\n  🟢 Verde = rápido  🟡 Amarillo = normal  🔴 Rojo = lento  ⚫ Gris = sin respuesta',
                'Si aparece un aviso rojo, significa que hay un dispositivo nuevo que nunca habías visto',
                'Toca cualquier dispositivo para ver más detalles',
                'Usa "Actualizar ms" para ver la latencia actual sin re-escanear',
              ],
            ),

            _TarjetaPaso(
              numero: '2',
              titulo: 'Detalle de dispositivo',
              icono: Icons.devices_other,
              color: const Color(0xFF7C3AED),
              pasos: [
                'Toca "Hacer Ping" para medir la velocidad de respuesta',
                'Toca "En vivo" para medir automáticamente cada 2 segundos — verás el gráfico actualizarse',
                'Toca "Ver Puertos" para saber qué servicios tiene activos (puede tardar)',
                'Puedes cambiar el nombre del dispositivo tocando el ícono de editar junto al nombre',
                'Toca la IP o MAC para copiarla al portapapeles',
              ],
            ),

            _TarjetaPaso(
              numero: '3',
              titulo: 'Pantalla Estadísticas',
              icono: Icons.bar_chart,
              color: NetMonitorTema.verdeActivo,
              pasos: [
                'Muestra un resumen rápido de tu red',
                '"Dispositivos Totales": todos los que alguna vez se han visto',
                '"Activos Ahora": los del último escaneo',
                '"Latencia Prom.": velocidad promedio de respuesta',
                '"Intrusos": dispositivos nuevos detectados',
                'Desliza hacia abajo para ver la lista completa',
              ],
            ),

            _TarjetaPaso(
              numero: '4',
              titulo: 'Pantalla Historial',
              icono: Icons.history,
              color: const Color(0xFFF59E0B),
              pasos: [
                'Guarda automáticamente cada escaneo que hagas',
                'Muestra fecha, hora, cantidad de dispositivos y si hubo intrusos',
                'Desliza hacia abajo para recargar la lista',
                'Útil para comparar si tu red cambia con el tiempo',
              ],
            ),

            const _Separador('Preguntas frecuentes'),

            _TarjetaFAQ(
              pregunta: '¿Por qué aparecen varios "Routers/Modems"?',
              respuesta:
                  'Es normal. Además del router principal, pueden aparecer: '
                  'repetidores WiFi, switches, adaptadores de red, televisores inteligentes o '
                  'dispositivos IoT que el sistema no logra identificar con certeza. '
                  'El de IP .1 o .254 suele ser tu router principal.',
            ),

            _TarjetaFAQ(
              pregunta: '¿Qué es "Dispositivo (8)" o "Dispositivo (11)"?',
              respuesta:
                  'El número entre paréntesis es el último número de la IP del dispositivo. '
                  'Aparece cuando el escáner no pudo obtener el nombre real del aparato ni '
                  'identificar el fabricante. Puedes cambiarle el nombre tú mismo '
                  'tocando el dispositivo y usando el botón de editar.',
            ),

            _TarjetaFAQ(
              pregunta: '¿Por qué dice solo "Huawei" sin más info?',
              respuesta:
                  'El escáner identificó que la tarjeta de red es de Huawei (por la dirección MAC), '
                  'pero no pudo obtener más datos como el nombre del equipo. '
                  'Puede ser un teléfono, tablet, laptop o router Huawei. '
                  'Puedes asignarle un nombre personalizado para recordarlo.',
            ),

            _TarjetaFAQ(
              pregunta: '¿La app es segura? ¿Espía mi red?',
              respuesta:
                  'Completamente segura. NetMonitor solo escucha los mensajes normales '
                  'que ocurren en tu red (como cualquier dispositivo conectado). '
                  'No accede a tus archivos, no envía datos a internet y no modifica nada. '
                  'Todo queda guardado localmente en tu PC.',
            ),

            _TarjetaFAQ(
              pregunta: '¿Debo abrir start.bat cada vez?',
              respuesta:
                  'Sí. El start.bat levanta el servidor que hace el trabajo pesado (escaneo de red). '
                  'Sin él, la app muestra "Sin conexión". '
                  'Tip: crea un acceso directo al start.bat en tu escritorio para abrirlo rápido.',
            ),

            _TarjetaFAQ(
              pregunta: '¿Por qué algunos dispositivos no aparecen?',
              respuesta:
                  'Algunos aparatos (especialmente iPhones con "Dirección WiFi Privada" activada) '
                  'usan una MAC aleatoria y pueden no responder al escaneo. '
                  'En iPhone: Ajustes → WiFi → tu red → desactivar "Dirección Wi‑Fi privada".',
            ),

            const SizedBox(height: 80),
          ]),
        ),
      ],
    );
  }
}

// ─── Widgets internos ─────────────────────────────────────────────────────────

class _TarjetaAviso extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String contenido;
  const _TarjetaAviso({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(
                        color: color, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(contenido,
                    style: const TextStyle(
                        color: NetMonitorTema.textoSecundario,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _Separador extends StatelessWidget {
  final String titulo;
  const _Separador(this.titulo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: Text(titulo,
          style: const TextStyle(
              color: NetMonitorTema.textoTerciario,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }
}

class _TarjetaPaso extends StatefulWidget {
  final String numero;
  final String titulo;
  final IconData icono;
  final Color color;
  final List<String> pasos;
  const _TarjetaPaso({
    required this.numero,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.pasos,
  });

  @override
  State<_TarjetaPaso> createState() => _TarjetaPasoState();
}

class _TarjetaPasoState extends State<_TarjetaPaso> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: NetMonitorTema.fondoCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expandido
                ? widget.color.withOpacity(0.4)
                : NetMonitorTema.bordeCard,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icono, color: widget.color, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.titulo,
                        style: const TextStyle(
                            color: NetMonitorTema.textoPrimario,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                  Icon(
                    _expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: NetMonitorTema.textoTerciario,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expandido) ...[
              const Divider(height: 1, color: NetMonitorTema.bordeCard, indent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: widget.pasos.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: TextStyle(
                                      color: widget.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.value,
                                style: const TextStyle(
                                    color: NetMonitorTema.textoSecundario,
                                    fontSize: 13,
                                    height: 1.5)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaFAQ extends StatefulWidget {
  final String pregunta;
  final String respuesta;
  const _TarjetaFAQ({required this.pregunta, required this.respuesta});

  @override
  State<_TarjetaFAQ> createState() => _TarjetaFAQState();
}

class _TarjetaFAQState extends State<_TarjetaFAQ> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NetMonitorTema.fondoCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NetMonitorTema.bordeCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('?',
                    style: TextStyle(
                        color: NetMonitorTema.azulElectrico,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.pregunta,
                      style: const TextStyle(
                          color: NetMonitorTema.textoPrimario,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _expandido ? Icons.remove : Icons.add,
                  color: NetMonitorTema.textoTerciario,
                  size: 18,
                ),
              ],
            ),
            if (_expandido) ...[
              const SizedBox(height: 10),
              Text(widget.respuesta,
                  style: const TextStyle(
                      color: NetMonitorTema.textoSecundario,
                      fontSize: 13,
                      height: 1.6)),
            ],
          ],
        ),
      ),
    );
  }
}
