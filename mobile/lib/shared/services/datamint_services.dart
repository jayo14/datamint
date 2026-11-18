import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/models.dart';

class AuthService {
  final ApiClient apiClient;
  final ISecureStorageService storage;

  AuthService({required this.apiClient, required this.storage});

  Future<UserModel> register({
    required String email,
    required String password,
    String role = 'BOTH',
    String? displayName,
    String? walletAddress,
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'role': role,
        'display_name': displayName,
        'wallet_address': walletAddress,
      },
    );

    final data = response.data as Map<String, dynamic>;
    if (data['access_token'] != null) {
      await storage.setAccessToken(data['access_token'] as String);
    }
    if (data['refresh_token'] != null) {
      await storage.setRefreshToken(data['refresh_token'] as String);
    }

    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    if (data['access_token'] != null) {
      await storage.setAccessToken(data['access_token'] as String);
    }
    if (data['refresh_token'] != null) {
      await storage.setRefreshToken(data['refresh_token'] as String);
    }

    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userJson);
  }

  Future<Map<String, dynamic>> getSiweChallenge({required String address}) async {
    final response = await apiClient.get(
      '/auth/siwe-challenge',
      queryParameters: {'address': address},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> verifySiwe({
    required String message,
    required String signature,
  }) async {
    final response = await apiClient.post(
      '/auth/siwe-verify',
      data: {
        'message': message,
        'signature': signature,
      },
    );

    final data = response.data as Map<String, dynamic>;
    if (data['access_token'] != null) {
      await storage.setAccessToken(data['access_token'] as String);
    }
    if (data['refresh_token'] != null) {
      await storage.setRefreshToken(data['refresh_token'] as String);
    }

    final userJson = data['user'] as Map<String, dynamic>? ?? data;
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await apiClient.get('/users/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await storage.clearAll();
  }
}

class MarketplaceService {
  final ApiClient apiClient;

  MarketplaceService({required this.apiClient});

  Future<List<CampaignModel>> getCampaigns({
    String? dataType,
    String? category,
    String? search,
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (dataType != null && dataType.isNotEmpty) {
      query['data_type'] = dataType;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    final response = await apiClient.get('/marketplace', queryParameters: query);
    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((c) => CampaignModel.fromJson(c))
        .toList();
  }

  Future<CampaignModel> getCampaignDetails(String id) async {
    final response = await apiClient.get('/marketplace/$id');
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }
}

class CampaignService {
  final ApiClient apiClient;

  CampaignService({required this.apiClient});

  Future<CampaignModel> createDraft(Map<String, dynamic> campaignData) async {
    final response = await apiClient.post('/campaigns/draft', data: campaignData);
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CampaignModel> updateDraft(String id, Map<String, dynamic> campaignData) async {
    final response = await apiClient.put('/campaigns/drafts/$id', data: campaignData);
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CampaignModel> publishCampaign(String id) async {
    final response = await apiClient.post('/campaigns/drafts/$id/publish');
    return CampaignModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CampaignModel>> getMyCampaigns() async {
    final response = await apiClient.get('/campaigns/my-campaigns');
    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((c) => CampaignModel.fromJson(c))
        .toList();
  }
}

class SubmissionService {
  final ApiClient apiClient;

  SubmissionService({required this.apiClient});

  Future<SubmissionModel> createDraft(String campaignId) async {
    final response = await apiClient.post(
      '/submissions/drafts',
      data: {'campaign_id': campaignId},
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> updateDraft(String id, {String? textContent}) async {
    final response = await apiClient.put(
      '/submissions/drafts/$id',
      data: {'text_content': textContent},
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getUploadUrl(
    String id, {
    required String contentType,
    required String fileName,
  }) async {
    final response = await apiClient.post(
      '/submissions/drafts/$id/upload-url',
      data: {
        'content_type': contentType,
        'file_name': fileName,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> confirmUpload(String id, {required String assetId}) async {
    await apiClient.post(
      '/submissions/drafts/$id/confirm-upload',
      data: {'asset_id': assetId},
    );
  }

  Future<SubmissionModel> submit(String id) async {
    final response = await apiClient.post('/submissions/drafts/$id/submit');
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SubmissionModel>> getMySubmissions() async {
    final response = await apiClient.get('/submissions/my-submissions');
    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((s) => SubmissionModel.fromJson(s))
        .toList();
  }

  Future<SubmissionModel> getSubmission(String id) async {
    final response = await apiClient.get('/submissions/$id');
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }
}

class ReviewService {
  final ApiClient apiClient;

  ReviewService({required this.apiClient});

  Future<List<ReviewQueueItem>> getReviewQueue() async {
    final response = await apiClient.get('/reviews/queue');
    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => ReviewQueueItem.fromJson(item))
        .toList();
  }

  Future<void> decideReview({
    required String submissionId,
    required String decision, // "APPROVE" or "REJECT"
    String? notes,
  }) async {
    await apiClient.post(
      '/reviews/submissions/$submissionId/decide',
      data: {
        'decision': decision,
        'notes': notes,
      },
    );
  }

  Future<void> submitAppeal({
    required String submissionId,
    required String reason,
    String? evidenceText,
  }) async {
    await apiClient.post(
      '/appeals/submissions/$submissionId',
      data: {
        'reason': reason,
        'evidence_text': evidenceText,
      },
    );
  }
}

class PayoutService {
  final ApiClient apiClient;

  PayoutService({required this.apiClient});

  Future<PayoutVoucherModel> getVoucher(String submissionId) async {
    final response = await apiClient.get('/payouts/submissions/$submissionId/voucher');
    return PayoutVoucherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> recordClaimOnChain({
    required String submissionId,
    required String claimTxHash,
  }) async {
    final response = await apiClient.post(
      '/payouts/submissions/$submissionId/claim',
      data: {'claim_tx_hash': claimTxHash},
    );
    final data = response.data as Map<String, dynamic>;
    return data['claim_tx_hash'] as String? ?? claimTxHash;
  }
}

class NotificationService {
  final ApiClient apiClient;

  NotificationService({required this.apiClient});

  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.get('/notifications');
    final data = response.data;
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map && data['items'] is List) {
      items = data['items'] as List;
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map((n) => NotificationModel.fromJson(n))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await apiClient.put('/notifications/$id/read');
  }
}
