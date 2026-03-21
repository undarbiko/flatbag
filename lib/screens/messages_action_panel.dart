import 'package:flutter/material.dart';

/// A contextual action panel that provides options for interacting with system logs.
class MessagesActionPanel extends StatelessWidget {
  final VoidCallback? onCopy;

  const MessagesActionPanel({super.key, required this.onCopy});

  @override
  Widget build(BuildContext context) {
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
                  "System Logs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text("View application and system activity", style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          _buildActionButton(context, icon: Icons.copy, label: 'Copy log to clipboard', color: const Color(0xFF86B0FF), onPressed: onCopy),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
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
        foregroundColor: MaterialStateProperty.all(onPressed != null ? Colors.black : Colors.grey),
      ),
      onPressed: onPressed,
    );
  }
}
