import 'package:flutter/material.dart';
import '../models/flatpak_remote_app.dart';
import 'custom_action_button.dart';
import '../main.dart'; // Import to access SemanticColors

/// A contextual action panel that displays the selected remote app's name and provides install, execute, and details actions.
class RemoteActionsPanel extends StatelessWidget {
  final FlatpakRemoteApp? selectedApp;
  final VoidCallback? onInstall;
  final VoidCallback? onExecute;
  final VoidCallback? onDetails;

  const RemoteActionsPanel({super.key, required this.selectedApp, required this.onInstall, required this.onExecute, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final bool isInstalled = selectedApp?.isInstalled ?? false;
    final semanticColors = Theme.of(context).extension<SemanticColors>()!;

    return Container(
      width: double.infinity,
      color: selectedApp != null
          ? Theme.of(context).colorScheme.inversePrimary
          : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300]),
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
                  selectedApp?.summary ?? "Select an app from the list",
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CustomActionButton(
            icon: isInstalled ? Icons.play_arrow : Icons.download,
            label: isInstalled ? 'Execute' : 'Install',
            color: semanticColors.successButton,
            onPressed: isInstalled ? onExecute : onInstall,
          ),
          const SizedBox(width: 8),
          CustomActionButton(icon: Icons.info_outline, label: 'Details', color: semanticColors.infoButton, onPressed: onDetails),
        ],
      ),
    );
  }
}
