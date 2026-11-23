import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/widgets/mint_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _newTasksEnabled = true;
  bool _paymentsEnabled = true;
  bool _streaksEnabled = false;
  bool _biometricEnabled = true;

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
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1F18),
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Account section
                  const Text(
                    'Account',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD5EDE2)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Phone', '+234 803 123 4567'),
                        const Divider(height: 16, color: Color(0xFFF0F7F4)),
                        _buildRow('Payout wallet', 'MiniPay'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Notifications section
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD5EDE2)),
                    ),
                    child: Column(
                      children: [
                        _buildToggle(
                          'New tasks for me',
                          _newTasksEnabled,
                          (v) => setState(() => _newTasksEnabled = v),
                        ),
                        const Divider(height: 16, color: Color(0xFFF0F7F4)),
                        _buildToggle(
                          'Payments and payouts',
                          _paymentsEnabled,
                          (v) => setState(() => _paymentsEnabled = v),
                        ),
                        const Divider(height: 16, color: Color(0xFFF0F7F4)),
                        _buildToggle(
                          'Streak reminders',
                          _streaksEnabled,
                          (v) => setState(() => _streaksEnabled = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Privacy section
                  const Text(
                    'Privacy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD5EDE2)),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening recordings and photos manager')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Manage my recordings and photos',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFF0D1F18),
                                  ),
                                ),
                                Icon(
                                  Symbols.chevron_right,
                                  size: 20,
                                  color: Color(0xFF3F5F52),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 16, color: Color(0xFFF0F7F4)),
                        _buildToggle(
                          'Biometric lock',
                          _biometricEnabled,
                          (v) => setState(() => _biometricEnabled = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  MintButton(
                    label: 'Sign out',
                    isGhost: true,
                    onPressed: () {
                      context.go('/auth/welcome');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _showDeleteAccountDialog(context);
                    },
                    child: const Text(
                      'Delete account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB3261E),
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

  Widget _buildRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF0D1F18),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0B9E6B),
            activeTrackColor: const Color(0xFF74E3B6),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your DataMint account? Any remaining balance will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/auth/welcome');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
  }
}
