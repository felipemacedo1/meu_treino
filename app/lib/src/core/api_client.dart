import 'package:dio/dio.dart';

import 'env.dart';

/// Erro de API já traduzido para uma mensagem que pode ir para a tela.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

typedef TokenReader = String? Function();
typedef UnauthorizedHandler = void Function();

class ApiClient {
  ApiClient({required TokenReader tokenReader, UnauthorizedHandler? onUnauthorized})
      : _tokenReader = tokenReader,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenReader();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenReader _tokenReader;
  final UnauthorizedHandler? _onUnauthorized;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => _dio.post(path, data: body, queryParameters: _clean(query)));

  Future<dynamic> put(String path, {Object? body}) => _run(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) => _run(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _run(() => _dio.delete(path));

  /// Retorna null quando a API responde 204 (usado em /sessions/active).
  Future<dynamic> getOrNull(String path) async {
    final response = await _run(() => _dio.get(path), raw: true);
    if (response is Response && response.statusCode == 204) return null;
    return (response as Response).data;
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? query) {
    if (query == null) return null;
    final result = <String, dynamic>{};
    query.forEach((key, value) {
      if (value != null) result[key] = value;
    });
    return result;
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() request, {bool raw = false}) async {
    try {
      final response = await request();
      return raw ? response : response.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiException _toApiException(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      final fields = data['fields'];
      if (fields is Map && fields.isNotEmpty) {
        final detail = fields.values.whereType<String>().join(' · ');
        return ApiException('${data['message']}: $detail', statusCode: status);
      }
      return ApiException(data['message'] as String, statusCode: status);
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('Tempo de conexão esgotado. Tente novamente.', statusCode: status);
      case DioExceptionType.connectionError:
        return ApiException(
          'Não foi possível falar com o servidor. Confira se a API está no ar.',
          statusCode: status,
        );
      default:
        return ApiException(
          status == null ? 'Falha inesperada de rede.' : 'Erro $status ao chamar a API.',
          statusCode: status,
        );
    }
  }
}
