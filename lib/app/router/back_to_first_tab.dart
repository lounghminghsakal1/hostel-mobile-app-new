import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Wraps a bottom-navigation shell so the Android back button on any tab
/// other than the first (Home) goes to Home instead of closing the app.
/// On Home, back closes the app as usual. Pages pushed on top of the tabs
/// (details, forms) still pop first.
class BackToFirstTab extends StatelessWidget {
  const BackToFirstTab({super.key, required this.navigationShell, required this.child});

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onFirstTab = navigationShell.currentIndex == 0;
    return PopScope(
      canPop: onFirstTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !onFirstTab) navigationShell.goBranch(0);
      },
      child: child,
    );
  }
}
