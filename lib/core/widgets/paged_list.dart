import 'package:flutter/material.dart';

import '../models/paginated.dart';
import '../theme/app_dimens.dart';
import 'cards.dart';
import 'state_views.dart';

/// A pull-to-refresh list that loads pages as you scroll.
///
/// Pass the current search and filters as [query]: when it changes, the list
/// starts over from page 1 but keeps its [header] widgets, so a search field
/// there keeps its text and keyboard focus. (A new `key` also starts over, but
/// rebuilds the header too.)
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    this.query,
    this.header = const [],
    this.empty,
    this.grouped = false,
    this.columns = 1,
    this.gap = 12,
    this.bottomPadding = 24,
  });

  /// Lays items out in a grid with this many columns.
  final int columns;

  final Future<PageResult<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// The search and filters behind [fetch]; the list reloads when it changes.
  /// Use a value with `==`, such as a record: `(search, status)`.
  final Object? query;

  /// Widgets shown above the items (search, chips, summaries).
  final List<Widget> header;
  final Widget? empty;

  /// Puts all rows in one card separated by hairlines.
  final bool grouped;
  final double gap;
  final double bottomPadding;

  @override
  State<PagedList<T>> createState() => PagedListState<T>();
}

class PagedListState<T> extends State<PagedList<T>> {
  final List<T> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  /// Bumped on every restart, so a page that arrives for an old query is dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  @override
  void didUpdateWidget(covariant PagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) refresh();
  }

  Future<void> refresh() async {
    _generation++;
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    await _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loading || !_hasMore) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.fetch(_page + 1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(result.items);
        _page += 1;
        _hasMore = result.hasMore;
      });
    } on Object catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[...widget.header];

    if (_items.isEmpty) {
      if (_loading) {
        children.add(const LoadingView());
      } else if (_error != null) {
        children.add(ErrorView(error: _error!, onRetry: refresh));
      } else {
        children.add(widget.empty ?? const EmptyView(title: 'Nothing here yet', message: 'New items will show up here.'));
      }
    } else {
      final rows = [for (final item in _items) widget.itemBuilder(context, item)];
      if (widget.grouped) {
        children.add(GroupedCard(children: rows));
      } else if (widget.columns > 1) {
        for (var i = 0; i < rows.length; i += widget.columns) {
          children.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < widget.columns; c++) ...[
                if (c > 0) SizedBox(width: widget.gap),
                Expanded(child: i + c < rows.length ? rows[i + c] : const SizedBox.shrink()),
              ],
            ],
          ));
        }
      } else {
        children.addAll(rows);
      }
      if (_loading) children.add(const LoadingView(padding: EdgeInsets.all(16)));
      if (_error != null) children.add(ErrorView(error: _error!, onRetry: _loadNext));
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 400 && _hasMore && !_loading && _error == null) _loadNext();
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 4, AppSpacing.gutter, widget.bottomPadding),
          itemCount: children.length,
          separatorBuilder: (_, i) => SizedBox(height: i < widget.header.length ? 14 : widget.gap),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    );
  }
}
