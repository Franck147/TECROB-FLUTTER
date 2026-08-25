import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../data/models/dni_respuesta_model.dart';

class DniService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.dniBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<DniRespuestaModel?> consultarDni(String numeroDni) async {
    try {
      final response = await _dio.get(
        'dni/$numeroDni',
        queryParameters: {'token': AppConstants.dniApiToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return DniRespuestaModel.fromJson(response.data as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print('Error al consultar DNI API: $e');
      return null;
    }
  }
}
