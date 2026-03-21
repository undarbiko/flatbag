import 'package:flutter/material.dart';
import '../../state/home_state.dart';

/// The main vertical navigation rail located on the left side of the application.
class SideNavigation extends StatelessWidget {
  final HomeState state;

  const SideNavigation({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final int activeTaskCount = state.taskQueue.length + (state.currentTask != null ? 1 : 0);

    return Column(
      children: [
        const SizedBox(height: 8),
        _SideNavigationItem(
          icon: Icons.apps,
          label: 'Installed',
          isSelected: state.currentView == AppView.installedApps,
          onTap: () => state.setView(AppView.installedApps),
        ),
        _SideNavigationItem(
          icon: Icons.public,
          label: 'Remote',
          isSelected: state.currentView == AppView.remoteApps,
          onTap: () => state.setView(AppView.remoteApps),
        ),
        _SideNavigationItem(
          icon: Icons.update,
          label: 'Updates',
          isSelected: state.currentView == AppView.updates,
          onTap: () => state.setView(AppView.updates),
        ),
        _SideNavigationItem(
          icon: Icons.sync,
          label: 'Processes',
          isSelected: state.currentView == AppView.processes,
          onTap: () => state.setView(AppView.processes),
          badgeCount: activeTaskCount,
        ),
        const Spacer(),
        _SideNavigationItem(
          icon: Icons.settings,
          label: 'Settings',
          isSelected: state.currentView == AppView.settings,
          onTap: () => state.setView(AppView.settings),
        ),
        const SizedBox(height: 8),
        _SideNavigationItem(
          icon: Icons.terminal,
          label: 'Logs',
          isSelected: state.currentView == AppView.messages,
          onTap: () => state.setView(AppView.messages),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// An individual item within the [SideNavigation] rail.
class _SideNavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _SideNavigationItem({required this.icon, required this.label, required this.isSelected, required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72 * textScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                child: Container(
                  width: 56 * textScale,
                  height: 32 * textScale,
                  decoration: isSelected ? BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(16)) : null,
                  child: Icon(icon, color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant, size: 24),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
