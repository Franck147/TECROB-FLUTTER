class ClienteModel {
  final int id;
  final int? empresaId;
  final String nombre;
  final String? apellido;
  final String? dni;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? createdAt;

  ClienteModel({
    required this.id,
    this.empresaId,
    required this.nombre,
    this.apellido,
    this.dni,
    this.telefono,
    this.email,
    this.direccion,
    this.createdAt,
  });

  String get nombreCompleto {
    if (apellido != null && apellido!.trim().isNotEmpty) {
      return '$nombre $apellido'.trim();
    }
    return nombre;
  }

  String get iniciales {
    if (nombre.isEmpty) return '?';
    final n = nombre.trim()[0].toUpperCase();
    if (apellido != null && apellido!.trim().isNotEmpty) {
      return '$n${apellido!.trim()[0].toUpperCase()}';
    }
    return n;
  }

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      empresaId: json['empresa_id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String?,
      dni: json['dni'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (empresaId != null) 'empresa_id': empresaId,
      'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (dni != null) 'dni': dni,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (direccion != null) 'direccion': direccion,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  ClienteModel copyWith({
    int? id,
    int? empresaId,
    String? nombre,
    String? apellido,
    String? dni,
    String? telefono,
    String? email,
    String? direccion,
    String? createdAt,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
