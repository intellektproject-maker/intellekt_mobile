import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/fee.dart';
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

  void _handlePay() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Online Payment'),
          content: const Text(
            'Online payment option will be available soon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusTable(Fee fee) {
    final totalFee = fee.totalFee;
    final feePaid = fee.feePaid;
    final balance = fee.balance;
    final fullyPaid = balance == 0;

    return SingleChildScrollView(
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
          color: Color(0xFF374151),
          fontSize: 14,
        ),
        columns: const [
          DataColumn(label: Text('Total Fee')),
          DataColumn(label: Text('Total Paid')),
          DataColumn(label: Text('Balance')),
          DataColumn(label: Text('Next Due')),
          DataColumn(label: Text('Payment')),
        ],
        rows: [
          DataRow(
            cells: [
              DataCell(Text('₹${_formatAmount(totalFee)}')),
              DataCell(Text('₹${_formatAmount(feePaid)}')),
              DataCell(
                Text(
                  '₹${_formatAmount(balance)}',
                  style: TextStyle(
                    color: fullyPaid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  fullyPaid ? 'Fully Paid' : _formatDate(fee.nextDue),
                ),
              ),
              DataCell(
                fullyPaid
                    ? const Text(
                        'Paid',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handlePay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Pay',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(Fee fee) {
    if (fee.paymentHistory.isEmpty) {
      if (fee.feePaid <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Payment history will appear here after payment records are added.',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 14,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment History',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF374151),
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
                color: Color(0xFF374151),
                fontSize: 14,
              ),
              columns: const [
                DataColumn(label: Text('Payment Date')),
                DataColumn(label: Text('Amount Paid')),
                DataColumn(label: Text('Total Paid')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Next Due')),
                DataColumn(label: Text('Status')),
              ],
              rows: fee.paymentHistory.map((payment) {
                final paymentBalance =
                    payment.balance ?? (fee.totalFee - payment.totalPaid);
                final safeBalance = paymentBalance < 0 ? 0 : paymentBalance;
                final fullyPaid = safeBalance == 0;

                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(payment.paymentDate))),
                    DataCell(
                      Text('₹${_formatAmount(payment.amountPaid)}'),
                    ),
                    DataCell(
                      Text('₹${_formatAmount(payment.totalPaid)}'),
                    ),
                    DataCell(
                      Text(
                        '₹${_formatAmount(safeBalance)}',
                        style: TextStyle(
                          color: fullyPaid
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        fullyPaid ? '-' : _formatDate(payment.nextDue),
                      ),
                    ),
                    DataCell(
                      Text(
                        fullyPaid ? 'Fully Paid' : 'Partially Paid',
                        style: TextStyle(
                          color: fullyPaid
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF97316),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECECEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000153),
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
            onRefresh: () => provider.refreshFees(widget.rollNo),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Fee Details',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.hasFees)
                  ...provider.fees.map(
                    (fee) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          const Text(
                            'Current Fee Status',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatusTable(fee),
                          _buildPaymentHistory(fee),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No fee records found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
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
