import '../../../../core/error/app_exception.dart';
import '../../../../core/models/paginated.dart';

class Room {
  const Room({required this.id, required this.number, required this.capacity, required this.occupied});

  final int id;
  final String number;
  final int capacity;
  final int occupied;

  int get free => (capacity - occupied).clamp(0, capacity);
  bool get isFull => free == 0;
  bool get isEmpty => occupied == 0;
}

class RoomOccupant {
  const RoomOccupant({
    required this.name,
    this.rollNumber,
    this.contactNumber,
    this.departmentName,
    this.studentId,
    this.imageKey,
  });

  final String name;
  final String? rollNumber;
  final String? contactNumber;
  final String? departmentName;
  final int? studentId;
  final String? imageKey;
}

class RoomDetail {
  const RoomDetail({required this.room, required this.occupants});

  final Room room;
  final List<RoomOccupant> occupants;
}

/// `search` matches the start of the room number.
typedef RoomQuery = ({String? search, bool onlyVacancy, int page});

abstract interface class RoomRepository {
  Future<PageResult<Room>> list(RoomQuery query);

  /// Every room (for pickers), up to 100.
  Future<List<Room>> all();
  Future<RoomDetail> get(int id);
  Future<Room> create({required String number, required int capacity});
  Future<Room> update(int id, {required String number, required int capacity});
}

class SaveRoom {
  const SaveRoom(this._repository);
  final RoomRepository _repository;

  Future<Room> call({required String number, required int capacity, Room? existing}) {
    final trimmed = number.trim();
    if (trimmed.isEmpty) throw const AppException('Enter a room number.', code: 'room_number');
    if (capacity < 1) throw const AppException('A room needs at least 1 bed.', code: 'capacity');
    if (existing != null && capacity < existing.occupied) {
      throw AppException(
        '${existing.occupied} students live here, so it needs at least ${existing.occupied} beds. Move someone out first.',
        code: 'capacity',
      );
    }
    return existing == null
        ? _repository.create(number: trimmed, capacity: capacity)
        : _repository.update(existing.id, number: trimmed, capacity: capacity);
  }
}
