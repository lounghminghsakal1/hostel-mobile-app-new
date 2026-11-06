import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../data/room_data.dart';
import '../domain/room.dart';

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => RoomRepositoryImpl(RoomRemoteDataSource(ref.watch(dioProvider))),
);

final saveRoomProvider = Provider((ref) => SaveRoom(ref.watch(roomRepositoryProvider)));

/// All rooms, for pickers and for showing room numbers next to students.
final allRoomsProvider = FutureProvider.autoDispose<List<Room>>((ref) => ref.watch(roomRepositoryProvider).all());

final roomDetailProvider = FutureProvider.autoDispose.family<RoomDetail, int>(
  (ref, id) => ref.watch(roomRepositoryProvider).get(id),
);
