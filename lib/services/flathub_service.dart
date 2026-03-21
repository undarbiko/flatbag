import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/flatpak_remote_app.dart';
import '../utils/app_logger.dart';

class FlathubService {
  static const String _baseUrl = 'https://flathub.org/api/v2';

  /// Timestamp of the last successful fetch of the apps list.
  static DateTime? lastFetchTimestamp;

  /// Indicates if the last fetch attempt was successful.
  static bool lastFetchSucceeded = false;

  /// In-memory cache of all apps data to avoid repeated file I/O.
  static List<dynamic>? _inMemoryCache;

  /// Fetches AppStream data for a specific App ID from Flathub.
  /// Flow:
  /// 1. Attempt to read from memory cache.
  /// 2. Attempt to load from the main cache file if memory is empty.
  /// 3. Fallback to network request for base appstream data.
  /// 4. Lazily fetch summary data (permissions/license) if missing.
  /// Returns null if the app is not found or on error.
  Future<Map<String, dynamic>?> getAppDetails(String appId) async {
    Map<String, dynamic>? appData;

    if (appId.endsWith('.desktop')) {
      appId = appId.substring(0, appId.length - 8);
    }

    if (_inMemoryCache != null) {
      final app = _inMemoryCache!.firstWhere(
        (element) => element is Map && (element['flatpakAppId'] == appId || element['id'] == appId),
        orElse: () => null,
      );
      if (app != null) {
        appData = app as Map<String, dynamic>;
      }
    }

    if (appData == null) {
      final String cachePath = _getCacheFilePath();
      final File cacheFile = File(cachePath);
      if (_inMemoryCache == null && await cacheFile.exists()) {
        try {
          final content = await cacheFile.readAsString();
          _inMemoryCache = json.decode(content);
          return getAppDetails(appId); // Retry with populated cache
        } catch (_) {}
      }
    }

    // Network fallback for base appstream data
    if (appData == null) {
      try {
        final appStreamUrl = Uri.parse('$_baseUrl/appstream/$appId');
        final response = await http.get(appStreamUrl);
        if (response.statusCode == 200) {
          appData = json.decode(response.body) as Map<String, dynamic>;
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    }

    // Fetch summary data lazily if missing
    if (appData != null && !appData.containsKey('is_free_license')) {
      try {
        final summaryUrl = Uri.parse('$_baseUrl/summary/$appId');
        final summaryResponse = await http.get(summaryUrl);

        if (summaryResponse.statusCode == 200) {
          final summaryData = json.decode(summaryResponse.body) as Map<String, dynamic>;
          appData['permissions'] = summaryData['metadata']?['permissions'] ?? {};
          appData['is_free_license'] = summaryData['is_free_license'];
          if (summaryData['metadata'] != null) {
            appData['metadata'] = summaryData['metadata'];
          }
        } else {
          // Mark as fetched to avoid repeated failed requests
          appData['is_free_license'] = null;
        }
      } catch (e) {
        // Ignore error and proceed
      }
    }

    return appData;
  }

  /// Retrieves the raw cached data for a specific app ID from memory.
  /// This is useful for accessing fields (like dates) that might not be in the model yet.
  Map<String, dynamic>? getCachedAppStreamData(String appId) {
    if (appId.endsWith('.desktop')) {
      appId = appId.substring(0, appId.length - 8);
    }

    if (_inMemoryCache == null) return null;
    try {
      final app = _inMemoryCache!.firstWhere(
        (element) => element is Map && (element['flatpakAppId'] == appId || element['id'] == appId),
        orElse: () => null,
      );
      return app as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Retrieves the cached EOL (End of Life) data.
  Future<Map<String, String>> getEolData() async {
    final String cachePath = _getCacheFilePath();
    final File appsFile = File(cachePath);
    final File eolFile = File('${appsFile.parent.path}/flathub_eol.json');

    AppLogger().addMessage('Reading EOL data from: ${eolFile.path}');
    if (await eolFile.exists()) {
      try {
        final content = await eolFile.readAsString();
        AppLogger().addMessage('EOL file content length: ${content.length}');
        final Map<String, String> data = Map<String, String>.from(json.decode(content));
        AppLogger().addMessage('Successfully loaded ${data.length} EOL entries from cache.');
        return data;
      } catch (e) {
        AppLogger().addMessage('Error parsing EOL cache: $e');
      }
    } else {
      AppLogger().addMessage('EOL file does not exist at ${eolFile.path}');
    }
    return {};
  }

  /// Fetches the list of all available applications from Flathub.
  /// Flow:
  /// 1. Check for an existing valid cache file.
  /// 2. Validate cache freshness (trigger background refresh if stale).
  /// 3. Handle cache misses by fetching a fallback ID list and starting a background sync.
  Future<List<FlatpakRemoteApp>> getRemoteApps({bool forceRefresh = false}) async {
    final String cachePath = _getCacheFilePath();
    final File cacheFile = File(cachePath);

    if (!forceRefresh && await cacheFile.exists()) {
      try {
        AppLogger().addMessage('Loading remote apps from cache: $cachePath');
        final String content = await cacheFile.readAsString();
        final List<dynamic> data = json.decode(content);

        // Ensure cache is the rich data, not the old simple list of strings
        if (data.isNotEmpty && data.first is Map) {
          _inMemoryCache = data;

          // Check for staleness AFTER loading, so UI is not blocked
          final lastModified = await cacheFile.lastModified();
          if (DateTime.now().difference(lastModified).inHours >= 24) {
            AppLogger().addMessage('Cache is stale. Triggering background refresh.');
            fetchAndSaveRemoteAppsInBackground(); // No await, run silently
          }

          return data.map((json) => FlatpakRemoteApp.fromJson(json)).toList();
        } else {
          // The cache is invalid (e.g., old string list), treat as a cache miss.
          AppLogger().addMessage('Cache file contains invalid data. Deleting and treating as cache miss.');
          await cacheFile.delete();
        }
      } catch (e) {
        AppLogger().addMessage('Error reading or parsing cache: $e. Treating as cache miss.');
        // Attempt to delete corrupted file
        try {
          await cacheFile.delete();
        } catch (_) {}
      }
    }

    if (forceRefresh) {
      AppLogger().addMessage('Force refresh requested. Starting background sync...');
    } else {
      AppLogger().addMessage('Cache miss. Fetching fallback list and starting background sync.');
    }

    // Immediately start the full background download. This runs and does not block.
    fetchAndSaveRemoteAppsInBackground(forceRefresh: forceRefresh);

    // For the current session, fetch the simple list of IDs as a temporary measure.
    final url = Uri.parse('$_baseUrl/appstream');
    try {
      final response = await http.get(url);
      AppLogger().addMessage('Fallback fetch response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _inMemoryCache = data; // Store simple list in memory for this session

        // This data is NOT written to the cache file.
        if (data.isNotEmpty && data.first is String) {
          return data
              .map(
                (id) => FlatpakRemoteApp(
                  flatpakAppId: id.toString(),
                  name: id.toString(), // Use ID as name temporarily
                  summary: '',
                  categories: [],
                  iconUrl: null,
                  screenshots: [],
                  releases: [],
                ),
              )
              .toList();
        }
      }
      // If fallback fails, return empty list.
      return [];
    } catch (e) {
      AppLogger().addMessage('Error fetching fallback remote apps: $e');
      return [];
    }
  }

  /// Fetches the list of all available Flathub apps in a background process
  /// and saves the list as a file.
  Future<void> fetchAndSaveRemoteAppsInBackground({Function(String)? onLog, bool forceRefresh = false}) async {
    final receivePort = ReceivePort();
    final String cachePath = _getCacheFilePath();

    if (onLog != null) {
      onLog('Starting background process to fetch apps to $cachePath');
    }

    try {
      await Isolate.spawn(_backgroundWorker, [receivePort.sendPort, cachePath, forceRefresh]);
    } catch (e) {
      if (onLog != null) onLog('Failed to spawn background worker: $e');
    }

    receivePort.listen((message) {
      if (message is String) {
        if (message == 'DONE') {
          receivePort.close();
        } else {
          if (message == 'Successfully saved Flathub apps list.') {
            lastFetchSucceeded = true;
            lastFetchTimestamp = DateTime.now();
          } else if (message.startsWith('Error:')) {
            lastFetchSucceeded = false;
          }
          if (onLog != null) {
            onLog(message);
          } else {
            AppLogger().addMessage(message);
          }
        }
      }
    });
  }

  /// Background isolate worker to fetch, parse, and save Flathub app data.
  /// Flow:
  /// 1. Check remote 'Last-Modified' headers to skip download if unchanged.
  /// 2. Download and decompress the GZipped AppStream XML.
  /// 3. Parse XML and extract relevant app metadata (icons, screenshots, releases).
  /// 4. Fetch EOL (End of Life) and Rebase data from the Flathub API.
  /// 5. Save all processed data to local cache files.
  static Future<void> _backgroundWorker(List<dynamic> args) async {
    SendPort sendPort = args[0];
    String filePath = args[1];
    bool forceRefresh = args.length > 2 ? args[2] : false;

    // The URL for the repository's compressed AppStream file, used by software centers
    final url = Uri.parse('https://dl.flathub.org/repo/appstream/x86_64/appstream.xml.gz');
    const iconRepoBaseUrl = 'https://dl.flathub.org/repo/appstream/x86_64/icons/';
    final eolRebaseUrl = Uri.parse('https://flathub.org/api/v2/eol/rebase');
    final eolMessageUrl = Uri.parse('https://flathub.org/api/v2/eol/message');

    // Check for updates using Last-Modified header
    final metaFile = File('$filePath.meta');
    String? remoteLastModified;
    Map<String, dynamic> localMetaData = {};

    if (metaFile.existsSync()) {
      try {
        final content = await metaFile.readAsString();
        try {
          localMetaData = json.decode(content);
        } catch (_) {
          // Legacy support: file contained only the string
          localMetaData['lastModified'] = content.trim();
        }
      } catch (_) {}
    }

    bool shouldFetchAppStream = true;

    try {
      final headResponse = await http.head(url);
      if (headResponse.statusCode == 200) {
        remoteLastModified = headResponse.headers['last-modified'];
        if (!forceRefresh && remoteLastModified != null && File(filePath).existsSync()) {
          final localLastModified = localMetaData['lastModified'];
          if (localLastModified == remoteLastModified.trim()) {
            sendPort.send('Local cache is up to date ($remoteLastModified). Skipping download.');
            shouldFetchAppStream = false;
          }
        }
      }
    } catch (_) {}

    if (shouldFetchAppStream) {
      try {
        sendPort.send('Fetching AppStream data from $url...');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          sendPort.send('Download complete. Decompressing and parsing XML...');

          final lastModified = response.headers['last-modified'];

          final decompressed = GZipCodec().decode(response.bodyBytes);
          final xmlString = utf8.decode(decompressed);

          final document = XmlDocument.parse(xmlString);
          final components = document.findAllElements('component').where((node) {
            final type = node.getAttribute('type');
            return type == 'desktop-application' || type == 'desktop';
          });

          sendPort.send('Found ${components.length} components. Extracting app details...');

          List<Map<String, dynamic>> appsData = [];

          String? getLocalized(XmlElement parent, String tag, {bool asXml = false}) {
            final elements = parent.findElements(tag);
            if (elements.isEmpty) return null;

            var el = elements.where((e) => e.getAttribute('xml:lang') == null).firstOrNull;
            el ??= elements.where((e) => e.getAttribute('xml:lang')?.startsWith('en') == true).firstOrNull;
            el ??= elements.first;

            return asXml ? el.innerXml : el.innerText;
          }

          for (final component in components) {
            var id = component.findElements('id').firstOrNull?.innerText;
            if (id == null || id.isEmpty) continue;

            if (id.endsWith('.desktop')) {
              id = id.substring(0, id.length - 8);
            }

            String? iconUrl;
            final icons = component.findElements('icon');
            var iconNode = icons.where((icon) => icon.getAttribute('type') == 'remote').firstOrNull;

            if (iconNode != null) {
              iconUrl = iconNode.innerText;
            } else {
              // Fallback to a cached icon. Flathub stores them in /icons/<width>x<height>/<filename>
              // We prefer 128x128, then 64x64, then whatever is available.
              iconNode = icons.where((icon) => icon.getAttribute('type') == 'cached' && icon.getAttribute('width') == '128').firstOrNull;
              iconNode ??= icons.where((icon) => icon.getAttribute('type') == 'cached' && icon.getAttribute('width') == '64').firstOrNull;
              // Fallback: Grab ANY cached icon if the specific sizes are missing
              iconNode ??= icons.where((icon) => icon.getAttribute('type') == 'cached').firstOrNull;

              if (iconNode != null) {
                final width = iconNode.getAttribute('width') ?? '64';
                final height = iconNode.getAttribute('height') ?? '64';
                final filename = iconNode.innerText;
                iconUrl = '$iconRepoBaseUrl${width}x$height/$filename';
              }
            }

            final screenshots =
                component
                    .findElements('screenshots')
                    .firstOrNull
                    ?.findElements('screenshot')
                    .map((s) {
                      final imageNode = s.findElements('image').firstOrNull;
                      if (imageNode != null) {
                        final url = imageNode.innerText;
                        return {
                          'imgDesktopUrl': url,
                          'imgMobileUrl': url,
                          'thumbnailUrl': url, // No separate thumbnail in appstream xml
                        };
                      }
                      return null;
                    })
                    .whereType<Map<String, String>>()
                    .toList() ??
                [];

            final releases =
                component.findElements('releases').firstOrNull?.findElements('release').map((r) {
                  final timestampStr = r.getAttribute('timestamp');
                  return {
                    'version': r.getAttribute('version'),
                    'timestamp': timestampStr != null ? int.tryParse(timestampStr) : null,
                    'description': r.findElements('description').firstOrNull?.innerXml,
                    'url': r.getAttribute('url'),
                  };
                }).toList() ??
                [];

            appsData.add({
              'flatpakAppId': id,
              'name': getLocalized(component, 'name'),
              'summary': getLocalized(component, 'summary'),
              'description': getLocalized(component, 'description', asXml: true),
              'developerName': getLocalized(component, 'developer_name'),
              'projectLicense': component.findElements('project_license').firstOrNull?.innerText,
              'categories': component.findElements('categories').firstOrNull?.findElements('category').map((c) => c.innerText).toList() ?? [],
              'iconUrl': iconUrl,
              'iconDesktopUrl': iconUrl,
              'iconMobileUrl': iconUrl, // Use same for both
              'screenshots': screenshots,
              'releases': releases,
              'homepageUrl': component.findElements('url').where((e) => e.getAttribute('type') == 'homepage').firstOrNull?.innerText,
              'bugtrackerUrl': component.findElements('url').where((e) => e.getAttribute('type') == 'bugtracker').firstOrNull?.innerText,
              'helpUrl': component.findElements('url').where((e) => e.getAttribute('type') == 'help').firstOrNull?.innerText,
              'donationUrl': component.findElements('url').where((e) => e.getAttribute('type') == 'donation').firstOrNull?.innerText,
              'translateUrl': component.findElements('url').where((e) => e.getAttribute('type') == 'translate').firstOrNull?.innerText,
              'currentReleaseVersion': releases.isNotEmpty ? releases.first['version'] : null,
              'currentReleaseDate': releases.isNotEmpty && releases.first['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch((releases.first['timestamp'] as int) * 1000).toIso8601String()
                  : null,
            });
          }

          sendPort.send('Saving ${appsData.length} apps to file...');
          final file = File(filePath);
          if (!file.parent.existsSync()) {
            file.parent.createSync(recursive: true);
          }
          // Serialize the full list to the file
          await file.writeAsString(json.encode(appsData));

          if (lastModified != null) {
            final int oldCount = localMetaData['appCount'] is int ? localMetaData['appCount'] : 0;
            if (oldCount != 0 && oldCount != appsData.length) {
              sendPort.send('App count changed.');
            }

            final newMeta = {'lastModified': lastModified, 'appCount': appsData.length};
            await metaFile.writeAsString(json.encode(newMeta));
          }
        } else {
          sendPort.send('Error: HTTP ${response.statusCode}');
        }
      } catch (e, s) {
        sendPort.send('Error: $e\n$s');
      }
    }

    sendPort.send('Fetching EOL data...');
    Map<String, String> combinedEolData = {};
    final apiHeaders = {'User-Agent': 'FlatpakLauncher/1.0 (Linux)', 'Accept': 'application/json'};

    try {
      sendPort.send('Fetching rebase data from $eolRebaseUrl ...');
      final rebaseResponse = await http.get(eolRebaseUrl, headers: apiHeaders).timeout(const Duration(seconds: 30));
      if (rebaseResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(rebaseResponse.body);
        // Flathub API /api/v2/eol/rebase returns: { "new_app_id": [ "old_app_id" ] }
        data.forEach((newId, oldIds) {
          if (oldIds is List) {
            for (var oldId in oldIds) {
              combinedEolData[oldId.toString()] = newId;
            }
          } else if (oldIds != null) {
            combinedEolData[oldIds.toString()] = newId;
          }
        });
      }

      sendPort.send('Fetching EOL messages from $eolMessageUrl ...');
      final messageResponse = await http.get(eolMessageUrl, headers: apiHeaders).timeout(const Duration(seconds: 30));
      if (messageResponse.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(messageResponse.body);
        data.forEach((k, v) {
          // Prioritize existing rebase data (migration targets) over generic messages if collision occurs
          if (!combinedEolData.containsKey(k)) {
            combinedEolData[k] = v.toString();
          }
        });
      }

      if (combinedEolData.isNotEmpty) {
        final File appsFile = File(filePath);
        final File eolFile = File('${appsFile.parent.path}/flathub_eol.json');
        await eolFile.writeAsString(json.encode(combinedEolData));
        sendPort.send('Saved ${combinedEolData.length} EOL entries.');
      }
    } catch (e) {
      sendPort.send('Failed to fetch EOL data: $e');
    }

    sendPort.send('Successfully saved Flathub apps list.');
    sendPort.send('DONE');
  }

  String _getCacheFilePath() {
    String dir;
    if (Platform.isWindows) {
      dir = Platform.environment['LOCALAPPDATA'] ?? '.';
      dir = '$dir\\flatbag';
    } else {
      // Linux and others
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
    return '$dir/flathub_apps_details.json';
  }
}
