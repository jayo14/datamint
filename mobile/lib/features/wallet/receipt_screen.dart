import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/widgets/mint_components.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Bar
            Positioned(
              top: 14,
              left: 20,
              child: MintBackButton(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/history');
                  }
                },
              ),
            ),
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Receipt',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1F18),
                  ),
                ),
              ),
            ),
            // Main Content
            Positioned.fill(
              top: 70,
              bottom: 120,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF74E3B6),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Symbols.mic,
                        size: 32,
                        color: Color(0xFF0D1F18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAFBF3),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFF74E3B6)),
                      ),
                      child: const Text(
                        'PAID',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B9E6B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '+0.50 cUSD',
                      style: TextStyle(
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0D1F18),
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Key-Value Rows Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFD5EDE2)),
                      ),
                      child: Column(
                        children: [
                          _buildKvRow('Task', 'Short phrase · Yoruba'),
                          const Divider(height: 20, color: Color(0xFFF0F7F4)),
                          _buildKvRow('Builder', 'Verified builder'),
                          const Divider(height: 20, color: Color(0xFFF0F7F4)),
                          _buildKvRow('Validated by', 'GPT-4o'),
                          const Divider(height: 20, color: Color(0xFFF0F7F4)),
                          _buildKvRow('Date', 'Today, 10:42'),
                          const Divider(height: 20, color: Color(0xFFF0F7F4)),
                          _buildKvRow('Network', 'Celo'),
                          const Divider(height: 20, color: Color(0xFFF0F7F4)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transaction',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF3F5F52),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    const ClipboardData(
                                        text: '0x8a1c4e7f2b1d03a56e9c4b2a1f0d8e7c6b5a4d1e'),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transaction hash copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Text(
                                      '0x8a1c…d41e',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D1F18),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Symbols.content_copy,
                                      size: 18,
                                      color: Color(0xFF087A52),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Action Buttons
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MintButton(
                    label: 'View on Celo explorer',
                    trailingIcon: Symbols.open_in_new,
                    isGhost: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening https://celoscan.io/tx/0x8a1c…d41e'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support ticket created')),
                      );
                    },
                    child: const Text(
                      'Report a problem',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3F5F52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKvRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF3F5F52),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1F18),
          ),
        ),
      ],
    );
  }
}
