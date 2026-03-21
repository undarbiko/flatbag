import 'package:flutter/material.dart';

/// A standardized button component used across various action panels in the application.
class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback? onPressed;

  const CustomActionButton({super.key, required this.icon, required this.label, required this.color, this.textColor, this.onPressed});

  @override
  Widget build(BuildContext context) {
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
          if (states.contains(WidgetState.disabled)) return Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200];
          return color;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.grey;
          return textColor ?? Colors.black;
        }),
      ),
      onPressed: onPressed,
    );
  }
}
