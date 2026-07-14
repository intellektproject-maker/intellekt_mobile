import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/test.dart';
import '../../../providers/student/test_schedule_provider.dart';

class TestScheduleScreen extends StatefulWidget {
  final String rollNo;

  const TestScheduleScreen({super.key, required this.rollNo});

  @override
  State<TestScheduleScreen> createState() => _TestScheduleScreenState();
}

class _TestScheduleScreenState extends State<TestScheduleScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TestScheduleProvider>().loadTests(widget.rollNo);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return DateFormat('dd MMM yyyy').format(date);
  }

  List<DateTime> _buildWritingDates(Test test) {
    final testDate = test.testDate;
    final writingAllowedTill = test.writingAllowedTill;

    if (testDate == null || writingAllowedTill == null) {
      return [];
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(testDate.year, testDate.month, testDate.day);

    final end = DateTime(
      writingAllowedTill.year,
      writingAllowedTill.month,
      writingAllowedTill.day,
    );

    final dates = <DateTime>[];

    var current = start;

    while (!current.isAfter(end)) {
      if (!current.isBefore(today)) {
        dates.add(current);
      }

      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  Future<void> _showRegistrationDialog(Test test) async {
    final writingDates = _buildWritingDates(test);

    if (writingDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid writing dates available')),
      );

      return;
    }

    DateTime? selectedWritingDate;

    List<Map<String, dynamic>> slots = [];

    Map<String, dynamic>? selectedSlot;

    bool isLoadingSlots = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadSlots(DateTime date) async {
              setDialogState(() {
                isLoadingSlots = true;
                slots = [];
                selectedSlot = null;
              });

              final loadedSlots = await context
                  .read<TestScheduleProvider>()
                  .loadSlots(testCode: test.testCode ?? '', writingDate: date);

              if (!dialogContext.mounted) {
                return;
              }

              setDialogState(() {
                slots = loadedSlots;
                isLoadingSlots = false;
              });
            }

            return AlertDialog(
              title: const Text(
                'Register Test',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogDetail(
                      label: 'Test Code',
                      value: test.testCode ?? test.testName ?? 'Test',
                    ),

                    const SizedBox(height: 8),

                    _DialogDetail(
                      label: 'Subject',
                      value: test.subjectName ?? '-',
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Select Writing Date',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<DateTime>(
                      initialValue: selectedWritingDate,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose date',
                      ),
                      items: writingDates.map((date) {
                        return DropdownMenuItem<DateTime>(
                          value: date,
                          child: Text(_formatDate(date)),
                        );
                      }).toList(),
                      onChanged: (date) {
                        if (date == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedWritingDate = date;
                        });

                        loadSlots(date);
                      },
                    ),

                    const SizedBox(height: 20),

                    if (selectedWritingDate != null) ...[
                      const Text(
                        'Select Slot',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      if (isLoadingSlots)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (slots.isEmpty)
                        const Text(
                          'No slots available for this date.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        )
                      else
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: selectedSlot,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Choose slot',
                          ),
                          items: slots.map((slot) {
                            final start = slot['start']?.toString() ?? '';

                            final end = slot['end']?.toString() ?? '';

                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: slot,
                              child: Text('$start - $end'),
                            );
                          }).toList(),
                          onChanged: (slot) {
                            setDialogState(() {
                              selectedSlot = slot;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isLoadingSlots
                      ? null
                      : () {
                          if (selectedWritingDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a writing date'),
                              ),
                            );

                            return;
                          }

                          if (selectedSlot == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a slot'),
                              ),
                            );

                            return;
                          }

                          final start =
                              selectedSlot!['start']?.toString() ?? '';

                          final end = selectedSlot!['end']?.toString() ?? '';

                          final slotLabel = '$start - $end';

                          context.read<TestScheduleProvider>().registerTest(
                            test: test,
                            writingDate: selectedWritingDate!,
                            registeredSlotLabel: slotLabel,
                          );

                          Navigator.of(dialogContext).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'INTELLEKT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<TestScheduleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.errorMessage ?? 'Something went wrong',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        provider.loadTests(widget.rollNo);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return provider.refreshTests(widget.rollNo);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                const Text(
                  'Test Schedule',
                  style: TextStyle(
                    color: Color(0xFF1746C7),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 32),

                if (!provider.hasTests)
                  const _EmptyTestSchedule()
                else
                  ...provider.tests.map(
                    (test) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _TestCard(
                        test: test,
                        formatDate: _formatDate,
                        onRegister: () {
                          _showRegistrationDialog(test);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyTestSchedule extends StatelessWidget {
  const _EmptyTestSchedule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'No tests scheduled.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final Test test;

  final String Function(DateTime?) formatDate;

  final VoidCallback onRegister;

  const _TestCard({
    required this.test,
    required this.formatDate,
    required this.onRegister,
  });

  String _getSubjectName() {
    if (test.subjectName != null && test.subjectName!.isNotEmpty) {
      return test.subjectName!;
    }

    switch (test.subjectId) {
      case 1:
        return 'Maths';

      case 2:
        return 'Physics';

      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            test.testCode ?? test.testName ?? 'Test',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          _TestDetail(label: 'Subject', value: _getSubjectName()),

          _TestDetail(label: 'Test Date', value: formatDate(test.testDate)),

          _TestDetail(
            label: 'Total Marks',
            value: test.totalMarks?.toString() ?? '-',
          ),

          _TestDetail(
            label: 'Duration',
            value: test.durationMinutes == null
                ? '-'
                : '${test.durationMinutes} mins',
          ),

          _TestDetail(
            label: 'Registration Ends',
            value: formatDate(test.registrationEndDate),
          ),

          _TestDetail(
            label: 'Writing Allowed Till',
            value: formatDate(test.writingAllowedTill),
          ),

          if (test.portion != null && test.portion!.isNotEmpty) ...[
            const SizedBox(height: 8),

            _TestDetail(label: 'Portion', value: test.portion!),
          ],

          const SizedBox(height: 16),

          if (test.isRegistered)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Registered',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (test.writingDate != null) ...[
                  const SizedBox(height: 8),

                  Text(
                    'Date: ${formatDate(test.writingDate)}',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                    ),
                  ),
                ],

                if (test.registeredSlotLabel != null) ...[
                  const SizedBox(height: 4),

                  Text(
                    test.registeredSlotLabel!,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            )
          else
            ElevatedButton(
              onPressed: onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestDetail extends StatelessWidget {
  final String label;

  final String value;

  const _TestDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 15,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DialogDetail extends StatelessWidget {
  final String label;

  final String value;

  const _DialogDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 15),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
