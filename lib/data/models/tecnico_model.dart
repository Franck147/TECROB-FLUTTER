class TecnicoModel {
  final int id;
  final int? empresaId;
  final String? authUserId;
  final String nombre;
  final String? apellido;
  final String email;
  final String rol; // 'administrador' | 'tecnico'
  final bool activo;
  final String? createdAt;

  TecnicoModel({
    required this.id,
    this.empresaId,
    this.authUserId,
    required this.nombre,
    this.apellido,
    required this.email,
    required this.rol,
    this.activo = true,
    this.createdAt,
  });

  bool get esAdmin => rol.toLowerCase() == 'administrador' || rol.toLowerCase() == 'admin';

  String get nombreCompleto {
    if (apellido != null && apellido!.trim().isNotEmpty) {
      return '$nombre $apellido'.trim();
    }
    return nombre;
  }

  String get inicial {
    if (nombre.isEmpty) return '?';
    return nombre.trim()[0].toUpperCase();
  }

  factory TecnicoModel.fromJson(Map<String, dynamic> json) {
    return TecnicoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      empresaId: json['empresa_id'] as int?,
      authUserId: json['auth_user_id'] as String?,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String?,
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? 'tecnico',
      activo: json['activo'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      if (authUserId != null) 'auth_user_id': authUserId,
      'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      'email': email,
      'rol': rol,
      'activo': activo,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
