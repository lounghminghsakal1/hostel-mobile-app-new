import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:our_hostel/app/router/back_to_first_tab.dart';
import 'package:our_hostel/core/widgets/paged_list.dart';
import 'package:our_hostel/core/widgets/search_field.dart';
import 'package:our_hostel/features/admin/attendance/domain/attendance_report.dart';

class _SearchableList extends StatefulWidget {
  const _SearchableList({required this.queries});

  final List<String> queries;

  @override
  State<_SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<_SearchableList> {
  final _controller = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PagedList<String>(
        query: _search,
        fetch: (page) async {
          widget.queries.add(_search);
          final all = ['Asha', 'Bilal', 'Charan'];
          final items = all.where((n) => n.toLowerCase().contains(_search.toLowerCase())).toList();
          return (items: items, hasMore: false);
        },
        header: [SearchField(controller: _controller, hint: 'Search by name', onSearch: (v) => setState(() => _search = v))],
        itemBuilder: (_, name) => ListTile(title: Text(name)),
      ),
    );
  }
}

void main() {
  testWidgets('search text and focus stay after the list reloads', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(MaterialApp(home: _SearchableList(queries: queries)));
    await tester.pumpAndSettle();
    expect(find.text('Bilal'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'ash');
    await tester.pump(const Duration(milliseconds: 500)); // debounce
    await tester.pumpAndSettle();

    expect(queries.last, 'ash');
    expect(find.text('ash'), findsOneWidget, reason: 'typed text is still shown');
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Bilal'), findsNothing);
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue, reason: 'keyboard stays up');

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(queries.last, '');
    expect(find.text('Bilal'), findsOneWidget);
  });

  testWidgets('back on another tab goes to the first tab, then lets the app close', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => BackToFirstTab(navigationShell: shell, child: Scaffold(body: shell)),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const Text('Home tab'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/fees', builder: (_, _) => const Text('Fees tab'))]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/fees');
    await tester.pumpAndSettle();
    expect(find.text('Fees tab'), findsOneWidget);

    // Android back: handled in the app, lands on Home
    final handled = await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Home tab'), findsOneWidget);

    // Back again on Home: not handled, so Android closes the app
    expect(await router.routerDelegate.popRoute(), isFalse);
  });

  test('face match levels: 65+ trusted, 30-65 check, below 30 mismatch', () {
    expect(FaceMatchLevel.of(65), FaceMatchLevel.trusted);
    expect(FaceMatchLevel.of(64.9), FaceMatchLevel.check);
    expect(FaceMatchLevel.of(30), FaceMatchLevel.check);
    expect(FaceMatchLevel.of(29.9), FaceMatchLevel.mismatch);
    expect(FaceMatchLevel.of(null), FaceMatchLevel.unknown);
  });

  test('one-tap low face match filter vs a custom one', () {
    final today = DateTime(2026, 11, 6);
    final none = AttendanceFilters(from: today, to: today);
    final low = none.withFaceMatch(FaceMatchLevel.trustedFrom);
    expect(low.isLowFaceMatchOnly, isTrue);
    expect(low.hasCustomFaceMatch, isFalse);
    final custom = none.withFaceMatch(80, FaceMatchOperator.atLeast);
    expect(custom.isLowFaceMatchOnly, isFalse);
    expect(custom.hasCustomFaceMatch, isTrue);
    expect(low.withFaceMatch(null).faceMatchPercent, isNull);
    expect(low.withDay(DateTime(2026, 11, 5)).isLowFaceMatchOnly, isTrue, reason: 'kept when picking another day');
  });
}
