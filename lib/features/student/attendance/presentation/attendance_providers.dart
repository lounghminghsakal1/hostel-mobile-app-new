import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/image_capture_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../common/media/presentation/media_providers.dart';
import '../../home/domain/student_home.dart';
import '../../home/presentation/student_home_providers.dart';
import '../data/attendance_data.dart';
import '../domain/attendance.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(AttendanceRemoteDataSource(ref.watch(dioProvider))),
);

final markAttendanceProvider = Provider(
  (ref) => MarkAttendance(ref.watch(attendanceRepositoryProvider), ref.watch(mediaRepositoryProvider)),
);

/// What the result screen shows.
sealed class AttendanceOutcome {
  const AttendanceOutcome();
}

class AttendanceMarked extends AttendanceOutcome {
  const AttendanceMarked(this.mark);
  final AttendanceMark mark;
}

/// The hostel hasn't uploaded the student's reference photo yet.
class AttendanceNeedsPhoto extends AttendanceOutcome {
  const AttendanceNeedsPhoto();
}

class MarkAttendanceState {
  const MarkAttendanceState({this.location = const AsyncLoading(), this.selfie, this.submitting = false, this.error});

  final AsyncValue<GeoPoint> location;
  final Uint8List? selfie;
  final bool submitting;
  final AppException? error;

  bool get canSubmit => location.hasValue && selfie != null && !submitting;

  MarkAttendanceState copyWith({
    AsyncValue<GeoPoint>? location,
    Uint8List? selfie,
    bool? submitting,
    AppException? error,
    bool clearError = false,
  }) =>
      MarkAttendanceState(
        location: location ?? this.location,
        selfie: selfie ?? this.selfie,
        submitting: submitting ?? this.submitting,
        error: clearError ? null : (error ?? this.error),
      );
}

final markAttendanceControllerProvider =
    NotifierProvider.autoDispose<MarkAttendanceController, MarkAttendanceState>(MarkAttendanceController.new);

class MarkAttendanceController extends Notifier<MarkAttendanceState> {
  @override
  MarkAttendanceState build() {
    Future.microtask(locate);
    return const MarkAttendanceState();
  }

  Future<void> locate() async {
    state = state.copyWith(location: const AsyncLoading(), clearError: true);
    try {
      final point = await ref.read(locationServiceProvider).currentPosition();
      if (ref.mounted) state = state.copyWith(location: AsyncData(point));
    } on Object catch (e, st) {
      if (ref.mounted) state = state.copyWith(location: AsyncError(toAppException(e), st));
    }
  }

  Future<void> takeSelfie() async {
    final bytes = await ref.read(imageCaptureServiceProvider).takeSelfie();
    if (bytes != null && ref.mounted) state = state.copyWith(selfie: bytes, clearError: true);
  }

  /// Returns the outcome to show, or null when an inline error was set.
  Future<AttendanceOutcome?> submit() async {
    final location = state.location.value;
    final selfie = state.selfie;
    if (location == null || selfie == null) return null;

    state = state.copyWith(submitting: true, clearError: true);
    try {
      final mark = await ref.read(markAttendanceProvider)(selfie: selfie, location: location);
      ref.read(markedTodayProvider.notifier).record(TodayAttendance(
            reportedTime: mark.reportedTime,
            insideHostelRadius: mark.insideHostelRadius,
            distanceMeters: mark.distanceFromHostelMeters,
          ));
      ref.invalidate(studentHomeProvider);
      return AttendanceMarked(mark);
    } on Object catch (e) {
      final error = toAppException(e);
      // 409 {errors: "Student's image not uploaded"} when no profile photo is on file.
      if (error.code == "Student's image not uploaded" || error.message.toLowerCase().contains('image is not uploaded')) {
        ref.invalidate(studentHomeProvider);
        return const AttendanceNeedsPhoto();
      }
      if (ref.mounted) state = state.copyWith(error: error);
      return null;
    } finally {
      if (ref.mounted) state = state.copyWith(submitting: false);
    }
  }
}
