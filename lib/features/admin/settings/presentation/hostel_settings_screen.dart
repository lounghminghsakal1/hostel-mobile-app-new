import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/widgets.dart';
import '../../home/presentation/admin_providers.dart';
import '../domain/hostel_settings.dart';
import 'hostel_settings_providers.dart';

class HostelSettingsScreen extends ConsumerWidget {
  const HostelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(hostelSettingsProvider);
    return value.when(
      data: (s) => _SettingsForm(initial: s),
      loading: () => const Scaffold(appBar: AppTopBar(title: 'Hostel settings', showBack: true), body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: const AppTopBar(title: 'Hostel settings', showBack: true),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(hostelSettingsProvider)),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.initial});

  final HostelSettings initial;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late String _start = widget.initial.windowStart;
  late String _end = widget.initial.windowEnd;
  late double _radius = widget.initial.radiusMeters.clamp(100, 2000).toDouble();
  late final _name = TextEditingController(text: widget.initial.name);
  late final _location = TextEditingController(text: widget.initial.location);
  late final _contactName = TextEditingController(text: widget.initial.contactPersonName);
  late final _contactNumber = TextEditingController(text: widget.initial.contactNumber);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _location, _contactName, _contactNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts.first) ?? 0) * 60 + (int.tryParse(parts.last) ?? 0);
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.tryParse(parts.first) ?? 20, minute: int.tryParse(parts.last) ?? 30),
    );
    if (picked == null) return;
    setState(() {
      final value = AppDates.hhmm(picked.hour, picked.minute);
      start ? _start = value : _end = value;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_minutes(_end) <= _minutes(_start)) {
      setState(() => _error = 'The window must close after it opens (both on the same evening).');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final i = widget.initial;
      await ref.read(hostelSettingsRepositoryProvider).save(HostelSettings(
            id: i.id,
            name: _name.text,
            location: _location.text,
            contactPersonName: _contactName.text,
            contactNumber: _contactNumber.text,
            windowStart: _start,
            windowEnd: _end,
            radiusMeters: _radius.roundToDouble(),
          ));
      ref
        ..invalidate(hostelSettingsProvider)
        ..invalidate(adminProfileProvider);
      if (!mounted) return;
      context.showMessage('Settings saved.');
      context.pop();
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
    final windowLabel = '${AppDates.clockLabel(_start)} and ${AppDates.clockLabel(_end)}';

    Widget timeTile(String label, String value, bool start) => Expanded(
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.line, width: 1.5)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _pickTime(start),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(label, style: t.caption), Text(AppDates.clockLabel(value), style: t.number.copyWith(fontSize: 24))],
                ),
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: const AppTopBar(title: 'Hostel settings', showBack: true),
      bottomNavigationBar: BottomActionBar(children: [AppButton(label: 'Save changes', loading: _saving, onPressed: _save)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const IconTile(icon: Icons.schedule_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Attendance window', style: t.heading), Text('Every night, India time', style: t.small)],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [timeTile('Opens', _start, true), const SizedBox(width: 10), timeTile('Closes', _end, false)]),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: t.caption.copyWith(color: p.dangerInk))],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STUDENTS WILL SEE', style: t.overline.copyWith(fontSize: 10.5)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Icon(Icons.photo_camera_outlined, size: 18, color: p.onPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mark attendance between $windowLabel',
                              style: t.label.copyWith(fontSize: 13.5, color: p.onPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const IconTile(icon: Icons.location_on_outlined, tone: Tone.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text('Check-in radius', style: t.heading), Text('Further away gets flagged for you', style: t.small)],
                    ),
                  ),
                  Text('${_radius.round()} m', style: t.number.copyWith(fontSize: 22)),
                ]),
                Slider(
                  value: _radius,
                  min: 100,
                  max: 2000,
                  divisions: 38,
                  label: '${_radius.round()} m',
                  onChanged: (v) => setState(() => _radius = v),
                ),
                Row(children: [Text('100 m', style: t.caption), const Spacer(), Text('2 km', style: t.caption)]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Hostel name', controller: _name),
          const SizedBox(height: 14),
          AppTextField(label: 'Location', controller: _location),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: AppTextField(label: 'Contact person', controller: _contactName)),
            const SizedBox(width: 10),
            Expanded(child: AppTextField(label: 'Contact number', controller: _contactNumber, keyboardType: TextInputType.phone)),
          ]),
        ],
      ),
    );
  }
}
