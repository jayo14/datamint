import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/widgets/mint_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Earnings, 2: Cash outs

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 20,
              child: MintBackButton(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            Positioned.fill(
              top: 70,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1F18),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      MintChip(
                        label: 'All',
                        isSelected: _selectedFilter == 0,
                        onTap: () => setState(() => _selectedFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      MintChip(
                        label: 'Earnings',
                        isSelected: _selectedFilter == 1,
                        onTap: () => setState(() => _selectedFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      MintChip(
                        label: 'Cash outs',
                        isSelected: _selectedFilter == 2,
                        onTap: () => setState(() => _selectedFilter = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Monthly summary card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF74E3B6),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This month',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF12402F),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '+18.40 cUSD',
                              style: TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 34,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D1F18),
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        // Bar chart visualization
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar(18, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(30, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(22, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(40, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(26, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(34, const Color(0x590D1F18)),
                            const SizedBox(width: 5),
                            _buildBar(48, const Color(0xFF0D1F18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Today group
                  if (_selectedFilter != 2) ...[
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3F5F52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildHistoryItem(
                      icon: Symbols.mic,
                      iconBg: const Color(0xFF74E3B6),
                      title: 'Voice task',
                      subtitle: '10:42 · Approved',
                      amount: '+0.50',
                      onTap: () => context.push('/receipt'),
                    ),
                    _buildHistoryItem(
                      icon: Symbols.photo_camera,
                      iconBg: const Color(0xFFFFF1B8),
                      title: 'Image task',
                      subtitle: '09:15 · Approved',
                      amount: '+0.35',
                      onTap: () => context.push('/receipt'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Yesterday group
                  const Text(
                    'Yesterday',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFilter != 1)
                    _buildHistoryItem(
                      icon: Symbols.south_west,
                      iconBg: Colors.white,
                      title: 'Cash out to MiniPay',
                      subtitle: '18:20 · Sent',
                      amount: '−5.00',
                      isNegative: true,
                    ),
                  if (_selectedFilter != 2)
                    _buildHistoryItem(
                      icon: Symbols.text_fields,
                      iconBg: const Color(0xFFD9F3FF),
                      title: 'Pidgin translation pack',
                      subtitle: '11:05 · Approved',
                      amount: '+2.00',
                      onTap: () => context.push('/receipt'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String amount,
    bool isNegative = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                border: iconBg == Colors.white
                    ? Border.all(color: const Color(0xFFD5EDE2))
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF0D1F18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1F18),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isNegative ? const Color(0xFFB3261E) : const Color(0xFF0D1F18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
