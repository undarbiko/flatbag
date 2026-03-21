/// Defines the type of operation a background task is performing.
enum TaskType { install, uninstall, update, migrate, sync, other }

/// Defines the current execution state of a background task.
enum TaskStatus { queued, running, success, failed, canceled }

/// Represents a long-running background operation, such as installing or updating an application.
class BackgroundTask {
  final String id;
  final TaskType type;
  final String name;
  final String? details;
  TaskStatus status;
  double progress;
  final List<String> log;
  final DateTime startTime;
  DateTime? endTime;

  BackgroundTask({
    required this.id,
    required this.type,
    required this.name,
    this.details,
    this.status = TaskStatus.queued,
    this.progress = 0.0,
    List<String>? log,
    DateTime? startTime,
    this.endTime,
  }) : log = log ?? [],
       startTime = startTime ?? DateTime.now();

  BackgroundTask copyWith({TaskStatus? status, double? progress, List<String>? log, DateTime? endTime}) {
    return BackgroundTask(
      id: id,
      type: type,
      name: name,
      details: details,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      log: log ?? this.log,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
