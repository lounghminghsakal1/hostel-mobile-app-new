import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/back_to_first_tab.dart';

/// Bottom navigation for hostel admins: Home, Rooms, Leave, Students, Notices.
/// Mess bills, settings, password and sign out live in the account sheet.
/// Back on another tab returns to Home before closing the app.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BackToFirstTab(
      navigationShell: navigationShell,
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.bed_outlined), selectedIcon: Icon(Icons.bed_rounded), label: 'Rooms'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note_rounded), label: 'Leave'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Students'),
            NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Notices'),
          ],
        ),
      ),
    );
  }
}
