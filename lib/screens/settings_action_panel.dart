import 'package:flutter/material.dart';
import '../state/home_state.dart';

/// A contextual action panel that provides options to apply, cancel, or restore application settings.
class SettingsActionPanel extends StatelessWidget {
  final HomeState state;
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final VoidCallback onRestore;
  final VoidCallback onAbout;

  const SettingsActionPanel({
    super.key,
    required this.state,
    required this.onCancel,
    required this.onApply,
    required this.onRestore,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasChanges = state.settingsHasChanges;

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.inversePrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Settings",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text("Configure application behavior", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          _buildActionButton(context, icon: Icons.info_outline, label: 'About', color: const Color(0xFF86B0FF), onPressed: onAbout),
          const SizedBox(width: 8),
          _buildActionButton(context, icon: Icons.restore, label: 'Restore Defaults', color: const Color(0xFFFF994A), onPressed: onRestore),
          const SizedBox(width: 8),
          _buildActionButton(
            context,
            icon: Icons.cancel_outlined,
            label: 'Cancel',
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
            textColor: Theme.of(context).colorScheme.onSurface,
            onPressed: hasChanges ? onCancel : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(context, icon: Icons.check, label: 'Apply', color: const Color(0xFF7AE190), onPressed: hasChanges ? onApply : null),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ButtonStyle(
        elevation: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.disabled) ? 0.0 : 3.0),
        shadowColor: MaterialStateProperty.all(Colors.black),
        side: MaterialStateProperty.resolveWith(
          (states) => BorderSide(color: states.contains(MaterialState.disabled) ? Colors.grey[400]! : Colors.black45, width: 1.0),
        ),
        backgroundColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.disabled)
              ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200])
              : color,
        ),
        foregroundColor: MaterialStateProperty.all(onPressed != null ? (textColor ?? Colors.black) : Colors.grey),
      ),
      onPressed: onPressed,
    );
  }
}
