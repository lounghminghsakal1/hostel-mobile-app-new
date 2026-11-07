import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/services/image_capture_service.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/widgets/result_illustration.dart';
import '../../../common/media/domain/media_repository.dart';
import '../../../common/media/presentation/media_providers.dart';
import '../../../common/media/presentation/signed_image.dart';
import '../../../common/students/student_profile.dart';
import '../../rooms/presentation/room_providers.dart';
import '../domain/admin_students.dart';
import 'admin_student_providers.dart';

/// Add a student, or edit one when [editingId] is set.
class StudentFormScreen extends ConsumerWidget {
  const StudentFormScreen({super.key, this.editingId});

  final int? editingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = editingId;
    if (id == null) return const _StudentForm();
    return ref.watch(adminStudentProvider(id)).when(
          data: (s) => _StudentForm(existing: s),
          loading: () => const Scaffold(body: LoadingView()),
          error: (e, _) => Scaffold(appBar: const AppTopBar(showBack: true), body: ErrorView(error: e)),
        );
  }
}

class _StudentForm extends ConsumerStatefulWidget {
  const _StudentForm({this.existing});

  final StudentProfile? existing;

  @override
  ConsumerState<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _roll = TextEditingController(text: widget.existing?.rollNumber);
  late final _phone = TextEditingController(text: widget.existing?.contactNumber);
  late final _parent = TextEditingController(text: widget.existing?.parentMobileNumber);
  late int? _departmentId = widget.existing?.departmentId;
  int? _roomId;
  Uint8List? _photo;

  // The picked photo is uploaded and face-checked right away
  String? _photoKey;
  bool _checkingPhoto = false;
  PhotoCheck? _photoCheck;
  String? _photoCheckFailed;
  int _photoAttempt = 0;

  bool _saving = false;
  StudentProfile? _created;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_email, _name, _roll, _phone, _parent]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final camera = ref.read(imageCaptureServiceProvider);
    final choice = await showAppSheet<String>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Only the student, facing the camera, in good light, with the whole face in the frame.',
              style: sheetContext.text.small,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheetContext).pop('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop('gallery'),
          ),
          if (_photo != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove this photo'),
              onTap: () => Navigator.of(sheetContext).pop('remove'),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'remove') return _clearPhoto();
    final bytes = choice == 'camera' ? await camera.takePhoto() : await camera.pickFromGallery();
    if (bytes != null && mounted) await _checkPhoto(bytes);
  }

  void _clearPhoto() {
    setState(() {
      _photoAttempt++;
      _photo = null;
      _photoKey = null;
      _photoCheck = null;
      _photoCheckFailed = null;
      _checkingPhoto = false;
    });
  }

  /// Uploads the photo and asks the server's face check whether it's usable.
  Future<void> _checkPhoto(Uint8List bytes) async {
    final attempt = ++_photoAttempt;
    setState(() {
      _photo = bytes;
      _photoKey = null;
      _photoCheck = null;
      _photoCheckFailed = null;
      _checkingPhoto = true;
    });
    try {
      final key = await ref.read(uploadImageProvider)(MediaFor.studentImage, bytes);
      if (!mounted || attempt != _photoAttempt) return;
      setState(() => _photoKey = key);
      final result = await ref.read(adminStudentRepositoryProvider).checkPhoto(key);
      if (!mounted || attempt != _photoAttempt) return;
      setState(() => _photoCheck = result);
    } on Object catch (e) {
      if (!mounted || attempt != _photoAttempt) return;
      setState(() => _photoCheckFailed = toAppException(e).message);
    } finally {
      if (mounted && attempt == _photoAttempt) setState(() => _checkingPhoto = false);
    }
  }

  /// Checks an already-uploaded photo again (after "couldn't check").
  Future<void> _recheckPhoto() async {
    final photo = _photo;
    if (photo != null) await _checkPhoto(photo);
  }

  StudentDraft _changes() {
    final s = widget.existing!;
    String? changed(TextEditingController c, String? old) => c.text.trim() == (old ?? '') ? null : c.text.trim();
    return StudentDraft(
      email: changed(_email, s.email),
      name: changed(_name, s.name),
      contactNumber: changed(_phone, s.contactNumber),
      parentMobileNumber: changed(_parent, s.parentMobileNumber),
      departmentId: _departmentId == s.departmentId ? null : _departmentId,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkingPhoto) {
      context.showMessage('Checking the photo. Try again in a moment.');
      return;
    }
    final check = _photoCheck;
    if (check != null && !check.ok) {
      context.showMessage("This photo can't be used: ${check.message} Retake it or remove it.");
      return;
    }
    setState(() => _saving = true);
    try {
      final save = ref.read(saveStudentProvider);
      if (_editing) {
        await save(_changes(), photo: _photoKey == null ? _photo : null, photoKey: _photoKey, editingId: widget.existing!.id);
        ref.invalidate(adminStudentProvider(widget.existing!.id));
        if (!mounted) return;
        context.showMessage('Profile updated.');
        context.pop();
      } else {
        final created = await save(
          StudentDraft(
            email: _email.text,
            name: _name.text,
            rollNumber: _roll.text,
            contactNumber: _phone.text,
            parentMobileNumber: _parent.text,
            departmentId: _departmentId,
            roomId: _roomId,
          ),
          photo: _photoKey == null ? _photo : null,
          photoKey: _photoKey,
        );
        ref.invalidate(allRoomsProvider);
        if (mounted) setState(() => _created = created);
      }
    } on Object catch (e) {
      if (mounted) context.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_created != null) return _Success(student: _created!, onAddAnother: _resetForAnother);
    final p = context.colors;
    final departments = ref.watch(departmentsProvider).value ?? const [];
    final rooms = ref.watch(allRoomsProvider).value ?? const [];
    final phoneFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)];

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppTopBar(title: _editing ? 'Edit student' : 'Add student', showBack: true, backgroundColor: p.surface),
      bottomNavigationBar: BottomActionBar(children: [
        AppButton(
          label: _editing ? 'Save changes' : 'Create and send invite',
          icon: _editing ? null : Icons.send_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickPhoto,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.primarySoft,
                      border: Border.all(color: p.primaryTint, width: 2),
                    ),
                    child: _photo != null
                        ? Image.memory(_photo!, fit: BoxFit.cover)
                        : (widget.existing?.imageUrl != null || widget.existing?.imageKey != null)
                            ? PersonAvatar(name: widget.existing!.name, imageKey: widget.existing!.imageKey, imageUrl: widget.existing!.imageUrl, size: 64)
                            : Icon(Icons.add_a_photo_outlined, color: p.primaryDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _PhotoStatus(
                    hasPhoto: _photo != null,
                    checking: _checkingPhoto,
                    check: _photoCheck,
                    failed: _photoCheckFailed != null,
                  )),
                ]),
              ),
            ),
            if (_photoCheck != null && _photoCheck!.errors.isNotEmpty) ...[
              const SizedBox(height: 10),
              InfoCallout(
                tone: Tone.danger,
                icon: Icons.no_photography_outlined,
                title: "This photo can't be used",
                message: _photoCheck!.errors.map((i) => '\n• ${i.message}').join(),
                action: AppButton(label: 'Retake', compact: true, variant: ButtonVariant.light, onPressed: _pickPhoto),
              ),
            ] else if (_photoCheck != null && _photoCheck!.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              InfoCallout(
                tone: Tone.warning,
                icon: Icons.tips_and_updates_outlined,
                title: 'Photo can be used, but could be better',
                message: _photoCheck!.warnings.map((i) => '\n• ${i.message}').join(),
              ),
            ] else if (_photoCheckFailed != null) ...[
              const SizedBox(height: 10),
              InfoCallout(
                tone: Tone.neutral,
                icon: Icons.cloud_off_outlined,
                title: "Couldn't check the photo",
                message: '$_photoCheckFailed You can still save; the photo is checked again on save.',
                action: AppButton(label: 'Try again', compact: true, variant: ButtonVariant.light, onPressed: _recheckPhoto),
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              label: 'College email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(label: 'Full name', controller: _name, validator: (v) => Validators.required(v, 'Name')),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: AppTextField(
                  label: 'Roll number',
                  controller: _roll,
                  enabled: !_editing,
                  helperText: _editing ? "Can't be changed yet" : null,
                  validator: (v) => Validators.required(v, 'Roll number'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabeledField(
                  label: 'Department',
                  child: DropdownButtonFormField<int>(
                    initialValue: _departmentId,
                    isExpanded: true,
                    hint: const Text('Choose'),
                    validator: (v) => v == null ? 'Pick one' : null,
                    items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: AppTextField(
                  label: 'Phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneFormatters,
                  validator: Validators.phone,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: "Parent's phone",
                  controller: _parent,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneFormatters,
                  validator: (v) => Validators.phone(v, "Parent's phone"),
                ),
              ),
            ]),
            if (!_editing) ...[
              const SizedBox(height: 14),
              LabeledField(
                label: 'Room',
                optional: true,
                child: DropdownButtonFormField<int?>(
                  initialValue: _roomId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Assign later')),
                    for (final r in rooms.where((r) => !r.isFull))
                      DropdownMenuItem(value: r.id, child: Text('${r.number} · ${r.free} bed${r.free == 1 ? '' : 's'} free')),
                  ],
                  onChanged: (v) => setState(() => _roomId = v),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _resetForAnother() {
    for (final c in [_email, _name, _roll, _phone, _parent]) {
      c.clear();
    }
    _clearPhoto();
    setState(() {
      _created = null;
      _roomId = null;
    });
  }
}

/// The text next to the photo: what state the photo check is in.
class _PhotoStatus extends StatelessWidget {
  const _PhotoStatus({required this.hasPhoto, required this.checking, required this.check, required this.failed});

  final bool hasPhoto;
  final bool checking;
  final PhotoCheck? check;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final p = context.colors;
    final (String title, String subtitle, Color? color, Widget? leading) = switch ((hasPhoto, checking, check, failed)) {
      (false, _, _, _) => ('Profile photo', 'Needed for attendance. Face the camera, in good light.', null, null),
      (true, true, _, _) => (
          'Checking photo…',
          'Making sure the face is clear',
          null,
          SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: p.primary)),
        ),
      (true, false, final PhotoCheck c, _) when !c.ok => (
          "Photo can't be used",
          'Tap to retake',
          p.dangerInk,
          Icon(Icons.error_outline_rounded, size: 16, color: p.dangerInk),
        ),
      (true, false, final PhotoCheck c, _) when c.warnings.isNotEmpty => (
          'Photo OK',
          'See the tips below',
          p.warningInk,
          Icon(Icons.check_circle_outline_rounded, size: 16, color: p.warningInk),
        ),
      (true, false, PhotoCheck(), _) => (
          'Photo looks good',
          'Clear, front-facing face',
          p.successInk,
          Icon(Icons.verified_outlined, size: 16, color: p.successInk),
        ),
      _ => ('Photo ready', "Couldn't check it yet", null, null),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Flexible(child: Text(title, style: t.label.copyWith(color: color))),
        ]),
        Text(subtitle, style: t.small),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.student, required this.onAddAnother});

  final StudentProfile student;
  final VoidCallback onAddAnother;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
          child: Column(
            children: [
              ResultIllustration(icon: student.activationEmailSent ? Icons.mark_email_read_outlined : Icons.person_add_alt_1_outlined, size: 140),
              const SizedBox(height: 24),
              Text('${student.name.firstName} is added!', style: t.display, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              if (!student.activationEmailSent)
                InfoCallout(
                  tone: Tone.warning,
                  icon: Icons.warning_amber_rounded,
                  title: "Activation email wasn't sent",
                  message: "The student is saved, but the email to ${student.email ?? 'them'} failed"
                      "${student.activationEmailError == null ? '' : ': ${student.activationEmailError}'}. "
                      'Once that is fixed, open their profile and tap Resend.',
                )
              else
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'An activation link has been sent to '),
                    TextSpan(text: student.email ?? 'their email', style: t.body.copyWith(color: context.colors.ink, fontWeight: FontWeight.w700)),
                    const TextSpan(text: ". They'll set a password and can sign in right after."),
                  ]),
                  style: t.body,
                  textAlign: TextAlign.center,
                ),
              const Spacer(),
              AppButton(label: 'View profile', expand: true, onPressed: () => context.pushReplacement(Routes.student(student.id))),
              const SizedBox(height: 12),
              AppButton(label: 'Add another student', variant: ButtonVariant.outline, expand: true, onPressed: onAddAnother),
            ],
          ),
        ),
      ),
    );
  }
}
