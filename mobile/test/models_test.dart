import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/shared/models/models.dart';

void main() {
  group('UserModel Serialization & Capabilities', () {
    test('deserializes user correctly and checks dual role capabilities', () {
      final json = {
        'id': 'usr-123',
        'email': 'contributor@datamint.ai',
        'role': 'BOTH',
        'display_name': 'Ayobami',
        'primary_wallet': '0x71c67d5e1d346644578325039B642710A477dFB0',
        'is_verified': true,
        'reputation_score': 4.8,
        'total_submissions': 25,
        'approved_submissions': 24,
        'total_earned_cusd': 120.0,
        'created_at': '2026-03-01T12:00:00Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'usr-123');
      expect(user.email, 'contributor@datamint.ai');
      expect(user.role, 'BOTH');
      expect(user.canContribute, isTrue);
      expect(user.canCreate, isTrue);
      expect(user.reputationScore, 4.8);
      expect(user.totalEarnedCusd, 120.0);

      final outJson = user.toJson();
      expect(outJson['email'], 'contributor@datamint.ai');
      expect(outJson['role'], 'BOTH');
    });

    test('contributor-only user canContribute=true and canCreate=false', () {
      final user = UserModel.fromJson({
        'id': 'usr-contrib',
        'email': 'only@contrib.com',
        'role': 'CONTRIBUTOR',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(user.canContribute, isTrue);
      expect(user.canCreate, isFalse);
    });
  });

  group('CampaignModel Serialization', () {
    test('deserializes campaign correctly and verifies active status', () {
      final json = {
        'id': 'camp-456',
        'title': 'Medical Audio Transcriptions',
        'description': 'Transcribe patient voice notes into clinical terminology',
        'category': 'Healthcare',
        'data_type': 'VOICE',
        'reward_per_submission': 2.50,
        'remaining_budget': 250.0,
        'total_budget': 500.0,
        'min_submissions': 1,
        'max_submissions': 200,
        'total_submissions': 100,
        'approved_submissions': 95,
        'status': 'ACTIVE',
        'creator_id': 'creator-99',
        'onchain_campaign_id': '0x0000000000000000000000000000000000000000000000000000000000000001',
        'created_at': '2026-02-15T10:00:00Z',
      };

      final campaign = CampaignModel.fromJson(json);

      expect(campaign.id, 'camp-456');
      expect(campaign.dataType, 'VOICE');
      expect(campaign.rewardPerSubmission, 2.50);
      expect(campaign.isActive, isTrue);
      expect(campaign.onchainCampaignId, isNotNull);
    });
  });

  group('SubmissionModel & Validation Findings', () {
    test('deserializes submission with nested validation findings and status checks', () {
      final json = {
        'id': 'sub-789',
        'campaign_id': 'camp-456',
        'contributor_id': 'usr-123',
        'status': 'APPROVED',
        'text_content': 'Patient exhibits mild respiratory symptoms',
        'validation_score': 0.94,
        'findings': [
          {
            'check_name': 'Format Integrity',
            'passed': true,
            'confidence': 1.0,
            'severity': 'INFO',
          },
          {
            'check_name': 'Instruction Compliance',
            'passed': true,
            'confidence': 0.94,
            'severity': 'INFO',
          }
        ],
        'reward_amount': 2.50,
        'claim_tx_hash': null,
        'created_at': '2026-03-02T14:00:00Z',
        'updated_at': '2026-03-02T14:05:00Z',
      };

      final sub = SubmissionModel.fromJson(json);

      expect(sub.id, 'sub-789');
      expect(sub.isApproved, isTrue);
      expect(sub.isRejected, isFalse);
      expect(sub.canClaim, isTrue);
      expect(sub.findings.length, 2);
      expect(sub.findings[0].passed, isTrue);
      expect(sub.findings[1].checkName, 'Instruction Compliance');
    });

    test('rejected submission allows appeal', () {
      final sub = SubmissionModel.fromJson({
        'id': 'sub-rej',
        'campaign_id': 'camp-1',
        'contributor_id': 'usr-1',
        'status': 'REJECTED',
        'created_at': '2026-03-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
      });

      expect(sub.isRejected, isTrue);
      expect(sub.canAppeal, isTrue);
      expect(sub.canClaim, isFalse);
    });
  });

  group('PayoutVoucherModel Serialization', () {
    test('deserializes EIP-712 payout voucher correctly', () {
      final json = {
        'campaign_id': '0x' + 'a' * 64,
        'contributor': '0x71c67d5e1d346644578325039B642710A477dFB0',
        'amount': '2500000000000000000', // 2.5 cUSD in wei
        'nonce': 1,
        'deadline': 1800000000,
        'signature': '0x' + 'f' * 130,
        'contract_address': '0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44',
        'chain_id': 44787,
      };

      final voucher = PayoutVoucherModel.fromJson(json);

      expect(voucher.contributor, '0x71c67d5e1d346644578325039B642710A477dFB0');
      expect(voucher.amount, '2500000000000000000');
      expect(voucher.nonce, 1);
      expect(voucher.chainId, 44787);
    });
  });
}
