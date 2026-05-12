import 'package:intl/intl.dart';

class TimeFormatter {
  const TimeFormatter._();

  static String relativeFromUnixSeconds(int unixSeconds) {
    final itemTime = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final now = DateTime.now();
    final diff = now.difference(itemTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(itemTime);
  }
}
