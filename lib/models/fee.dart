class Fee {
  final double totalFee;
  final double feePaid;
  final DateTime? nextDue;

  const Fee({required this.totalFee, required this.feePaid, this.nextDue});

  double get balance {
    final remainingBalance = totalFee - feePaid;

    if (remainingBalance < 0) {
      return 0;
    }

    return remainingBalance;
  }

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      totalFee: _parseDouble(json['total_fee']),
      feePaid: _parseDouble(json['fee_paid']),
      nextDue: DateTime.tryParse(json['next_due']?.toString() ?? ''),
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
