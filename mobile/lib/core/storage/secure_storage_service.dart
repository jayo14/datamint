import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

abstract class ISecureStorageService {
  Future<String?> getAccessToken();
  Future<void> setAccessToken(String token);
  Future<void> clearAccessToken();

  Future<String?> getRefreshToken();
  Future<void> setRefreshToken(String token);
  Future<void> clearRefreshToken();

  Future<WorkspaceRole> getActiveWorkspace();
  Future<void> setActiveWorkspace(WorkspaceRole role);

  Future<String?> getLinkedWallet();
  Future<void> setLinkedWallet(String address);
  Future<void> clearLinkedWallet();

  Future<void> clearAll();
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: AppConstants.accessTokenKey) ??
          _memoryFallback[AppConstants.accessTokenKey];
    } catch (_) {
      return _memoryFallback[AppConstants.accessTokenKey];
    }
  }

  @override
  Future<void> setAccessToken(String token) async {
    _memoryFallback[AppConstants.accessTokenKey] = token;
    try {
      await _storage.write(key: AppConstants.accessTokenKey, value: token);
    } catch (_) {}
  }

  @override
  Future<void> clearAccessToken() async {
    _memoryFallback.remove(AppConstants.accessTokenKey);
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
    } catch (_) {}
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey) ??
          _memoryFallback[AppConstants.refreshTokenKey];
    } catch (_) {
      return _memoryFallback[AppConstants.refreshTokenKey];
    }
  }

  @override
  Future<void> setRefreshToken(String token) async {
    _memoryFallback[AppConstants.refreshTokenKey] = token;
    try {
      await _storage.write(key: AppConstants.refreshTokenKey, value: token);
    } catch (_) {}
  }

  @override
  Future<void> clearRefreshToken() async {
    _memoryFallback.remove(AppConstants.refreshTokenKey);
    try {
      await _storage.delete(key: AppConstants.refreshTokenKey);
    } catch (_) {}
  }

  @override
  Future<WorkspaceRole> getActiveWorkspace() async {
    String? val;
    try {
      val = await _storage.read(key: AppConstants.activeWorkspaceKey) ??
          _memoryFallback[AppConstants.activeWorkspaceKey];
    } catch (_) {
      val = _memoryFallback[AppConstants.activeWorkspaceKey];
    }
    if (val == 'creator') {
      return WorkspaceRole.creator;
    }
    return WorkspaceRole.contributor;
  }

  @override
  Future<void> setActiveWorkspace(WorkspaceRole role) async {
    final str = role == WorkspaceRole.creator ? 'creator' : 'contributor';
    _memoryFallback[AppConstants.activeWorkspaceKey] = str;
    try {
      await _storage.write(key: AppConstants.activeWorkspaceKey, value: str);
    } catch (_) {}
  }

  @override
  Future<String?> getLinkedWallet() async {
    try {
      return await _storage.read(key: AppConstants.linkedWalletKey) ??
          _memoryFallback[AppConstants.linkedWalletKey];
    } catch (_) {
      return _memoryFallback[AppConstants.linkedWalletKey];
    }
  }

  @override
  Future<void> setLinkedWallet(String address) async {
    _memoryFallback[AppConstants.linkedWalletKey] = address;
    try {
      await _storage.write(key: AppConstants.linkedWalletKey, value: address);
    } catch (_) {}
  }

  @override
  Future<void> clearLinkedWallet() async {
    _memoryFallback.remove(AppConstants.linkedWalletKey);
    try {
      await _storage.delete(key: AppConstants.linkedWalletKey);
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    _memoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
