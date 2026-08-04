class TestCode {
  final String code;
  final String className;
  final String board;
  final String subject;

  const TestCode({
    required this.code,
    required this.className,
    required this.board,
    required this.subject,
  });

  factory TestCode.fromJson(Map<String, dynamic> json) {
    return TestCode(
      code: json['code'],
      className: json['className'],
      board: json['board'],
      subject: json['subject'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'className': className,
      'board': board,
      'subject': subject,
    };
  }
}