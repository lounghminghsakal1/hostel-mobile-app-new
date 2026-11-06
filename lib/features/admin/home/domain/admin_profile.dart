class AdminProfile {
  const AdminProfile({required this.id, required this.name, required this.hostelName, required this.collegeName, this.hostelId});

  final int id;
  final String name;
  final String hostelName;
  final String collegeName;

  /// Not in the splash response yet (see API_GAPS.md); resolved by name for now.
  final int? hostelId;
}

abstract interface class AdminProfileRepository {
  Future<AdminProfile> load();
}
