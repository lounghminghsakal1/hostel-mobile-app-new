import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/image_capture_service.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../common/events/domain/hostel_event.dart';
import '../../../common/events/presentation/event_providers.dart';
import '../../../common/events/presentation/event_widgets.dart';
import '../../../common/media/domain/media_repository.dart';
import '../../../common/media/presentation/media_providers.dart';

/// Create an event, or edit one when [editingId] is set.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.editingId});

  final int? editingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = editingId;
    if (id == null) return const _Form();
    return ref.watch(eventProvider(id)).when(
          data: (e) => _Form(existing: e),
          loading: () => const Scaffold(body: LoadingView()),
          error: (e, _) => Scaffold(appBar: const AppTopBar(showBack: true), body: ErrorView(error: e)),
        );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({this.existing});

  final HostelEvent? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _contactName = TextEditingController(text: widget.existing?.contactName);
  late final _contactPhone = TextEditingController(text: widget.existing?.contactPhone);
  late final _link = TextEditingController(text: widget.existing?.link);
  // Wall-clock times in India; converted to UTC when saving.
  late DateTime _start = widget.existing == null ? _defaultStart() : AppDates.toIstWallTime(widget.existing!.startingAt);
  late DateTime _end = widget.existing == null ? _start.add(const Duration(hours: 2)) : AppDates.toIstWallTime(widget.existing!.endingAt);
  late bool _active = widget.existing?.isActive ?? true;
  Uint8List? _cover;
  bool _saving = false;
  String? _timeError;

  bool get _editing => widget.existing != null;

  static DateTime _defaultStart() {
    final d = AppDates.todayIst().add(const Duration(days: 1));
    return DateTime(d.year, d.month, d.day, 18);
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _contactName, _contactPhone, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickCover() async {
    final bytes = await ref.read(imageCaptureServiceProvider).pickFromGallery();
    if (bytes != null && mounted) setState(() => _cover = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      setState(() => _timeError = 'The event must end after it starts.');
      return;
    }
    setState(() {
      _saving = true;
      _timeError = null;
    });
    try {
      String? imageKey = widget.existing?.imageKey;
      if (_cover != null) imageKey = await ref.read(uploadImageProvider)(MediaFor.eventImage, _cover!);
      final draft = EventDraft(
        name: _name.text,
        description: _description.text,
        startingAt: AppDates.fromIstWallTime(_start),
        endingAt: AppDates.fromIstWallTime(_end),
        isActive: _active,
        imageKey: imageKey,
        link: _link.text,
        contactName: _contactName.text,
        contactPhone: _contactPhone.text,
      );
      await ref.read(saveEventProvider)(draft, id: widget.existing?.id);
      if (_editing) ref.invalidate(eventProvider(widget.existing!.id));
      ref.invalidate(eventsProvider(false));
      if (!mounted) return;
      context.showMessage(_editing ? 'Event updated.' : 'Event created.');
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
    String label(DateTime d) => '${AppDates.weekdayDayMonth(d)}, ${AppDates.clockLabel(AppDates.hhmm(d.hour, d.minute))}';

    Widget timeField(String title, DateTime value, ValueChanged<DateTime> onPicked) => Expanded(
          child: LabeledField(
            label: title,
            child: OutlinedButton(
              onPressed: () async {
                final picked = await _pickDateTime(value);
                if (picked != null) onPicked(picked);
              },
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: _timeError != null && title == 'Ends' ? p.danger : p.line, width: 1.5),
              ),
              child: Text(label(value), style: t.label.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
          ),
        );

    final existing = widget.existing;
    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppTopBar(title: _editing ? 'Edit event' : 'New event', showBack: true, backIcon: Icons.close_rounded, backgroundColor: p.surface),
      bottomNavigationBar: BottomActionBar(children: [
        AppButton(label: _editing ? 'Save changes' : 'Create event', loading: _saving, onPressed: _save),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            InkWell(
              onTap: _pickCover,
              borderRadius: BorderRadius.circular(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cover != null)
                        Image.memory(_cover!, fit: BoxFit.cover)
                      else if (existing != null)
                        EventCover(event: existing, height: 120, showDate: false)
                      else
                        DottedCover(color: p.primary, height: 120),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: p.ink.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(12)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.image_outlined, size: 18, color: p.onPrimary),
                            const SizedBox(width: 8),
                            Text(_cover == null ? 'Add cover image' : 'Change cover', style: t.label.copyWith(color: p.onPrimary, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Event name', controller: _name, validator: (v) => Validators.required(v, 'Event name')),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Description',
              controller: _description,
              maxLines: 4,
              minLines: 3,
              validator: (v) => Validators.required(v, 'Description'),
            ),
            const SizedBox(height: 14),
            Row(children: [
              timeField('Starts', _start, (v) => setState(() {
                    _start = v;
                    if (!_end.isAfter(_start)) _end = _start.add(const Duration(hours: 2));
                    _timeError = null;
                  })),
              const SizedBox(width: 10),
              timeField('Ends', _end, (v) => setState(() {
                    _end = v;
                    _timeError = null;
                  })),
            ]),
            if (_timeError != null) ...[
              const SizedBox(height: 6),
              Text(_timeError!, style: t.caption.copyWith(color: p.dangerInk)),
            ],
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: AppTextField(label: 'Contact', optional: true, controller: _contactName)),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: 'Phone',
                  controller: _contactPhone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Registration link',
              optional: true,
              controller: _link,
              hint: 'https://',
              prefixIcon: Icons.link_rounded,
              keyboardType: TextInputType.url,
              validator: Validators.url,
            ),
            if (_editing) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  title: Text('Visible to students', style: t.label.copyWith(fontSize: 14.5)),
                  subtitle: Text('Turn off to hide it without deleting', style: t.small),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
