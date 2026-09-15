class AppConstants {
  // Supabase Credentials (del proyecto TecrobSys)
  static const String supabaseUrl = 'https://cgjzbwqoeyqtvnfspybg.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_4prX92nOSSbKaay8HMQuVw_5wynwwa3';

  /// Token de la consulta de DNI en ApisPeru.
  ///
  /// Va escrito aquí a propósito, y se sube al repositorio, para que la app
  /// funcione con un flutter run normal mientras sea de pruebas. Para probar
  /// con otro sin tocar el código se puede pasar --dart-define=DNI_API_TOKEN=...
  static const String dniApiToken = String.fromEnvironment(
    'DNI_API_TOKEN',
    defaultValue:
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6ImFkbGVyY2lzbmVyb3MxNDdAZ21haWwuY29tIn0.oXEO8knJ9JOVp6mhAG_T9DKOSqN78IsbWXLTK13-QRo',
  );

  static bool get consultaDniDisponible => dniApiToken.isNotEmpty;

  static const String dniBaseUrl = 'https://dniruc.apisperu.com/api/v1/';

  // Empresa Info
  static const String appName = 'TecrobSys';
  static const String empresaRazonSocial = 'MULTISERVICIOS TECROB SYS E.I.R.L.';
  static const String empresaSubtitulo = 'Servicio Técnico Especializado';
  static const String empresaEmail = 'tecrobsys@gmail.com';
  static const String empresaTelefono = 'RPC: 000-000-000';
}
