class HnApiException implements Exception {
  HnApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'HnApiException: $message';
    }
    return 'HnApiException($statusCode): $message';
  }
}
