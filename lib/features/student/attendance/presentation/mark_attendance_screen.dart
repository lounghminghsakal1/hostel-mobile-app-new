import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../home/presentation/student_home_providers.dart';
import 'attendance_providers.dart';

/// Selfie + location check-in. The phone's own camera takes the photo;
/// this screen frames it, shows the location status and submits.
class MarkAttendanceScreen extends ConsumerWidget {
  const MarkAttendanceScreen({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(markAttendanceControllerProvider.notifier).submit();
    if (outcome != null && context.mounted) {
      context.pushReplacement(Routes.attendanceResult, extra: outcome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(markAttendanceControllerProvider);
    final controller = ref.read(markAttendanceControllerProvider.notifier);
    final hostel = ref.watch(studentHomeProvider).value?.hostel;
    final p = context.colors;
    final t = context.text;
    final dark = p.ink;
    final located = state.location.hasValue;

    return Scaffold(
      backgroundColor: dark,
      appBar: AppTopBar(
        showBack: true,
        backIcon: Icons.close_rounded,
        backgroundColor: dark,
        foregroundColor: p.onPrimary,
        titleWidget: Text(
          'Mark attendance',
          textAlign: TextAlign.center,
          style: t.label.copyWith(color: p.onPrimary, fontSize: 16),
        ),
        actions: const [SizedBox(width: 44)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: p.onPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face_retouching_natural_outlined, size: 16, color: p.onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    state.selfie == null ? 'Fit your face inside the oval' : 'Looking good! Submit when ready.',
                    style: t.caption.copyWith(color: p.onPrimary, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _FaceFrame(
                  selfie: state.selfie,
                  ready: located,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                children: [
                  if (state.error != null) ...[
                    InfoCallout(message: state.error!.message, tone: Tone.danger, icon: Icons.error_outline_rounded),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _StatusCard(
                          title: state.location.isLoading
                              ? 'Finding you…'
                              : (located ? 'Location found' : 'Location needed'),
                          subtitle: state.location.when(
                            data: (_) => 'Ready to check in',
                            loading: () => 'Using GPS',
                            error: (e, _) => 'Tap to try again',
                          ),
                          ok: located,
                          loading: state.location.isLoading,
                          onTap: state.location.hasError ? controller.locate : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatusCard(
                          title: 'Daily window',
                          subtitle: hostel?.windowLabel ?? '—',
                          ok: true,
                          icon: Icons.schedule_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (state.location.hasError) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.location.error.toString(),
                      textAlign: TextAlign.center,
                      style: t.caption.copyWith(color: p.onPrimaryMuted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (state.selfie == null)
                    Semantics(
                      button: true,
                      label: 'Take selfie',
                      child: GestureDetector(
                        onTap: controller.takeSelfie,
                        child: Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.onPrimary, width: 4)),
                          child: Container(
                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                            child: Icon(Icons.photo_camera_outlined, size: 30, color: p.onAccent),
                          ),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Retake',
                            variant: ButtonVariant.light,
                            onPressed: state.submitting ? null : controller.takeSelfie,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: state.submitting ? 'Checking you in…' : 'Submit',
                            icon: Icons.check_rounded,
                            variant: ButtonVariant.accent,
                            loading: state.submitting,
                            onPressed: state.canSubmit ? () => _submit(context, ref) : null,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Text(
                    "Your photo is only used to verify tonight's attendance.",
                    textAlign: TextAlign.center,
                    style: t.caption.copyWith(color: p.onPrimaryMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceFrame extends StatelessWidget {
  const _FaceFrame({required this.selfie, required this.ready});

  final Uint8List? selfie;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      width: 240,
      height: 316,
      decoration: ShapeDecoration(
        shape: OvalBorder(side: BorderSide(color: ready ? p.success : p.onPrimary.withValues(alpha: 0.5), width: 3)),
        color: p.inkSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: selfie == null
          ? Icon(Icons.face_outlined, size: 120, color: p.onPrimary.withValues(alpha: 0.25))
          : Image.memory(selfie!, fit: BoxFit.cover),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.ok,
    this.loading = false,
    this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool ok;
  final bool loading;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final indicator = loading
        ? SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary))
        : icon != null
            ? Icon(icon, size: 18, color: p.success)
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: ok ? p.success : p.accent, shape: BoxShape.circle),
              );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.onPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.onPrimary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            indicator,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.caption.copyWith(color: p.onPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.caption.copyWith(color: p.onPrimaryMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
