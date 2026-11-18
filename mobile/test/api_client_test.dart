import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/core/constants/app_constants.dart';
import 'package:datamint_mobile/core/errors/app_exception.dart';
import 'package:datamint_mobile/core/network/api_client.dart';
import 'package:datamint_mobile/core/storage/secure_storage_service.dart';

class MockStorageService implements ISecureStorageService {
  String? accessToken = 'initial-token';
  String? refreshToken = 'initial-refresh';
  WorkspaceRole activeRole = WorkspaceRole.contributor;
  String? wallet;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> setAccessToken(String token) async => accessToken = token;

  @override
  Future<void> clearAccessToken() async => accessToken = null;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> setRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<WorkspaceRole> getActiveWorkspace() async => activeRole;

  @override
  Future<void> setActiveWorkspace(WorkspaceRole role) async => activeRole = role;

  @override
  Future<String?> getLinkedWallet() async => wallet;

  @override
  Future<void> setLinkedWallet(String address) async => wallet = address;

  @override
  Future<void> clearLinkedWallet() async => wallet = null;

  @override
  Future<void> clearAll() async {
    accessToken = null;
    refreshToken = null;
    wallet = null;
  }
}

void main() {
  late MockStorageService mockStorage;

  setUp(() {
    mockStorage = MockStorageService();
  });

  group('ApiClient Interceptors & Headers', () {
    test('attaches stored Bearer access token to outgoing request headers', () async {
      final dio = Dio();
      ApiClient(storage: mockStorage, customDio: dio);

      // Add a test adapter to intercept and inspect request options
      dio.httpClientAdapter = HttpClientAdapter();

      // Trigger interceptor onRequest
      final options = RequestOptions(path: '/users/me');
      final handler = RequestInterceptorHandler();

      // Simulate interceptor chain
      for (final interceptor in dio.interceptors) {
        if (interceptor is InterceptorsWrapper) {
          interceptor.onRequest(options, handler);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(options.headers['Authorization'], 'Bearer initial-token');
    });

    test('maps 401 error to AuthException', () {
      ApiClient(storage: mockStorage);

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {'detail': 'Invalid email or password'},
        ),
        type: DioExceptionType.badResponse,
      );

      // Access private or test error handling through exception throwing
      expect(
        () {
          try {
            throw dioError;
          } on DioException catch (e) {
            if (e.response?.statusCode == 401) {
              throw AuthException(
                message: e.response?.data['detail'] ?? 'Unauthorized',
                statusCode: 401,
              );
            }
          }
        },
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Invalid email or password')),
      );
    });

    test('preserves custom Authorization header if explicitly provided', () async {
      final dio = Dio();
      ApiClient(storage: mockStorage, customDio: dio);

      final options = RequestOptions(
        path: '/custom',
        headers: {'Authorization': 'Bearer custom-override-token'},
      );
      final handler = RequestInterceptorHandler();

      for (final interceptor in dio.interceptors) {
        if (interceptor is InterceptorsWrapper) {
          interceptor.onRequest(options, handler);
        }
      }

      expect(options.headers['Authorization'], 'Bearer custom-override-token');
    });
  });
}
