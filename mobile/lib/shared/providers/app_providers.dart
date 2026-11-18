import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/models.dart';
import '../services/datamint_services.dart';
import '../services/wallet_service.dart';

// Config Provider
final configProvider = Provider<EnvConfig>((ref) {
  return EnvConfig.dev;
});

// Storage Provider
final secureStorageProvider = Provider<ISecureStorageService>((ref) {
  return SecureStorageService();
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});

// Services Providers
final walletServiceProvider = Provider<IWalletService>((ref) {
  final config = ref.watch(configProvider);
  return WalletService(config: config);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthService(apiClient: apiClient, storage: storage);
});

final marketplaceServiceProvider = Provider<MarketplaceService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MarketplaceService(apiClient: apiClient);
});

final campaignServiceProvider = Provider<CampaignService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CampaignService(apiClient: apiClient);
});

final submissionServiceProvider = Provider<SubmissionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubmissionService(apiClient: apiClient);
});

final reviewServiceProvider = Provider<ReviewService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReviewService(apiClient: apiClient);
});

final payoutServiceProvider = Provider<PayoutService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PayoutService(apiClient: apiClient);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient: apiClient);
});

// Active Workspace Notifier (Contributor vs Creator)
class WorkspaceNotifier extends StateNotifier<WorkspaceRole> {
  final ISecureStorageService _storage;

  WorkspaceNotifier(this._storage) : super(WorkspaceRole.contributor) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final role = await _storage.getActiveWorkspace();
    state = role;
  }

  Future<void> setWorkspace(WorkspaceRole role) async {
    state = role;
    await _storage.setActiveWorkspace(role);
  }

  void toggle() {
    final newRole = state == WorkspaceRole.contributor
        ? WorkspaceRole.creator
        : WorkspaceRole.contributor;
    setWorkspace(newRole);
  }
}

final activeWorkspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceRole>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return WorkspaceNotifier(storage);
});

// User State Notifier
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final ISecureStorageService _storage;

  CurrentUserNotifier(this._authService, this._storage)
      : super(const AsyncValue.loading()) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    state = const AsyncValue.loading();
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  void setUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    state = const AsyncValue.data(null);
    await _authService.logout();
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final storage = ref.watch(secureStorageProvider);
  return CurrentUserNotifier(authService, storage);
});

// Wallet State
class WalletState {
  final String? address;
  final int chainId;
  final bool isConnected;
  final double celoBalance;
  final double cusdBalance;
  final bool isLoading;

  const WalletState({
    this.address,
    required this.chainId,
    this.isConnected = false,
    this.celoBalance = 0.0,
    this.cusdBalance = 0.0,
    this.isLoading = false,
  });

  WalletState copyWith({
    String? address,
    int? chainId,
    bool? isConnected,
    double? celoBalance,
    double? cusdBalance,
    bool? isLoading,
  }) {
    return WalletState(
      address: address ?? this.address,
      chainId: chainId ?? this.chainId,
      isConnected: isConnected ?? this.isConnected,
      celoBalance: celoBalance ?? this.celoBalance,
      cusdBalance: cusdBalance ?? this.cusdBalance,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WalletStateNotifier extends StateNotifier<WalletState> {
  final IWalletService _walletService;

  WalletStateNotifier(this._walletService)
      : super(WalletState(chainId: _walletService.chainId)) {
    _init();
  }

  void _init() {
    _walletService.addressStream.listen((addr) {
      if (addr != null) {
        refreshBalances(addr);
      } else {
        state = WalletState(chainId: _walletService.chainId);
      }
    });
  }

  Future<void> connect({String? explicitAddress}) async {
    state = state.copyWith(isLoading: true);
    try {
      final addr = await _walletService.connect(explicitAddress: explicitAddress);
      final balances = await _walletService.getBalances(addr);
      state = state.copyWith(
        address: addr,
        isConnected: true,
        celoBalance: balances['CELO'] ?? 0.0,
        cusdBalance: balances['cUSD'] ?? 0.0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> refreshBalances([String? addr]) async {
    final target = addr ?? state.address;
    if (target == null) return;
    try {
      final balances = await _walletService.getBalances(target);
      state = state.copyWith(
        address: target,
        isConnected: true,
        celoBalance: balances['CELO'] ?? 0.0,
        cusdBalance: balances['cUSD'] ?? 0.0,
      );
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _walletService.disconnect();
    state = WalletState(chainId: _walletService.chainId);
  }
}

final walletStateProvider =
    StateNotifierProvider<WalletStateNotifier, WalletState>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  return WalletStateNotifier(walletService);
});

// Filter state for marketplace
class MarketplaceFilter {
  final String? dataType;
  final String? category;
  final String? search;

  const MarketplaceFilter({this.dataType, this.category, this.search});

  MarketplaceFilter copyWith({String? dataType, String? category, String? search}) {
    return MarketplaceFilter(
      dataType: dataType ?? this.dataType,
      category: category ?? this.category,
      search: search ?? this.search,
    );
  }
}

final marketplaceFilterProvider =
    StateProvider<MarketplaceFilter>((ref) => const MarketplaceFilter());

final marketplaceCampaignsProvider =
    FutureProvider<List<CampaignModel>>((ref) async {
  final service = ref.watch(marketplaceServiceProvider);
  final filter = ref.watch(marketplaceFilterProvider);
  return await service.getCampaigns(
    dataType: filter.dataType,
    category: filter.category,
    search: filter.search,
  );
});

// Notifications count provider
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  try {
    final service = ref.watch(notificationServiceProvider);
    final notifications = await service.getNotifications();
    return notifications.where((n) => !n.isRead).length;
  } catch (_) {
    return 0;
  }
});
