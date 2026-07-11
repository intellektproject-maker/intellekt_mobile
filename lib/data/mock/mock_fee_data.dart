const Map<String, dynamic> mockFeeData = {
  'roll_no': 'IA001',
  'student_name': 'Anushree P',
  'academic_year': '2026-2027',
  'total_fee': 50000,
  'paid_amount': 30000,
  'pending_amount': 20000,
  'status': 'Partially Paid',
  'payments': [
    {
      'payment_id': 1,
      'payment_date': '2026-06-01',
      'amount': 15000,
      'payment_mode': 'UPI',
    },
    {
      'payment_id': 2,
      'payment_date': '2026-07-01',
      'amount': 15000,
      'payment_mode': 'Cash',
    },
  ],
};