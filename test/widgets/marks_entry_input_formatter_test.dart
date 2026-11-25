import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellekt_mobile/widgets/marks_entry_input_formatter.dart';

void main() {
  const formatter = MarksEntryInputFormatter();

  TextEditingValue format(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: oldText, selection: TextSelection.collapsed(offset: oldText.length)),
      TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length)),
    );
  }

  test('accepts zero and whole-number marks', () {
    expect(format('', '0').text, '0');
    expect(format('0', '100000').text, '100000');
    expect(format('1', '99999').text, '99999');
  });

  test('converts lowercase absent marker to uppercase', () {
    expect(format('', 'a').text, 'A');
    expect(format('A', 'a').text, 'A');
  });

  test('allows an empty field while editing', () {
    expect(format('12', '').text, '');
  });

  test('rejects values above 100000', () {
    expect(format('100000', '100001').text, '100000');
    expect(format('', '999999').text, '');
  });

  test('rejects letters other than A and mixed letters', () {
    expect(format('', 'B').text, '');
    expect(format('12', '12A').text, '12');
  });

  test('rejects special characters, negative and decimal values', () {
    expect(format('', '@').text, '');
    expect(format('', '-1').text, '');
    expect(format('12', '12.5').text, '12');
  });
}
