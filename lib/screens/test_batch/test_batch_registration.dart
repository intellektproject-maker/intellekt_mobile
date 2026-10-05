import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../services/student/test_batch_registration_service.dart';

class TestBatchRegistrationScreen extends StatefulWidget {
  final String rollNo;
  final String? subjectFilter;
  final String? categoryFilter;

  const TestBatchRegistrationScreen({
    super.key,
    required this.rollNo,
    this.subjectFilter,
    this.categoryFilter,
  });

  @override
  State<TestBatchRegistrationScreen> createState() =>
      _TestBatchRegistrationScreenState();
}

class _TestBatchRegistrationScreenState
    extends State<TestBatchRegistrationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _tests = [];
  String? _registeringCode;
  String? _expandedCode;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tests = await TestBatchRegistrationService.getTests(widget.rollNo);
      if (!mounted) return;
      final sortedTests = List<Map<String, dynamic>>.from(tests);
      sortedTests.sort((a, b) {
        final aRegistered = _isRegistered(a);
        final bRegistered = _isRegistered(b);

        // Tests still requiring registration always appear first.
        if (aRegistered != bRegistered) {
          return aRegistered ? 1 : -1;
        }

        // Keep the nearest relevant date first within each group.
        final aDate = _dateOnly(
          a['writing_date'] ?? a['application_close_date'] ?? a['test_date'],
        );
        final bDate = _dateOnly(
          b['writing_date'] ?? b['application_close_date'] ?? b['test_date'],
        );

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

      setState(() {
        _tests = sortedTests;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  DateTime? _dateOnly(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _formatDate(dynamic value) {
    final date = _dateOnly(value);
    return date == null ? '-' : DateFormat('dd MMM yyyy').format(date);
  }

  bool _isRegistered(Map<String, dynamic> test) =>
      test['is_registered'] == true;

  bool _isCompleted(Map<String, dynamic> test) {
    final status = test['status']?.toString().trim().toLowerCase() ?? '';
    return status == 'completed' || status == 'returned';
  }

  String _categoryForTest(Map<String, dynamic> test) {
    if (_isCompleted(test)) return 'Completed';
    if (_isRegistered(test)) return 'Registered';
    return 'Yet to Register';
  }

  bool _matchesSubject(Map<String, dynamic> test, String subject) {
    final value = test['subject_name']?.toString().trim().toLowerCase() ?? '';
    if (subject == 'Mathematics') return value.contains('math');
    if (subject == 'Physics') return value.contains('physics');
    return false;
  }

  List<Map<String, dynamic>> get _visibleTests {
    if (widget.subjectFilter == null || widget.categoryFilter == null) {
      return const [];
    }
    return _tests
        .where((test) =>
            _matchesSubject(test, widget.subjectFilter!) &&
            _categoryForTest(test) == widget.categoryFilter)
        .toList();
  }

  List<Map<String, dynamic>> _subjectTests(String subject) =>
      _tests.where((test) => _matchesSubject(test, subject)).toList();

  Future<void> _startRegistration(Map<String, dynamic> test) async {
    final openDate = _dateOnly(test['application_open_date']);
    final closeDate = _dateOnly(test['application_close_date']);

    final today = DateTime.now();
    final minimumDate = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 3));

    var firstDate = openDate ?? minimumDate;
    if (firstDate.isBefore(minimumDate)) firstDate = minimumDate;

    final lastDate = closeDate ?? firstDate;

    if (lastDate.isBefore(firstDate)) {
      _showMessage(
        'Registration is not currently available for this test.',
        isError: true,
      );
      return;
    }

    var selectedDate = _dateOnly(test['writing_date']);
    if (selectedDate == null ||
        selectedDate.isBefore(firstDate) ||
        selectedDate.isAfter(lastDate)) {
      selectedDate = firstDate;
    }

    final durationValue =
        int.tryParse(test['duration_minutes']?.toString() ?? '');
    if (durationValue != 90 && durationValue != 180) {
      _showMessage(
        'This test has an unsupported slot duration.',
        isError: true,
      );
      return;
    }
    final duration = durationValue!;

    var slots = _slotsForDate(selectedDate, duration);
    if (slots.isEmpty) {
      selectedDate = _nextDateWithSlots(firstDate, lastDate, duration);
      if (selectedDate == null) {
        _showMessage(
          'No valid test slots are available in the registration window.',
          isError: true,
        );
        return;
      }
      slots = _slotsForDate(selectedDate, duration);
    }

    String? selectedSlot;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        DateTime dialogDate = selectedDate!;
        List<Map<String, String>> dialogSlots = slots;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Register for Test',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        test['test_code']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Test date',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: firstDate,
                            lastDate: lastDate,
                            initialDate: dialogDate,
                            helpText: 'Select your test date',
                          );
                          if (picked == null) return;

                          final normalized =
                              DateTime(picked.year, picked.month, picked.day);
                          final newSlots =
                              _slotsForDate(normalized, duration);
                          if (newSlots.isEmpty) {
                            _showMessage(
                              'No valid slots are available on Sunday for this duration.',
                              isError: true,
                            );
                            return;
                          }

                          setSheetState(() {
                            dialogDate = normalized;
                            dialogSlots = newSlots;
                            selectedSlot = null;
                          });
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(dialogDate),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Available slot',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...dialogSlots.map(
                        (slot) => RadioListTile<String>(
                          value: slot['start']! + '|' + slot['end']!,
                          groupValue: selectedSlot,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            slot['label']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              selectedSlot = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: selectedSlot == null
                              ? null
                              : () async {
                                  final parts = selectedSlot!.split('|');
                                  Navigator.of(sheetContext).pop();
                                  await _register(
                                    test,
                                    DateFormat('yyyy-MM-dd').format(dialogDate),
                                    parts[0],
                                    parts[1],
                                  );
                                },
                          child: const Text('Confirm Registration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime? _nextDateWithSlots(
    DateTime firstDate,
    DateTime lastDate,
    int duration,
  ) {
    var date = firstDate;
    while (!date.isAfter(lastDate)) {
      if (_slotsForDate(date, duration).isNotEmpty) return date;
      date = date.add(const Duration(days: 1));
    }
    return null;
  }

  List<Map<String, String>> _slotsForDate(DateTime date, int duration) {
    final isSunday = date.weekday == DateTime.sunday;

    if (duration == 90) {
      if (isSunday) {
        return [
          {'start': '07:00', 'end': '08:30', 'label': '7:00 AM - 8:30 AM'},
          {'start': '08:30', 'end': '10:00', 'label': '8:30 AM - 10:00 AM'},
          {'start': '10:00', 'end': '11:30', 'label': '10:00 AM - 11:30 AM'},
          {'start': '11:30', 'end': '13:00', 'label': '11:30 AM - 1:00 PM'},
        ];
      }

      return [
        {'start': '17:30', 'end': '19:00', 'label': '5:30 PM - 7:00 PM'},
        {'start': '19:00', 'end': '20:30', 'label': '7:00 PM - 8:30 PM'},
      ];
    }

    if (duration == 180) {
      if (isSunday) {
        return [
          {'start': '07:00', 'end': '10:00', 'label': '7:00 AM - 10:00 AM'},
          {'start': '10:00', 'end': '13:00', 'label': '10:00 AM - 1:00 PM'},
        ];
      }

      return [
        {'start': '17:30', 'end': '20:30', 'label': '5:30 PM - 8:30 PM'},
      ];
    }

    return [];
  }

  Future<void> _register(
    Map<String, dynamic> test,
    String writingDate,
    String slotStart,
    String slotEnd,
  ) async {
    final testCode = test['test_code']?.toString() ?? '';
    if (testCode.isEmpty) return;

    setState(() => _registeringCode = testCode);

    try {
      await TestBatchRegistrationService.register(
        rollNo: widget.rollNo,
        testCode: testCode,
        writingDate: writingDate,
        slotStart: slotStart,
        slotEnd: slotEnd,
      );

      if (!mounted) return;
      _showMessage('Test registration completed successfully.');
      await _loadTests();
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _registeringCode = null);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subjectFilter;
    final category = widget.categoryFilter;
    final visibleTests = _visibleTests;

    final title = subject == null
        ? 'Test Registration'
        : category == null
            ? subject + ' Registration'
            : category;

    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTests,
        child: _loading
            ? ListView(children: const [
                SizedBox(height: 260),
                Center(child: CircularProgressIndicator()),
              ])
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 150),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(child: FilledButton(
                        onPressed: _loadTests,
                        child: const Text('Retry'),
                      )),
                    ],
                  )
                : subject == null
                    ? _subjectSelection()
                    : category == null
                        ? _categorySelection(subject)
                        : visibleTests.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  SizedBox(height: 150),
                                  Icon(Icons.event_busy_outlined, size: 56, color: Color(0xFF6B7280)),
                                  SizedBox(height: 14),
                                  Text('No tests in this section.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF4B5563))),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: visibleTests.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) => _testCard(visibleTests[index]),
                              ),
      ),
    );
  }

  Widget _subjectSelection() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        const Text('Select Subject', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 14),
        _subjectCard(subject: 'Mathematics', icon: Icons.calculate_outlined),
        const SizedBox(height: 14),
        _subjectCard(subject: 'Physics', icon: Icons.science_outlined),
      ],
    );
  }

  Widget _subjectCard({required String subject, required IconData icon}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TestBatchRegistrationScreen(rollNo: widget.rollNo, subjectFilter: subject))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Text(subject, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 30),
          ]),
        ),
      ),
    );
  }

  Widget _categorySelection(String subject) {
    final tests = _subjectTests(subject);
    final yetToRegister = tests.where((test) => _categoryForTest(test) == 'Yet to Register').length;
    final registered = tests.where((test) => _categoryForTest(test) == 'Registered').length;
    final completed = tests.where((test) => _categoryForTest(test) == 'Completed').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text(subject, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 16),
        _categoryCard(title: 'Yet to Register', subtitle: yetToRegister.toString() + (yetToRegister == 1 ? ' test' : ' tests'), icon: Icons.app_registration_outlined, category: 'Yet to Register'),
        const SizedBox(height: 12),
        _categoryCard(title: 'Registered', subtitle: registered.toString() + (registered == 1 ? ' test' : ' tests'), icon: Icons.event_available_outlined, category: 'Registered'),
        const SizedBox(height: 12),
        _categoryCard(title: 'Completed', subtitle: completed.toString() + (completed == 1 ? ' test' : ' tests'), icon: Icons.task_alt_outlined, category: 'Completed'),
      ],
    );
  }

  Widget _categoryCard({required String title, required String subtitle, required IconData icon, required String category}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TestBatchRegistrationScreen(rollNo: widget.rollNo, subjectFilter: widget.subjectFilter, categoryFilter: category))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 30),
          ]),
        ),
      ),
    );
  }

  Widget _testCard(Map<String, dynamic> test) {
    final registered = _isRegistered(test);
    final code = test['test_code']?.toString() ?? '-';
    final subject = test['subject_name']?.toString() ?? '-';
    final isExpanded = _expandedCode == code;

    final marks = test['total_marks']?.toString() ?? '-';
    final duration = test['duration_minutes']?.toString() ?? '-';
    final portion = test['portion']?.toString() ?? '';
    final chapter = test['chapter']?.toString() ?? '';

    final details = <String>[
      'Test date: ${_formatDate(test['test_date'])}',
      'Marks: $marks',
      'Duration: $duration minutes',
      if (portion.isNotEmpty) 'Portion: $portion',
      if (chapter.isNotEmpty) 'Chapter: $chapter',
      'Registration: ${_formatDate(test['application_open_date'])} - ${_formatDate(test['application_close_date'])}',
    ];

    if (registered) {
      details.add(
        'Registered writing date: ${_formatDate(test['registered_writing_date'])}',
      );
      final slotStart = test['registered_slot_start']?.toString();
      final slotEnd = test['registered_slot_end']?.toString();
      if (slotStart != null &&
          slotEnd != null &&
          slotStart.isNotEmpty &&
          slotEnd.isNotEmpty) {
        details.add('Registered slot: ${_slotLabel(slotStart, slotEnd)}');
      }
    }

    return Card(
      elevation: isExpanded ? 3 : 2,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedCode = isExpanded ? null : code;
              });
            },
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$subject  •  $code',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _statusChip(
                    _isCompleted(test)
                        ? 'Completed'
                        : registered
                            ? 'Registered'
                            : 'Available',
                    _isCompleted(test) || registered,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        detail,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  if (!registered && !_isCompleted(test)) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: _registeringCode == code
                            ? null
                            : () => _startRegistration(test),
                        icon: _registeringCode == code
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.app_registration_outlined,
                              ),
                        label: Text(
                          _registeringCode == code
                              ? 'Registering...'
                              : 'Register for Test',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool registered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: registered
            ? Colors.green.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: registered ? Colors.green.shade700 : AppColors.primary,
        ),
      ),
    );
  }

  String _slotLabel(String start, String end) {
    String format(String value) {
      final parts = value.split(':');
      if (parts.length < 2) return value;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1].substring(0, 2);
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:$minute $suffix';
    }

    return '${format(start)} - ${format(end)}';
  }
}
