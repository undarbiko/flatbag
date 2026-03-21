import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../state/home_state.dart';

/// The main view responsible for rendering the list, grid, or icon layout of remote applications.
class RemoteAppsView extends StatelessWidget {
  final HomeState state;

  const RemoteAppsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.remoteApps.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final apps = state.filteredRemoteApps;

    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No apps found matching "${state.searchQuery}"'),
          ],
        ),
      );
    }

    if (state.appsViewType == 2) {
      return _RemoteIconsView(state: state);
    }

    if (state.appsViewType == 1) {
      return _RemoteGridView(state: state);
    }

    return _RemoteListView(state: state);
  }
}

/// Renders remote applications as a vertical list of tiles.
class _RemoteListView extends StatelessWidget {
  const _RemoteListView({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final apps = state.filteredRemoteApps;
    return ListView.builder(
      controller: state.scrollController,
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = state.selectedAppId == app.flatpakAppId;
        final bool hasDetails = app.summary.isNotEmpty;
        final String? size = app.size;

        final rawData = state.getRemoteAppCache(app.flatpakAppId);
        String? dateStr;
        String? version;
        if (rawData != null) {
          if (rawData['currentReleaseDate'] != null) {
            try {
              final date = DateTime.parse(rawData['currentReleaseDate']);
              dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
          version = rawData['currentReleaseVersion'];
        }

        return Card(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 1.0)
                : const BorderSide(color: Color.fromARGB(100, 166, 166, 166), width: 1.0),
          ),
          child: Stack(
            children: [
              ListTile(
                selected: isSelected,
                leading: app.iconUrl != null
                    ? CachedNetworkImage(
                        imageUrl: app.iconUrl!,
                        width: 40,
                        height: 40,
                        placeholder: (context, url) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: Icon(Icons.downloading, size: 20, color: Colors.grey)),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('Failed to load icon for ${app.name}: $error');
                          return const Icon(Icons.broken_image, size: 40, color: Colors.redAccent);
                        },
                      )
                    : const Icon(Icons.public, size: 40),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        app.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (version != null && state.settings.listViewShowVersion)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(version, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                  ],
                ),
                subtitle: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.settings.listViewShowDescription)
                      hasDetails
                          ? Text(app.summary, maxLines: 2, overflow: TextOverflow.ellipsis)
                          : const Text(
                              'Fetching details...',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                    if (state.settings.listViewShowAppId)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(app.flatpakAppId, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (app.categories.isNotEmpty && state.settings.listViewShowCategory)
                      Text(app.categories.first, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (size != null && state.settings.listViewShowSize)
                      Text('download size: $size', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (dateStr != null && state.settings.listViewShowDate) Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                onTap: () => state.selectApp(app.flatpakAppId),
              ),
              if (app.isInstalled) const Positioned(bottom: 4, left: 4, child: Icon(Icons.check_circle, size: 16, color: Colors.green)),
            ],
          ),
        );
      },
    );
  }
}

/// Renders remote applications as a grid of compact icons.
class _RemoteIconsView extends StatelessWidget {
  const _RemoteIconsView({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final apps = state.filteredRemoteApps;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.builder(
      controller: state.scrollController,
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110 * textScale,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = state.selectedAppId == app.flatpakAppId;
        final rawData = state.getRemoteAppCache(app.flatpakAppId);
        String? version;
        if (rawData != null) {
          version = rawData['currentReleaseVersion'];
        }

        return InkWell(
          onTap: () => state.selectApp(isSelected ? null : app.flatpakAppId),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.0),
                  )
                : null,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Align from top to bottom
                    crossAxisAlignment: CrossAxisAlignment.center, // Force horizontal centering
                    children: [
                      // Fixed height container for top labels ensures the icon is always perfectly aligned vertically.
                      SizedBox(
                        height: 28 * textScale,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (app.categories.isNotEmpty && state.settings.iconViewShowCategory)
                              Text(
                                app.categories.first,
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (version != null && state.settings.iconViewShowVersion)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  version,
                                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (app.iconUrl != null)
                        CachedNetworkImage(
                          imageUrl: app.iconUrl!,
                          width: 48,
                          height: 48,
                          placeholder: (context, url) => const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(child: Icon(Icons.downloading, size: 24, color: Colors.grey)),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        )
                      else
                        const Icon(Icons.public, size: 48, color: Colors.grey),

                      const SizedBox(height: 8),

                      // Fill remaining space, aligning text to the top so multi-line wrapping doesn't shift the icon layout.
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            app.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (app.isInstalled) const Positioned(bottom: 4, left: 4, child: Icon(Icons.check_circle, size: 16, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Renders remote applications as a grid of detailed cards.
class _RemoteGridView extends StatelessWidget {
  const _RemoteGridView({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final apps = state.filteredRemoteApps;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.builder(
      controller: state.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300 * textScale,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = state.selectedAppId == app.flatpakAppId;
        final bool hasDetails = app.summary.isNotEmpty;
        final String? size = app.size;

        final rawData = state.getRemoteAppCache(app.flatpakAppId);
        String? dateStr;
        String? version;
        if (rawData != null) {
          if (rawData['currentReleaseDate'] != null) {
            try {
              final date = DateTime.parse(rawData['currentReleaseDate']);
              dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
          version = rawData['currentReleaseVersion'];
        }

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 1.0)
                : const BorderSide(color: Color.fromARGB(100, 166, 166, 166), width: 1.0),
          ),
          child: InkWell(
            onTap: () => state.selectApp(isSelected ? null : app.flatpakAppId),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (app.iconUrl != null)
                            CachedNetworkImage(
                              imageUrl: app.iconUrl!,
                              width: 48,
                              height: 48,
                              placeholder: (context, url) => const SizedBox(
                                width: 48,
                                height: 48,
                                child: Center(child: Icon(Icons.downloading, size: 24, color: Colors.grey)),
                              ),
                              errorWidget: (context, url, error) {
                                debugPrint('Failed to load icon for ${app.name} (${app.iconUrl}): $error');
                                return const Icon(Icons.broken_image, size: 48, color: Colors.redAccent);
                              },
                            )
                          else
                            const Icon(Icons.public, size: 48, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (state.settings.gridViewShowCategory)
                                  Text(
                                    app.categories.isNotEmpty ? app.categories.first : 'Remote',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                if (size != null && state.settings.gridViewShowSize)
                                  Text(
                                    'Package size: $size',
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.right,
                                  ),
                                if (dateStr != null && state.settings.gridViewShowDate)
                                  Text(
                                    dateStr,
                                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    textAlign: TextAlign.right,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              app.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (version != null && state.settings.gridViewShowVersion)
                            Padding(
                              padding: const EdgeInsets.only(left: 6.0),
                              child: Text(version, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                        ],
                      ),
                      if (state.settings.gridViewShowAppId)
                        Text(
                          app.flatpakAppId,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          hasDetails ? app.summary : 'Fetching details...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: hasDetails ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey,
                          ),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
                if (app.isInstalled) const Positioned(bottom: 8, left: 8, child: Icon(Icons.check_circle, size: 16, color: Colors.green)),
              ],
            ),
          ),
        );
      },
    );
  }
}
