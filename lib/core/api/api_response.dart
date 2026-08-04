/// ===========================================================
/// INTELLEKT API RESPONSE
/// ===========================================================
///
/// Standard API Response Model
///
/// Every repository should return ApiResponse<T>.
///
/// Example:
///
/// ApiResponse<StudentModel>
/// ApiResponse<List<TestModel>>
///
/// ===========================================================

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  /// ------------------------------
  /// Success Response
  /// ------------------------------

  factory ApiResponse.success({
    required T data,
    String message = "Success",
    int statusCode = 200,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  /// ------------------------------
  /// Error Response
  /// ------------------------------

  factory ApiResponse.error({
    required String message,
    int statusCode = 500,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      statusCode: statusCode,
    );
  }

  /// ------------------------------
  /// Loading State
  /// ------------------------------

  factory ApiResponse.loading() {
    return ApiResponse<T>(
      success: false,
      message: "Loading...",
      data: null,
      statusCode: null,
    );
  }

  bool get hasData => data != null;

  bool get hasError => !success;

  @override
  String toString() {
    return '''
ApiResponse(
  success: $success,
  message: $message,
  statusCode: $statusCode,
  data: $data
)
''';
  }
}