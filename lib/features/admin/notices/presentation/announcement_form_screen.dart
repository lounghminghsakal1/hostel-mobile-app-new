import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/announcements/domain/announcement.dart';
import '../../../common/announcements/presentation/announcement_providers.dart';

/// Create an announcement, or edit one when [editingId] is set.
class AnnouncementFormScreen extends ConsumerWidget {
  const AnnouncementFormScreen({super.key, this.editingId});

  final int? editingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = editingId;
    if (id == null) return const _Form();
    return ref.watch(announcementProvider(id)).when(
          data: (a) => _Form(existing: a),
          loading: () => const Scaffold(body: LoadingView()),
          error: (e, _) => Scaffold(appBar: const AppTopBar(showBack: true), body: ErrorView(error: e)),
        );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({this.existing});

  final Announcement? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _link = TextEditingController(text: widget.existing?.linkUrl);
  late AnnouncementType _type = widget.existing?.type ?? AnnouncementType.hostel;
  late DateTime _start = widget.existing?.startDate ?? AppDates.todayIst();
  late DateTime _end = widget.existing?.endDate ?? AppDates.todayIst().add(const Duration(days: 1));
  late bool _important = widget.existing?.isImportant ?? false;
  late bool _push = widget.existing?.pushNotification ?? false;
  late bool _active = widget.existing?.isActive ?? true;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  Future<void> _save({required bool active}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = AnnouncementDraft(
      title: _title.text,
      description: _description.text,
      linkUrl: _link.text,
      isActive: active,
      startDate: _start,
      endDate: _end,
      type: _type,
      isImportant: _important,
      pushNotification: _push,
    );
    try {
      final repo = ref.read(announcementRepositoryProvider);
      if (_editing) {
        await repo.update(widget.existing!.id, draft);
        ref.invalidate(announcementProvider(widget.existing!.id));
      } else {
        await repo.create(draft);
      }
      if (!mounted) return;
      context.showMessage(_editing ? 'Announcement updated.' : (active ? 'Announcement published.' : 'Saved as inactive.'));
      context.pop(true);
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;

    Widget dateField(String label, DateTime value, VoidCallback onTap) => Expanded(
          child: LabeledField(
            label: label,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14)),
              child: Text(AppDates.weekdayDayMonth(value), style: t.label.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        );

    Widget toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          value: value,
          onChanged: onChanged,
          title: Text(title, style: t.label.copyWith(fontSize: 14.5)),
          subtitle: Text(subtitle, style: t.small),
        );

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppTopBar(
        title: _editing ? 'Edit announcement' : 'New announcement',
        showBack: true,
        backIcon: Icons.close_rounded,
        backgroundColor: p.surface,
      ),
      bottomNavigationBar: BottomActionBar(
        children: _editing
            ? [AppButton(label: 'Save changes', loading: _saving, onPressed: () => _save(active: _active))]
            : [
                AppButton(label: 'Save as inactive', variant: ButtonVariant.outline, onPressed: _saving ? null : () => _save(active: false)),
                AppButton(label: 'Publish', loading: _saving, onPressed: () => _save(active: true)),
              ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            AppTextField(label: 'Title', controller: _title, validator: (v) => Validators.required(v, 'Title')),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Message',
              controller: _description,
              maxLines: 5,
              minLines: 3,
              validator: (v) => Validators.required(v, 'Message'),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Category',
              child: FilterChipBar<AnnouncementType>(
                selected: _type,
                onSelected: (v) => setState(() => _type = v),
                options: [for (final type in AnnouncementType.values) FilterOption(type, type.label)],
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              dateField('Show from', _start, () => _pickDate(start: true)),
              const SizedBox(width: 10),
              dateField('Until', _end, () => _pickDate(start: false)),
            ]),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Link',
              optional: true,
              controller: _link,
              hint: 'https://',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: Validators.url,
              helperText: _editing && widget.existing?.linkUrl != null ? "A saved link can't be removed yet, only replaced." : null,
            ),
            const SizedBox(height: 14),
            GroupedCard(children: [
              toggle('Mark as important', 'Pinned to the top with a coral tag', _important, (v) => setState(() => _important = v)),
              toggle('Push notification', "Saved now; phones get alerts once notifications go live", _push, (v) => setState(() => _push = v)),
              if (_editing) toggle('Active', 'Turn off to hide it from students', _active, (v) => setState(() => _active = v)),
            ]),
          ],
        ),
      ),
    );
  }
}
