import 'package:flutter/material.dart';
import '../state/home_state.dart';

/// The main view for configuring application preferences, layout defaults, and appearance.
class SettingsView extends StatelessWidget {
  final HomeState state;
  const SettingsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: state.scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: state.scrollController,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Application Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // --- General Settings ---
            CheckboxListTile(
              title: const Text('Persist Window Size on Exit', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Restore the application window to its last used size upon startup.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: state.draftSettings.persistWindowSize,
              onChanged: (bool? value) {
                state.updateDraftSettings(persistWindowSize: value);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Auto-Check for Updates', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Fetch remote app data in the background upon startup.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.autoCheckUpdates,
              onChanged: (bool? value) {
                state.updateDraftSettings(autoCheckUpdates: value);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Default Installation Scope', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Select the default scope when installing new applications.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.draftSettings.defaultInstallScope,
                      items: const [
                        DropdownMenuItem(
                          value: 'ask',
                          child: Text('Ask every time', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Current User', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System-wide', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      onChanged: (String? value) => state.updateDraftSettings(defaultInstallScope: value),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Default Installed Apps View', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Select how installed applications are displayed by default.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: state.draftSettings.defaultInstalledAppsView,
                      items: const [
                        DropdownMenuItem(value: -1, child: Text('Remember Last Used', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 0, child: Text('List', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 1, child: Text('Grid Cards', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 2, child: Text('Icons', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (int? value) => state.updateDraftSettings(defaultInstalledAppsView: value),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Default Remote Apps View', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Select how available remote applications are displayed by default.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: state.draftSettings.defaultRemoteAppsView,
                      items: const [
                        DropdownMenuItem(value: -1, child: Text('Remember Last Used', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 0, child: Text('List', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 1, child: Text('Grid Cards', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 2, child: Text('Icons', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (int? value) => state.updateDraftSettings(defaultRemoteAppsView: value),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // --- Appearance Settings ---
            const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme Mode', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Select the overall color theme of the application.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.draftSettings.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('Default', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Light Mode', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text('Dark Mode', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      onChanged: (String? value) => state.updateDraftSettings(themeMode: value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Font Scale', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Adjust the global font size of the application.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: state.draftSettings.textScale,
                      items: const [
                        DropdownMenuItem(value: 0.8, child: Text('Small', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 1.0, child: Text('Normal', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 1.2, child: Text('Large', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: 1.4, child: Text('Extra Large', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (double? value) => state.updateDraftSettings(textScale: value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Accent Color', style: TextStyle(fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Choose a primary accent color for the interface.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    _buildColorOption(context, 0xFF9BA2FF), // Purple
                    _buildColorOption(context, 0xFF7AE190), // Green
                    _buildColorOption(context, 0xFF86B0FF), // Blue
                    _buildColorOption(context, 0xFFFF994A), // Orange
                    _buildColorOption(context, 0xFFF472B6), // Pink
                    _buildColorOption(context, 0xFFEF4444), // Red
                    _buildColorOption(context, 0xFF14B8A6), // Teal
                    _buildColorOption(context, 0xFF6366F1), // Indigo
                    _buildColorOption(context, 0xFF6B7280), // Grey
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // --- Icon View Settings ---
            const Text('Icon View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Main Category', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Display the primary category of the application in the icon view.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: state.draftSettings.iconViewShowCategory,
              onChanged: (bool? value) {
                state.updateDraftSettings(iconViewShowCategory: value);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Version', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application version in the icon view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.iconViewShowVersion,
              onChanged: (bool? value) {
                state.updateDraftSettings(iconViewShowVersion: value);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 32),

            // --- Grid View Settings ---
            const Text('Grid View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Main Category', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Display the primary category of the application in the grid view.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: state.draftSettings.gridViewShowCategory,
              onChanged: (bool? value) => state.updateDraftSettings(gridViewShowCategory: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Version', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application version in the grid view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.gridViewShowVersion,
              onChanged: (bool? value) => state.updateDraftSettings(gridViewShowVersion: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show AppId', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application ID in the grid view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.gridViewShowAppId,
              onChanged: (bool? value) => state.updateDraftSettings(gridViewShowAppId: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Size', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the package size in the grid view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.gridViewShowSize,
              onChanged: (bool? value) => state.updateDraftSettings(gridViewShowSize: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Date', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the date information in the grid view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.gridViewShowDate,
              onChanged: (bool? value) => state.updateDraftSettings(gridViewShowDate: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(height: 32),

            // --- List View Settings ---
            const Text('List View', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show Main Category', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Display the primary category of the application in the list view.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: state.draftSettings.listViewShowCategory,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowCategory: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Version', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application version in the list view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.listViewShowVersion,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowVersion: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show AppId', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application ID in the list view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.listViewShowAppId,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowAppId: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Size', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the package size in the list view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.listViewShowSize,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowSize: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Date', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the date information in the list view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.listViewShowDate,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowDate: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Show Description', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Display the application description in the list view.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: state.draftSettings.listViewShowDescription,
              onChanged: (bool? value) => state.updateDraftSettings(listViewShowDescription: value),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(BuildContext context, int colorValue) {
    final isSelected = state.draftSettings.accentColor == colorValue;
    return InkWell(
      onTap: () => state.updateDraftSettings(accentColor: colorValue),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 3),
          boxShadow: isSelected ? [BoxShadow(color: Color(colorValue).withOpacity(0.6), blurRadius: 8)] : [],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.black54, size: 20) : null,
      ),
    );
  }
}
