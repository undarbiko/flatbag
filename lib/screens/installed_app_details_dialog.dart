import 'package:flutter/material.dart';
import '../models/flatpak_app.dart';
import 'app_icon.dart';
import 'custom_action_button.dart';

/// A dialog displaying comprehensive technical details and metadata for an installed Flatpak application.
class InstalledAppDetailsDialog extends StatefulWidget {
  final FlatpakApp app;

  const InstalledAppDetailsDialog({super.key, required this.app});

  @override
  State<InstalledAppDetailsDialog> createState() => _InstalledAppDetailsDialogState();
}

class _InstalledAppDetailsDialogState extends State<InstalledAppDetailsDialog> {
  final ScrollController _detailsController = ScrollController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final app = widget.app;
    final dateStr = app.installDate != null
        ? '${app.installDate!.year}-${app.installDate!.month.toString().padLeft(2, '0')}-${app.installDate!.day.toString().padLeft(2, '0')}'
        : 'Unknown';
    final permissionsStr = app.permissions.map((p) => '• $p').join('\n');

    return Dialog(
      child: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.8,
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Installed App Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // --- App Info Header ---
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(iconPath: app.iconPath, size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(app.name, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        SelectableText(
                          app.description,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        if (app.categories.isNotEmpty) Wrap(spacing: 8, children: app.categories.map((c) => Chip(label: Text(c))).toList()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // --- Technical Details ---
            Expanded(
              child: Scrollbar(
                controller: _detailsController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _detailsController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Technical Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      _DetailRow(label: 'App ID', value: app.application),
                      if (app.version.isNotEmpty) _DetailRow(label: 'Version', value: app.version),
                      if (app.branch.isNotEmpty) _DetailRow(label: 'Branch', value: app.branch),
                      if (app.arch.isNotEmpty) _DetailRow(label: 'Architecture', value: app.arch),
                      if (app.runtime.isNotEmpty) _DetailRow(label: 'Runtime', value: app.runtime),
                      if (app.origin.isNotEmpty) _DetailRow(label: 'Origin', value: app.origin),
                      if (app.installation.isNotEmpty) _DetailRow(label: 'Installation', value: app.installation),
                      if (app.ref.isNotEmpty) _DetailRow(label: 'Ref', value: app.ref),
                      if (app.active.isNotEmpty) _DetailRow(label: 'Commit Active', value: app.active),
                      if (app.latest.isNotEmpty) _DetailRow(label: 'Commit Latest', value: app.latest),
                      if (app.size.isNotEmpty) _DetailRow(label: 'Size', value: app.size),
                      _DetailRow(label: 'Installed', value: dateStr),
                      const SizedBox(height: 24),
                      if (app.keywords.isNotEmpty) ...[
                        const Text('Keywords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        SelectableText(app.keywords.join(', ')),
                        const SizedBox(height: 24),
                      ],
                      if (app.permissions.isNotEmpty) ...[
                        const Text('Sandbox Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        SelectableText(permissionsStr),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // --- Footer ---
            Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 16.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomActionButton(
                    icon: Icons.exit_to_app,
                    label: 'Close',
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A reusable row component for displaying a key-value pair in the details list.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
