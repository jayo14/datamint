import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

enum Environment { dev, staging, production }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final int chainId;
  final String chainName;
  final String rpcUrl;
  final String escrowContractAddress;
  final String cusdTokenAddress;
  final String blockExplorerUrl;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.chainId,
    required this.chainName,
    required this.rpcUrl,
    required this.escrowContractAddress,
    required this.cusdTokenAddress,
    required this.blockExplorerUrl,
  });

  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:8000/api/v1';
  }

  static const EnvConfig dev = EnvConfig(
    environment: Environment.dev,
    apiBaseUrl: 'http://localhost:8000/api/v1',
    chainId: 44787, // Celo Alfajores Testnet
    chainName: 'Celo Alfajores',
    rpcUrl: 'https://alfajores-forno.celo-testnet.org',
    escrowContractAddress: '0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44',
    cusdTokenAddress: '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1',
    blockExplorerUrl: 'https://alfajores.celoscan.io',
  );

  static const EnvConfig staging = EnvConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.datamint.ai/api/v1',
    chainId: 44787,
    chainName: 'Celo Alfajores',
    rpcUrl: 'https://alfajores-forno.celo-testnet.org',
    escrowContractAddress: '0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44',
    cusdTokenAddress: '0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1',
    blockExplorerUrl: 'https://alfajores.celoscan.io',
  );

  static const EnvConfig production = EnvConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.datamint.ai/api/v1',
    chainId: 42220, // Celo Mainnet
    chainName: 'Celo Mainnet',
    rpcUrl: 'https://forno.celo.org',
    escrowContractAddress: '0x9999999999999999999999999999999999999999',
    cusdTokenAddress: '0x765DE816845861e75A25fCA122bb6898B8B1282a',
    blockExplorerUrl: 'https://celoscan.io',
  );
}
