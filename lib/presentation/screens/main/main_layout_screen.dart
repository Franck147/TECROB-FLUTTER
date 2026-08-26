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
    final isDark = AppColors.isDark(context);

    final screens = [
      DashboardScreen(onNavigateToOrdenes: () => navegarA(1)),
      const OrdenesScreen(),
      NuevaOrdenScreen(onOrderCreated: () => navegarA(1)),
      const CatalogoScreen(),
      const ConfiguracionScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.fondoTarjetaOf(context),
          border: Border(
            top: BorderSide(color: AppColors.fondoBordeOf(context), width: 1.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.space_dashboard_outlined,
                  activeIcon: Icons.space_dashboard_rounded,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Órdenes',
                ),
                // Botón Central Destacado: Nueva Orden
                _buildCenterActionButton(),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Catálogo',
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune_rounded,
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => navegarA(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.rojoPrimario.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.rojoPrimario : AppColors.textoSecundarioOf(context),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.rojoPrimario : AppColors.textoSecundarioOf(context),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterActionButton() {
    final isSelected = _currentIndex == 2;

    return InkWell(
      onTap: () => navegarA(2),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.rojoPrimario, AppColors.rojoOscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.rojoPrimario.withValues(alpha: isSelected ? 0.6 : 0.35),
              blurRadius: isSelected ? 12 : 8,
              spreadRadius: isSelected ? 2 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
