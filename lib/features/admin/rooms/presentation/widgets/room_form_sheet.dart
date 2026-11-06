import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/app_exception.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/room.dart';
import '../room_providers.dart';

/// Add a room, or edit [existing]. Resolves to the saved room.
Future<Room?> showRoomFormSheet(BuildContext context, {Room? existing}) {
  return showAppSheet<Room>(context, builder: (_) => _RoomForm(existing: existing));
}

class _RoomForm extends ConsumerStatefulWidget {
  const _RoomForm({this.existing});

  final Room? existing;

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  late final _number = TextEditingController(text: widget.existing?.number);
  late int _capacity = widget.existing?.capacity ?? 3;
  bool _saving = false;
  String? _numberError;
  String? _capacityError;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _numberError = null;
      _capacityError = null;
    });
    try {
      final room = await ref.read(saveRoomProvider)(number: _number.text, capacity: _capacity, existing: widget.existing);
      if (mounted) Navigator.of(context).pop(room);
    } on AppException catch (e) {
      if (!mounted) return;
      final message = e.message;
      final aboutCapacity = e.code == 'capacity' || message.toLowerCase().contains('capacity');
      setState(() => aboutCapacity ? _capacityError = message : _numberError = message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final editing = widget.existing != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          const IconTile(icon: Icons.bed_outlined, size: 48),
          const SizedBox(width: 12),
          Text(editing ? 'Edit room ${widget.existing!.number}' : 'Add a room', style: t.title.copyWith(fontSize: 22)),
        ]),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Room number',
          controller: _number,
          hint: 'e.g. C-306',
          errorText: _numberError,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Beds (capacity)',
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _capacityError == null ? p.line : p.danger, width: 1.5),
            ),
            child: Row(
              children: [
                AppIconButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Fewer beds',
                  onPressed: _capacity > 1 ? () => setState(() => _capacity--) : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Text('$_capacity', style: t.number.copyWith(fontSize: 28)), const SizedBox(width: 8), Text('beds', style: t.small)],
                  ),
                ),
                AppIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'More beds',
                  style: IconButtonStyle.tonal,
                  onPressed: () => setState(() => _capacity++),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _capacityError ?? 'You can raise this later. Lowering it is blocked while the beds are taken.',
          style: _capacityError == null ? t.caption : t.caption.copyWith(color: p.dangerInk),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: AppButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(context).pop())),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: AppButton(label: editing ? 'Save changes' : 'Add room', loading: _saving, onPressed: _save)),
        ]),
      ],
    );
  }
}
