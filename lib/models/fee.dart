class Fee {
  final double totalFee;
  final double feePaid;
  final DateTime? nextDue;
  final List<FeePayment> paymentHistory;

  const Fee({
    required this.totalFee,
    required this.feePaid,
    this.nextDue,
    this.paymentHistory = const [],
  });

  double get balance {
    final remainingBalance = totalFee - feePaid;

    if (remainingBalance < 0) {
      return 0;
    }

    return remainingBalance;
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    final paymentHistoryJson = json['payment_history'];

    return Fee(
      totalFee: _parseDouble(json['total_fee']),
      feePaid: _parseDouble(json['fee_paid']),
      nextDue: DateTime.tryParse(json['next_due']?.toString() ?? ''),
      paymentHistory: paymentHistoryJson is List
          ? paymentHistoryJson
              .whereType<Map>()
              .map(
                (payment) => FeePayment.fromJson(
                  Map<String, dynamic>.from(payment),
                ),
              )
              .toList()
          : const [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class FeePayment {
  final DateTime? paymentDate;
  final double amountPaid;
  final double totalPaid;
  final double? balance;
  final DateTime? nextDue;

  const FeePayment({
    this.paymentDate,
    required this.amountPaid,
    required this.totalPaid,
    this.balance,
    this.nextDue,
  });

  double get calculatedBalance {
    final remaining = balance ?? 0;
    return remaining < 0 ? 0 : remaining;
  }

  factory FeePayment.fromJson(Map<String, dynamic> json) {
    return FeePayment(
      paymentDate:
          DateTime.tryParse(json['payment_date']?.toString() ?? ''),
      amountPaid: Fee._parseDouble(json['amount_paid']),
      totalPaid: Fee._parseDouble(json['total_paid']),
      balance: json['balance'] == null
          ? null
          : Fee._parseDouble(json['balance']),
      nextDue: DateTime.tryParse(json['next_due']?.toString() ?? ''),
    );
  }
}
