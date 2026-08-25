class DniRespuestaModel {
  final bool? success;
  final String? dni;
  final String? nombres;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? codVerifica;

  DniRespuestaModel({
    this.success,
    this.dni,
    this.nombres,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.codVerifica,
  });

  String get nombreCompleto {
    final parts = [
      nombres ?? '',
      apellidoPaterno ?? '',
      apellidoMaterno ?? '',
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(' ');
  }

  String get apellidosCompletos {
    final parts = [
      apellidoPaterno ?? '',
      apellidoMaterno ?? '',
    ].where((p) => p.isNotEmpty).toList();
    return parts.join(' ');
  }

  factory DniRespuestaModel.fromJson(Map<String, dynamic> json) {
    return DniRespuestaModel(
      success: json['success'] as bool?,
      dni: json['dni'] as String? ?? json['numero'] as String?,
      nombres: json['nombres'] as String?,
      apellidoPaterno: json['apellidoPaterno'] as String? ?? json['apellido_paterno'] as String?,
      apellidoMaterno: json['apellidoMaterno'] as String? ?? json['apellido_materno'] as String?,
      codVerifica: json['codVerifica'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'dni': dni,
      'nombres': nombres,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'codVerifica': codVerifica,
    };
  }
}
