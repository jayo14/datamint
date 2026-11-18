import 'dart:async';
import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final ISecureStorageService storage;
  final String baseUrl;

  Completer<String?>? _refreshCompleter;

  ApiClient({
    required this.storage,
    String? baseUrl,
    Dio? customDio,
  })  : baseUrl = baseUrl ?? EnvConfig.defaultBaseUrl,
        dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? EnvConfig.defaultBaseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                sendTimeout: AppConstants.sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // If Authorization header isn't already set, attach the stored token
          if (!options.headers.containsKey('Authorization')) {
            final token = await storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final statusCode = error.response?.statusCode;
          final requestPath = error.requestOptions.path;

          // Check if this is an unauthorized error on a non-auth endpoint
          final isAuthEndpoint = requestPath.contains('/auth/login') ||
              requestPath.contains('/auth/register') ||
              requestPath.contains('/auth/refresh');

          if (statusCode == 401 && !isAuthEndpoint) {
            try {
              final newToken = await _refreshToken();
              if (newToken != null) {
                // Retry failed request with new access token
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              // Refresh failed, session expired
              await storage.clearAccessToken();
              await storage.clearRefreshToken();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshToken() async {
    // If a refresh is already in progress, await the existing future
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return null;
      }

      // Use a separate Dio instance without interceptors to avoid loops
      final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await storage.setAccessToken(newAccessToken);
          if (newRefreshToken != null) {
            await storage.setRefreshToken(newRefreshToken);
          }
          _refreshCompleter!.complete(newAccessToken);
          return newAccessToken;
        }
      }
      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> uploadBinary({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final uploadDio = Dio();
      return await uploadDio.put(
        uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
          },
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  AppException _handleDioError(DioException e) {
    final res = e.response;
    final statusCode = res?.statusCode;
    String message = 'Network communication failed';
    dynamic details;

    if (res?.data != null) {
      if (res!.data is Map) {
        final data = res.data as Map;
        message = data['detail']?.toString() ??
            data['message']?.toString() ??
            e.message ??
            message;
        details = data['errors'] ?? data['details'];
      } else if (res.data is String) {
        message = res.data as String;
      }
    } else if (e.message != null) {
      message = e.message!;
    }

    if (statusCode == 401) {
      return AuthException(
        message: message,
        statusCode: statusCode,
      );
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      details: details,
    );
  }
}
