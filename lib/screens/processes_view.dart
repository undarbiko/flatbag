import 'package:flutter/material.dart';
import '../models/background_task.dart';
import '../state/home_state.dart';

/// The main view responsible for displaying queued, running, and completed background tasks.
class ProcessesView extends StatelessWidget {
  final HomeState state;
  const ProcessesView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final runningTask = state.currentTask;
    final queuedTasks = state.taskQueue;
    final completedTasks = state.completedTasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (runningTask == null && queuedTasks.isEmpty && completedTasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No background tasks have run in this session.', style: TextStyle(color: Colors.grey)),
            ),
          ),

        // --- Completed Tasks ---
        if (completedTasks.isNotEmpty) ...[
          Text('Completed', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ...completedTasks.map((task) => _TaskCard(task: task, isSelected: state.selectedTaskId == task.id, onTap: () => state.selectTask(task.id))),
          const Divider(height: 32),
        ],

        // --- Running Task ---
        if (runningTask != null) ...[
          Text('Running', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          _TaskCard(
            task: runningTask,
            isRunning: true,
            isSelected: state.selectedTaskId == runningTask.id,
            onTap: () => state.selectTask(runningTask.id),
          ),
          const Divider(height: 32),
        ],

        // --- Queued Tasks ---
        if (queuedTasks.isNotEmpty) ...[
          Text('Queued (${queuedTasks.length})', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          ...queuedTasks.map((task) => _TaskCard(task: task, isSelected: state.selectedTaskId == task.id, onTap: () => state.selectTask(task.id))),
        ],
      ],
    );
  }
}

/// A visual card representing a single background task and its current status.
class _TaskCard extends StatelessWidget {
  final BackgroundTask task;
  final bool isRunning;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskCard({required this.task, this.isRunning = false, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (task.status) {
      case TaskStatus.running:
        statusIcon = Icons.sync;
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case TaskStatus.queued:
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.grey;
        statusText = 'Queued';
        break;
      case TaskStatus.success:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Succeeded';
        break;
      case TaskStatus.failed:
        statusIcon = Icons.error;
        statusColor = Colors.red;
        statusText = 'Failed';
        break;
      case TaskStatus.canceled:
        statusIcon = Icons.cancel;
        statusColor = Colors.orange;
        statusText = 'Canceled';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      shape: isSelected
          ? RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        onTap: onTap,
        leading: Icon(statusIcon, color: statusColor, size: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(task.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRunning) ...[SizedBox(width: 50, child: LinearProgressIndicator(value: task.progress, minHeight: 4)), const SizedBox(width: 12)],
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
