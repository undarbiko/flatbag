import 'package:flutter/material.dart';
import '../models/flatpak_app.dart';
import '../state/home_state.dart';

/// A contextual action panel for the updates view, allowing users to process individual or all available updates.
class UpdatesActionPanel extends StatelessWidget {
  final HomeState state;

  const UpdatesActionPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    FlatpakApp? selectedUpdate;
    if (state.selectedAppId != null) {
      selectedUpdate = state.flatpakUpdates.where((a) => a.uniqueId == state.selectedAppId).firstOrNull;
    }

    final bool hasSelection = selectedUpdate != null;
    final bool hasUpdates = state.filteredUpdates.isNotEmpty;

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
                  hasSelection ? selectedUpdate.name : "No Update Selected",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: hasSelection ? Colors.black : Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasSelection
                      ? (selectedUpdate.eolMessage != null ? '⚠️ End of Life / Migration' : 'New Version: ${selectedUpdate.version}')
                      : "Select an update from the list or process all",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildActionButton(
            icon: Icons.update,
            label: 'Process Selected',
            color: const Color(0xFF86B0FF),
            onPressed: hasSelection
                ? () {
                    if (selectedUpdate!.eolMessage != null) {
                      if (selectedUpdate.eolRebaseId != null) {
                        state.migrateApp(selectedUpdate);
                      } else {
                        state.uninstallApp(selectedUpdate.name, selectedUpdate.application, selectedUpdate.installation);
                      }
                    } else {
                      state.updateApp(selectedUpdate);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.system_update_alt,
            label: 'Process All Shown',
            color: const Color(0xFF7AE190),
            onPressed: hasUpdates ? () => state.updateAllApps() : null,
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
        elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? 0.0 : 3.0),
        shadowColor: MaterialStateProperty.all(Colors.black),
        side: MaterialStateProperty.resolveWith(
          (states) => BorderSide(color: states.contains(MaterialState.disabled) ? Colors.grey[400]! : Colors.black45, width: 1.0),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? Colors.grey[200] : color),
        foregroundColor: MaterialStateProperty.all(onPressed != null ? Colors.black : Colors.grey),
      ),
      onPressed: onPressed,
    );
  }
}
