import 'dart:async';

import 'package:flutter/material.dart';

/// Search box for list screens.
///
/// The screen owns [controller], so the typed text stays put while the list
/// below reloads. [onSearch] fires after a short pause in typing, on the
/// keyboard's search key, and with '' when the clear button is tapped.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hint = 'Search',
    this.debounce = const Duration(milliseconds: 400),
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final String hint;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onSearch(value.trim()));
  }

  void _submit(String value) {
    _timer?.cancel();
    widget.onSearch(value.trim());
  }

  void _clear() {
    _timer?.cancel();
    widget.controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) => TextField(
        controller: widget.controller,
        onChanged: _changed,
        onSubmitted: _submit,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close_rounded, size: 20), tooltip: 'Clear search', onPressed: _clear),
        ),
      ),
    );
  }
}
