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

  Widget _buildStatusItem({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF374151),
  }) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTable(Fee fee) {
    final totalFee = fee.totalFee;
    final feePaid = fee.feePaid;
    final balance = fee.balance;
    final fullyPaid = balance == 0;

    return Column(
      children: [
        Row(
          children: [
            _buildStatusItem(
              label: 'Total Fee',
              value: '₹${_formatAmount(totalFee)}',
            ),
            const SizedBox(width: 10),
            _buildStatusItem(
              label: 'Total Paid',
              value: '₹${_formatAmount(feePaid)}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildStatusItem(
              label: 'Balance',
              value: '₹${_formatAmount(balance)}',
              valueColor: fullyPaid
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 10),
            _buildStatusItem(
              label: 'Next Due',
              value: fullyPaid ? 'Fully Paid' : _formatDate(fee.nextDue),
              valueColor: fullyPaid
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF374151),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: fullyPaid
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Fully Paid',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pay Fee',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(Fee fee) {
    if (fee.paymentHistory.isEmpty) {
      if (fee.feePaid <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'Payment history will appear here after payment records are added.',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment History',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...fee.paymentHistory.map((payment) {
            final paymentBalance =
                payment.balance ?? (fee.totalFee - payment.totalPaid);
            final safeBalance =
                (paymentBalance < 0 ? 0 : paymentBalance).toDouble();
            final fullyPaid = safeBalance == 0;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  _buildHistoryRow(
                    'Payment Date',
                    _formatDate(payment.paymentDate),
                  ),
                  _buildHistoryRow(
                    'Amount Paid',
                    '₹${_formatAmount(payment.amountPaid)}',
                  ),
                  _buildHistoryRow(
                    'Total Paid',
                    '₹${_formatAmount(payment.totalPaid)}',
                  ),
                  _buildHistoryRow(
                    'Balance',
                    '₹${_formatAmount(safeBalance)}',
                    valueColor: fullyPaid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                  _buildHistoryRow(
                    'Next Due',
                    fullyPaid ? '-' : _formatDate(payment.nextDue),
                  ),
                  _buildHistoryRow(
                    'Status',
                    fullyPaid ? 'Fully Paid' : 'Partially Paid',
                    valueColor: fullyPaid
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF97316),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    String label,
    String value, {
    Color valueColor = const Color(0xFF374151),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                const Text(
                  'Fee Details',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                if (provider.hasFees)
                  ...provider.fees.map(
                    (fee) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
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
                              fontSize: 19,
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
                      borderRadius: BorderRadius.circular(14),
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
