import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/posted_test.dart';
import '../../../providers/faculty/test_management/post_test_provider.dart';

class PostTestScreen extends StatefulWidget {
  const PostTestScreen({super.key});

  @override
  State<PostTestScreen> createState() => _PostTestScreenState();
}

class _PostTestScreenState extends State<PostTestScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _testCodeController =
  TextEditingController();

  final TextEditingController _portionController =
  TextEditingController();

  final TextEditingController _chapterController =
  TextEditingController();

  final TextEditingController _searchController =
  TextEditingController();

  String? _selectedClass;
  String? _selectedBoard;
  String? _selectedSubject;

  DateTime? _testDate;
  DateTime? _registrationEndDate;
  DateTime? _writingAllowedTill;

  int? _totalMarks;
  int? _durationMinutes;

  PostedTest? _editingTest;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<PostTestProvider>().loadTests();
    });
  }

  @override
  void dispose() {
    _testCodeController.dispose();
    _portionController.dispose();
    _chapterController.dispose();
    _searchController.dispose();

    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<PostTestProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Post Test',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Test Code',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                          setState(() {});
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      provider.search(value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 20),

Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Post Test',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 24),

Row(
children: [
Expanded(
child: TextFormField(
controller: _testCodeController,
decoration: const InputDecoration(
labelText: 'Test Code',
border: OutlineInputBorder(),
),
validator: (value) {
if (value == null || value.trim().isEmpty) {
return 'Enter Test Code';
}
return null;
},
),
),

const SizedBox(width: 16),

Expanded(
child: DropdownButtonFormField<String>(
value: _selectedSubject,
decoration: const InputDecoration(
labelText: 'Subject',
border: OutlineInputBorder(),
),
items: const [
DropdownMenuItem(
value: 'Mathematics',
child: Text('Mathematics'),
),
DropdownMenuItem(
value: 'Physics',
child: Text('Physics'),
),
DropdownMenuItem(
value: 'Chemistry',
child: Text('Chemistry'),
),
DropdownMenuItem(
value: 'Biology',
child: Text('Biology'),
),
],
onChanged: (value) {
setState(() {
_selectedSubject = value;
});
},
validator: (value) {
if (value == null) {
return 'Select Subject';
}
return null;
},
),
),
],
),

  const SizedBox(height: 20),

  Row(
    children: [
      Expanded(
        child: TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Test Date',
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
            hintText: _testDate == null
                ? 'Select Date'
                : '${_testDate!.day}/${_testDate!.month}/${_testDate!.year}',
          ),
          validator: (_) {
            if (_testDate == null) {
              return 'Select Test Date';
            }
            return null;
          },
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2035),
            );

            if (picked != null) {
              setState(() {
                _testDate = picked;
              });
            }
          },
        ),
      ),

      const SizedBox(width: 16),

      Expanded(
        child: TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Marks',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter Total Marks';
            }

            final marks = int.tryParse(value);

            if (marks == null || marks <= 0) {
              return 'Invalid Marks';
            }

            return null;
          },
          onChanged: (value) {
            _totalMarks = int.tryParse(value);
          },
        ),
      ),
    ],
  ),
  const SizedBox(height: 20),

  Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: _portionController,
          decoration: const InputDecoration(
            labelText: 'Portion',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter Portion';
            }
            return null;
          },
        ),
      ),

      const SizedBox(width: 16),

      Expanded(
        child: TextFormField(
          controller: _chapterController,
          decoration: const InputDecoration(
            labelText: 'Chapter',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter Chapter';
            }
            return null;
          },
        ),
      ),
    ],
  ),
],
  Row(
    children: [
      Expanded(
        child: TextFormField(
          controller: _chapterController,
          decoration: const InputDecoration(
            labelText: 'Chapter',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter Chapter';
            }
            return null;
          },
        ),
      ),
    ],
  ),
  ],
),
),
),
),
),
),
),
),

            const SizedBox(height: 24),

// Table goes her

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}