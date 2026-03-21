import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Defines global theme state variables and utility methods.
class AppTheme {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<Color> seedColor = ValueNotifier(const Color(0xFF9BA2FF));
  static final ValueNotifier<double> textScale = ValueNotifier(1.0);

  static ThemeMode parseThemeMode(String mode) {
    if (mode == 'light') return ThemeMode.light;
    if (mode == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }
}

/// A data model representing the user's saved application settings.
class AppSettings {
  bool persistWindowSize;
  bool autoCheckUpdates;
  String defaultInstallScope;
  String themeMode;
  int accentColor;
  double textScale;
  int defaultInstalledAppsView;
  int defaultRemoteAppsView;
  int lastInstalledAppsView;
  int lastRemoteAppsView;
  bool iconViewShowCategory;
  bool iconViewShowVersion;
  bool gridViewShowCategory;
  bool gridViewShowVersion;
  bool gridViewShowAppId;
  bool gridViewShowSize;
  bool gridViewShowDate;
  bool listViewShowCategory;
  bool listViewShowVersion;
  bool listViewShowAppId;
  bool listViewShowSize;
  bool listViewShowDate;
  bool listViewShowDescription;
  double? windowWidth;
  double? windowHeight;

  AppSettings({
    this.persistWindowSize = true,
    this.autoCheckUpdates = true,
    this.defaultInstallScope = 'ask',
    this.themeMode = 'system',
    this.accentColor = 0xFF9BA2FF,
    this.textScale = 1.0,
    this.defaultInstalledAppsView = 1,
    this.defaultRemoteAppsView = 1,
    this.lastInstalledAppsView = 1,
    this.lastRemoteAppsView = 1,
    this.iconViewShowCategory = true,
    this.iconViewShowVersion = true,
    this.gridViewShowCategory = true,
    this.gridViewShowVersion = true,
    this.gridViewShowAppId = true,
    this.gridViewShowSize = true,
    this.gridViewShowDate = true,
    this.listViewShowCategory = true,
    this.listViewShowVersion = true,
    this.listViewShowAppId = true,
    this.listViewShowSize = true,
    this.listViewShowDate = true,
    this.listViewShowDescription = true,
    this.windowWidth,
    this.windowHeight,
  });

  Map<String, dynamic> toJson() => {
    'persistWindowSize': persistWindowSize,
    'autoCheckUpdates': autoCheckUpdates,
    'defaultInstallScope': defaultInstallScope,
    'themeMode': themeMode,
    'accentColor': accentColor,
    'textScale': textScale,
    'defaultInstalledAppsView': defaultInstalledAppsView,
    'defaultRemoteAppsView': defaultRemoteAppsView,
    'lastInstalledAppsView': lastInstalledAppsView,
    'lastRemoteAppsView': lastRemoteAppsView,
    'iconViewShowCategory': iconViewShowCategory,
    'iconViewShowVersion': iconViewShowVersion,
    'gridViewShowCategory': gridViewShowCategory,
    'gridViewShowVersion': gridViewShowVersion,
    'gridViewShowAppId': gridViewShowAppId,
    'gridViewShowSize': gridViewShowSize,
    'gridViewShowDate': gridViewShowDate,
    'listViewShowCategory': listViewShowCategory,
    'listViewShowVersion': listViewShowVersion,
    'listViewShowAppId': listViewShowAppId,
    'listViewShowSize': listViewShowSize,
    'listViewShowDate': listViewShowDate,
    'listViewShowDescription': listViewShowDescription,
    'windowWidth': windowWidth,
    'windowHeight': windowHeight,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      persistWindowSize: json['persistWindowSize'] ?? true,
      autoCheckUpdates: json['autoCheckUpdates'] ?? true,
      defaultInstallScope: json['defaultInstallScope'] ?? 'ask',
      themeMode: json['themeMode'] ?? 'system',
      accentColor: json['accentColor'] ?? 0xFF9BA2FF,
      textScale: (json['textScale'] ?? 1.0).toDouble(),
      defaultInstalledAppsView: json['defaultInstalledAppsView'] ?? 1,
      defaultRemoteAppsView: json['defaultRemoteAppsView'] ?? 1,
      lastInstalledAppsView: json['lastInstalledAppsView'] ?? 1,
      lastRemoteAppsView: json['lastRemoteAppsView'] ?? 1,
      iconViewShowCategory: json['iconViewShowCategory'] ?? true,
      iconViewShowVersion: json['iconViewShowVersion'] ?? true,
      gridViewShowCategory: json['gridViewShowCategory'] ?? true,
      gridViewShowVersion: json['gridViewShowVersion'] ?? true,
      gridViewShowAppId: json['gridViewShowAppId'] ?? true,
      gridViewShowSize: json['gridViewShowSize'] ?? true,
      gridViewShowDate: json['gridViewShowDate'] ?? true,
      listViewShowCategory: json['listViewShowCategory'] ?? true,
      listViewShowVersion: json['listViewShowVersion'] ?? true,
      listViewShowAppId: json['listViewShowAppId'] ?? true,
      listViewShowSize: json['listViewShowSize'] ?? true,
      listViewShowDate: json['listViewShowDate'] ?? true,
      listViewShowDescription: json['listViewShowDescription'] ?? true,
      windowWidth: json['windowWidth']?.toDouble(),
      windowHeight: json['windowHeight']?.toDouble(),
    );
  }

  static Future<File> _getConfigFile() async {
    String dir;
    if (Platform.isWindows) {
      dir = Platform.environment['LOCALAPPDATA'] ?? '.';
      dir = '$dir\\flatbag';
    } else {
      String? home = Platform.environment['HOME'];
      String? xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
      if (xdgConfig != null && xdgConfig.isNotEmpty) {
        dir = '$xdgConfig/flatbag';
      } else if (home != null) {
        dir = '$home/.config/flatbag';
      } else {
        dir = Directory.systemTemp.path;
      }
    }
    final d = Directory(dir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return File('$dir/settings.json');
  }

  /// Loads the settings from the local JSON configuration file.
  /// Returns a default instance if the file does not exist or fails to parse.
  static Future<AppSettings> load() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return AppSettings.fromJson(json.decode(content));
      }
    } catch (_) {}
    return AppSettings();
  }

  /// Saves the current settings to the local JSON configuration file.
  Future<void> save() async {
    try {
      final file = await _getConfigFile();
      await file.writeAsString(json.encode(toJson()));
    } catch (_) {}
  }
}
