import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../../data/models/dni_respuesta_model.dart';

class DniService {
  /// Consulta DNI en ApisPeru con token
  Future<DniRespuestaModel?> consultarDni(String numeroDni) async {
    final dniLimpio = numeroDni.replaceAll(RegExp(r'\D'), '').trim();
    if (dniLimpio.length != 8) return null;

    const token = AppConstants.dniApiToken;

    // 1. Intentar con HTTP estándar (Evita bloqueos de CORS en Web)
    try {
      final uri = Uri.parse('https://dniruc.apisperu.com/api/v1/dni/$dniLimpio?token=$token');
      debugPrint('🔎 Consultando DNI: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Respuesta DNI ($dniLimpio): HTTP ${response.statusCode} -> ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
        final model = DniRespuestaModel.fromJson(data);

        if (model.nombres != null && model.nombres!.trim().isNotEmpty) {
          debugPrint('✓ DNI $dniLimpio resuelto con éxito: ${model.nombreCompleto}');
          return model;
        }
      }
    } catch (e) {
      debugPrint('Aviso: Error en consulta directa DNI para $dniLimpio: $e');
    }

    return null;
  }
}
