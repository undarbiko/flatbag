import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/flatpak_remote_app.dart';
import 'screenshot_viewer_dialog.dart';
import 'custom_action_button.dart';
import '../main.dart'; // Import to access SemanticColors

/// A dialog displaying comprehensive details, safety data, and screenshots for a remote Flathub application.
class RemoteAppDetailsDialog extends StatefulWidget {
  final FlatpakRemoteApp app;
  final VoidCallback? onInstall;
  final Future<Map<String, dynamic>?>? dataFetcher;

  const RemoteAppDetailsDialog({super.key, required this.app, this.onInstall, this.dataFetcher});

  @override
  State<RemoteAppDetailsDialog> createState() => _RemoteAppDetailsDialogState();
}

class _RemoteAppDetailsDialogState extends State<RemoteAppDetailsDialog> {
  final ScrollController _detailsController = ScrollController();
  final ScrollController _screenshotsController = ScrollController();
  final ScrollController _onlineDataController = ScrollController();

  @override
  void dispose() {
    _detailsController.dispose();
    _screenshotsController.dispose();
    _onlineDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      child: SizedBox(
        width: size.width * 0.8,
        height: size.height * 0.8,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('App Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    if (widget.app.iconUrl != null)
                      CachedNetworkImage(
                        imageUrl: widget.app.iconUrl!,
                        width: 64,
                        height: 64,
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64),
                      )
                    else
                      const Icon(Icons.public, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: SelectableText(widget.app.name, style: Theme.of(context).textTheme.headlineSmall)),
                              if (!widget.app.isInstalled && widget.onInstall != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: CustomActionButton(
                                    icon: Icons.download,
                                    label: 'Install',
                                    color: Theme.of(context).extension<SemanticColors>()!.successButton,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onInstall!();
                                    },
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            widget.app.summary,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          if (widget.app.categories.isNotEmpty)
                            Wrap(spacing: 8, children: widget.app.categories.map((c) => Chip(label: Text(c))).toList()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // --- Tab Navigation ---
              TabBar(
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                tabs: [
                  Tab(text: 'Details'),
                  Tab(text: 'Screenshots'),
                  Tab(text: 'Online Data'),
                ],
              ),
              // --- Tab Views ---
              Expanded(
                child: TabBarView(
                  children: [_buildRemoteDetailsTab(context), _buildRemoteScreenshotsTab(context), _buildRemoteOnlineDataTab(context)],
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
      ),
    );
  }

  Widget _buildRemoteDetailsTab(BuildContext context) {
    // Helper to strip basic HTML tags from descriptions.
    String cleanDescription(String html) {
      String parsed = html
          .replaceAll(RegExp(r'<br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<p.*?>'), '') // Handle <p> tags (even if they have attributes)
          .replaceAll(RegExp(r'</p>'), '\n\n')
          .replaceAll(RegExp(r'<li.*?>'), '• ')
          .replaceAll(RegExp(r'</li>'), '\n')
          .replaceAll(RegExp(r'<[^>]*>'), ''); // Strip all remaining HTML tags

      parsed = parsed.split('\n').map((line) => line.trim()).join('\n');

      parsed = parsed.replaceAll(RegExp(r'\n{3,}'), '\n\n');

      return parsed.trim();
    }

    return Scrollbar(
      controller: _detailsController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _detailsController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SelectableText(cleanDescription(widget.app.description ?? 'No description available.')),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Safety & Development', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (widget.dataFetcher != null) ...[
              FutureBuilder<Map<String, dynamic>?>(
                future: widget.dataFetcher,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Text('Safety details not available.', style: TextStyle(color: Colors.grey));
                  }

                  final data = snapshot.data!;
                  final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

                  final tags = metadata['tags'] as List<dynamic>? ?? [];
                  final bool isProprietary = tags.contains('proprietary') || data['is_free_license'] == false;
                  final bool isFreeLicense = !isProprietary;

                  final bool isVerified =
                      metadata['flathub::verification::verified'] == 'true' || metadata['flathub::verification::verified'] == true;

                  final permissions = data['permissions'] as Map<String, dynamic>? ?? {};

                  final List<dynamic> shared = permissions['shared'] ?? [];
                  final List<dynamic> sockets = permissions['sockets'] ?? [];
                  final List<dynamic> filesystems = permissions['filesystems'] ?? [];
                  final List<dynamic> devices = permissions['devices'] ?? [];

                  final bool hasNetwork = shared.contains('network');
                  final bool hasLegacyX11 = sockets.contains('x11') || sockets.contains('fallback-x11');
                  final bool hasAudio = sockets.contains('pulseaudio');
                  final bool hasDevices = devices.contains('all');

                  List<Widget> safetyWidgets = [];

                  safetyWidgets.add(
                    _SafetyBadge(
                      icon: isVerified ? Icons.verified : Icons.people_alt,
                      iconColor: isVerified ? Colors.blue : Colors.grey[600]!,
                      title: isVerified ? 'Software developer is verified' : 'Community Built',
                      subtitle: isVerified
                          ? 'The software developer has verified their identity, which makes the app more likely to be safe.'
                          : 'This app is packaged and maintained by the Flathub community.',
                    ),
                  );
                  safetyWidgets.add(const SizedBox(height: 12));

                  safetyWidgets.add(
                    _SafetyBadge(
                      icon: isFreeLicense ? Icons.code : Icons.privacy_tip,
                      iconColor: isFreeLicense ? Colors.green : Colors.orange,
                      title: isFreeLicense ? 'Open Source' : 'Proprietary code',
                      subtitle: isFreeLicense
                          ? 'The source code is public and can be independently audited.'
                          : 'The source code is not public, so it cannot be independently audited and might be unsafe.',
                    ),
                  );
                  safetyWidgets.add(const SizedBox(height: 12));

                  if (hasNetwork) {
                    safetyWidgets.add(
                      _SafetyBadge(icon: Icons.wifi, iconColor: Colors.orange, title: 'Network access', subtitle: 'Has network access'),
                    );
                  } else {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.wifi_off,
                        iconColor: Colors.green,
                        title: 'No network access',
                        subtitle: 'This app runs entirely offline.',
                      ),
                    );
                  }
                  safetyWidgets.add(const SizedBox(height: 12));

                  if (hasAudio) {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.mic,
                        iconColor: Colors.orange,
                        title: 'Microphone access and audio playback',
                        subtitle: 'Can listen using microphones and play audio without asking permission',
                      ),
                    );
                    safetyWidgets.add(const SizedBox(height: 12));
                  }

                  if (hasDevices) {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.camera_alt,
                        iconColor: Colors.orange,
                        title: 'User device access',
                        subtitle: 'Can access webcams or gaming controllers',
                      ),
                    );
                  } else {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.videocam_off,
                        iconColor: Colors.green,
                        title: 'No user device access',
                        subtitle: 'The app cannot access any user devices such as webcams or gaming controllers',
                      ),
                    );
                  }
                  safetyWidgets.add(const SizedBox(height: 12));

                  if (hasLegacyX11) {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.warning_amber,
                        iconColor: Colors.orange,
                        title: 'Legacy Windowing (X11)',
                        subtitle: 'This app uses a legacy windowing system which cannot isolate it from reading other active windows.',
                      ),
                    );
                    safetyWidgets.add(const SizedBox(height: 12));
                  } else {
                    safetyWidgets.add(
                      _SafetyBadge(
                        icon: Icons.shield,
                        iconColor: Colors.green,
                        title: 'Modern Windowing (Wayland)',
                        subtitle: 'This app uses modern display protocols with strong visual isolation.',
                      ),
                    );
                    safetyWidgets.add(const SizedBox(height: 12));
                  }

                  // Process filesystem permissions into readable safety badges.
                  for (var fsRaw in filesystems) {
                    final String fs = fsRaw.toString();
                    final bool isReadOnly = fs.endsWith(':ro');
                    final String cleanFs = fs.replaceAll(':ro', '').replaceAll(':create', '');

                    String title = '';
                    String subtitle = isReadOnly ? 'Can read data in the directory' : 'Can read and write all data in the directory';
                    IconData icon = Icons.folder_open;
                    Color color = Colors.orange;

                    if (cleanFs == 'home' || cleanFs == '~') {
                      title = 'Home folder';
                      icon = Icons.home;
                    } else if (cleanFs == 'host' || cleanFs == 'host-os' || cleanFs == 'host-etc') {
                      title = 'Host system folders';
                      icon = Icons.computer;
                    } else if (cleanFs == 'xdg-download') {
                      title = 'Download folder';
                      icon = Icons.download;
                    } else if (cleanFs == 'xdg-documents') {
                      title = 'Documents folder';
                      icon = Icons.description;
                    } else if (cleanFs == 'xdg-music') {
                      title = 'Music folder';
                      icon = Icons.library_music;
                    } else if (cleanFs == 'xdg-pictures') {
                      title = 'Pictures folder';
                      icon = Icons.photo_library;
                    } else if (cleanFs == 'xdg-videos') {
                      title = 'Videos folder';
                      icon = Icons.video_library;
                    } else if (cleanFs == 'xdg-desktop') {
                      title = 'Desktop folder';
                      icon = Icons.desktop_windows;
                    } else if (cleanFs.startsWith('xdg-run/')) {
                      title = 'User runtime subfolder ${cleanFs.replaceAll('xdg-run/', '')}';
                      icon = Icons.settings_applications;
                    } else if (cleanFs.startsWith('xdg-config/')) {
                      title = 'Configuration subfolder ${cleanFs.replaceAll('xdg-config/', '')}';
                      icon = Icons.settings;
                    } else {
                      title = 'Folder $cleanFs';
                    }

                    safetyWidgets.add(_SafetyBadge(icon: icon, iconColor: color, title: title, subtitle: subtitle));
                    safetyWidgets.add(const SizedBox(height: 12));
                  }

                  if (safetyWidgets.isNotEmpty) {
                    safetyWidgets.removeLast(); // Remove the trailing spacing
                  }

                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: safetyWidgets);
                },
              ),
            ] else ...[
              const Text('Safety details not available.', style: TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _DetailRow(label: 'App ID', value: widget.app.flatpakAppId),
            if (widget.app.currentReleaseVersion != null) _DetailRow(label: 'Version', value: widget.app.currentReleaseVersion!),
            if (widget.app.currentReleaseDate != null)
              _DetailRow(label: 'Released', value: widget.app.currentReleaseDate!.toIso8601String().split('T').first),
            if (widget.app.developerName != null) _DetailRow(label: 'Developer', value: widget.app.developerName!),
            if (widget.app.projectLicense != null) _DetailRow(label: 'License', value: widget.app.projectLicense!),
            if (widget.app.size != null) _DetailRow(label: 'Download Size', value: widget.app.size!),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteScreenshotsTab(BuildContext context) {
    if (widget.app.screenshots.isEmpty) {
      return const Center(child: Text('No screenshots available.'));
    }

    return Scrollbar(
      controller: _screenshotsController,
      thumbVisibility: true,
      child: GridView.builder(
        controller: _screenshotsController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.app.screenshots.length,
        itemBuilder: (context, index) {
          final s = widget.app.screenshots[index];
          final url = s.imgDesktopUrl;
          if (url.isEmpty) return const SizedBox.shrink();

          return InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ScreenshotViewerDialog(screenshots: widget.app.screenshots, initialIndex: index),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemoteOnlineDataTab(BuildContext context) {
    if (widget.dataFetcher == null) return const Center(child: Text('No data source provided.'));

    return FutureBuilder<Map<String, dynamic>?>(
      future: widget.dataFetcher,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data available.'));
        }

        final data = snapshot.data!;
        final Map<String, String> links = {};

        if (data['homepageUrl'] != null) links['Homepage'] = data['homepageUrl'];
        if (data['bugtrackerUrl'] != null) links['Bug Tracker'] = data['bugtrackerUrl'];
        if (data['helpUrl'] != null) links['Help / Documentation'] = data['helpUrl'];
        if (data['donationUrl'] != null) links['Donation'] = data['donationUrl'];
        if (data['translateUrl'] != null) links['Translate'] = data['translateUrl'];

        final appId = data['flatpakAppId'] ?? data['id'];
        if (appId != null) {
          links['Flathub Page'] = 'https://flathub.org/apps/$appId';
        }

        if (links.isEmpty) {
          return const Center(child: Text('No online links found.'));
        }

        return Scrollbar(
          controller: _onlineDataController,
          thumbVisibility: true,
          child: ListView(
            controller: _onlineDataController,
            padding: const EdgeInsets.all(16),
            children: links.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(e.value), mode: LaunchMode.externalApplication),
                      child: Text(
                        e.value,
                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
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
            width: 120,
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

/// A badge component for displaying a specific safety or permission attribute.
class _SafetyBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SafetyBadge({required this.icon, required this.iconColor, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
