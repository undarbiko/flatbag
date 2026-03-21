/// A singleton utility for maintaining a session-wide application log.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal();

  final List<String> _logs = [];

  /// Returns a view of the current logs.
  List<String> get logs => _logs;

  /// Appends a new message to the log with the current timestamp.
  void addMessage(String message) {
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    _logs.add("[$timeString] $message");
  }

  /// Clears all existing log entries.
  void clear() {
    _logs.clear();
  }
}
