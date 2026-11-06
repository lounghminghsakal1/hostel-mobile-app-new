import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../home/presentation/admin_providers.dart';

/// Opened from the avatar on admin screens: mess bills, hostel settings,
/// change password and sign out.
Future<void> showAdminAccountSheet(BuildContext context) {
  return showAppSheet<void>(context, builder: (_) => const _AccountSheet());
}

class _AccountSheet extends ConsumerWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    final p = context.colors;
    final profile = ref.watch(adminProfileProvider).value;
    final email = ref.watch(currentUserProvider)?.email;

    void go(String route) {
      Navigator.of(context).pop();
      context.push(route);
    }

    Widget row(IconData icon, Tone tone, String title, String? subtitle, String route) => ListTile(
          minTileHeight: 62,
          leading: IconTile(icon: icon, tone: tone),
          title: Text(title, style: t.label),
          subtitle: subtitle == null ? null : Text(subtitle, style: t.small),
          trailing: Icon(Icons.chevron_right_rounded, color: p.subtle),
          onTap: () => go(route),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            InitialsAvatar(name: profile?.name ?? 'Warden', size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.name ?? 'Warden', style: t.heading),
                  Text('Warden · ${profile?.hostelName ?? ''}', style: t.small),
                  if (email != null) Text(email, style: t.small),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GroupedCard(children: [
          row(Icons.restaurant_outlined, Tone.accent, 'Mess bills', 'Create and publish monthly bills', Routes.messBills),
          row(Icons.apartment_rounded, Tone.primary, 'Hostel settings', 'Attendance window and radius', Routes.hostelSettings),
          row(Icons.lock_outline_rounded, Tone.neutral, 'Change password', null, Routes.adminChangePassword),
        ]),
        const SizedBox(height: 16),
        AppButton(
          label: 'Sign out',
          icon: Icons.logout_rounded,
          variant: ButtonVariant.danger,
          expand: true,
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Sign out?',
              message: "You'll need your email and password to sign in again.",
              confirmLabel: 'Sign out',
              icon: Icons.logout_rounded,
              destructive: true,
            );
            if (ok) await ref.read(authControllerProvider.notifier).logout();
          },
        ),
        const SizedBox(height: 10),
        Text('${AppConfig.appName} 1.0', textAlign: TextAlign.center, style: t.caption),
      ],
    );
  }
}
