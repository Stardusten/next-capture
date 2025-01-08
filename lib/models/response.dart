class ApiResponse<T> {
  final bool success;
  final String? code;
  final T? data;

  ApiResponse({
    required this.success,
    this.code,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      code: json['code'] as String?,
      data: json['data'] != null ? fromJson(json['data']) : null,
    );
  }
}
