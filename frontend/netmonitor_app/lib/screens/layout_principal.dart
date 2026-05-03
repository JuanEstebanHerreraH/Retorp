// screens/layout_principal.dart - Layout con 4 tabs: Escaneo, Estadísticas, Historial, Ayuda

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/red_provider.dart';
import '../services/tema.dart';
import '../widgets/stat_card.dart';
import 'home_screen.dart';
import 'estadisticas_screen.dart';
import 'historial_screen.dart';
import 'ayuda_screen.dart';

class LayoutPrincipal extends StatefulWidget {
  const LayoutPrincipal({super.key});
  @override
  State<LayoutPrincipal> createState() => _LayoutPrincipalState();
}

class _LayoutPrincipalState extends State<LayoutPrincipal> {
  int _indiceActual = 0;

  final List<_Nav> _destinos = const [
    _Nav(icono: Icons.radar_outlined, iconoSel: Icons.radar, label: 'Escaneo'),
    _Nav(icono: Icons.bar_chart_outlined, iconoSel: Icons.bar_chart, label: 'Stats'),
    _Nav(icono: Icons.history_outlined, iconoSel: Icons.history, label: 'Historial'),
    _Nav(icono: Icons.help_outline, iconoSel: Icons.help, label: 'Ayuda'),
  ];

  final List<Widget> _pantallas = const [
    HomeScreen(),
    EstadisticasScreen(),
    HistorialScreen(),
    AyudaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final esDesktop = MediaQuery.of(context).size.width >= 800;
    if (esDesktop) {
      return _Desktop(
        indice: _indiceActual,
        onChange: (i) => setState(() => _indiceActual = i),
        destinos: _destinos,
        pantallas: _pantallas,
      );
    }
    return _Movil(
      indice: _indiceActual,
      onChange: (i) => setState(() => _indiceActual = i),
      destinos: _destinos,
      pantallas: _pantallas,
    );
  }
}

// ─── Móvil ────────────────────────────────────────────────────────────────────

class _Movil extends StatelessWidget {
  final int indice;
  final void Function(int) onChange;
  final List<_Nav> destinos;
  final List<Widget> pantallas;
  const _Movil({required this.indice, required this.onChange,
      required this.destinos, required this.pantallas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetMonitorTema.fondoPrincipal,
      body: SafeArea(child: IndexedStack(index: indice, children: pantallas)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NetMonitorTema.fondoSecundario,
          border: Border(top: BorderSide(color: NetMonitorTema.bordeCard)),
        ),
        child: NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: onChange,
          backgroundColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinos.map((d) => NavigationDestination(
            icon: Icon(d.icono),
            selectedIcon: Icon(d.iconoSel),
            label: d.label,
          )).toList(),
        ),
      ),
    );
  }
}

// ─── Desktop ──────────────────────────────────────────────────────────────────

class _Desktop extends StatelessWidget {
  final int indice;
  final void Function(int) onChange;
  final List<_Nav> destinos;
  final List<Widget> pantallas;
  const _Desktop({required this.indice, required this.onChange,
      required this.destinos, required this.pantallas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NetMonitorTema.fondoPrincipal,
      body: Row(
        children: [
          _Sidebar(indice: indice, onChange: onChange, destinos: destinos),
          Container(width: 1, color: NetMonitorTema.bordeCard),
          Expanded(child: IndexedStack(index: indice, children: pantallas)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int indice;
  final void Function(int) onChange;
  final List<_Nav> destinos;
  const _Sidebar({required this.indice, required this.onChange, required this.destinos});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: NetMonitorTema.fondoSecundario,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [NetMonitorTema.azulElectrico, Color(0xFF0055EE)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.radar, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text('Retorp',
                      style: GoogleFonts.poppins(
                          color: NetMonitorTema.textoPrimario,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  Text('Monitoreo de red local',
                      style: GoogleFonts.poppins(
                          color: NetMonitorTema.textoTerciario, fontSize: 11)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Divider(color: NetMonitorTema.bordeCard, height: 1),
            ),
            const SizedBox(height: 10),
            ...destinos.asMap().entries.map((e) {
              final activo = e.key == indice;
              return GestureDetector(
                onTap: () => onChange(e.key),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: activo
                        ? NetMonitorTema.azulElectrico.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: activo
                        ? Border.all(
                            color: NetMonitorTema.azulElectrico.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activo ? e.value.iconoSel : e.value.icono,
                        color: activo
                            ? NetMonitorTema.azulElectrico
                            : NetMonitorTema.grisInactivo,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(e.value.label,
                          style: TextStyle(
                            color: activo
                                ? NetMonitorTema.azulElectrico
                                : NetMonitorTema.textoSecundario,
                            fontSize: 13,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            Consumer<RedProvider>(
              builder: (_, p, __) => Padding(
                padding: const EdgeInsets.all(14),
                child: IndicadorConexion(conectado: p.servidorConectado),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Nav {
  final IconData icono;
  final IconData iconoSel;
  final String label;
  const _Nav({required this.icono, required this.iconoSel, required this.label});
}
