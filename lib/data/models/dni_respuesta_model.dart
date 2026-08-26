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
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(' ').trim();
  }

  String get apellidosCompletos {
    final parts = [
      apellidoPaterno ?? '',
      apellidoMaterno ?? '',
    ].where((p) => p.trim().isNotEmpty).toList();
    return parts.join(' ').trim();
  }

  factory DniRespuestaModel.fromJson(Map<String, dynamic> json) {
    // Manejo de éxito
    bool? successVal;
    if (json['success'] != null) {
      if (json['success'] is bool) {
        successVal = json['success'] as bool;
      } else {
        successVal = json['success'].toString().toLowerCase() == 'true' || json['success'] == 1;
      }
    }

    // Extracción de datos con múltiples alias comunes
    final dniVal = json['dni']?.toString() ??
        json['numero']?.toString() ??
        json['documento']?.toString() ??
        json['data']?['numero']?.toString();

    final nombresVal = json['nombres']?.toString() ??
        json['nombre']?.toString() ??
        json['data']?['nombres']?.toString() ??
        json['data']?['nombre']?.toString();

    final apellidoPaternoVal = json['apellidoPaterno']?.toString() ??
        json['apellido_paterno']?.toString() ??
        json['paterno']?.toString() ??
        json['data']?['apellido_paterno']?.toString();

    final apellidoMaternoVal = json['apellidoMaterno']?.toString() ??
        json['apellido_materno']?.toString() ??
        json['materno']?.toString() ??
        json['data']?['apellido_materno']?.toString();

    final codVerificaVal = json['codVerifica']?.toString() ??
        json['cod_verifica']?.toString() ??
        json['codigo_verificacion']?.toString();

    return DniRespuestaModel(
      success: successVal ?? (nombresVal != null && nombresVal.isNotEmpty),
      dni: dniVal,
      nombres: nombresVal,
      apellidoPaterno: apellidoPaternoVal,
      apellidoMaterno: apellidoMaternoVal,
      codVerifica: codVerificaVal,
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
