import 'package:flutter/material.dart';
import '../../models/flatpak_app.dart';
import 'custom_action_button.dart';
import '../main.dart'; // Import to access SemanticColors

/// A contextual action panel that displays the selected app's name and provides execution, details, and uninstallation actions.
class ActionsPanel extends StatelessWidget {
  final FlatpakApp? selectedApp;
  final VoidCallback? onExecute;
  final VoidCallback? onDetails;
  final VoidCallback? onUninstall;

  const ActionsPanel({super.key, required this.selectedApp, required this.onExecute, required this.onDetails, required this.onUninstall});

  @override
  Widget build(BuildContext context) {
    final semanticColors = Theme.of(context).extension<SemanticColors>()!;

    return Container(
      width: double.infinity,
      color: selectedApp != null
          ? Theme.of(context).colorScheme.inversePrimary
          : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]), // Dim the background if nothing is selected
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedApp?.name ?? "No App Selected",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: selectedApp != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  selectedApp?.categories.join(' • ') ?? "Select an app from the list",
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          CustomActionButton(icon: Icons.play_arrow, label: 'Execute', color: semanticColors.successButton, onPressed: onExecute),
          const SizedBox(width: 8),
          CustomActionButton(icon: Icons.info_outline, label: 'Details', color: semanticColors.infoButton, onPressed: onDetails),
          const SizedBox(width: 8),
          CustomActionButton(icon: Icons.delete_outline, label: 'Uninstall', color: semanticColors.warningButton, onPressed: onUninstall),
        ],
      ),
    );
  }
}
