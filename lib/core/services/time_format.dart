// lib/core/utils/time_format.dart
// Used by post_author_row, comment_tile, notifications_page, etc.
String timeAgoShort(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// Returns a longer "time ago"
/// Long form (e.g. "5m ago", "2h ago", "3 days ago") good for post headers.
String timeAgoLong(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// All-caps notification style (e.g. "5 MINUTES AGO", "JUST NOW").
String timeAgoUpperCase(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'JUST NOW';
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'MINUTE' : 'MINUTES'} AGO';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} ${diff.inHours == 1 ? 'HOUR' : 'HOURS'} AGO';
  }
  if (diff.inDays == 1) return 'YESTERDAY';
  return '${diff.inDays} DAYS AGO';
}

/// Feed card style — very short with no unit word for recent times.
String timeAgoFeed(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
