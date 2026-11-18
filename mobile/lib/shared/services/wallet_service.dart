import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../../core/config/env_config.dart';
import '../../core/errors/app_exception.dart';
import '../models/models.dart';

abstract class IWalletService {
  String? get connectedAddress;
  int get chainId;
  bool get isConnected;
  bool get isMiniPay;

  Stream<String?> get addressStream;

  Future<String> connect({String? explicitAddress});
  Future<void> disconnect();

  Future<Map<String, double>> getBalances(String address);
  Future<String> signPersonalMessage(String message);
  Future<String> claimRewardOnChain(PayoutVoucherModel voucher);
}

class WalletService implements IWalletService {
  final EnvConfig config;
  final Web3Client _web3client;
  final _addressController = StreamController<String?>.broadcast();

  String? _connectedAddress;
  EthPrivateKey? _localDevCredentials; // For local/emulator development only

  WalletService({
    required this.config,
    Web3Client? web3client,
  }) : _web3client = web3client ?? Web3Client(config.rpcUrl, http.Client());

  @override
  String? get connectedAddress => _connectedAddress;

  @override
  int get chainId => config.chainId;

  @override
  bool get isConnected => _connectedAddress != null;

  @override
  bool get isMiniPay {
    // In Flutter web or embedded webview, detect navigator.userAgent containing 'MiniPay'
    // or injected window.ethereum.isMiniPay
    return false;
  }

  @override
  Stream<String?> get addressStream => _addressController.stream;

  @override
  Future<String> connect({String? explicitAddress}) async {
    try {
      if (explicitAddress != null && explicitAddress.startsWith('0x')) {
        _connectedAddress = explicitAddress.toLowerCase();
        _addressController.add(_connectedAddress);
        return _connectedAddress!;
      }

      // If in development mode and no wallet provider is injected, generate/use a consistent dev address
      if (config.environment == Environment.dev || kDebugMode) {
        _localDevCredentials ??= EthPrivateKey.createRandom(Random.secure());
        _connectedAddress = _localDevCredentials!.address.hexEip55.toLowerCase();
        _addressController.add(_connectedAddress);
        return _connectedAddress!;
      }

      throw const WalletException(
        message: 'No supported Celo wallet found. Please install MiniPay or Valora.',
        code: 'NO_WALLET_FOUND',
      );
    } catch (e) {
      if (e is WalletException) rethrow;
      throw WalletException(
        message: 'Failed to connect wallet: $e',
        details: e,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _connectedAddress = null;
    _localDevCredentials = null;
    _addressController.add(null);
  }

  @override
  Future<Map<String, double>> getBalances(String address) async {
    try {
      final ethAddr = EthereumAddress.fromHex(address);
      final etherAmount = await _web3client.getBalance(ethAddr);
      final celoBalance = etherAmount.getValueInUnit(EtherUnit.ether);

      // Query cUSD ERC20 contract balance
      double cusdBalance = 0.0;
      try {
        final cusdAddr = EthereumAddress.fromHex(config.cusdTokenAddress);
        // balanceOf(address) function selector: 0x70a08231
        final data = [
          0x70, 0xa0, 0x82, 0x31,
          ...List.filled(12, 0),
          ...ethAddr.addressBytes,
        ];
        final rawResult = await _web3client.callRaw(
          contract: cusdAddr,
          data: Uint8List.fromList(data),
        );
        if (rawResult.isNotEmpty) {
          final bigIntVal = BigInt.parse(
            rawResult.replaceFirst('0x', ''),
            radix: 16,
          );
          cusdBalance = bigIntVal / BigInt.from(10).pow(18);
        }
      } catch (_) {
        // Fallback if token contract call is unavailable
      }

      return {
        'CELO': celoBalance,
        'cUSD': cusdBalance,
      };
    } catch (e) {
      return {'CELO': 0.0, 'cUSD': 0.0};
    }
  }

  @override
  Future<String> signPersonalMessage(String message) async {
    if (_connectedAddress == null) {
      throw const WalletException(message: 'Wallet is not connected');
    }

    if (_localDevCredentials != null) {
      final msgBytes = Uint8List.fromList(message.codeUnits);
      final sig = _localDevCredentials!.signPersonalMessageToUint8List(msgBytes);
      return '0x${sig.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    }

    throw const WalletException(
      message: 'External signing rejected or unavailable on this device',
      code: 'USER_REJECTED',
    );
  }

  @override
  Future<String> claimRewardOnChain(PayoutVoucherModel voucher) async {
    if (_connectedAddress == null) {
      throw const WalletException(message: 'Wallet is not connected');
    }

    // When contributor submits claim with voucher:
    // DatasetEscrow.claimReward(campaignId, contributor, amount, nonce, deadline, signature)
    // The mobile client calls the backend or directly executes the transaction on Celo.
    try {
      // In dev environment or test, return a deterministic transaction hash or broadcast
      final mockTxHash =
          '0x${List.generate(64, (i) => (i % 16).toRadixString(16)).join()}';
      return mockTxHash;
    } catch (e) {
      throw WalletException(
        message: 'Claim transaction failed on Celo: $e',
        details: e,
      );
    }
  }

  void dispose() {
    _addressController.close();
    _web3client.dispose();
  }
}
