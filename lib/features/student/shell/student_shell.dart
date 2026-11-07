import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/back_to_first_tab.dart';
import '../home/presentation/student_home_providers.dart';

/// Bottom navigation for students: Home, Leave, Notices, Fees.
/// Back on another tab returns to Home before closing the app.
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackToFirstTab(
      navigationShell: navigationShell,
      child: _scaffold(context, ref),
    );
  }

  void _select(int index, WidgetRef ref) {
    // Coming back to Home: reload it so notices posted meanwhile show up
    if (index == 0) ref.invalidate(studentHomeProvider);
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  Widget _scaffold(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => _select(i, ref),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'Leave'),
            NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Notices'),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Fees',
            ),
          ],
        ),
      ),
    );
  }
}
