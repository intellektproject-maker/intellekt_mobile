import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/student/fee_provider.dart';

class FeeScreen extends StatefulWidget {
  final String rollNo;

  const FeeScreen({super.key, required this.rollNo});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeeProvider>().loadFees(widget.rollNo);
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return DateFormat('dd-MM-yyyy').format(date);
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
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
      body: Consumer<FeeProvider>(
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
                        provider.loadFees(widget.rollNo);
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
              return provider.refreshFees(widget.rollNo);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                const Text(
                  'Fee Details',
                  style: TextStyle(
                    color: Color(0xFF1746C7),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
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
                  child: provider.hasFees
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF1D4ED8),
                            ),
                            border: TableBorder.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                            headingTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            dataTextStyle: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Text('Total Fee')),
                              DataColumn(label: Text('Fee Paid')),
                              DataColumn(label: Text('Balance')),
                              DataColumn(label: Text('Next Due')),
                            ],
                            rows: provider.fees.map((fee) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(_formatAmount(fee.totalFee))),
                                  DataCell(Text(_formatAmount(fee.feePaid))),
                                  DataCell(
                                    Text(
                                      _formatAmount(fee.balance),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(fee.nextDue))),
                                ],
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'No fee records found',
                              style: TextStyle(color: Colors.grey),
                            ),
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
