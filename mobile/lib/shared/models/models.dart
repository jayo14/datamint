import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String email;
  final String role; // "BOTH", "CONTRIBUTOR", "CREATOR"
  final String? displayName;
  final String? primaryWallet;
  final bool isVerified;
  final double reputationScore;
  final int totalSubmissions;
  final int approvedSubmissions;
  final double totalEarnedCusd;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.primaryWallet,
    this.isVerified = false,
    this.reputationScore = 1.0,
    this.totalSubmissions = 0,
    this.approvedSubmissions = 0,
    this.totalEarnedCusd = 0.0,
    required this.createdAt,
  });

  bool get canContribute => role == 'BOTH' || role == 'CONTRIBUTOR';
  bool get canCreate => role == 'BOTH' || role == 'CREATOR';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String? ?? 'BOTH').toUpperCase(),
      displayName: json['display_name'] as String?,
      primaryWallet: json['primary_wallet'] as String? ?? json['wallet_address'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      reputationScore: (json['reputation_score'] as num?)?.toDouble() ?? 1.0,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      approvedSubmissions: json['approved_submissions'] as int? ?? 0,
      totalEarnedCusd: (json['total_earned_cusd'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'display_name': displayName,
      'primary_wallet': primaryWallet,
      'is_verified': isVerified,
      'reputation_score': reputationScore,
      'total_submissions': totalSubmissions,
      'approved_submissions': approvedSubmissions,
      'total_earned_cusd': totalEarnedCusd,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class WalletModel {
  final String address;
  final int chainId;
  final bool isPrimary;
  final DateTime? verifiedAt;

  const WalletModel({
    required this.address,
    required this.chainId,
    this.isPrimary = false,
    this.verifiedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'] as String? ?? '',
      chainId: json['chain_id'] as int? ?? 44787,
      isPrimary: json['is_primary'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'chain_id': chainId,
        'is_primary': isPrimary,
        'verified_at': verifiedAt?.toIso8601String(),
      };
}

@immutable
class CampaignModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String dataType; // "TEXT", "VOICE", "IMAGE"
  final double rewardPerSubmission;
  final double remainingBudget;
  final double totalBudget;
  final int minSubmissions;
  final int maxSubmissions;
  final int totalSubmissions;
  final int approvedSubmissions;
  final String status; // "DRAFT", "PUBLISHED", "ACTIVE", "PAUSED", "COMPLETED"
  final String creatorId;
  final String? instructions;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> validationPolicy;
  final DateTime? deadline;
  final String? onchainCampaignId;
  final String? escrowAddress;
  final DateTime createdAt;

  const CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dataType,
    required this.rewardPerSubmission,
    required this.remainingBudget,
    required this.totalBudget,
    this.minSubmissions = 1,
    this.maxSubmissions = 100,
    this.totalSubmissions = 0,
    this.approvedSubmissions = 0,
    required this.status,
    required this.creatorId,
    this.instructions,
    this.requirements = const {},
    this.validationPolicy = const {},
    this.deadline,
    this.onchainCampaignId,
    this.escrowAddress,
    required this.createdAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'PUBLISHED';

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      dataType: (json['data_type'] as String? ?? 'TEXT').toUpperCase(),
      rewardPerSubmission: (json['reward_per_submission'] as num?)?.toDouble() ?? 0.0,
      remainingBudget: (json['remaining_budget'] as num?)?.toDouble() ?? 0.0,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      minSubmissions: json['min_submissions'] as int? ?? 1,
      maxSubmissions: json['max_submissions'] as int? ?? 100,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      approvedSubmissions: json['approved_submissions'] as int? ?? 0,
      status: (json['status'] as String? ?? 'DRAFT').toUpperCase(),
      creatorId: json['creator_id'] as String? ?? '',
      instructions: json['instructions'] as String?,
      requirements: json['requirements'] is Map
          ? Map<String, dynamic>.from(json['requirements'] as Map)
          : {},
      validationPolicy: json['validation_policy'] is Map
          ? Map<String, dynamic>.from(json['validation_policy'] as Map)
          : {},
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      onchainCampaignId: json['onchain_campaign_id'] as String?,
      escrowAddress: json['escrow_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'data_type': dataType,
        'reward_per_submission': rewardPerSubmission,
        'remaining_budget': remainingBudget,
        'total_budget': totalBudget,
        'min_submissions': minSubmissions,
        'max_submissions': maxSubmissions,
        'total_submissions': totalSubmissions,
        'approved_submissions': approvedSubmissions,
        'status': status,
        'creator_id': creatorId,
        'instructions': instructions,
        'requirements': requirements,
        'validation_policy': validationPolicy,
        'deadline': deadline?.toIso8601String(),
        'onchain_campaign_id': onchainCampaignId,
        'escrow_address': escrowAddress,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class ValidationFinding {
  final String checkName;
  final bool passed;
  final double confidence;
  final String severity; // "INFO", "WARNING", "ERROR"
  final String? details;

  const ValidationFinding({
    required this.checkName,
    required this.passed,
    this.confidence = 1.0,
    this.severity = 'INFO',
    this.details,
  });

  factory ValidationFinding.fromJson(Map<String, dynamic> json) {
    return ValidationFinding(
      checkName: json['check_name'] as String? ?? json['name'] as String? ?? '',
      passed: json['passed'] as bool? ?? (json['status'] == 'PASSED'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      severity: (json['severity'] as String? ?? 'INFO').toUpperCase(),
      details: json['details'] as String? ?? json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'check_name': checkName,
        'passed': passed,
        'confidence': confidence,
        'severity': severity,
        'details': details,
      };
}

@immutable
class SubmissionModel {
  final String id;
  final String campaignId;
  final String contributorId;
  final String status; // "DRAFT", "SUBMITTED", "PENDING_VALIDATION", "APPROVED", "REJECTED", "HUMAN_REVIEW", "APPEALED", "PAID"
  final String? textContent;
  final String? assetKey;
  final String? assetUrl;
  final String? mediaType;
  final double? durationSeconds;
  final double? validationScore;
  final List<ValidationFinding> findings;
  final String? humanReviewNotes;
  final double? rewardAmount;
  final String? claimTxHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubmissionModel({
    required this.id,
    required this.campaignId,
    required this.contributorId,
    required this.status,
    this.textContent,
    this.assetKey,
    this.assetUrl,
    this.mediaType,
    this.durationSeconds,
    this.validationScore,
    this.findings = const [],
    this.humanReviewNotes,
    this.rewardAmount,
    this.claimTxHash,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'PAID';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get inReview => status.toUpperCase() == 'HUMAN_REVIEW';
  bool get canAppeal => isRejected;
  bool get canClaim => isApproved && (claimTxHash == null || claimTxHash!.isEmpty);

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final rawFindings = json['findings'] ?? json['validation_findings'];
    List<ValidationFinding> parsedFindings = [];
    if (rawFindings is List) {
      parsedFindings = rawFindings
          .whereType<Map<String, dynamic>>()
          .map((f) => ValidationFinding.fromJson(f))
          .toList();
    }

    return SubmissionModel(
      id: json['id'] as String? ?? '',
      campaignId: json['campaign_id'] as String? ?? '',
      contributorId: json['contributor_id'] as String? ?? '',
      status: (json['status'] as String? ?? 'DRAFT').toUpperCase(),
      textContent: json['text_content'] as String?,
      assetKey: json['asset_key'] as String?,
      assetUrl: json['asset_url'] as String?,
      mediaType: json['media_type'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble(),
      validationScore: (json['validation_score'] as num?)?.toDouble(),
      findings: parsedFindings,
      humanReviewNotes: json['human_review_notes'] as String?,
      rewardAmount: (json['reward_amount'] as num?)?.toDouble(),
      claimTxHash: json['claim_tx_hash'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_id': campaignId,
        'contributor_id': contributorId,
        'status': status,
        'text_content': textContent,
        'asset_key': assetKey,
        'asset_url': assetUrl,
        'media_type': mediaType,
        'duration_seconds': durationSeconds,
        'validation_score': validationScore,
        'findings': findings.map((f) => f.toJson()).toList(),
        'human_review_notes': humanReviewNotes,
        'reward_amount': rewardAmount,
        'claim_tx_hash': claimTxHash,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

@immutable
class ReviewQueueItem {
  final String submissionId;
  final String campaignId;
  final String campaignTitle;
  final String contributorAddress;
  final String dataType;
  final String? textContent;
  final String? assetUrl;
  final String flagReason;
  final double aiScore;
  final List<ValidationFinding> findings;
  final DateTime submittedAt;

  const ReviewQueueItem({
    required this.submissionId,
    required this.campaignId,
    required this.campaignTitle,
    required this.contributorAddress,
    required this.dataType,
    this.textContent,
    this.assetUrl,
    required this.flagReason,
    this.aiScore = 0.5,
    this.findings = const [],
    required this.submittedAt,
  });

  factory ReviewQueueItem.fromJson(Map<String, dynamic> json) {
    final rawFindings = json['findings'];
    List<ValidationFinding> parsedFindings = [];
    if (rawFindings is List) {
      parsedFindings = rawFindings
          .whereType<Map<String, dynamic>>()
          .map((f) => ValidationFinding.fromJson(f))
          .toList();
    }

    return ReviewQueueItem(
      submissionId: json['submission_id'] as String? ?? json['id'] as String? ?? '',
      campaignId: json['campaign_id'] as String? ?? '',
      campaignTitle: json['campaign_title'] as String? ?? 'Dataset Campaign',
      contributorAddress: json['contributor_address'] as String? ?? '0x...',
      dataType: (json['data_type'] as String? ?? 'TEXT').toUpperCase(),
      textContent: json['text_content'] as String?,
      assetUrl: json['asset_url'] as String?,
      flagReason: json['flag_reason'] as String? ?? 'Requires human verification',
      aiScore: (json['ai_score'] as num?)?.toDouble() ?? 0.5,
      findings: parsedFindings,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

@immutable
class PayoutVoucherModel {
  final String campaignId; // bytes32 hex
  final String contributor; // Ethereum address
  final String amount; // raw string wei / cusd
  final int nonce;
  final int deadline;
  final String signature; // 0x hex
  final String contractAddress;
  final int chainId;

  const PayoutVoucherModel({
    required this.campaignId,
    required this.contributor,
    required this.amount,
    required this.nonce,
    required this.deadline,
    required this.signature,
    required this.contractAddress,
    required this.chainId,
  });

  factory PayoutVoucherModel.fromJson(Map<String, dynamic> json) {
    return PayoutVoucherModel(
      campaignId: json['campaign_id'] as String? ?? json['campaignId'] as String? ?? '',
      contributor: json['contributor'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0',
      nonce: json['nonce'] as int? ?? 0,
      deadline: json['deadline'] as int? ?? 0,
      signature: json['signature'] as String? ?? '',
      contractAddress: json['contract_address'] as String? ?? json['contractAddress'] as String? ?? '',
      chainId: json['chain_id'] as int? ?? json['chainId'] as int? ?? 44787,
    );
  }

  Map<String, dynamic> toJson() => {
        'campaign_id': campaignId,
        'contributor': contributor,
        'amount': amount,
        'nonce': nonce,
        'deadline': deadline,
        'signature': signature,
        'contract_address': contractAddress,
        'chain_id': chainId,
      };
}

@immutable
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: (json['type'] as String? ?? 'SYSTEM').toUpperCase(),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'data': data,
      };
}
