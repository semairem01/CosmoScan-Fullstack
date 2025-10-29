import 'package:dio/dio.dart';

class ApiService {
  //static const String baseUrl = 'http://10.0.2.2:8080'; // Android emülatör
  static const String baseUrl = 'http://192.168.1.43:8080';
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 90),
            receiveTimeout: const Duration(seconds: 90),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 REQUEST: ${options.method} ${options.uri}');
          print(
              '📤 Data length: ${(options.data as List?)?.length ?? 0} items');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ ERROR TYPE: ${error.type}');
          print('❌ ERROR MESSAGE: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

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
      // Bağlantı hatası detayları
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Bağlantı zaman aşımı. Backend çalışıyor mu?\n'
          'URL: $baseUrl\n'
          'IP adresinizi kontrol edin.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Bağlantı hatası!\n'
          '1. Backend çalışıyor mu?\n'
          '2. IP doğru mu? ($baseUrl)\n'
          '3. Firewall kapalı mı?\n'
          '4. Aynı ağda mısınız?\n\n'
          'Hata: ${e.message}',
        );
      }

      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception(
        'API hatası (${status ?? 'bilinmiyor'}): ${data ?? e.message}',
      );
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
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

          final bool isHarmful = (chemical?['harmful'] as bool?) ??
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
