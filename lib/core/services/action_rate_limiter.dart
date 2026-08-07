import 'dart:collection';

class ActionRateLimiter {
  ActionRateLimiter._();
  static final ActionRateLimiter instance = ActionRateLimiter._();

  ///constant limit controller
  static const Duration _actionCooldown = Duration(milliseconds: 600);
  static const int _maxComments = 5;
  static const Duration _commentWindow = Duration(seconds: 60);
  static const Duration _commentBlock = Duration(seconds: 10);

  // Like / Follow / Save / Share
  final Map<String, DateTime> _lastAction = {};

  // Comments
  final Map<String, Queue<DateTime>> _commentTimestamps = {};
  final Map<String, DateTime> _commentBlockUntil = {};

  // ── Like / Follow / Save / Share ──────────────────────────────────────────

  /// Returns true if [actionKey] is outside the cooldown window.
  bool tryAcquire(String actionKey, {Duration? customCooldown}) {
    final now = DateTime.now();
    final cd = customCooldown ?? _actionCooldown;

    // Periodically clean up old entries to prevent memory leaks
    // since action keys might contain unique IDs (e.g., post IDs)
    if (_lastAction.length > 50) {
      _lastAction.removeWhere((_, time) => now.difference(time) > cd);
    }

    final last = _lastAction[actionKey];
    if (last != null && now.difference(last) < cd) return false;
    
    _lastAction[actionKey] = now;
    return true;
  }

  ///comment
  /// Returns true if [userId] can post a comment (5 per 60s, 10s block on limit).
  bool tryAcquireComment(String userId) {
    final now = DateTime.now();

    final block = _commentBlockUntil[userId];
    if (block != null) {
      if (now.isBefore(block)) return false;
      _commentBlockUntil.remove(userId);
      _commentTimestamps.remove(userId);
    }

    final ts = _commentTimestamps.putIfAbsent(userId, Queue.new);
    final cutoff = now.subtract(_commentWindow);
    ts.removeWhere((t) => t.isBefore(cutoff));

    if (ts.length < _maxComments) {
      ts.addLast(now);
      return true;
    }

    _commentBlockUntil[userId] = now.add(_commentBlock);
    return false;
  }

  /// Seconds remaining in the comment block cooldown. Returns 0 if not blocked.
  int commentCooldownRemaining(String userId) {
    final block = _commentBlockUntil[userId];
    if (block == null) return 0;
    final secs = block.difference(DateTime.now()).inSeconds;
    return secs > 0 ? secs : 0;
  }

  /// Clears all state. Call on sign-out.
  void clear() {
    _lastAction.clear();
    _commentTimestamps.clear();
    _commentBlockUntil.clear();
  }
}
