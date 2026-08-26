import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../../data/models/dni_respuesta_model.dart';

class DniService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'TecrobSys-Flutter/1.0',
      },
    ),
  );

  /// Consulta DNI en ApisPeru con token
  Future<DniRespuestaModel?> consultarDni(String numeroDni) async {
    final dniLimpio = numeroDni.replaceAll(RegExp(r'\D'), '').trim();
    if (dniLimpio.length != 8) return null;

    // 1. Proveedor Principal: ApisPeru
    try {
      const token = AppConstants.dniApiToken;
      final url = 'https://dniruc.apisperu.com/api/v1/dni/$dniLimpio?token=$token';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic>? data;

        if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else if (response.data is String) {
          try {
            data = Map<String, dynamic>.from(jsonDecode(response.data as String) as Map);
          } catch (_) {}
        }

        if (data != null) {
          final model = DniRespuestaModel.fromJson(data);
          if (model.nombres != null && model.nombres!.trim().isNotEmpty) {
            debugPrint('✓ DNI $dniLimpio encontrado en ApisPeru: ${model.nombreCompleto}');
            return model;
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso: Fallo proveedor principal ApisPeru para DNI $dniLimpio: $e');
    }

    // 2. Proveedor Secundario de Respaldo: PeruDevs
    try {
      final fallbackResponse = await _dio.get(
        'https://api.perudevs.com/api/v1/dni/simple',
        queryParameters: {
          'document': dniLimpio,
          'key': 'cGVydWRldnMucHJvZHVjdGlvbi52MS42NmQwMDQ5MzBkYTkxMDk3NTcwZThjNmE=',
        },
      );

      if (fallbackResponse.statusCode == 200 && fallbackResponse.data != null) {
        Map<String, dynamic>? data;
        if (fallbackResponse.data is Map) {
          data = Map<String, dynamic>.from(fallbackResponse.data as Map);
        } else if (fallbackResponse.data is String) {
          try {
            data = Map<String, dynamic>.from(jsonDecode(fallbackResponse.data as String) as Map);
          } catch (_) {}
        }

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
            debugPrint('✓ DNI $dniLimpio encontrado en Proveedor Secundario: ${model.nombreCompleto}');
            return model;
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso: Fallo proveedor secundario DNI para $dniLimpio: $e');
    }

    return null;
  }
}
