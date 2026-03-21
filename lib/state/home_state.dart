import 'dart:convert';
import 'dart:io';
import '../models/background_task.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/flatpak_app.dart';
import '../models/flatpak_remote_app.dart';
import '../utils/app_logger.dart';
import '../models/app_settings.dart';
import '../services/flathub_service.dart';
import '../services/flatpak_service.dart';

enum AppView { messages, installedApps, remoteApps, updates, settings, processes }

class HomeState extends ChangeNotifier {
  // --- State Variables ---
  List<FlatpakApp> flatpakInstalledApps = [];
  List<FlatpakApp> flatpakUpdates = [];
  List<FlatpakRemoteApp> remoteApps = [];
  bool isLoading = true;
  bool isCheckingUpdates = false;
  AppView currentView = AppView.installedApps;

  AppSettings settings = AppSettings();
  AppSettings draftSettings = AppSettings();
  int installedAppsViewType = 1;
  int remoteAppsViewType = 1;

  int get appsViewType {
    if (currentView == AppView.remoteApps) return remoteAppsViewType;
    return installedAppsViewType;
  }

  String? statusTextOverride;

  // --- Controllers ---
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  String? selectedAppId;
  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'Alphabet'; // 'Alphabet', 'Date', 'Size'
  bool isAscending = true;
  final AppLogger appLogger = AppLogger();

  // --- Flathub Integration ---
  final FlathubService _flathubService = FlathubService();
  final Map<String, Map<String, dynamic>> _flathubDetailsCache = {};
  final FlatpakService _flatpakService;

  HomeState({FlatpakService? flatpakService}) : _flatpakService = flatpakService ?? FlatpakService();

  // --- Background Task State ---
  List<BackgroundTask> taskQueue = [];
  List<BackgroundTask> completedTasks = [];
  BackgroundTask? currentTask;
  bool _isProcessingQueue = false;
  String? selectedTaskId;

  @override
  // --- Lifecycle Methods ---
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // --- Actions & State Updates ---

  void log(String message) {
    appLogger.addMessage(message);
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void setAppsViewType(int type) {
    if (currentView == AppView.remoteApps) {
      remoteAppsViewType = type;
      settings.lastRemoteAppsView = type;
    } else {
      installedAppsViewType = type;
      settings.lastInstalledAppsView = type;
    }
    settings.save(); // Persist the last used view immediately
    notifyListeners();
  }

  void setStatusText(String? text) {
    statusTextOverride = text;
    notifyListeners();
  }

  void setView(AppView view) {
    // Revert any unapplied settings if navigating away from the settings view
    if (currentView == AppView.settings && view != AppView.settings) {
      if (settingsHasChanges) {
        cancelSettings();
      }
    }

    currentView = view;
    // Auto-fetch updates when switching to the updates tab
    if (currentView == AppView.updates && flatpakUpdates.isEmpty) {
      fetchUpdates();
    }
    // Auto-fetch remote apps when switching to the remote apps tab
    if (currentView == AppView.remoteApps && remoteApps.isEmpty) {
      fetchRemoteApps();
    }

    // Ensure the selected category is valid for the new view to prevent DropdownButton errors
    if (!availableCategories.contains(selectedCategory)) {
      selectedCategory = 'All';
    }
    notifyListeners();
  }

  void updateSearch(String query) {
    searchQuery = query;
    if (selectedAppId != null && !filteredApps.any((a) => a.uniqueId == selectedAppId)) {
      selectedAppId = null;
    }
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery = '';
    notifyListeners();
  }

  void setCategory(String category) {
    selectedCategory = category;
    if (selectedAppId != null && !filteredApps.any((a) => a.uniqueId == selectedAppId)) {
      selectedAppId = null;
    }
    notifyListeners();
  }

  void setSort(String sort) {
    sortBy = sort;
    notifyListeners();
  }

  void toggleSortOrder() {
    isAscending = !isAscending;
    notifyListeners();
  }

  void selectApp(String? appId) {
    selectedAppId = appId;
    if (appId != null) {
      _fetchFlathubDetails(appId);
    }
    notifyListeners();
  }

  void selectTask(String? taskId) {
    if (selectedTaskId == taskId) {
      selectedTaskId = null;
    } else {
      selectedTaskId = taskId;
    }
    notifyListeners();
  }

  void deleteTask(String taskId) {
    completedTasks.removeWhere((t) => t.id == taskId);
    taskQueue.removeWhere((t) => t.id == taskId);
    if (selectedTaskId == taskId) {
      selectedTaskId = null;
    }
    notifyListeners();
  }

  bool get settingsHasChanges {
    return jsonEncode(settings.toJson()) != jsonEncode(draftSettings.toJson());
  }

  Future<void> initSettings() async {
    settings = await AppSettings.load();
    draftSettings = AppSettings.fromJson(settings.toJson());
    installedAppsViewType = settings.defaultInstalledAppsView == -1 ? settings.lastInstalledAppsView : settings.defaultInstalledAppsView;
    remoteAppsViewType = settings.defaultRemoteAppsView == -1 ? settings.lastRemoteAppsView : settings.defaultRemoteAppsView;
    settings.lastInstalledAppsView = installedAppsViewType;
    settings.lastRemoteAppsView = remoteAppsViewType;
    notifyListeners();
  }

  void updateDraftSettings({
    bool? persistWindowSize,
    bool? autoCheckUpdates,
    String? defaultInstallScope,
    String? themeMode,
    int? accentColor,
    double? textScale,
    int? defaultInstalledAppsView,
    int? defaultRemoteAppsView,
    bool? iconViewShowCategory,
    bool? iconViewShowVersion,
    bool? gridViewShowCategory,
    bool? gridViewShowVersion,
    bool? gridViewShowAppId,
    bool? gridViewShowSize,
    bool? gridViewShowDate,
    bool? listViewShowCategory,
    bool? listViewShowVersion,
    bool? listViewShowAppId,
    bool? listViewShowSize,
    bool? listViewShowDate,
    bool? listViewShowDescription,
  }) {
    if (persistWindowSize != null) draftSettings.persistWindowSize = persistWindowSize;
    if (autoCheckUpdates != null) draftSettings.autoCheckUpdates = autoCheckUpdates;
    if (defaultInstallScope != null) draftSettings.defaultInstallScope = defaultInstallScope;
    if (themeMode != null) {
      draftSettings.themeMode = themeMode;
      AppTheme.themeMode.value = AppTheme.parseThemeMode(themeMode);
    }
    if (accentColor != null) {
      draftSettings.accentColor = accentColor;
      AppTheme.seedColor.value = Color(accentColor);
    }
    if (textScale != null) {
      draftSettings.textScale = textScale;
      AppTheme.textScale.value = textScale;
      windowManager.setMinimumSize(Size(900 + (textScale - 1.0) * 300, 650 + (textScale - 1.0) * 300));
    }
    if (defaultInstalledAppsView != null) draftSettings.defaultInstalledAppsView = defaultInstalledAppsView;
    if (defaultRemoteAppsView != null) draftSettings.defaultRemoteAppsView = defaultRemoteAppsView;
    if (iconViewShowCategory != null) draftSettings.iconViewShowCategory = iconViewShowCategory;
    if (iconViewShowVersion != null) draftSettings.iconViewShowVersion = iconViewShowVersion;
    if (gridViewShowCategory != null) draftSettings.gridViewShowCategory = gridViewShowCategory;
    if (gridViewShowVersion != null) draftSettings.gridViewShowVersion = gridViewShowVersion;
    if (gridViewShowAppId != null) draftSettings.gridViewShowAppId = gridViewShowAppId;
    if (gridViewShowSize != null) draftSettings.gridViewShowSize = gridViewShowSize;
    if (gridViewShowDate != null) draftSettings.gridViewShowDate = gridViewShowDate;
    if (listViewShowCategory != null) draftSettings.listViewShowCategory = listViewShowCategory;
    if (listViewShowVersion != null) draftSettings.listViewShowVersion = listViewShowVersion;
    if (listViewShowAppId != null) draftSettings.listViewShowAppId = listViewShowAppId;
    if (listViewShowSize != null) draftSettings.listViewShowSize = listViewShowSize;
    if (listViewShowDate != null) draftSettings.listViewShowDate = listViewShowDate;
    if (listViewShowDescription != null) draftSettings.listViewShowDescription = listViewShowDescription;
    notifyListeners();
  }

  void applySettings() async {
    settings = AppSettings.fromJson(draftSettings.toJson());
    installedAppsViewType = settings.defaultInstalledAppsView == -1 ? settings.lastInstalledAppsView : settings.defaultInstalledAppsView;
    remoteAppsViewType = settings.defaultRemoteAppsView == -1 ? settings.lastRemoteAppsView : settings.defaultRemoteAppsView;
    settings.lastInstalledAppsView = installedAppsViewType;
    settings.lastRemoteAppsView = remoteAppsViewType;
    await settings.save();
    notifyListeners();
  }

  void cancelSettings() {
    draftSettings = AppSettings.fromJson(settings.toJson());
    AppTheme.themeMode.value = AppTheme.parseThemeMode(settings.themeMode);
    AppTheme.seedColor.value = Color(settings.accentColor);
    AppTheme.textScale.value = settings.textScale;
    windowManager.setMinimumSize(Size(900 + (settings.textScale - 1.0) * 300, 650 + (settings.textScale - 1.0) * 300));
    notifyListeners();
  }

  void restoreDefaultSettings() {
    final currentWidth = draftSettings.windowWidth;
    final currentHeight = draftSettings.windowHeight;
    draftSettings = AppSettings();
    draftSettings.windowWidth = currentWidth;
    draftSettings.windowHeight = currentHeight;
    AppTheme.themeMode.value = AppTheme.parseThemeMode(draftSettings.themeMode);
    AppTheme.seedColor.value = Color(draftSettings.accentColor);
    AppTheme.textScale.value = draftSettings.textScale;
    windowManager.setMinimumSize(Size(900 + (draftSettings.textScale - 1.0) * 300, 650 + (draftSettings.textScale - 1.0) * 300));
    notifyListeners();
  }

  void removeApp(String uniqueId) {
    flatpakInstalledApps.removeWhere((a) => a.uniqueId == uniqueId);
    selectedAppId = null;
    isLoading = false;
    notifyListeners();
  }

  void updateAllApps() {
    for (var app in List.from(filteredUpdates)) {
      if (app.eolMessage != null) {
        if (app.eolRebaseId != null) {
          migrateApp(app);
        } else {
          uninstallApp(app.name, app.application, app.installation);
        }
      } else {
        updateApp(app);
      }
    }
  }

  Future<int> executeAppCommand(String appId) {
    return _flatpakService.executeAppCommand(appId);
  }

  // --- Application Logic ---

  Future<void> fetchFlatpakList() async {
    log('Fetching flatpak list...');
    try {
      final List<FlatpakApp> parsedApps = await _flatpakService.getInstalledApps();

      if (parsedApps.isNotEmpty) {
        log('Successfully loaded ${parsedApps.length} applications.');
        flatpakInstalledApps = parsedApps;
        _updateRemoteAppsInstalledStatus();
        isLoading = false;
      } else {
        log('No flatpak apps found.');
        log('There are no flatpak apps to display.');
        isLoading = false;
      }
    } catch (e) {
      log('Failed to execute command: $e');
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> fetchUpdates() async {
    if (isCheckingUpdates) return;

    isCheckingUpdates = true;
    notifyListeners();
    log('Checking for updates...');

    try {
      final updates = await _flatpakService.getUpdates();
      flatpakUpdates = updates;
      log('Found ${updates.length} available updates.');

      log('Checking installed apps against EOL data...');
      final eolData = await _flathubService.getEolData();

      if (eolData.isNotEmpty) {
        for (var app in flatpakInstalledApps) {
          if (eolData.containsKey(app.application)) {
            log('Found EOL match for ${app.name} (${app.application})');
            final eolReason = eolData[app.application]!;
            // Heuristic: If the reason looks like an ID (no spaces), it's a rebase.
            final String? newId = !eolReason.contains(' ') ? eolReason.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').trim() : null;
            final String displayMessage = newId != null ? 'Rebased to $newId' : eolReason;

            // Check if this app is already in the updates list (e.g. normal update + EOL)
            final existingIndex = flatpakUpdates.indexWhere((u) => u.application == app.application);

            if (existingIndex != -1) {
              flatpakUpdates[existingIndex] = flatpakUpdates[existingIndex].copyWith(eolMessage: displayMessage, eolRebaseId: newId);
            } else {
              // Add as a special update entry
              flatpakUpdates.add(app.copyWith(eolMessage: displayMessage, eolRebaseId: newId));
            }
          }
        }
      } else {
        log('No EOL data available or list is empty.');
      }
    } catch (e) {
      log('Error checking updates: $e');
    }

    isCheckingUpdates = false;
    notifyListeners();
  }

  Future<void> fetchRemoteApps({bool force = false, bool forceSizes = false}) async {
    if (remoteApps.isNotEmpty && !force) return; // Don't refetch if we already have them

    log('Fetching remote apps from Flathub...');
    try {
      final apps = await _flathubService.getRemoteApps(forceRefresh: force);
      remoteApps = apps;
      log('Successfully loaded ${apps.length} remote applications.');
      _updateRemoteAppsInstalledStatus();
      fetchRemoteSizes(force: force || forceSizes);
    } catch (e) {
      log('Failed to fetch remote apps: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> runBackgroundUpdate({bool force = false}) async {
    if (force) setLoading(true);
    bool appCountChanged = false;
    await _flathubService.fetchAndSaveRemoteAppsInBackground(
      forceRefresh: force,
      onLog: (msg) {
        log(msg);
        if (msg == 'App count changed.') {
          appCountChanged = true;
        }
        if (msg == 'Successfully saved Flathub apps list.') {
          // The background worker finished. Reload to show icons and details immediately.
          // We clear the current list to ensure fetchRemoteApps doesn't skip the update,
          // but we pass force: false so the service loads from the disk cache we just created.
          remoteApps = [];
          fetchRemoteApps(force: false, forceSizes: force || appCountChanged);
        } else if (msg == 'DONE' || msg.startsWith('Error:')) {
          if (isLoading) setLoading(false);
        }
      },
    );
  }

  void _updateRemoteAppsInstalledStatus() {
    if (remoteApps.isEmpty) return;
    final installedIds = flatpakInstalledApps.map((a) => a.application).toSet();

    remoteApps = remoteApps.map((app) {
      final isInstalled = installedIds.contains(app.flatpakAppId);
      return app.isInstalled != isInstalled ? app.copyWith(isInstalled: isInstalled) : app;
    }).toList();
  }

  /// Fetches the download sizes for remote apps.
  /// Flow:
  /// 1. Try to load previously cached sizes from disk.
  /// 2. If forced or cache is stale, execute 'flatpak remote-ls' for system and user scopes.
  /// 3. Parse the output and merge the sizes into the remote apps list.
  /// 4. Update the local cache file.
  Future<void> fetchRemoteSizes({bool force = false}) async {
    final cacheFile = await _getSizesCacheFile();
    bool isStale = false;

    if (!force && await cacheFile.exists()) {
      // Check if cache is stale (older than 24 hours)
      final lastModified = await cacheFile.lastModified();
      if (DateTime.now().difference(lastModified).inHours >= 24) {
        isStale = true;
        log('Sizes cache is stale (>24h). Refreshing...');
      }

      try {
        final content = await cacheFile.readAsString();
        final Map<String, dynamic> cachedSizes = json.decode(content);

        bool changed = false;
        remoteApps = remoteApps.map((app) {
          if (app.size == null && cachedSizes.containsKey(app.flatpakAppId)) {
            changed = true;
            return app.copyWith(size: cachedSizes[app.flatpakAppId] as String);
          }
          return app;
        }).toList();

        if (changed) notifyListeners();

        // If we successfully loaded sizes, we can skip the slow command unless forced or stale
        if (!isStale && remoteApps.any((app) => app.size != null)) return;
      } catch (e) {
        log('Error reading sizes cache: $e');
      }
    }

    if (!force && !isStale && remoteApps.any((app) => app.size != null)) return;

    log('Fetching remote app sizes...');
    try {
      final results = await Future.wait([
        Process.run('flatpak', ['remote-ls', '--system', '--columns=application,download-size', 'flathub']),
        Process.run('flatpak', ['remote-ls', '--user', '--columns=application,download-size', 'flathub']),
      ]);

      final systemResult = results[0];
      final userResult = results[1];

      final Map<String, String> systemSizes = {};
      final Map<String, String> userSizes = {};
      final RegExp regex = RegExp(r'^(\S+)\s+(.+)$');

      void parseOutput(String output, Map<String, String> map) {
        for (var line in const LineSplitter().convert(output)) {
          final match = regex.firstMatch(line.trim());
          if (match != null) {
            map[match.group(1)!] = match.group(2)!;
          }
        }
      }

      if (systemResult.exitCode == 0) {
        parseOutput(systemResult.stdout as String, systemSizes);
      }

      if (userResult.exitCode == 0) {
        parseOutput(userResult.stdout as String, userSizes);
      }

      remoteApps = remoteApps.map((app) {
        // Prefer system size, fallback to user size, else 'N/A'
        final size = systemSizes[app.flatpakAppId] ?? userSizes[app.flatpakAppId] ?? 'N/A';
        return app.copyWith(size: size);
      }).toList();

      notifyListeners();

      // Save to cache
      final Map<String, String> cacheToSave = {};
      for (var app in remoteApps) {
        if (app.size != null && app.size != 'N/A') {
          cacheToSave[app.flatpakAppId] = app.size!;
        }
      }
      await cacheFile.writeAsString(json.encode(cacheToSave));
    } catch (e) {
      log('Failed to fetch remote sizes: $e');
    }
  }

  Future<File> _getSizesCacheFile() async {
    String dir;
    if (Platform.isWindows) {
      dir = Platform.environment['LOCALAPPDATA'] ?? '.';
      dir = '$dir\\flatbag';
    } else {
      String? home = Platform.environment['HOME'];
      String? xdgCache = Platform.environment['XDG_CACHE_HOME'];
      if (xdgCache != null && xdgCache.isNotEmpty) {
        dir = '$xdgCache/flatbag';
      } else if (home != null) {
        dir = '$home/.cache/flatbag';
      } else {
        dir = Directory.systemTemp.path;
      }
    }
    final d = Directory(dir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return File('$dir/sizes_cache.json');
  }

  // --- Task Queue Management ---

  void _addTask(TaskType type, String name, String details) {
    final task = BackgroundTask(id: DateTime.now().millisecondsSinceEpoch.toString(), type: type, name: name, details: details);
    taskQueue.add(task);
    log('Queued task: ${type.name} for $name');
    notifyListeners();
    _processQueue();
  }

  /// Processes the background task queue sequentially.
  /// Flow:
  /// 1. Mark the next task as running.
  /// 2. Listen to process output to parse progress metrics.
  /// 3. Execute the corresponding Flatpak command.
  /// 4. Update task status and trigger UI refreshes upon completion.
  Future<void> _processQueue() async {
    if (_isProcessingQueue || taskQueue.isEmpty) return;

    _isProcessingQueue = true;
    currentTask = taskQueue.removeAt(0);
    currentTask!.status = TaskStatus.running;
    log('Starting task: ${currentTask!.type.name} for ${currentTask!.name}');
    notifyListeners();

    int exitCode = 1;

    void handleOutput(String line) {
      currentTask!.log.add(line);

      // Example line: "Receiving delta parts: 169/170 12.3 MB/s 5.3 MB/5.3 MB"
      final progressRegex = RegExp(r'(\d+)%|(\d+)\/(\d+)');
      final match = progressRegex.firstMatch(line);
      if (match != null) {
        double progress = 0;
        if (match.group(1) != null) {
          progress = (double.tryParse(match.group(1)!) ?? 0) / 100.0;
        } else if (match.group(2) != null && match.group(3) != null) {
          final current = double.tryParse(match.group(2)!) ?? 0;
          final total = double.tryParse(match.group(3)!) ?? 1;
          if (total > 0) {
            progress = current / total;
          }
        }
        currentTask!.progress = progress;
      }

      notifyListeners();
    }

    switch (currentTask!.type) {
      case TaskType.update:
        exitCode = await _flatpakService.updateAppCommand(currentTask!.details!, onStdOut: handleOutput, onStdErr: handleOutput);
        break;
      case TaskType.migrate:
        final parts = currentTask!.details!.split('->');
        final oldId = parts[0];
        final newId = parts[1];
        final appToMigrate = flatpakInstalledApps.where((a) => a.application == oldId).firstOrNull;
        final isSystem = appToMigrate?.installation == 'system';

        if (oldId == newId) {
          handleOutput('Old and new app IDs are identical ($oldId). Skipping migration.');
          exitCode = 0;
          break;
        }

        handleOutput('Removing old app: $oldId...');
        exitCode = await _flatpakService.uninstallAppCommand(
          oldId,
          isSystem ? 'system' : 'user',
          deleteData: false,
          onStdOut: handleOutput,
          onStdErr: handleOutput,
        );

        if (exitCode == 0) {
          handleOutput('Installing new app: $newId...');
          exitCode = await _flatpakService.installAppCommand(newId, isSystem: isSystem, onStdOut: handleOutput, onStdErr: handleOutput);
        }
        break;
      case TaskType.install:
        final parts = currentTask!.details!.split('|');
        final appId = parts[0];
        final isSystem = parts[1] == 'system';
        exitCode = await _flatpakService.installAppCommand(appId, isSystem: isSystem, onStdOut: handleOutput, onStdErr: handleOutput);
        break;
      case TaskType.uninstall:
        final parts = currentTask!.details!.split('|');
        final appId = parts[0];
        final installation = parts[1];
        exitCode = await _flatpakService.uninstallAppCommand(appId, installation, deleteData: true, onStdOut: handleOutput, onStdErr: handleOutput);
        break;
      default:
        handleOutput('Unknown task type');
        exitCode = -1;
    }

    currentTask!.status = exitCode == 0 ? TaskStatus.success : TaskStatus.failed;
    currentTask!.endTime = DateTime.now();
    currentTask!.progress = 1.0;
    log('Task finished: ${currentTask!.type.name} for ${currentTask!.name} with exit code $exitCode');

    completedTasks.add(currentTask!);

    if (exitCode == 0) {
      if (currentTask!.type != TaskType.update) {
        await fetchFlatpakList();
      }
      if (currentTask!.type == TaskType.update || currentTask!.type == TaskType.migrate) {
        String? targetId = currentTask!.details;
        if (currentTask!.type == TaskType.migrate && targetId != null) {
          targetId = targetId.split('->').first;
        }
        flatpakUpdates.removeWhere((a) => a.application == currentTask!.name || a.application == targetId);
        await fetchFlatpakList();
      }
    }

    currentTask = null;
    _isProcessingQueue = false;
    notifyListeners();

    _processQueue();
  }

  Future<void> updateApp(FlatpakApp app) async {
    _addTask(TaskType.update, app.name, app.application);
    _removeFromUpdates(app.application);
  }

  void migrateApp(FlatpakApp app) {
    if (app.eolRebaseId != null) {
      // Failsafe: Validate that the target app actually exists in Flathub
      final bool targetExists = remoteApps.any((r) => r.flatpakAppId == app.eolRebaseId);
      if (!targetExists && remoteApps.isNotEmpty) {
        log('Warning: Target ${app.eolRebaseId} is not in remote apps. Falling back to uninstall.');
        _addTask(TaskType.uninstall, app.name, '${app.application}|${app.installation}');
        _removeFromUpdates(app.application);
        return;
      }

      _addTask(TaskType.migrate, app.name, '${app.application}->${app.eolRebaseId}');
      _removeFromUpdates(app.application);
    }
  }

  void installApp(String name, String appId, bool isSystem) {
    _addTask(TaskType.install, name, '$appId|${isSystem ? 'system' : 'user'}');
  }

  void uninstallApp(String name, String appId, String installation) {
    _addTask(TaskType.uninstall, name, '$appId|$installation');
    _removeFromUpdates(appId);
  }

  void _removeFromUpdates(String appId) {
    final initialCount = flatpakUpdates.length;
    flatpakUpdates.removeWhere((a) => a.application == appId);
    if (flatpakUpdates.length < initialCount) {
      if (currentView == AppView.updates && selectedAppId != null) {
        if (!flatpakUpdates.any((a) => a.uniqueId == selectedAppId)) {
          selectedAppId = null;
        }
      }
      notifyListeners();
    }
  }

  Future<void> _fetchFlathubDetails(String appId) async {
    if (_flathubDetailsCache.containsKey(appId)) return;
    log('Fetching Flathub details for $appId...');

    try {
      final details = await _flathubService.getAppDetails(appId);
      if (details != null) {
        _flathubDetailsCache[appId] = details;
        if (selectedAppId == appId) {
          notifyListeners();
        }
      }
    } catch (e) {
      log('Error fetching Flathub details for $appId: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchRawAppDetails(String appId) {
    return _flathubService.getAppDetails(appId);
  }

  Map<String, dynamic>? getRemoteAppCache(String appId) {
    return _flathubService.getCachedAppStreamData(appId);
  }

  // --- Getters / Computed Properties ---

  List<String> get availableCategories {
    final Set<String> categories = {};

    if (currentView == AppView.remoteApps) {
      for (var app in remoteApps) {
        categories.addAll(app.categories);
      }
    } else if (currentView == AppView.updates) {
      for (var app in flatpakUpdates) {
        categories.addAll(app.categories);
      }
    } else {
      for (var app in flatpakInstalledApps) {
        categories.addAll(app.categories);
      }
    }
    final list = categories.toList();
    list.sort();
    return ['All', 'All (show uncategorized)', ...list];
  }

  List<FlatpakApp> get filteredApps {
    List<FlatpakApp> list = flatpakInstalledApps.where((app) {
      final matchesSearch =
          searchQuery.isEmpty ||
          app.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.application.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery.toLowerCase())) ||
          app.categories.any((category) => category.toLowerCase().contains(searchQuery.toLowerCase()));

      bool matchesCategory = false;
      if (selectedCategory == 'All') {
        matchesCategory = !app.categories.contains('Uncategorized');
      } else if (selectedCategory == 'All (show uncategorized)') {
        matchesCategory = true;
      } else {
        matchesCategory = app.categories.contains(selectedCategory);
      }
      return matchesSearch && matchesCategory;
    }).toList();

    list.sort((a, b) {
      int result;
      switch (sortBy) {
        case 'Date':
          result = (a.installDate ?? DateTime(0)).compareTo(b.installDate ?? DateTime(0));
          break;
        case 'Size':
          result = _compareSizes(a.size, b.size);
          break;
        case 'Alphabet':
        default:
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      if (result == 0 && sortBy != 'Alphabet') {
        result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        if (!isAscending) {
          result = -result;
        }
      }
      return isAscending ? result : -result;
    });

    return list;
  }

  List<FlatpakApp> get filteredUpdates {
    List<FlatpakApp> list = flatpakUpdates.where((app) {
      final matchesSearch =
          searchQuery.isEmpty ||
          app.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.application.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.keywords.any((keyword) => keyword.toLowerCase().contains(searchQuery.toLowerCase())) ||
          app.categories.any((category) => category.toLowerCase().contains(searchQuery.toLowerCase()));

      bool matchesCategory = false;
      if (selectedCategory == 'All') {
        matchesCategory = !app.categories.contains('Uncategorized');
      } else if (selectedCategory == 'All (show uncategorized)') {
        matchesCategory = true;
      } else {
        matchesCategory = app.categories.contains(selectedCategory);
      }
      return matchesSearch && matchesCategory;
    }).toList();

    return list;
  }

  List<FlatpakRemoteApp> get filteredRemoteApps {
    List<FlatpakRemoteApp> list = remoteApps.where((app) {
      final matchesSearch =
          searchQuery.isEmpty ||
          app.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.flatpakAppId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          app.summary.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesCategory = false;
      if (selectedCategory == 'All') {
        matchesCategory = true;
      } else if (selectedCategory == 'All (show uncategorized)') {
        matchesCategory = true;
      } else {
        matchesCategory = app.categories.contains(selectedCategory);
      }
      return matchesSearch && matchesCategory;
    }).toList();

    list.sort((a, b) {
      int result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (sortBy == 'Size') {
        final sizeA = a.size ?? '';
        final sizeB = b.size ?? '';
        result = _compareSizes(sizeA, sizeB);
      }
      return isAscending ? result : -result;
    });

    return list;
  }

  // Helper to parse "10.5 MB" or "1.2 GB" for sorting
  int _compareSizes(String sizeA, String sizeB) {
    double toMb(String sizeStr) {
      if (sizeStr.trim().isEmpty) return 0.0;
      String normalizedStr = sizeStr.replaceAll(',', '.');
      final match = RegExp(r'([\d.]+)\s*([a-zA-Z]+)?').firstMatch(normalizedStr);
      if (match == null) return 0.0;
      double val = double.tryParse(match.group(1) ?? '0') ?? 0.0;
      String unit = (match.group(2) ?? '').toUpperCase();
      if (unit.contains('G')) return val * 1024.0;
      if (unit.contains('K')) return val / 1024.0;
      if (unit == 'B' || unit == 'BYTES') return val / (1024.0 * 1024.0);
      return val;
    }

    return toMb(sizeA).compareTo(toMb(sizeB));
  }

  /// Returns the cached Flathub details for the currently selected app, if available.
  Map<String, dynamic>? get selectedAppFlathubDetails {
    return selectedAppId != null ? _flathubDetailsCache[selectedAppId] : null;
  }

  /// Returns the latest release information (version, notes, date) from Flathub.
  Map<String, dynamic>? get selectedAppLatestRelease {
    final details = selectedAppFlathubDetails;
    if (details == null || details['releases'] == null) return null;

    // {
    //   "version": "1.2.3",
    //   "timestamp": 1699315200,
    //   "description": "<p>Fixed a bug in the rendering engine.</p><ul><li>New feature A</li></ul>",
    //   "url": "https://example.com/release-notes"
    // }
    final releases = details['releases'] as List;
    if (releases.isEmpty) return null;
    return releases.first as Map<String, dynamic>;
  }
}
