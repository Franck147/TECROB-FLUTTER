import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/sticker_label_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/create_tecnico_dialog.dart';
import '../auth/login_screen.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTecnicosSiEsAdmin();
    });
  }

  void _cargarTecnicosSiEsAdmin() {
    final auth = ref.read(authProvider);
    if (auth.tecnico != null && auth.tecnico!.esAdmin && auth.tecnico!.empresaId != null) {
      ref.read(configuracionProvider.notifier).cargarTecnicos(auth.tecnico!.empresaId!);
    }
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjetaOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.fondoBordeOf(context)),
        ),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión en TecrobSys?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _probarImpresionStickerPrueba() async {
    final itemPrueba = StickerItem(
      titulo: '🏷️ STICKER DE PRUEBA',
      subtitulo: 'Laptop Dell Inspiron 15 (S/N: TEST-001)',
      ordenCodigo: '#OT-TEST',
      clienteNombre: 'CLIENTE DE PRUEBA',
      clienteTelefono: '999-888-777',
      fecha: '26/08/2026 15:30',
      esPrincipal: true,
    );

    try {
      await StickerLabelService.imprimirStickers(
        items: [itemPrueba],
        tituloTrabajo: 'Test_Sticker_TecrobSys',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en impresión de prueba: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _abrirDialogoNuevoTecnico() {
    final auth = ref.read(authProvider);
    final empresaId = auth.tecnico?.empresaId;
    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => CreateTecnicoDialog(
        onSave: ({
          required String nombre,
          required String apellido,
          required String email,
          required String password,
          required String rol,
        }) async {
          final ok = await ref.read(configuracionProvider.notifier).crearTecnico(
                empresaId: empresaId,
                nombre: nombre,
                apellido: apellido,
                email: email,
                password: password,
                rol: rol,
              );
          if (ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Técnico creado con éxito'),
                backgroundColor: AppColors.tertiary,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmarDesactivarTecnico(int tecnicoId, String nombreTecnico) {
    final auth = ref.read(authProvider);
    final miId = auth.tecnico?.id;
    final empresaId = auth.tecnico?.empresaId;

    if (miId == tecnicoId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes desactivar tu propia cuenta actual.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (empresaId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.fondoTarjetaOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.fondoBordeOf(context)),
        ),
        title: const Text('Desactivar Técnico'),
        content: Text('¿Deseas dar de baja a "$nombreTecnico"? Ya no podrá acceder al sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textoSecundarioOf(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(configuracionProvider.notifier).desactivarTecnico(tecnicoId, empresaId);
            },
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final configState = ref.watch(configuracionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = AppColors.isDark(context);

    final tecnico = authState.tecnico;
    final esAdmin = tecnico?.esAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.fondoPrincipalOf(context),
        title: const Text('Perfil y Configuración'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tarjeta de Perfil de Usuario ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.fondoTarjetaOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rojoPrimario, AppColors.rojoOscuro],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rojoPrimario.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        tecnico?.inicial ?? '?',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tecnico?.nombreCompleto ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textoPrincipalOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tecnico?.email ?? '',
                    style: TextStyle(fontSize: 13, color: AppColors.textoSecundarioOf(context)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: esAdmin
                          ? AppColors.rojoContenedorOf(context)
                          : AppColors.fondoSuperficieOf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: esAdmin ? AppColors.rojoClaro : AppColors.fondoBordeOf(context),
                      ),
                    ),
                    child: Text(
                      esAdmin ? 'ADMINISTRADOR' : 'TÉCNICO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: esAdmin ? AppColors.rojoPrimario : AppColors.textoSecundarioOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                    label: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error, width: 1),
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _confirmarCerrarSesion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sección Apariencia & Tema (Modo Claro / Modo Oscuro) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fondoTarjetaOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.rojoPrimario,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'APARIENCIA & TEMA VISUAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textoPrincipalOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona el modo de visualización preferido para la interfaz.',
                    style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOption(
                          context: context,
                          label: 'Modo Oscuro',
                          icon: Icons.dark_mode_rounded,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          context: context,
                          label: 'Modo Claro',
                          icon: Icons.light_mode_rounded,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOption(
                          context: context,
                          label: 'Sistema',
                          icon: Icons.brightness_auto_rounded,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sección Impresora Térmica / Bluetooth ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fondoTarjetaOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fondoBordeOf(context), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_audio_rounded, color: AppColors.rojoPrimario, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'IMPRESORA TÉRMICA & BLUETOOTH',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textoPrincipalOf(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Formato estándar de stickers adhesivos: 50mm x 30mm y rollo térmico 58mm / 80mm con Código QR de orden.',
                    style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _probarImpresionStickerPrueba,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.rojoPrimario.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18, color: AppColors.rojoPrimario),
                      label: const Text(
                        'Imprimir Etiqueta / Sticker de Prueba',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Sección Exclusiva Admin: Gestión de Técnicos ──
            if (esAdmin) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GESTIÓN DE TÉCNICOS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.textoSecundarioOf(context),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Nuevo Técnico'),
                    onPressed: _abrirDialogoNuevoTecnico,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (configState.isLoading && configState.tecnicos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.rojoPrimario),
                  ),
                )
              else if (configState.tecnicos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No hay técnicos adicionales registrados')),
                  ),
                )
              else
                ...configState.tecnicos.map((tec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjetaOf(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.fondoBordeOf(context)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tec.esAdmin
                            ? AppColors.rojoContenedorOf(context)
                            : AppColors.fondoSuperficieOf(context),
                        child: Text(
                          tec.inicial,
                          style: TextStyle(
                            color: tec.esAdmin ? AppColors.rojoPrimario : AppColors.textoPrincipalOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        tec.nombreCompleto,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${tec.email} • ${tec.esAdmin ? "Administrador" : "Técnico"}',
                        style: TextStyle(fontSize: 12, color: AppColors.textoSecundarioOf(context)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                        tooltip: 'Desactivar',
                        onPressed: () => _confirmarDesactivarTecnico(tec.id, tec.nombreCompleto),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],

            // ── Info de Versión y Empresa ──
            Center(
              child: Column(
                children: [
                  Text(
                    AppConstants.empresaRazonSocial,
                    style: TextStyle(fontSize: 11, color: AppColors.textoMutedOf(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TecrobSys Flutter v1.0.0 • Sistema de Gestión Técnica',
                    style: TextStyle(fontSize: 10, color: AppColors.textoMutedOf(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.rojoPrimario.withValues(alpha: isDark ? 0.15 : 0.1)
              : AppColors.fondoSuperficieOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.rojoPrimario : AppColors.fondoBordeOf(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.rojoPrimario : AppColors.textoSecundarioOf(context),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.rojoPrimario : AppColors.textoPrincipalOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
