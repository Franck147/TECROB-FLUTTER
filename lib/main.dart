import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con URL y Anon Key
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: TecrobSysApp(),
    ),
  );
}

class TecrobSysApp extends ConsumerWidget {
  const TecrobSysApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: authState.isLoading
          ? Scaffold(
              backgroundColor: themeMode == ThemeMode.dark
                  ? AppColors.darkFondoPrincipal
                  : AppColors.lightFondoPrincipal,
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.rojoPrimario),
                    SizedBox(height: 16),
                    Text(
                      'Cargando TecrobSys...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : authState.isAuthenticated
              ? const MainLayoutScreen()
              : const LoginScreen(),
    );
  }
}
