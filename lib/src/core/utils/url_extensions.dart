extension UrlHostExtension on String? {
  String hostOrFallback([String fallback = '--']) {
    final value = this;
    if (value == null || value.isEmpty) return fallback;
    final uri = Uri.tryParse(value);
    return uri?.host.isNotEmpty == true ? uri!.host : fallback;
  }
}
