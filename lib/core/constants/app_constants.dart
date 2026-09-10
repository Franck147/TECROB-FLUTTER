class AppConstants {
  // Supabase Credentials (del proyecto TecrobSys)
  static const String supabaseUrl = 'https://cgjzbwqoeyqtvnfspybg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_4prX92nOSSbKaay8HMQuVw_5wynwwa3';

  /// Token de la consulta de DNI en ApisPeru.
  ///
  /// Es una credencial personal, así que no vive en el código: se pasa al
  /// compilar con --dart-define=DNI_API_TOKEN=... . Si falta, la app funciona
  /// igual y la búsqueda por DNI queda desactivada.
  static const String dniApiToken =
      String.fromEnvironment('DNI_API_TOKEN', defaultValue: '');

  static bool get consultaDniDisponible => dniApiToken.isNotEmpty;

  static const String dniBaseUrl = 'https://dniruc.apisperu.com/api/v1/';

  // Empresa Info
  static const String appName = 'TecrobSys';
  static const String empresaRazonSocial = 'MULTISERVICIOS TECROB SYS E.I.R.L.';
  static const String empresaSubtitulo = 'Servicio Técnico Especializado';
  static const String empresaEmail = 'tecrobsys@gmail.com';
  static const String empresaTelefono = 'RPC: 000-000-000';
}
