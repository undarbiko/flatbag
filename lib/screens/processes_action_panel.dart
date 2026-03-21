import 'package:flutter/material.dart';
import '../models/background_task.dart';
import '../state/home_state.dart';
import '../main.dart'; // Import to access SemanticColors

/// A contextual action panel for the process manager that provides controls for the selected background task.
class ProcessesActionPanel extends StatelessWidget {
  final HomeState state;
  const ProcessesActionPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final selectedTaskId = state.selectedTaskId;
    BackgroundTask? selectedTask;
    if (selectedTaskId != null) {
      final allTasks = [if (state.currentTask != null) state.currentTask!, ...state.taskQueue, ...state.completedTasks];
      try {
        selectedTask = allTasks.firstWhere((t) => t.id == selectedTaskId);
      } catch (e) {
        selectedTask = null;
      }
    }

    final bool hasSelection = selectedTask != null;
    final bool isRunning = hasSelection && selectedTask.status == TaskStatus.running;
    final semanticColors = Theme.of(context).extension<SemanticColors>()!;

    return Container(
      width: double.infinity,
      color: hasSelection ? Theme.of(context).colorScheme.inversePrimary : Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection ? selectedTask.name : "No Task Selected",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hasSelection ? Colors.black : Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasSelection ? selectedTask.type.name.toUpperCase() : "Select a task from the list",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildActionButton(
            icon: Icons.description_outlined,
            label: 'Show Log',
            color: semanticColors.infoButton,
            onPressed: hasSelection ? () => _showLogDialog(context, selectedTask!) : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.delete_outline,
            label: 'Remove Entry',
            color: semanticColors.warningButton,
            onPressed: (hasSelection && !isRunning) ? () => state.deleteTask(selectedTask!.id) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ButtonStyle(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return 0.0;
          return 3.0;
        }),
        shadowColor: WidgetStateProperty.all(Colors.black),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: Colors.grey[400]!, width: 1.0);
          }
          return const BorderSide(color: Colors.black45, width: 1.0);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey[200];
          return color;
        }),
        foregroundColor: WidgetStateProperty.all(onPressed != null ? Colors.black : Colors.grey),
      ),
      onPressed: onPressed,
    );
  }

  void _showLogDialog(BuildContext context, BackgroundTask task) {
    showDialog(
      context: context,
      builder: (context) {
        final ScrollController controller = ScrollController();
        return AlertDialog(
          title: Text('Log for ${task.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: task.log.isNotEmpty
                ? Scrollbar(
                    thumbVisibility: true,
                    controller: controller,
                    child: SingleChildScrollView(
                      controller: controller,
                      child: SelectableText(task.log.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ),
                  )
                : const Center(child: Text('No log entries.')),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
        );
      },
    );
  }
}
