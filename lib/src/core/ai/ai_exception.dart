class AiException implements Exception {
  const AiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) return message;
    return '$message ($statusCode)';
  }
}
