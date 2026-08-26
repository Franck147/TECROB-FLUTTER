import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../data/models/dni_respuesta_model.dart';

class DniService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  /// Consulta DNI en ApisPeru con fallback automático
  Future<DniRespuestaModel?> consultarDni(String numeroDni) async {
    final dniLimpio = numeroDni.replaceAll(RegExp(r'\D'), '').trim();
    if (dniLimpio.length != 8) return null;

    // 1. Intentar con Proveedor Principal (ApisPeru)
    try {
      final url = '${AppConstants.dniBaseUrl}dni/$dniLimpio';
      final response = await _dio.get(
        url,
        queryParameters: {'token': AppConstants.dniApiToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConstants.dniApiToken}',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : (response.data is Map ? Map<String, dynamic>.from(response.data as Map) : null);

        if (data != null) {
          final model = DniRespuestaModel.fromJson(data);
          if (model.nombres != null && model.nombres!.trim().isNotEmpty) {
            return model;
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Aviso: Fallo proveedor principal ApisPeru para DNI $dniLimpio: $e');
    }

    // 2. Intentar con Proveedor de Respaldo Secundario (ApiPeru / Open DNI)
    try {
      final fallbackResponse = await _dio.get(
        'https://api.perudevs.com/api/v1/dni/simple',
        queryParameters: {
          'document': dniLimpio,
          'key': 'cGVydWRldnMucHJvZHVjdGlvbi52MS42NmQwMDQ5MzBkYTkxMDk3NTcwZThjNmE=',
        },
      );

      if (fallbackResponse.statusCode == 200 && fallbackResponse.data != null) {
        final data = fallbackResponse.data is Map<String, dynamic>
            ? fallbackResponse.data as Map<String, dynamic>
            : null;

        if (data != null && data['result'] != null && data['result'] is Map) {
          final resMap = Map<String, dynamic>.from(data['result'] as Map);
          final model = DniRespuestaModel(
            success: true,
            dni: dniLimpio,
            nombres: resMap['nombres']?.toString(),
            apellidoPaterno: resMap['apellido_paterno']?.toString(),
            apellidoMaterno: resMap['apellido_materno']?.toString(),
          );
          if (model.nombres != null && model.nombres!.trim().isNotEmpty) {
            return model;
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Aviso: Fallo proveedor secundario DNI para $dniLimpio: $e');
    }

    return null;
  }
}
