import 'package:flutter/material.dart';

import '../../../../models/test_code.dart';

class TestCodeDropdown extends StatelessWidget {
  final List<TestCode> codes;
  final TestCode? selected;
  final Function(TestCode?) onChanged;

  const TestCodeDropdown({
    super.key,
    required this.codes,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TestCode>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: "Test Code",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: codes.map((test) {
        return DropdownMenuItem<TestCode>(
          value: test,
          child: Text(
            "${test.code} — ${test.className} — ${test.board}",
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}