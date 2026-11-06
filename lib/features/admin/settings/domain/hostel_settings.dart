import '../../home/domain/admin_profile.dart';

class HostelSettings {
  const HostelSettings({
    required this.id,
    required this.name,
    required this.location,
    required this.contactPersonName,
    required this.contactNumber,
    required this.windowStart,
    required this.windowEnd,
    required this.radiusMeters,
  });

  final int id;
  final String name;
  final String location;
  final String contactPersonName;
  final String contactNumber;

  /// "HH:mm", India time.
  final String windowStart;
  final String windowEnd;
  final double radiusMeters;
}

abstract interface class HostelSettingsRepository {
  Future<HostelSettings> load(AdminProfile admin);
  Future<HostelSettings> save(HostelSettings settings);
}
