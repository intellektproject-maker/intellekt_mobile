import 'package:flutter/services.dart';

/// Allows whole-number marks (0–100000) or A for absent.
/// Lowercase a is normalized to uppercase A.
class MarksEntryInputFormatter extends TextInputFormatter {
  const MarksEntryInputFormatter();

  static final RegExp _valid = RegExp(r'^(?:A|[0-9]{0,6})$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text.toUpperCase();
    if (!_valid.hasMatch(normalized)) return oldValue;

    if (normalized.isNotEmpty && normalized != 'A') {
      final value = int.tryParse(normalized);
      if (value == null || value > 100000) return oldValue;
    }

    return newValue.copyWith(text: normalized, composing: TextRange.empty);
  }
}
