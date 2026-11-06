import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/models/account_status.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../../common/students/student_profile.dart';
import '../../home/presentation/student_home_providers.dart';
import 'profile_providers.dart';

/// Read-only: only the hostel admin can change a student's details.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message: "You'll need your email and password to sign in again.",
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (ok) await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.colors;
    final profile = ref.watch(myProfileProvider);
    final email = ref.watch(studentHomeProvider).value?.email;

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: p.primary,
            child: Stack(
              children: [
                Positioned(
                  right: -90,
                  top: -110,
                  child: Container(width: 240, height: 240, decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: AppTopBar(
                    title: 'My profile',
                    showBack: true,
                    backgroundColor: Colors.transparent,
                    foregroundColor: p.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -48),
              child: AsyncValueView(
                value: profile,
                onRetry: () => ref.invalidate(myProfileProvider),
                data: (s) => _Body(
                  profile: s,
                  email: s.email ?? email,
                  onSignOut: () => _signOut(context, ref),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile, required this.email, required this.onSignOut});

  final StudentProfile profile;
  final String? email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    return ScreenList(
      gap: 16,
      children: [
        AppCard(
          lifted: true,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.surface, width: 5)),
                child: PersonAvatar(name: profile.name, imageKey: profile.imageKey, imageUrl: profile.imageUrl, size: 96),
              ),
              const SizedBox(height: 10),
              Text(profile.name, style: t.title, textAlign: TextAlign.center),
              if (email != null) Text(email!, style: t.small),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (profile.status == AccountStatus.active) const StatusBadge(label: 'Active', tone: Tone.success),
                  if (profile.roomNumber != null)
                    StatusBadge(label: 'Room ${profile.roomNumber}', tone: Tone.primary, showDot: false),
                ],
              ),
            ],
          ),
        ),
        GroupedCard(children: [
          InfoRow(icon: Icons.badge_outlined, label: 'Roll number', value: profile.rollNumber),
          InfoRow(icon: Icons.school_outlined, label: 'Department', value: profile.departmentName ?? '—'),
          InfoRow(icon: Icons.call_outlined, label: 'My phone', value: profile.contactNumber.asPhone),
          InfoRow(
            icon: Icons.family_restroom_outlined,
            tone: Tone.accent,
            label: "Parent's phone",
            value: profile.parentMobileNumber.asPhone,
          ),
        ]),
        Text('Something wrong? Ask your hostel office to update it.', textAlign: TextAlign.center, style: t.small),
        GroupedCard(children: [
          ListTile(
            minTileHeight: 60,
            leading: const IconTile(icon: Icons.lock_outline_rounded, tone: Tone.neutral),
            title: Text('Change password', style: t.label),
            trailing: Icon(Icons.chevron_right_rounded, color: p.subtle),
            onTap: () => context.push(Routes.studentChangePassword),
          ),
          ListTile(
            minTileHeight: 60,
            leading: const IconTile(icon: Icons.logout_rounded, tone: Tone.danger),
            title: Text('Sign out', style: t.label.copyWith(color: p.dangerInk)),
            onTap: onSignOut,
          ),
        ]),
      ],
    );
  }
}
