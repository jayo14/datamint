import 'package:flutter_test/flutter_test.dart';
import 'package:datamint_mobile/core/config/env_config.dart';
import 'package:datamint_mobile/shared/services/wallet_service.dart';

void main() {
  group('WalletService on Celo', () {
    late WalletService walletService;

    setUp(() {
      walletService = WalletService(config: EnvConfig.dev);
    });

    tearDown(() {
      walletService.dispose();
    });

    test('connects and returns valid Ethereum hex address', () async {
      expect(walletService.isConnected, isFalse);

      final address = await walletService.connect();

      expect(walletService.isConnected, isTrue);
      expect(address.startsWith('0x'), isTrue);
      expect(address.length, 42); // 0x + 40 hex chars
      expect(walletService.connectedAddress, address);
    });

    test('connects with explicit address', () async {
      const customAddr = '0x71c67d5e1d346644578325039B642710A477dFB0';
      final address = await walletService.connect(explicitAddress: customAddr);

      expect(address, customAddr.toLowerCase());
      expect(walletService.connectedAddress, customAddr.toLowerCase());
    });

    test('signs personal message for SIWE authentication', () async {
      await walletService.connect();

      const message = 'datamint.ai wants you to sign in with your Ethereum account:\n0x...';
      final signature = await walletService.signPersonalMessage(message);

      expect(signature.startsWith('0x'), isTrue);
      expect(signature.length, greaterThan(64));
    });

    test('disconnect resets address and state', () async {
      await walletService.connect();
      expect(walletService.isConnected, isTrue);

      await walletService.disconnect();
      expect(walletService.isConnected, isFalse);
      expect(walletService.connectedAddress, isNull);
    });
  });
}
