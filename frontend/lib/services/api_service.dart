import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emülatör

  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  Future<Map<String, dynamic>> analyzeIngredients(
    List<String> ingredients,
  ) async {
    try {
      final Response<dynamic> response = await _dio.post(
        '/cosmetics/analyzeBatch',
        data: ingredients, // JSON array olarak gider
      );

      if (response.statusCode == 200) {
        return _parseResponse(response.data);
      } else {
        throw Exception('Hata: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Dio 5: DioError yerine DioException
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'İstek hatası (${status ?? 'unknown'}): ${e.message} ${data ?? ''}',
      );
    } catch (e) {
      throw Exception('Bilinmeyen hata: $e');
    }
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    final List<Map<String, dynamic>> harmful = [];
    final List<Map<String, dynamic>> safe = [];
    int harmfulCount = 0;

    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final String name = (item['name'] as String?) ?? 'Bilinmeyen';
          final String message = (item['message'] as String?) ?? '';
          final Map<String, dynamic>? chemical =
              item['chemical'] as Map<String, dynamic>?;

          final bool isHarmful =
              (chemical?['harmful'] as bool?) ??
              message.toLowerCase().contains('harmful');

          final record = {
            'name': name,
            'description':
                (chemical?['description'] as String?) ?? 'Açıklama yok',
            'message': message,
          };

          if (isHarmful) {
            harmful.add(record);
            harmfulCount++;
          } else {
            safe.add(record);
          }
        }
      }
    }

    String riskLevel = 'LOW';
    if (harmfulCount > 5) {
      riskLevel = 'HIGH';
    } else if (harmfulCount > 2) {
      riskLevel = 'MEDIUM';
    }

    return {
      'harmful_ingredients': harmful,
      'safe_ingredients': safe,
      'overall_risk': riskLevel,
      'total_analyzed': harmful.length + safe.length,
    };
  }
}
