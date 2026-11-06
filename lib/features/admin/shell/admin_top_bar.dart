import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../account/presentation/account_sheet.dart';
import '../home/presentation/admin_providers.dart';

/// Top bar for the admin tabs, with the avatar that opens the account sheet.
class AdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const AdminTopBar({super.key, required this.title, this.subtitle, this.titleWidget, this.actions = const []});

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(adminProfileProvider).value?.name ?? 'Warden';
    return AppTopBar(
      title: title,
      subtitle: subtitle,
      titleWidget: titleWidget,
      actions: [
        ...actions,
        Semantics(
          button: true,
          label: 'Account menu',
          child: GestureDetector(
            onTap: () => showAdminAccountSheet(context),
            child: InitialsAvatar(name: name, size: 44),
          ),
        ),
      ],
    );
  }
}
