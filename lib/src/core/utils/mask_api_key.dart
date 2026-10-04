String? maskApiKey(String? key) => key == null || key.isEmpty
    ? null
    : key.length > 4
    ? '•••• ${key.substring(key.length - 4)}'
    : '••••';
