import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../catalogo/catalogo_screen.dart';
import '../configuracion/configuracion_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../nueva_orden/nueva_orden_screen.dart';
import '../ordenes/ordenes_screen.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainLayoutScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void navegarA(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigateToOrdenes: () => navegarA(1)),
      const OrdenesScreen(),
      NuevaOrdenScreen(onOrderCreated: () => navegarA(1)),
      const CatalogoScreen(),
      const ConfiguracionScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.fondoBorde, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Órdenes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 28),
              activeIcon: Icon(Icons.add_circle, size: 28, color: AppColors.rojoPrimario),
              label: 'Nueva',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Catálogo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Config.',
            ),
          ],
        ),
      ),
    );
  }
}
