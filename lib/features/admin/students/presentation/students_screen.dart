import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/models/account_status.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../../common/students/student_profile.dart';
import '../../rooms/presentation/room_providers.dart';
import '../../shell/admin_top_bar.dart';
import 'admin_student_providers.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _search = '';
  int? _departmentId;
  int? _roomId;
  String? _roll;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final departments = ref.read(departmentsProvider).value ?? const [];
    final rooms = ref.read(allRoomsProvider).value ?? const [];
    final roll = TextEditingController(text: _roll);
    int? dep = _departmentId;
    int? room = _roomId;
    final applied = await showAppSheet<bool>(
      context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter students', style: context.text.title.copyWith(fontSize: 22)),
            const SizedBox(height: 18),
            LabeledField(
              label: 'Department',
              child: DropdownButtonFormField<int?>(
                initialValue: dep,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All departments')),
                  for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (v) => setSheet(() => dep = v),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Room',
              child: DropdownButtonFormField<int?>(
                initialValue: room,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All rooms')),
                  for (final r in rooms) DropdownMenuItem(value: r.id, child: Text(r.number)),
                ],
                onChanged: (v) => setSheet(() => room = v),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Roll number', controller: roll, hint: 'Exact roll number'),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: AppButton(
                  label: 'Clear',
                  variant: ButtonVariant.outline,
                  onPressed: () {
                    dep = null;
                    room = null;
                    roll.clear();
                    Navigator.of(sheetContext).pop(true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: AppButton(label: 'Apply', onPressed: () => Navigator.of(sheetContext).pop(true))),
            ]),
          ],
        ),
      ),
    );
    if (applied == true) {
      setState(() {
        _departmentId = dep;
        _roomId = room;
        _roll = roll.text.trim().isEmpty ? null : roll.text.trim();
      });
    }
    roll.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminStudentRepositoryProvider);
    final departmentNames = ref.watch(departmentNamesProvider);
    final roomNumbers = ref.watch(roomNumbersProvider);
    final activeFilters = [_departmentId, _roomId, _roll].where((v) => v != null).length;

    return Scaffold(
      appBar: const AdminTopBar(title: 'Students'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addStudent),
        backgroundColor: context.colors.accent,
        foregroundColor: context.colors.onAccent,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add student'),
      ),
      body: PagedList<StudentProfile>(
        query: (_search, _departmentId, _roomId, _roll),
        grouped: true,
        bottomPadding: 96,
        fetch: (page) => repo.list((
          search: _search.isEmpty ? null : _search,
          departmentId: _departmentId,
          roomId: _roomId,
          rollNumber: _roll,
          page: page,
        )),
        header: [
          Row(children: [
            Expanded(
              child: SearchField(
                controller: _searchController,
                hint: 'Search by name',
                onSearch: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 10),
            AppIconButton(
              icon: Icons.tune_rounded,
              tooltip: activeFilters == 0 ? 'Filters' : 'Filters, $activeFilters on',
              showDot: activeFilters > 0,
              size: 52,
              onPressed: _openFilters,
            ),
          ]),
        ],
        empty: const EmptyView(
          icon: Icons.groups_outlined,
          title: 'No students found',
          message: 'Try another name, or add a student with the button below.',
        ),
        itemBuilder: (context, s) => _StudentRow(
          student: s.copyWith(
            departmentName: s.departmentName ?? departmentNames[s.departmentId],
            roomNumber: s.roomNumber ?? roomNumbers[s.roomId],
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student});

  final StudentProfile student;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final s = student;
    final status = switch (s.status) {
      AccountStatus.active => const StatusBadge(label: 'Active', tone: Tone.success),
      AccountStatus.pendingActivation => const StatusBadge(label: 'Pending', tone: Tone.primary),
      AccountStatus.suspended => const StatusBadge(label: 'Suspended', tone: Tone.danger),
      AccountStatus.inactive => const StatusBadge(label: 'Inactive', tone: Tone.neutral),
      AccountStatus.unknown => null,
    };
    return InkWell(
      onTap: () => context.push(Routes.student(s.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            PersonAvatar(name: s.name, imageKey: s.imageKey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.label),
                  Text(
                    [s.rollNumber, s.departmentName, s.roomNumber ?? 'No room yet'].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.small,
                  ),
                ],
              ),
            ),
            ?status,
          ],
        ),
      ),
    );
  }
}
