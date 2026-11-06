import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:our_hostel/core/models/account_status.dart';
import 'package:our_hostel/core/models/paginated.dart';
import 'package:our_hostel/core/services/image_capture_service.dart';
import 'package:our_hostel/features/admin/rooms/presentation/room_providers.dart';
import 'package:our_hostel/features/admin/students/domain/admin_students.dart';
import 'package:our_hostel/features/admin/students/presentation/admin_student_providers.dart';
import 'package:our_hostel/features/admin/students/presentation/student_form_screen.dart';
import 'package:our_hostel/features/common/media/domain/media_repository.dart';
import 'package:our_hostel/features/common/media/presentation/media_providers.dart';
import 'package:our_hostel/features/common/students/student_profile.dart';

// A valid 1x1 PNG, so Image.memory can show it
final _photoBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

class _FakeCapture extends ImageCaptureService {
  _FakeCapture() : super(ImagePicker());

  @override
  Future<Uint8List?> takePhoto() async => _photoBytes;
}

class _FakeMedia implements MediaRepository {
  final uploaded = <MediaFor>[];

  @override
  Future<String> uploadImage(MediaFor mediaFor, Uint8List bytes) async {
    uploaded.add(mediaFor);
    return 'student_image/test-photo';
  }

  @override
  Future<String> imageUrl(String objectKey) async => 'https://example.com/$objectKey';
}

class _FakeStudents implements AdminStudentRepository {
  _FakeStudents(this.result);

  final PhotoCheck result;
  final checkedKeys = <String>[];
  var creates = 0;

  @override
  Future<PhotoCheck> checkPhoto(String imageKey) async {
    checkedKeys.add(imageKey);
    return result;
  }

  @override
  Future<List<Department>> departments() async => const [Department(id: 1, name: 'Computer Science')];

  @override
  Future<StudentProfile> create(StudentDraft draft) async {
    creates++;
    throw UnimplementedError();
  }

  @override
  Future<PageResult<StudentProfile>> list(StudentQuery query) async => (items: const <StudentProfile>[], hasMore: false);
  @override
  Future<StudentProfile> get(int id) => throw UnimplementedError();
  @override
  Future<StudentProfile> update(int id, StudentDraft changes) => throw UnimplementedError();
  @override
  Future<void> changeStatus(int id, AccountStatus status) async {}
  @override
  Future<void> changeRoom(int id, int roomId) async {}
  @override
  Future<void> resendActivation(int id) async {}
}

Future<_FakeStudents> _pumpForm(WidgetTester tester, PhotoCheck result, _FakeMedia media) async {
  final students = _FakeStudents(result);
  // Tall enough that the whole form is built (the form is a lazy ListView)
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      imageCaptureServiceProvider.overrideWithValue(_FakeCapture()),
      mediaRepositoryProvider.overrideWithValue(media),
      adminStudentRepositoryProvider.overrideWithValue(students),
      allRoomsProvider.overrideWith((ref) async => const []),
    ],
    child: const MaterialApp(home: StudentFormScreen()),
  ));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Profile photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();
  return students;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a rejected photo shows why and blocks saving', (tester) async {
    final media = _FakeMedia();
    final students = await _pumpForm(
      tester,
      const PhotoCheck(
        ok: false,
        message: 'The photo is blurry or out of focus.',
        issues: [PhotoIssue(code: 'BLURRY', message: 'The photo is blurry or out of focus.', isError: true)],
      ),
      media,
    );

    expect(media.uploaded, [MediaFor.studentImage], reason: 'uploaded right after picking');
    expect(students.checkedKeys, ['student_image/test-photo'], reason: 'checked right after uploading');
    expect(find.textContaining("This photo can't be used", findRichText: true), findsOneWidget);
    expect(find.textContaining('• The photo is blurry or out of focus.', findRichText: true), findsOneWidget);
    expect(find.text('Retake'), findsOneWidget);

    // Fill the form and try to save: blocked by the photo
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'asha@college.edu');
    await tester.enterText(fields.at(1), 'Asha Rao');
    await tester.enterText(fields.at(2), '22CS1043');
    await tester.enterText(fields.at(3), '9876543210');
    await tester.enterText(fields.at(4), '9876543211');
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Computer Science').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create and send invite'));
    await tester.pump();
    expect(students.creates, 0);
    expect(find.textContaining("This photo can't be used: The photo is blurry"), findsOneWidget);
  });

  testWidgets('a good photo is marked as looking good', (tester) async {
    await _pumpForm(tester, const PhotoCheck(ok: true, message: 'The photo looks good.'), _FakeMedia());
    expect(find.text('Photo looks good'), findsOneWidget);
    expect(find.textContaining("This photo can't be used", findRichText: true), findsNothing);
  });

  testWidgets('warnings are shown as tips without blocking', (tester) async {
    await _pumpForm(
      tester,
      const PhotoCheck(
        ok: true,
        message: 'The photo is a little soft.',
        issues: [PhotoIssue(code: 'SLIGHTLY_BLURRY', message: 'The photo is a little soft.', isError: false)],
      ),
      _FakeMedia(),
    );
    expect(find.text('Photo OK'), findsOneWidget);
    expect(find.textContaining('Photo can be used, but could be better', findRichText: true), findsOneWidget);
  });
}
