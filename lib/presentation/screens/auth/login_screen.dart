import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/custom_text_field.dart';
import '../main/main_layout_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  /// Cascada de aparición de logo, subtítulo, tarjeta y pie.
  late final AnimationController _entrada;

  /// Sacudida de la tarjeta cuando las credenciales fallan.
  late final AnimationController _sacudida;

  /// Se activa entre la autenticación correcta y la navegación, para dar
  /// tiempo a que el botón muestre la palomita.
  bool _exito = false;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _sacudida = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _entrada.dispose();
    _sacudida.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _intentarLogin() async {
    if (!_formKey.currentState!.validate()) {
      _sacudida.forward(from: 0);
      return;
    }
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

    if (!ok || !mounted) return;

    setState(() => _exito = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
    );
  }

  /// Progreso de un tramo de la cascada, normalizado a 0..1 y suavizado.
  double _tramo(double inicio, double fin) {
    return Interval(inicio, fin, curve: Curves.easeOutCubic)
        .transform(_entrada.value);
  }

  /// Envuelve a un hijo en el desvanecido y deslizamiento de su tramo.
  Widget _enCascada(double inicio, double fin, Widget hijo) {
    final t = _tramo(inicio, fin);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 24),
        child: hijo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = AppColors.isDark(context);

    // Escuchar errores
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        _sacudida.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipalOf(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: _entrada,
                  builder: (context, _) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logotipo TECROBSYS
                      Center(
                        child: AnimatedLogo(
                          progreso: _tramo(0.0, 0.62),
                          tamanoTexto: 34,
                          mostrarMarca: false,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtítulo
                      _enCascada(
                        0.34,
                        0.70,
                        Text(
                          'Gestión de Taller Técnico Especializado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textoSecundarioOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tarjeta de Formulario
                      _enCascada(
                        0.46,
                        0.88,
                        _TarjetaSacudible(
                          animacion: _sacudida,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.fondoTarjetaOf(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.fondoBordeOf(context),
                                width: 1.1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: isDark ? 0.3 : 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textoPrincipalOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ingresa con tus credenciales de técnico',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color:
                                        AppColors.textoSecundarioOf(context),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Campo Email
                                _CampoConHalo(
                                  child: CustomTextField(
                                    controller: _emailController,
                                    label: 'Correo Electrónico',
                                    hint: 'tecnico@ejemplo.com',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.alternate_email_rounded,
                                    enabled: !authState.isLoading && !_exito,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingresa tu correo electrónico';
                                      }
                                      if (!val.contains('@')) {
                                        return 'Correo inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Campo Contraseña
                                _CampoConHalo(
                                  child: CustomTextField(
                                    controller: _passwordController,
                                    label: 'Contraseña',
                                    hint: '••••••••',
                                    obscureText: _obscurePassword,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    enabled: !authState.isLoading && !_exito,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textoSecundarioOf(
                                            context),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Ingresa tu contraseña';
                                      }
                                      if (val.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Botón de Inicio de Sesión
                                _BotonIngresar(
                                  cargando: authState.isLoading,
                                  exito: _exito,
                                  onPressed: _intentarLogin,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pie de página
                      _enCascada(
                        0.72,
                        1.0,
                        Center(
                          child: Text(
                            'TecrobSys Flutter v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textoMutedOf(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Desplaza a su hijo de lado a lado con amplitud decreciente. Señala unas
/// credenciales rechazadas sin depender sólo del SnackBar.
class _TarjetaSacudible extends StatelessWidget {
  final Animation<double> animacion;
  final Widget child;

  const _TarjetaSacudible({required this.animacion, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, hijo) {
        final t = animacion.value;
        final desplazamiento = math.sin(t * math.pi * 4) * 11 * (1 - t);
        return Transform.translate(
          offset: Offset(desplazamiento, 0),
          child: hijo,
        );
      },
      child: child,
    );
  }
}

/// Dibuja un halo azul detrás del campo mientras éste tiene el foco.
///
/// Envuelve al campo en un [Focus] que no participa del recorrido de
/// tabulación; sólo observa si el foco cae en alguno de sus descendientes.
class _CampoConHalo extends StatefulWidget {
  final Widget child;

  const _CampoConHalo({required this.child});

  @override
  State<_CampoConHalo> createState() => _CampoConHaloState();
}

class _CampoConHaloState extends State<_CampoConHalo> {
  bool _enfocado = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (tieneFoco) {
        if (tieneFoco != _enfocado) setState(() => _enfocado = tieneFoco);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primarioOf(context)
                  .withValues(alpha: _enfocado ? 0.28 : 0.0),
              blurRadius: _enfocado ? 18 : 0,
              spreadRadius: _enfocado ? 1 : 0,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Botón principal con tres estados: reposo, cargando y éxito.
///
/// Al autenticar correctamente cambia de color y muestra una palomita antes de
/// que la pantalla navegue, para que el salto no se sienta abrupto.
class _BotonIngresar extends StatelessWidget {
  final bool cargando;
  final bool exito;
  final VoidCallback onPressed;

  const _BotonIngresar({
    required this.cargando,
    required this.exito,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Widget contenido;
    if (exito) {
      contenido = const Icon(
        Icons.check_rounded,
        key: ValueKey('exito'),
        color: Colors.white,
        size: 26,
      );
    } else if (cargando) {
      contenido = const SizedBox(
        key: ValueKey('cargando'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    } else {
      contenido = const Text(
        'INGRESAR AL SISTEMA',
        key: ValueKey('reposo'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      );
    }

    final fondo = exito ? AppColors.exitoOf(context) : AppColors.primario;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (cargando || exito) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: Colors.white,
          // Deshabilitado conserva su color: durante la carga y el éxito sigue
          // siendo el elemento protagonista de la tarjeta.
          disabledBackgroundColor: fondo,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.primario.withValues(alpha: 0.4),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (hijo, animacion) => ScaleTransition(
            scale: animacion,
            child: FadeTransition(opacity: animacion, child: hijo),
          ),
          child: contenido,
        ),
      ),
    );
  }
}
