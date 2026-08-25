import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../widgets/custom_text_field.dart';
import '../main/main_layout_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _intentarLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await ref.read(authProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Escuchar errores
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo TecrobSys
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.rojoPrimario,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.rojoPrimario.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'T',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título y Subtítulo
                  const Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gestión de Taller Técnico Especializado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Tarjeta de Formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.fondoTarjeta,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.fondoBorde, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ingresa con tus credenciales de técnico',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo Email
                        CustomTextField(
                          controller: _emailController,
                          label: 'Correo Electrónico',
                          hint: 'tecnico@ejemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          enabled: !authState.isLoading,
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
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          hint: '••••••••',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          enabled: !authState.isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textoSecundario,
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
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botón Ingresar
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _intentarLogin,
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('INGRESAR AL SISTEMA'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pie de página
                  const Text(
                    AppConstants.empresaRazonSocial,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textoMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
