import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/student/request_pdf_provider.dart';

class RequestPdfScreen extends StatefulWidget {
  final String rollNo;

  const RequestPdfScreen({super.key, required this.rollNo});

  @override
  State<RequestPdfScreen> createState() => _RequestPdfScreenState();
}

class _RequestPdfScreenState extends State<RequestPdfScreen> {
  String? _selectedTestCode;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<RequestPdfProvider>();

      await provider.loadRequestPdfData(widget.rollNo);

      if (!mounted) {
        return;
      }

      final data = provider.data;

      if (data != null) {
        _phoneController.text = data.student.phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedTestCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a test code')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    final provider = context.read<RequestPdfProvider>();

    final success = await provider.submitRequest(
      rollNo: widget.rollNo,
      testCode: _selectedTestCode!,
      phone: _phoneController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? provider.successMessage ?? 'Request submitted successfully'
              : provider.errorMessage ?? 'Failed to submit request',
        ),
      ),
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
      body: Consumer<RequestPdfProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError && provider.data == null) {
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
                        provider.loadRequestPdfData(widget.rollNo);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = provider.data;

          if (data == null) {
            return const Center(child: Text('Request PDF data not found'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const Text(
                'Request PDF',
                style: TextStyle(
                  color: Color(0xFF1746C7),
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: data.student.name),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Roll Number', value: data.student.rollNo),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Class', value: data.student.studentClass),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Board', value: data.student.board),
                    const SizedBox(height: 28),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTestCode,
                      decoration: const InputDecoration(
                        labelText: 'Test Code',
                        border: OutlineInputBorder(),
                      ),
                      items: data.tests.map((test) {
                        return DropdownMenuItem<String>(
                          value: test.testCode,
                          child: Text(test.testCode),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTestCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: provider.isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
