
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/widgets/widgets.dart';
import '../../shell/admin_top_bar.dart';
import '../domain/room.dart';
import 'room_providers.dart';
import 'widgets/room_form_sheet.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  bool _onlyVacancy = false;
  String _search = '';
  int _reload = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addRoom() async {
    final room = await showRoomFormSheet(context);
    if (room != null && mounted) {
      context.showMessage('Room ${room.number} added.');
      ref.invalidate(allRoomsProvider);
      setState(() => _reload++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(roomRepositoryProvider);
    return Scaffold(
      appBar: const AdminTopBar(title: 'Rooms', subtitle: 'Beds and who sleeps where'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoom,
        backgroundColor: context.colors.accent,
        foregroundColor: context.colors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add room'),
      ),
      body: PagedList<Room>(
        query: (_onlyVacancy, _search, _reload),
        columns: 2,
        bottomPadding: 96,
        fetch: (page) => repo.list((search: _search.isEmpty ? null : _search, onlyVacancy: _onlyVacancy, page: page)),
        header: [
          SearchField(
            controller: _searchController,
            hint: 'Room number',
            onSearch: (v) => setState(() => _search = v),
          ),
          FilterChipBar<bool>(
            selected: _onlyVacancy,
            onSelected: (v) => setState(() => _onlyVacancy = v),
            options: const [FilterOption(false, 'All rooms'), FilterOption(true, 'Has free beds')],
          ),
        ],
        empty: const EmptyView(icon: Icons.bed_outlined, title: 'No rooms found', message: 'Add your first room with the button below.'),
        itemBuilder: (context, room) => RoomCard(room: room, onTap: () => context.push(Routes.room(room.id))),
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final t = context.text;
    final (label, tone) = room.isFull
        ? ('Full', Tone.accent)
        : room.isEmpty
            ? ('Empty', Tone.primary)
            : ('${room.free} free', Tone.success);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(room.number, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.title)),
            StatusBadge(label: label, tone: tone, showDot: false, small: true),
          ]),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < room.capacity.clamp(1, 8); i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < room.occupied ? (room.isFull ? p.accent : p.primary) : p.primaryTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text('${room.occupied} of ${room.capacity} beds', style: t.small),
        ],
      ),
    );
  }
}
