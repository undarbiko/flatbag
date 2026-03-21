import 'dart:convert';
import 'dart:io';
import '../models/flatpak_app.dart';
import '../utils/app_logger.dart';

/// Retrieves a list of all currently installed Flatpak applications.
/// Flow:
/// 1. Execute `flatpak list` requesting required columns.
/// 2. Parse stdout lines into application data.
/// 3. Enrich data with install dates, icons, and sandbox permissions.
Future<List<FlatpakApp>> getflatpakInstalledApps() async {
  final List<FlatpakApp> parsedApps = [];
  try {
    final result = await Process.run('flatpak', [
      'list',
      '--columns=name,description,application,version,branch,arch,runtime,origin,installation,ref,active,latest,size',
    ]);

    if (result.exitCode == 0) {
      final String output = result.stdout as String;
      final List<String> lines = output.trim().split('\n');

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final columns = line.split('\t');

        if (columns.length >= 13) {
          final appId = columns[2].trim();
          final installDate = getInstallDate(appId);
          final desktopInfo = parseDesktopInfo(appId);
          final categories = desktopInfo.categories;
          final iconPath = getIconPath(appId, desktopInfo.iconName);
          final permissions = getPermissions(appId);

          parsedApps.add(
            FlatpakApp(
              name: columns[0].trim(),
              description: columns[1].trim(),
              application: columns[2].trim(),
              version: columns[3].trim(),
              branch: columns[4].trim(),
              arch: columns[5].trim(),
              runtime: columns[6].trim(),
              origin: columns[7].trim(),
              installation: columns[8].trim(),
              ref: columns[9].trim(),
              active: columns[10].trim(),
              latest: columns[11].trim(),
              size: columns[12].trim(),
              installDate: installDate,
              iconPath: iconPath,
              permissions: permissions,
              categories: categories,
              keywords: desktopInfo.keywords,
            ),
          );
        }
      }
    } else {
      throw Exception('Failed to execute command: ${result.stderr}');
    }
  } catch (e) {
    throw Exception('An error occurred: $e');
  }
  return parsedApps;
}

/// Executes a Flatpak application by its ID.
Future<int> executeFlatpakAppCommand(String appId) async {
  int exitCode = 1;
  try {
    final result = await Process.run('flatpak', ['run', appId]);
    exitCode = result.exitCode;
    if (exitCode != 0) {
      AppLogger().addMessage('Execution failed: ${result.stderr}');
    }
  } catch (e) {
    AppLogger().addMessage('Failed to execute run command: $e');
  }
  return exitCode;
}

/// Executes the flatpak uninstall command with optional flags.
/// Flow:
/// 1. Start the flatpak uninstall process.
/// 2. Listen to stdout/stderr for logs.
/// 3. If successful, remove local desktop overrides and refresh menu caches.
Future<int> uninstallFlatpakAppCommand(
  String appId,
  String? installation, {
  bool deleteData = false,
  void Function(String line)? onStdOut,
  void Function(String line)? onStdErr,
}) async {
  int exitCode = 1;
  try {
    List<String> args = ['uninstall', '-y', '-v'];
    if (deleteData) {
      args.add('--delete-data');
    }
    if (installation == 'system') {
      args.add('--system');
    } else if (installation == 'user') {
      args.add('--user');
    }
    args.add(appId);

    final process = await Process.start('flatpak', args);
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdOut);
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdErr);
    exitCode = await process.exitCode;

    if (exitCode == 0) {
      final String? home = Platform.environment['HOME'];
      if (home != null) {
        final overrideFile = File('$home/.local/share/applications/$appId.desktop');
        if (overrideFile.existsSync()) {
          if (onStdOut != null) onStdOut('Removing desktop menu override: ${overrideFile.path}');
          try {
            overrideFile.deleteSync();
          } catch (_) {}
        }
        try {
          Process.run('update-desktop-database', ['$home/.local/share/applications']);
        } catch (_) {}
        try {
          Process.run('kbuildsycoca6', ['--noincremental']);
        } catch (_) {}
        try {
          Process.run('kbuildsycoca5', ['--noincremental']);
        } catch (_) {}
      }
    }
  } catch (e) {
    final msg = 'Failed to execute uninstall command: $e';
    AppLogger().addMessage(msg);
    if (onStdErr != null) onStdErr(msg);
  }
  return exitCode;
}

/// Retrieves a list of available Flatpak updates.
/// Flow:
/// 1. Execute `flatpak remote-ls --updates`.
/// 2. Parse output and retrieve local desktop info and icons.
Future<List<FlatpakApp>> getFlatpakUpdates() async {
  final List<FlatpakApp> updates = [];
  try {
    final result = await Process.run('flatpak', [
      'remote-ls',
      '--updates',
      '--app',
      '--columns=name,description,application,version,branch,arch,origin',
    ]);

    if (result.exitCode == 0) {
      final String output = result.stdout as String;
      final List<String> lines = output.trim().split('\n');

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final columns = line.split('\t');

        if (columns.length >= 7) {
          final appId = columns[2].trim();
          final desktopInfo = parseDesktopInfo(appId);
          final iconPath = getIconPath(appId, desktopInfo.iconName);

          updates.add(
            FlatpakApp(
              name: columns[0].trim(),
              description: columns[1].trim(),
              application: appId,
              version: columns[3].trim(),
              branch: columns[4].trim(),
              arch: columns[5].trim(),
              runtime: '',
              origin: columns[6].trim(),
              installation: 'update',
              ref: '',
              active: '',
              latest: '',
              size: 'Unknown',
              installDate: null,
              iconPath: iconPath,
              permissions: [],
              categories: desktopInfo.categories,
              keywords: desktopInfo.keywords,
            ),
          );
        }
      }
    }
  } catch (e) {
    AppLogger().addMessage('Failed to check for updates: $e');
  }
  return updates;
}

/// Executes the flatpak update command for a specific application.
Future<int> updateFlatpakAppCommand(String appId, {void Function(String line)? onStdOut, void Function(String line)? onStdErr}) async {
  int exitCode = 1;
  try {
    final process = await Process.start('flatpak', ['update', '-y', '-v', appId]);

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdOut);
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdErr);

    exitCode = await process.exitCode;
  } catch (e) {
    final msg = 'Failed to execute update command: $e';
    AppLogger().addMessage(msg);
    if (onStdErr != null) onStdErr(msg);
  }
  return exitCode;
}

/// Executes the flatpak install command for a specific application.
Future<int> installFlatpakAppCommand(
  String appId, {
  bool isSystem = false,
  void Function(String line)? onStdOut,
  void Function(String line)? onStdErr,
}) async {
  int exitCode = 1;
  try {
    final List<String> args = ['install', '-y', '--noninteractive', '-v'];
    if (isSystem) {
      args.add('--system');
    } else {
      args.add('--user');
    }
    args.add('flathub');
    args.add(appId);

    final process = await Process.start('flatpak', args);

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdOut);
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(onStdErr);

    exitCode = await process.exitCode;
  } catch (e) {
    final msg = 'Failed to execute install command: $e';
    AppLogger().addMessage(msg);
    if (onStdErr != null) onStdErr(msg);
  }
  return exitCode;
}

/// Retrieves the installation date of a Flatpak application from the filesystem.
DateTime? getInstallDate(String appId) {
  final String? home = Platform.environment['HOME'];

  if (home != null) {
    final userDir = Directory('$home/.local/share/flatpak/app/$appId/current');
    if (userDir.existsSync()) {
      return userDir.statSync().modified;
    }
  }

  final systemDir = Directory('/var/lib/flatpak/app/$appId/current');
  if (systemDir.existsSync()) {
    return systemDir.statSync().modified;
  }

  return null;
}

/// Attempts to locate the local icon path for a given application.
/// Flow:
/// 1. Prioritize icon paths defined directly in the .desktop file.
/// 2. Search for standard SVG icons in the exports directory.
/// 3. Fallback to searching standard PNG sizes.
/// 4. If all else fails, search using the application ID.
String? getIconPath(String appId, String? iconName) {
  final String? home = Platform.environment['HOME'];

  final List<String> basePaths = [
    if (home != null) '$home/.local/share/flatpak/exports/share/icons/hicolor',
    '/var/lib/flatpak/exports/share/icons/hicolor',
  ];

  final List<String> sizes = ['128x128', '256x256', '64x64', '512x512', '32x32'];

  String? searchForIcon(String name) {
    for (final basePath in basePaths) {
      final File svgFile = File('$basePath/scalable/apps/$name.svg');
      if (svgFile.existsSync()) return svgFile.path;

      for (final size in sizes) {
        final File iconFile = File('$basePath/$size/apps/$name.png');
        if (iconFile.existsSync()) return iconFile.path;
      }
    }
    return null;
  }

  if (iconName != null && iconName.isNotEmpty) {
    if (iconName.startsWith('/')) {
      if (File(iconName).existsSync()) return iconName;
    } else {
      final path = searchForIcon(iconName);
      if (path != null) return path;
    }
  }

  return searchForIcon(appId);
}

/// Extracts sandbox permissions from the active Flatpak metadata file.
List<String> getPermissions(String appId) {
  final String? home = Platform.environment['HOME'];

  final List<String> metadataPaths = [
    if (home != null) '$home/.local/share/flatpak/app/$appId/current/active/metadata',
    '/var/lib/flatpak/app/$appId/current/active/metadata',
  ];

  for (final path in metadataPaths) {
    final file = File(path);
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();
      List<String> permissions = [];
      bool insideContextBlock = false;

      for (final line in lines) {
        if (line.trim() == '[Context]') {
          insideContextBlock = true;
          continue;
        }
        if (insideContextBlock && line.startsWith('[')) break;

        if (insideContextBlock) {
          if (line.startsWith('shared=')) {
            if (line.contains('network')) permissions.add('Network Access');
            if (line.contains('ipc')) permissions.add('Inter-Process Comm. (IPC)');
          }
          if (line.startsWith('sockets=')) {
            if (line.contains('x11') || line.contains('wayland')) permissions.add('Display Server');
            if (line.contains('pulseaudio')) permissions.add('Audio Output');
          }
          if (line.startsWith('filesystems=')) {
            if (line.contains('host')) permissions.add('Full Host Filesystem');
            if (line.contains('home')) permissions.add('Home Directory');
          }
          if (line.startsWith('devices=')) {
            if (line.contains('all')) permissions.add('Hardware Devices (Webcam, USB, TPM, etc.)');
          }
        }
      }
      return permissions.isNotEmpty ? permissions : ['Strict Sandbox (No external access)'];
    }
  }
  return ['Unknown'];
}

/// Parses the application's `.desktop` file to extract categories, keywords, and icon names.
DesktopInfo parseDesktopInfo(String appId) {
  final String? home = Platform.environment['HOME'];

  final List<String> desktopPaths = [
    if (home != null) '$home/.local/share/flatpak/exports/share/applications/$appId.desktop',
    '/var/lib/flatpak/exports/share/applications/$appId.desktop',
  ];

  List<String> categories = ['Uncategorized'];
  List<String> keywords = [];
  String? iconName;

  for (final path in desktopPaths) {
    final file = File(path);
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();

      for (final line in lines) {
        if (line.startsWith('Categories=')) {
          final categoryString = line.substring('Categories='.length);
          categories = categoryString.split(';').where((c) => c.trim().isNotEmpty).toList();
        } else if (line.startsWith('Icon=')) {
          iconName = line.substring('Icon='.length).trim();
        } else if (line.startsWith('Keywords=')) {
          final keywordString = line.substring('Keywords='.length);
          keywords = keywordString.split(';').where((k) => k.trim().isNotEmpty).toList();
        }
      }
      break;
    }
  }

  return DesktopInfo(categories, keywords, iconName);
}
