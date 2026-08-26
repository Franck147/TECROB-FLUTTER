import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/dni_service.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/servicio_catalogo_model.dart';
import '../../data/models/tecnico_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cliente_repository.dart';
import '../../data/repositories/orden_repository.dart';
import '../../data/repositories/servicio_repository.dart';
import '../../data/repositories/tecnico_repository.dart';

// ═══════════════════════════════════════════════════════════════════
//  1. CLIENTES & SERVICIOS BASE
// ═══════════════════════════════════════════════════════════════════

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dniServiceProvider = Provider<DniService>((ref) {
  return DniService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ClienteRepository(supabase);
});

final servicioRepositoryProvider = Provider<ServicioRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ServicioRepository(supabase);
});

final tecnicoRepositoryProvider = Provider<TecnicoRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TecnicoRepository(supabase);
});

final ordenRepositoryProvider = Provider<OrdenRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return OrdenRepository(supabase);
});

// ═══════════════════════════════════════════════════════════════════
//  2. AUTH STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final TecnicoModel? tecnico;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.tecnico,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    TecnicoModel? tecnico,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      tecnico: tecnico ?? this.tecnico,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(AuthState()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    final user = _authRepo.currentAuthUser;
    if (user != null) {
      state = state.copyWith(isLoading: true);
      try {
        final perfil = await _authRepo.obtenerPerfilTecnico(user.id);
        if (perfil != null) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            tecnico: perfil,
          );
          return;
        }
      } catch (e) {
        debugPrint('Error al restaurar sesión: $e');
      }
    }
    state = state.copyWith(isLoading: false, isAuthenticated: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _authRepo.login(email.trim(), password.trim());
      if (response.user != null) {
        final perfil = await _authRepo.obtenerPerfilTecnico(response.user!.id);
        if (perfil != null) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            tecnico: perfil,
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'No se encontró el perfil de técnico asociado.',
          );
          return false;
        }
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Error de autenticación.');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().contains('Invalid login credentials')
            ? 'Credenciales incorrectas. Verifica tu email y contraseña.'
            : 'Error al iniciar sesión: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});

// ═══════════════════════════════════════════════════════════════════
//  3. DASHBOARD STATE NOTIFIER (Centro Financiero y Operativo)
// ═══════════════════════════════════════════════════════════════════

class DashboardState {
  final bool isLoading;
  final double totalIngresos;
  final double cuentasPorCobrar;
  final int totalOrdenes;
  final int equiposReparados;
  final double ticketPromedio;
  final int activasCount;
  final int pendientesCount;
  final int listasCount;
  final List<OrdenModel> ordenesListasParaEntrega;
  final Map<String, int> distribucionEstados;
  final Map<String, int> distribucionTiposEquipo;
  final String? errorMessage;

  DashboardState({
    this.isLoading = false,
    this.totalIngresos = 0.0,
    this.cuentasPorCobrar = 0.0,
    this.totalOrdenes = 0,
    this.equiposReparados = 0,
    this.ticketPromedio = 0.0,
    this.activasCount = 0,
    this.pendientesCount = 0,
    this.listasCount = 0,
    this.ordenesListasParaEntrega = const [],
    this.distribucionEstados = const {},
    this.distribucionTiposEquipo = const {},
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    double? totalIngresos,
    double? cuentasPorCobrar,
    int? totalOrdenes,
    int? equiposReparados,
    double? ticketPromedio,
    int? activasCount,
    int? pendientesCount,
    int? listasCount,
    List<OrdenModel>? ordenesListasParaEntrega,
    Map<String, int>? distribucionEstados,
    Map<String, int>? distribucionTiposEquipo,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalIngresos: totalIngresos ?? this.totalIngresos,
      cuentasPorCobrar: cuentasPorCobrar ?? this.cuentasPorCobrar,
      totalOrdenes: totalOrdenes ?? this.totalOrdenes,
      equiposReparados: equiposReparados ?? this.equiposReparados,
      ticketPromedio: ticketPromedio ?? this.ticketPromedio,
      activasCount: activasCount ?? this.activasCount,
      pendientesCount: pendientesCount ?? this.pendientesCount,
      listasCount: listasCount ?? this.listasCount,
      ordenesListasParaEntrega: ordenesListasParaEntrega ?? this.ordenesListasParaEntrega,
      distribucionEstados: distribucionEstados ?? this.distribucionEstados,
      distribucionTiposEquipo: distribucionTiposEquipo ?? this.distribucionTiposEquipo,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final OrdenRepository _ordenRepo;

  DashboardNotifier(this._ordenRepo) : super(DashboardState());

  Future<void> cargarDatos(int empresaId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final todas = await _ordenRepo.listarOrdenes(empresaId);

      double ingresos = 0.0;
      double porCobrar = 0.0;
      int reparados = 0;
      int pendientes = 0;
      int activas = 0;
      int listas = 0;

      final List<OrdenModel> listasEntrega = [];
      final Map<String, int> estadosMap = {
        'pendiente': 0,
        'diagnostico': 0,
        'en_progreso': 0,
        'listo': 0,
        'entregado': 0,
        'cancelado': 0,
      };

      final Map<String, int> tiposMap = {};

      for (final o in todas) {
        final est = o.estado.toLowerCase();
        estadosMap[est] = (estadosMap[est] ?? 0) + 1;

        if (est != 'cancelado') {
          ingresos += (o.subtotal - o.descuento);
          porCobrar += o.saldoPendiente;
        }

        if (est == 'entregado' || est == 'listo') {
          reparados++;
        }

        if (est == 'pendiente') pendientes++;
        if (est == 'listo') {
          listas++;
          listasEntrega.add(o);
        }
        if (est == 'pendiente' || est == 'diagnostico' || est == 'en_progreso' || est == 'listo') {
          activas++;
        }

        // Tipo equipo
        final tipo = o.equipo?.tipo.toLowerCase() ?? 'otro';
        tiposMap[tipo] = (tiposMap[tipo] ?? 0) + 1;
      }

      final ticketProm = todas.isNotEmpty && ingresos > 0 ? (ingresos / todas.length) : 0.0;

      state = state.copyWith(
        isLoading: false,
        totalIngresos: ingresos,
        cuentasPorCobrar: porCobrar,
        totalOrdenes: todas.length,
        equiposReparados: reparados,
        ticketPromedio: ticketProm,
        activasCount: activas,
        pendientesCount: pendientes,
        listasCount: listas,
        ordenesListasParaEntrega: listasEntrega,
        distribucionEstados: estadosMap,
        distribucionTiposEquipo: tiposMap,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar dashboard: $e',
      );
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final ordenRepo = ref.watch(ordenRepositoryProvider);
  return DashboardNotifier(ordenRepo);
});

// ═══════════════════════════════════════════════════════════════════
//  4. ORDENES STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════

class OrdenesState {
  final bool isLoading;
  final List<OrdenModel> todasLasOrdenes;
  final List<OrdenModel> ordenesFiltradas;
  final String? filtroEstado; // null = Todas, 'pendiente', 'en_progreso', 'listo'
  final String busqueda;
  final String? errorMessage;

  OrdenesState({
    this.isLoading = false,
    this.todasLasOrdenes = const [],
    this.ordenesFiltradas = const [],
    this.filtroEstado,
    this.busqueda = '',
    this.errorMessage,
  });

  int get pendientesCount =>
      todasLasOrdenes.where((o) => o.estado == 'pendiente').length;
  int get enProgresoCount =>
      todasLasOrdenes.where((o) => o.estado == 'en_progreso').length;
  int get listasCount =>
      todasLasOrdenes.where((o) => o.estado == 'listo').length;

  OrdenesState copyWith({
    bool? isLoading,
    List<OrdenModel>? todasLasOrdenes,
    List<OrdenModel>? ordenesFiltradas,
    String? filtroEstado,
    bool clearFiltroEstado = false,
    String? busqueda,
    String? errorMessage,
  }) {
    return OrdenesState(
      isLoading: isLoading ?? this.isLoading,
      todasLasOrdenes: todasLasOrdenes ?? this.todasLasOrdenes,
      ordenesFiltradas: ordenesFiltradas ?? this.ordenesFiltradas,
      filtroEstado: clearFiltroEstado ? null : (filtroEstado ?? this.filtroEstado),
      busqueda: busqueda ?? this.busqueda,
      errorMessage: errorMessage,
    );
  }
}

class OrdenesNotifier extends StateNotifier<OrdenesState> {
  final OrdenRepository _ordenRepo;

  OrdenesNotifier(this._ordenRepo) : super(OrdenesState());

  Future<void> cargarOrdenes(int empresaId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ordenes = await _ordenRepo.listarOrdenes(empresaId);
      state = state.copyWith(
        isLoading: false,
        todasLasOrdenes: ordenes,
      );
      _aplicarFiltros();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar órdenes: $e',
      );
    }
  }

  void setFiltroEstado(String? estado) {
    if (estado == null) {
      state = state.copyWith(clearFiltroEstado: true);
    } else {
      state = state.copyWith(filtroEstado: estado);
    }
    _aplicarFiltros();
  }

  void setBusqueda(String texto) {
    state = state.copyWith(busqueda: texto.trim().toLowerCase());
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<OrdenModel>.from(state.todasLasOrdenes);

    // Filtro por estado
    if (state.filtroEstado != null && state.filtroEstado!.isNotEmpty) {
      lista = lista.where((o) => o.estado == state.filtroEstado).toList();
    }

    // Filtro por texto
    if (state.busqueda.isNotEmpty) {
      final query = state.busqueda;
      lista = lista.where((o) {
        final numOrd = o.numeroOrden?.toLowerCase() ?? '';
        final clienteNom = o.cliente?.nombreCompleto.toLowerCase() ?? '';
        final marca = o.equipo?.marca.toLowerCase() ?? '';
        final modelo = o.equipo?.modelo?.toLowerCase() ?? '';
        return numOrd.contains(query) ||
            clienteNom.contains(query) ||
            marca.contains(query) ||
            modelo.contains(query);
      }).toList();
    }

    state = state.copyWith(ordenesFiltradas: lista);
  }
}

final ordenesProvider = StateNotifierProvider<OrdenesNotifier, OrdenesState>((ref) {
  final ordenRepo = ref.watch(ordenRepositoryProvider);
  return OrdenesNotifier(ordenRepo);
});

// ═══════════════════════════════════════════════════════════════════
//  5. DETALLE DE ORDEN STATE NOTIFIER (Family por ordenId)
// ═══════════════════════════════════════════════════════════════════

class DetalleOrdenState {
  final bool isLoading;
  final OrdenModel? orden;
  final String? errorMessage;
  final String? successMessage;

  DetalleOrdenState({
    this.isLoading = false,
    this.orden,
    this.errorMessage,
    this.successMessage,
  });

  DetalleOrdenState copyWith({
    bool? isLoading,
    OrdenModel? orden,
    String? errorMessage,
    String? successMessage,
  }) {
    return DetalleOrdenState(
      isLoading: isLoading ?? this.isLoading,
      orden: orden ?? this.orden,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class DetalleOrdenNotifier extends StateNotifier<DetalleOrdenState> {
  final OrdenRepository _ordenRepo;
  final int ordenId;

  DetalleOrdenNotifier(this._ordenRepo, this.ordenId)
      : super(DetalleOrdenState()) {
    cargarOrden();
  }

  Future<void> cargarOrden() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orden = await _ordenRepo.obtenerOrdenPorId(ordenId);
      state = state.copyWith(isLoading: false, orden: orden);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar orden #$ordenId: $e',
      );
    }
  }

  Future<bool> actualizarEstado(String nuevoEstado) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ordenRepo.actualizarEstado(ordenId, nuevoEstado);
      await cargarOrden();
      state = state.copyWith(
        successMessage: 'Estado actualizado correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar estado: $e',
      );
      return false;
    }
  }

  Future<bool> registrarPago({
    required double monto,
    required String metodo,
    String? nota,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _ordenRepo.registrarPago(
        ordenId: ordenId,
        monto: monto,
        metodo: metodo,
        nota: nota,
      );
      await cargarOrden();
      state = state.copyWith(
        successMessage: 'Pago de S/ $monto registrado correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al registrar pago: $e',
      );
      return false;
    }
  }
}

final detalleOrdenProvider = StateNotifierProvider.family<DetalleOrdenNotifier, DetalleOrdenState, int>((ref, ordenId) {
  final ordenRepo = ref.watch(ordenRepositoryProvider);
  return DetalleOrdenNotifier(ordenRepo, ordenId);
});

// ═══════════════════════════════════════════════════════════════════
//  6. CATÁLOGO DE SERVICIOS STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════

class CatalogoState {
  final bool isLoading;
  final List<ServicioCatalogoModel> todosLosServicios;
  final List<ServicioCatalogoModel> serviciosFiltrados;
  final String? categoriaFiltro;
  final String busqueda;
  final String? errorMessage;
  final String? successMessage;

  CatalogoState({
    this.isLoading = false,
    this.todosLosServicios = const [],
    this.serviciosFiltrados = const [],
    this.categoriaFiltro,
    this.busqueda = '',
    this.errorMessage,
    this.successMessage,
  });

  CatalogoState copyWith({
    bool? isLoading,
    List<ServicioCatalogoModel>? todosLosServicios,
    List<ServicioCatalogoModel>? serviciosFiltrados,
    String? categoriaFiltro,
    bool clearCategoriaFiltro = false,
    String? busqueda,
    String? errorMessage,
    String? successMessage,
  }) {
    return CatalogoState(
      isLoading: isLoading ?? this.isLoading,
      todosLosServicios: todosLosServicios ?? this.todosLosServicios,
      serviciosFiltrados: serviciosFiltrados ?? this.serviciosFiltrados,
      categoriaFiltro: clearCategoriaFiltro ? null : (categoriaFiltro ?? this.categoriaFiltro),
      busqueda: busqueda ?? this.busqueda,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class CatalogoNotifier extends StateNotifier<CatalogoState> {
  final ServicioRepository _servicioRepo;

  CatalogoNotifier(this._servicioRepo) : super(CatalogoState());

  Future<void> cargarServicios(int empresaId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final servicios = await _servicioRepo.listarServicios(empresaId);
      state = state.copyWith(
        isLoading: false,
        todosLosServicios: servicios,
      );
      _aplicarFiltros();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar catálogo: $e',
      );
    }
  }

  void setCategoria(String? categoria) {
    if (categoria == null) {
      state = state.copyWith(clearCategoriaFiltro: true);
    } else {
      state = state.copyWith(categoriaFiltro: categoria);
    }
    _aplicarFiltros();
  }

  void setBusqueda(String texto) {
    state = state.copyWith(busqueda: texto.trim().toLowerCase());
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    var lista = List<ServicioCatalogoModel>.from(state.todosLosServicios);

    if (state.categoriaFiltro != null && state.categoriaFiltro!.isNotEmpty) {
      lista = lista.where((s) => s.categoria == state.categoriaFiltro).toList();
    }

    if (state.busqueda.isNotEmpty) {
      final query = state.busqueda;
      lista = lista.where((s) {
        return s.nombre.toLowerCase().contains(query) ||
            (s.descripcion?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(serviciosFiltrados: lista);
  }

  Future<bool> agregarServicio(int empresaId, Map<String, dynamic> datos) async {
    state = state.copyWith(isLoading: true);
    try {
      datos['empresa_id'] = empresaId;
      datos['activo'] = true;
      await _servicioRepo.crearServicio(datos);
      await cargarServicios(empresaId);
      state = state.copyWith(successMessage: 'Servicio agregado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al agregar servicio: $e',
      );
      return false;
    }
  }

  Future<bool> actualizarServicio(int id, int empresaId, Map<String, dynamic> datos) async {
    state = state.copyWith(isLoading: true);
    try {
      await _servicioRepo.actualizarServicio(id, datos);
      await cargarServicios(empresaId);
      state = state.copyWith(successMessage: 'Servicio actualizado exitosamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar servicio: $e',
      );
      return false;
    }
  }

  Future<bool> eliminarServicio(int id, int empresaId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _servicioRepo.eliminarServicio(id);
      await cargarServicios(empresaId);
      state = state.copyWith(successMessage: 'Servicio eliminado correctamente');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar servicio: $e',
      );
      return false;
    }
  }
}

final catalogoProvider = StateNotifierProvider<CatalogoNotifier, CatalogoState>((ref) {
  final servicioRepo = ref.watch(servicioRepositoryProvider);
  return CatalogoNotifier(servicioRepo);
});

// ═══════════════════════════════════════════════════════════════════
//  7. CONFIGURACIÓN & TÉCNICOS STATE NOTIFIER
// ═══════════════════════════════════════════════════════════════════

class ConfiguracionState {
  final bool isLoading;
  final List<TecnicoModel> tecnicos;
  final String? errorMessage;
  final String? successMessage;

  ConfiguracionState({
    this.isLoading = false,
    this.tecnicos = const [],
    this.errorMessage,
    this.successMessage,
  });

  ConfiguracionState copyWith({
    bool? isLoading,
    List<TecnicoModel>? tecnicos,
    String? errorMessage,
    String? successMessage,
  }) {
    return ConfiguracionState(
      isLoading: isLoading ?? this.isLoading,
      tecnicos: tecnicos ?? this.tecnicos,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ConfiguracionNotifier extends StateNotifier<ConfiguracionState> {
  final TecnicoRepository _tecnicoRepo;

  ConfiguracionNotifier(this._tecnicoRepo) : super(ConfiguracionState());

  Future<void> cargarTecnicos(int empresaId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final lista = await _tecnicoRepo.listarTecnicos(empresaId);
      state = state.copyWith(isLoading: false, tecnicos: lista);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar técnicos: $e',
      );
    }
  }

  Future<bool> crearTecnico({
    required int empresaId,
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String rol,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authRes = await _tecnicoRepo.registrarUsuarioAuth(email, password);
      final authUserId = authRes.user?.id;

      if (authUserId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo crear la cuenta de usuario Auth.',
        );
        return false;
      }

      await _tecnicoRepo.crearTecnico({
        'empresa_id': empresaId,
        'auth_user_id': authUserId,
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'rol': rol,
        'activo': true,
      });

      await cargarTecnicos(empresaId);
      state = state.copyWith(successMessage: 'Técnico creado con éxito.');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear técnico: $e',
      );
      return false;
    }
  }

  Future<bool> desactivarTecnico(int id, int empresaId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _tecnicoRepo.desactivarTecnico(id);
      await cargarTecnicos(empresaId);
      state = state.copyWith(successMessage: 'Técnico desactivado con éxito.');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al desactivar técnico: $e',
      );
      return false;
    }
  }
}

final configuracionProvider = StateNotifierProvider<ConfiguracionNotifier, ConfiguracionState>((ref) {
  final tecnicoRepo = ref.watch(tecnicoRepositoryProvider);
  return ConfiguracionNotifier(tecnicoRepo);
});

// ═══════════════════════════════════════════════════════════════════
//  8. THEME MODE NOTIFIER (Modo Claro / Modo Oscuro)
// ═══════════════════════════════════════════════════════════════════

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

