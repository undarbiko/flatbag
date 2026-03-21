import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/flatpak_app.dart';
import '../models/flatpak_remote_app.dart';
import '../state/home_state.dart';
import '../screens/app_icon.dart';
import 'installed_actions_panel.dart';
import '../screens/installed_apps_view.dart';
import '../screens/installed_apps_toolbar.dart';
import '../screens/remote_apps_toolbar.dart';
import '../screens/updates_toolbar.dart';
import '../screens/updates_view.dart';
import '../screens/settings_view.dart';
import '../screens/remote_actions_panel.dart';
import '../screens/updates_action_panel.dart';
import '../screens/remote_apps_view.dart';
import '../screens/message_view.dart';
import '../screens/side_navigation.dart';
import '../screens/messages_action_panel.dart';
import '../screens/processes_action_panel.dart';
import '../screens/processes_view.dart';
import '../screens/remote_app_details_dialog.dart';
import '../screens/installed_app_details_dialog.dart';
import '../screens/settings_action_panel.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final HomeState _state = HomeState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _state.fetchFlatpakList();
    _state.initSettings().then((_) {
      if (_state.settings.autoCheckUpdates) {
        _state.runBackgroundUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        final selectedApp = _state.selectedAppId != null
            ? _state.flatpakInstalledApps.firstWhere((a) => a.uniqueId == _state.selectedAppId, orElse: () => _state.flatpakInstalledApps.first)
            : null;
        final selectedRemoteApp = _state.currentView == AppView.remoteApps && _state.selectedAppId != null
            ? _state.remoteApps.where((a) => a.flatpakAppId == _state.selectedAppId).firstOrNull
            : null;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 40,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            titleSpacing: 0, // Removes default padding so drag area fills the space
            // Static Drag Area for the Title
            title: DragToMoveArea(
              child: Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16.0),
                child: const Text('FlatBag', style: TextStyle(fontSize: 15)),
              ),
            ),

            // Window Controls
            actions: [
              IconButton(
                icon: const Icon(Icons.minimize, size: 18),
                tooltip: 'Minimize',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                onPressed: () async => await windowManager.minimize(),
              ),
              IconButton(
                icon: const Icon(Icons.crop_square, size: 18),
                tooltip: 'Maximize',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                onPressed: () async {
                  bool isMaximized = await windowManager.isMaximized();
                  if (isMaximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Close',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                hoverColor: Colors.red,
                onPressed: () async {
                  if (_state.settings.persistWindowSize) {
                    final size = await windowManager.getSize();
                    _state.settings.windowWidth = size.width;
                    _state.settings.windowHeight = size.height;
                    await _state.settings.save();
                  }
                  await windowManager.close();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          body: Column(
            children: [
              // Actions / Details Panel (Full Width)
              if (_state.currentView == AppView.installedApps)
                ActionsPanel(
                  selectedApp: selectedApp,
                  onExecute: selectedApp != null ? () => _executeApp(selectedApp) : null,
                  onDetails: selectedApp != null ? () => _showDetails(selectedApp) : null,
                  onUninstall: selectedApp != null ? () => _uninstallApp(selectedApp) : null,
                ),
              if (_state.currentView == AppView.remoteApps)
                RemoteActionsPanel(
                  selectedApp: selectedRemoteApp,
                  onInstall: selectedRemoteApp != null ? () => _installApp(selectedRemoteApp) : null,
                  onExecute: selectedRemoteApp != null ? () => _executeRemoteApp(selectedRemoteApp) : null,
                  onDetails: selectedRemoteApp != null ? () => _showRemoteAppDetails(selectedRemoteApp) : null,
                ),
              if (_state.currentView == AppView.updates) UpdatesActionPanel(state: _state),
              if (_state.currentView == AppView.processes) ProcessesActionPanel(state: _state),
              if (_state.currentView == AppView.messages)
                MessagesActionPanel(
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _state.appLogger.logs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard.')));
                  },
                ),
              if (_state.currentView == AppView.settings)
                SettingsActionPanel(
                  state: _state,
                  onCancel: () => _state.cancelSettings(),
                  onApply: () => _state.applySettings(),
                  onRestore: () => _state.restoreDefaultSettings(),
                  onAbout: _showAboutDialog,
                ),

              // Main Content Area (Rail + View)
              Expanded(
                child: _state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          SideNavigation(state: _state),
                          const VerticalDivider(thickness: 1, width: 1),
                          Expanded(
                            child: Column(
                              children: [
                                _buildToolBar(), // Inject the tool bar
                                Expanded(
                                  child: Scrollbar(controller: _state.scrollController, thumbVisibility: true, child: _buildCurrentMainView()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              // --- Status Bar ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1.0)),
                ),
                child: Text(_getStatusBarText(), style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface)),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Methods ---

  String _getStatusBarText() {
    if (_state.statusTextOverride != null) {
      return _state.statusTextOverride!;
    }
    switch (_state.currentView) {
      case AppView.installedApps:
        return 'Installed Apps - shown ${_state.filteredApps.length} apps from total ${_state.flatpakInstalledApps.length} apps';
      case AppView.remoteApps:
        return 'Remote Apps - shown ${_state.filteredRemoteApps.length} apps from total ${_state.remoteApps.length} apps';
      case AppView.updates:
        return 'Available Updates - shown ${_state.filteredUpdates.length} updates from total ${_state.flatpakUpdates.length} updates';
      case AppView.messages:
        return 'System Logs - ${_state.appLogger.logs.length} messages';
      default:
        return 'Ready';
    }
  }

  Widget _buildCurrentMainView() {
    switch (_state.currentView) {
      case AppView.messages:
        return MessageView(state: _state);
      case AppView.installedApps:
        return InstalledAppsView(state: _state);
      case AppView.remoteApps:
        return RemoteAppsView(state: _state);
      case AppView.updates:
        return UpdatesView(state: _state);
      case AppView.settings:
        return SettingsView(state: _state);
      case AppView.processes:
        return ProcessesView(state: _state);
    }
  }

  Widget _buildToolBar() {
    if (_state.currentView == AppView.installedApps) {
      return InstalledAppsToolbar(state: _state);
    }
    if (_state.currentView == AppView.remoteApps) {
      return RemoteAppsToolbar(state: _state);
    }
    if (_state.currentView == AppView.updates) {
      return UpdatesToolbar(state: _state);
    }
    return const SizedBox();
  }

  Future<void> _executeApp(FlatpakApp app) async {
    _state.log('Executing ${app.name}...');
    // Fire and forget the flatpak run command.
    final result = await _state.executeAppCommand(app.application);
    if (result == 0) {
      _state.log('${app.name} was successfully executed.');
    }
  }

  Future<void> _executeRemoteApp(FlatpakRemoteApp app) async {
    _state.log('Executing ${app.name}...');
    final result = await _state.executeAppCommand(app.flatpakAppId);
    if (result == 0) {
      _state.log('${app.name} was successfully executed.');
    }
  }

  Future<void> _installApp(FlatpakRemoteApp app) async {
    bool? isSystem;

    if (_state.settings.defaultInstallScope == 'system') {
      isSystem = true;
    } else if (_state.settings.defaultInstallScope == 'user') {
      isSystem = false;
    } else {
      isSystem = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Install ${app.name}'),
          content: const Text('Choose installation scope:'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('User')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('System')),
          ],
        ),
      );
    }

    if (isSystem == null) return;

    _state.installApp(app.name, app.flatpakAppId, isSystem);
  }

  void _showDetails(FlatpakApp app) {
    showDialog(
      context: context,
      builder: (context) => InstalledAppDetailsDialog(app: app),
    );
  }

  void _showRemoteAppDetails(FlatpakRemoteApp app) {
    showDialog(
      context: context,
      builder: (context) =>
          RemoteAppDetailsDialog(app: app, onInstall: () => _installApp(app), dataFetcher: _state.fetchRawAppDetails(app.flatpakAppId)),
    );
  }

  /// Initiates the uninstallation process for a specific application.
  /// Flow:
  /// 1. Display a confirmation dialog.
  /// 2. If confirmed, queue the uninstall task.
  /// 3. Display a snackbar notification.
  Future<void> _uninstallApp(FlatpakApp app) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Application'),
        content: Text('Are you sure you want to completely remove ${app.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _state.uninstallApp(app.name, app.application, app.installation);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uninstalling ${app.name} in the background.')));
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FlatBag'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('A graphical interface for managing Flatpak applications on Linux.'),
            SizedBox(height: 16),
            Text('License: MIT\nCopyright (c) 2026 Alexey Nechay', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
