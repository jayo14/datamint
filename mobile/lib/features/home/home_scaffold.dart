import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';
import '../profile/profile_screen.dart';
import '../tasks/tasks_screen.dart';
import '../wallet/wallet_screen.dart';
import 'home_tab.dart';

class HomeScaffold extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScaffold({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(onGoToTasks: () => setState(() => _currentTabIndex = 1)),
      const TasksScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: pages,
            ),
            // Floating Glass Tab Bar at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: MintFloatingTabBar(
                  currentIndex: _currentTabIndex,
                  onTabSelected: (index) {
                    setState(() => _currentTabIndex = index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
