import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/widgets/mint_components.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Offline banner pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1F18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Symbols.wifi_off,
                            color: Color(0xFF74E3B6),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'You’re offline',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Main offline illustration icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9F3FF),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(
                        Symbols.cloud_off,
                        size: 48,
                        color: Color(0xFF0D1F18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No connection',
                      style: TextStyle(
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1F18),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: 300,
                      child: Text(
                        'Anything you recorded is saved on your phone. We’ll upload it automatically when you’re back online.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF3F5F52),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    MintButton(
                      label: 'Try again',
                      icon: Symbols.refresh,
                      onPressed: () {
                        context.go('/home');
                      },
                    ),
                    const Spacer(),
                    // Cached queue info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD5EDE2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1B8),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Symbols.save,
                              color: Color(0xFF0D1F18),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '1 recording waiting',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D1F18),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Voice task · Yoruba',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF3F5F52),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
