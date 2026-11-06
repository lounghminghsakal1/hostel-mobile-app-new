extension TextUtils on String {
  /// "Aarav Mehta" → "AM".
  String get initials {
    final words = trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1)).toUpperCase();
  }

  /// "9845012345" → "98450 12345".
  String get asPhone {
    final digits = replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return this;
    return '${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  /// "WAITING_FOR_APPROVAL" → "Waiting for approval".
  String get humanize {
    final lower = toLowerCase().replaceAll('_', ' ');
    return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  }

  String get firstName => trim().split(RegExp(r'\s+')).first;
}

extension NumberFormatting on num {
  /// 3450 → "₹3,450"; keeps paise when present.
  String get asRupees {
    final whole = this == truncate();
    final fixed = whole ? truncate().toString() : toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    // Indian grouping: last 3 digits, then pairs.
    if (digits.length <= 3) {
      buffer.write(digits);
    } else {
      final head = digits.substring(0, digits.length - 3);
      final tail = digits.substring(digits.length - 3);
      final pairs = <String>[];
      for (var i = head.length; i > 0; i -= 2) {
        pairs.insert(0, head.substring(i - 2 < 0 ? 0 : i - 2, i));
      }
      buffer
        ..write(pairs.join(','))
        ..write(',')
        ..write(tail);
    }
    return '₹$buffer${parts.length > 1 ? '.${parts[1]}' : ''}';
  }
}
