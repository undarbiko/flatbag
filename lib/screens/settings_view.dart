import 'package:flutter/material.dart';
import '../state/home_state.dart';

/// The main view for configuring application preferences, layout defaults, and appearance.
class SettingsView extends StatelessWidget {
  final HomeState state;
  const SettingsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final sectionDivider = Divider(height: 32, thickness: 1.0, color: Theme.of(context).dividerColor);

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
            const SizedBox(height: 24),

            // --- General Settings ---
            _SettingsSection(
              children: [
                _SettingsCheckboxRow(
                  title: 'Persist Window Size on Exit',
                  subtitle: 'Restore the application window to its last used size upon startup.',
                  value: state.draftSettings.persistWindowSize,
                  onChanged: (value) => state.updateDraftSettings(persistWindowSize: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Auto-Check for Updates',
                  subtitle: 'Fetch remote app data in the background upon startup.',
                  value: state.draftSettings.autoCheckUpdates,
                  onChanged: (value) => state.updateDraftSettings(autoCheckUpdates: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Perform Main Action on Double-Click',
                  subtitle: 'Run installed apps or install remote apps when double-clicking an item.',
                  value: state.draftSettings.doubleClickMainAction,
                  onChanged: (value) => state.updateDraftSettings(doubleClickMainAction: value),
                ),
                _SettingsDropdownRow<String>(
                  title: 'Default Installation Scope',
                  subtitle: 'Select the default scope when installing new applications.',
                  value: state.draftSettings.defaultInstallScope,
                  items: const [
                    DropdownMenuItem(value: 'ask', child: Text('Ask every time', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'user', child: Text('Current User', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'system', child: Text('System-wide', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) => state.updateDraftSettings(defaultInstallScope: value),
                ),
                _SettingsDropdownRow<int>(
                  title: 'Default Installed Apps View',
                  subtitle: 'Select how installed applications are displayed by default.',
                  value: state.draftSettings.defaultInstalledAppsView,
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('Remember Last Used', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 0, child: Text('List', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 1, child: Text('Grid Cards', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 2, child: Text('Icons', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) => state.updateDraftSettings(defaultInstalledAppsView: value),
                ),
                _SettingsDropdownRow<int>(
                  title: 'Default Remote Apps View',
                  subtitle: 'Select how available remote applications are displayed by default.',
                  value: state.draftSettings.defaultRemoteAppsView,
                  items: const [
                    DropdownMenuItem(value: -1, child: Text('Remember Last Used', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 0, child: Text('List', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 1, child: Text('Grid Cards', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 2, child: Text('Icons', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) => state.updateDraftSettings(defaultRemoteAppsView: value),
                ),
              ],
            ),
            sectionDivider,

            // --- Appearance Settings ---
            _SettingsSection(
              title: 'Appearance',
              children: [
                _SettingsDropdownRow<String>(
                  title: 'Theme Mode',
                  subtitle: 'Select the overall color theme of the application.',
                  value: state.draftSettings.themeMode,
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('Default', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'light', child: Text('Light Mode', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 'dark', child: Text('Dark Mode', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) => state.updateDraftSettings(themeMode: value),
                ),
                _SettingsDropdownRow<double>(
                  title: 'Font Scale',
                  subtitle: 'Adjust the global font size of the application.',
                  value: state.draftSettings.textScale,
                  items: const [
                    DropdownMenuItem(value: 0.8, child: Text('Small', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 1.0, child: Text('Normal', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 1.2, child: Text('Large', style: TextStyle(fontSize: 14))),
                    DropdownMenuItem(value: 1.4, child: Text('Extra Large', style: TextStyle(fontSize: 14))),
                  ],
                  onChanged: (value) => state.updateDraftSettings(textScale: value),
                ),
                _SettingsControlRow(
                  title: 'Accent Color',
                  subtitle: 'Choose a primary accent color for the interface.',
                  control: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _AccentColorOption(colorValue: 0xFF9BA2FF, state: state), // Purple
                      _AccentColorOption(colorValue: 0xFF7AE190, state: state), // Green
                      _AccentColorOption(colorValue: 0xFF86B0FF, state: state), // Blue
                      _AccentColorOption(colorValue: 0xFFFF994A, state: state), // Orange
                      _AccentColorOption(colorValue: 0xFFF472B6, state: state), // Pink
                      _AccentColorOption(colorValue: 0xFFEF4444, state: state), // Red
                      _AccentColorOption(colorValue: 0xFF14B8A6, state: state), // Teal
                      _AccentColorOption(colorValue: 0xFF6366F1, state: state), // Indigo
                      _AccentColorOption(colorValue: 0xFF6B7280, state: state), // Grey
                    ],
                  ),
                ),
              ],
            ),
            sectionDivider,

            // --- Icon View Settings ---
            _SettingsSection(
              title: 'Icon View',
              children: [
                _SettingsCheckboxRow(
                  title: 'Show Main Category',
                  subtitle: 'Display the primary category of the application in the icon view.',
                  value: state.draftSettings.iconViewShowCategory,
                  onChanged: (value) => state.updateDraftSettings(iconViewShowCategory: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Version',
                  subtitle: 'Display the application version in the icon view.',
                  value: state.draftSettings.iconViewShowVersion,
                  onChanged: (value) => state.updateDraftSettings(iconViewShowVersion: value),
                ),
              ],
            ),
            sectionDivider,

            // --- Grid View Settings ---
            _SettingsSection(
              title: 'Grid View',
              children: [
                _SettingsCheckboxRow(
                  title: 'Show Main Category',
                  subtitle: 'Display the primary category of the application in the grid view.',
                  value: state.draftSettings.gridViewShowCategory,
                  onChanged: (value) => state.updateDraftSettings(gridViewShowCategory: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Version',
                  subtitle: 'Display the application version in the grid view.',
                  value: state.draftSettings.gridViewShowVersion,
                  onChanged: (value) => state.updateDraftSettings(gridViewShowVersion: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show AppId',
                  subtitle: 'Display the application ID in the grid view.',
                  value: state.draftSettings.gridViewShowAppId,
                  onChanged: (value) => state.updateDraftSettings(gridViewShowAppId: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Size',
                  subtitle: 'Display the package size in the grid view.',
                  value: state.draftSettings.gridViewShowSize,
                  onChanged: (value) => state.updateDraftSettings(gridViewShowSize: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Date',
                  subtitle: 'Display the date information in the grid view.',
                  value: state.draftSettings.gridViewShowDate,
                  onChanged: (value) => state.updateDraftSettings(gridViewShowDate: value),
                ),
              ],
            ),
            sectionDivider,

            // --- List View Settings ---
            _SettingsSection(
              title: 'List View',
              children: [
                _SettingsCheckboxRow(
                  title: 'Show Main Category',
                  subtitle: 'Display the primary category of the application in the list view.',
                  value: state.draftSettings.listViewShowCategory,
                  onChanged: (value) => state.updateDraftSettings(listViewShowCategory: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Version',
                  subtitle: 'Display the application version in the list view.',
                  value: state.draftSettings.listViewShowVersion,
                  onChanged: (value) => state.updateDraftSettings(listViewShowVersion: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show AppId',
                  subtitle: 'Display the application ID in the list view.',
                  value: state.draftSettings.listViewShowAppId,
                  onChanged: (value) => state.updateDraftSettings(listViewShowAppId: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Size',
                  subtitle: 'Display the package size in the list view.',
                  value: state.draftSettings.listViewShowSize,
                  onChanged: (value) => state.updateDraftSettings(listViewShowSize: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Date',
                  subtitle: 'Display the date information in the list view.',
                  value: state.draftSettings.listViewShowDate,
                  onChanged: (value) => state.updateDraftSettings(listViewShowDate: value),
                ),
                _SettingsCheckboxRow(
                  title: 'Show Description',
                  subtitle: 'Display the application description in the list view.',
                  value: state.draftSettings.listViewShowDescription,
                  onChanged: (value) => state.updateDraftSettings(listViewShowDescription: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups settings rows under an optional heading with alternating zebra fills and hairline dividers.
class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stripeColor = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.045 : 0.035);
    final hairlineColor = theme.dividerColor.withValues(alpha: 0.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Material(
                  color: i.isOdd ? stripeColor : Colors.transparent,
                  child: children[i],
                ),
                if (i < children.length - 1) Divider(height: 1, thickness: 0.5, color: hairlineColor),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCheckboxRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _SettingsCheckboxRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
      value: value,
      onChanged: onChanged,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

class _SettingsControlRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget control;

  const _SettingsControlRow({
    required this.title,
    required this.subtitle,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

class _SettingsDropdownRow<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SettingsDropdownRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsControlRow(
      title: title,
      subtitle: subtitle,
      control: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.45), width: 0.75),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isDense: true,
            iconSize: 20,
            value: value,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _AccentColorOption extends StatelessWidget {
  final int colorValue;
  final HomeState state;

  const _AccentColorOption({required this.colorValue, required this.state});

  @override
  Widget build(BuildContext context) {
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
          boxShadow: isSelected ? [BoxShadow(color: Color(colorValue).withValues(alpha: 0.6), blurRadius: 8)] : [],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.black54, size: 20) : null,
      ),
    );
  }
}
