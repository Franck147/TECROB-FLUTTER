import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datos de idioma para intl: sin esto, todo DateFormat con locale 'es_PE'
  // lanza excepción y las fechas caen al formato de respaldo.
  await initializeDateFormatting('es_PE', null);

  // Inicialización de Supabase. La clave publicable puede viajar en la app:
  // lo que protege los datos son las políticas de seguridad por fila.
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
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
      // Sin estos delegados, el calendario y los diálogos de Material caen al
      // inglés por defecto: los meses y los días de la semana salen en inglés
      // aunque los botones lleven texto propio en español.
      locale: const Locale('es', 'PE'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('es'),
      ],
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
                    CircularProgressIndicator(color: AppColors.primario),
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
