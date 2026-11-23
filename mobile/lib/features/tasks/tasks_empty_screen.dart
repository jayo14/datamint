import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class TasksEmptyScreen extends StatelessWidget {
  const TasksEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 31,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  MintBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const Spacer(),

              // Empty Graphic with Coin and Glow
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFFB6F5D9), Colors.transparent],
                          stops: [0.0, 0.7],
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: -10 * math.pi / 180,
                      child: const MintDCoin(size: 120),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'You’re all caught up',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New tasks open throughout the day. We’ll let you know the moment one matches how you speak.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              MintButton(
                label: 'Notify me',
                icon: Symbols.notifications,
                width: 180,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications enabled for new tasks!')),
                  );
                },
              ),
              const SizedBox(height: 8),
              MintButton(
                label: 'See completed tasks',
                variant: MintButtonVariant.text,
                onPressed: () => context.push('/history'),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
