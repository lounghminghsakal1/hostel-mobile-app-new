import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/announcements/presentation/announcement_card.dart';
import '../../../common/events/presentation/event_widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../fees/presentation/fees_providers.dart';
import '../../leave/presentation/student_leave_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/student_home.dart';
import 'student_home_providers.dart';
import 'widgets/attendance_card.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  /// Home stays in memory behind the other tabs, so reload it when the app
  /// comes back to the foreground: new notices, the attendance window opening.
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(studentHomeProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // start listening
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(studentHomeProvider);
    final profile = ref.watch(myProfileProvider).value;
    final t = context.text;
    final name = profile?.name ?? home.value?.email.split('@').first ?? '';

    return Scaffold(
      appBar: AppTopBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppDates.greeting()},', style: t.small.copyWith(fontWeight: FontWeight.w600)),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title),
          ],
        ),
        actions: [
          AppIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notices',
            showDot: (home.value?.announcements.isNotEmpty ?? false),
            onPressed: () => context.go(Routes.studentNotices),
          ),
          Semantics(
            button: true,
            label: 'My profile',
            child: GestureDetector(
              onTap: () => context.push(Routes.profile),
              child: PersonAvatar(name: name.isEmpty ? '?' : name, imageUrl: profile?.imageUrl, size: 44),
            ),
          ),
        ],
      ),
      body: AsyncValueView(
        value: home,
        onRetry: () => ref.invalidate(studentHomeProvider),
        data: (data) => _HomeBody(home: data),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.home});

  final StudentHome home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardState = ref.watch(attendanceCardStateProvider) ?? AttendanceCardState.notOpenYet;
    final pendingLeave = ref.watch(pendingLeaveProvider);
    final dueBill = ref.watch(dueBillProvider);
    final t = context.text;

    final leaveTile = AppCard(
      onTap: () => pendingLeave == null
          ? context.push(Routes.applyLeave)
          : context.push(Routes.leaveDetail(pendingLeave.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(icon: Icons.event_note_outlined),
          const SizedBox(height: 10),
          if (pendingLeave == null) ...[
            Text('Leave', style: t.caption),
            const SizedBox(height: 4),
            Text('Apply for leave', style: t.label),
          ] else ...[
            Text('Leave · ${pendingLeave.rangeLabel}', style: t.caption),
            const SizedBox(height: 6),
            const StatusBadge(label: 'Pending', tone: Tone.warning),
          ],
        ],
      ),
    );

    return ScreenList(
      gap: 22,
      onRefresh: () async {
        ref.invalidate(studentHomeProvider);
        ref.invalidate(myLeavesProvider);
        await ref.read(studentHomeProvider.future);
      },
      children: [
        AttendanceCard(
          state: cardState,
          home: home,
          checkIn: ref.watch(todayCheckInProvider),
          onMark: () => context.push(Routes.markAttendance),
        ),
        Row(
          children: [
            Expanded(child: leaveTile),
            if (dueBill != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  onTap: () => context.go(Routes.fees),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(icon: Icons.restaurant_outlined, tone: Tone.accent),
                      const SizedBox(height: 10),
                      Text('Mess fee · Due ${AppDates.dayMonth(dueBill.lastDate)}', style: t.caption),
                      const SizedBox(height: 4),
                      Text(dueBill.amount.asRupees, style: t.number.copyWith(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Announcements',
              actionLabel: 'See all',
              onAction: () => context.go(Routes.studentNotices),
            ),
            const SizedBox(height: 4),
            if (home.announcements.isEmpty)
              AppCard(child: Text('No announcements today. Enjoy the quiet!', style: t.small))
            else
              for (final a in home.announcements.take(3)) ...[
                AnnouncementCard(
                  announcement: a,
                  compact: true,
                  onTap: () => context.push(Routes.studentAnnouncement(a.id)),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: 'Upcoming events',
              actionLabel: 'See all',
              onAction: () => context.go(Routes.studentNotices, extra: 1),
            ),
            const SizedBox(height: 4),
            if (home.events.isEmpty)
              AppCard(child: Text('No events planned yet. Check back soon.', style: t.small))
            else
              SizedBox(
                height: 186,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: home.events.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => EventCard(
                    event: home.events[i],
                    width: 250,
                    coverHeight: 104,
                    onTap: () => context.push(Routes.studentEvent(home.events[i].id)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
