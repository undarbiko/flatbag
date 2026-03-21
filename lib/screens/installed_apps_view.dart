import 'package:flutter/material.dart';
import '../../state/home_state.dart';
import '../screens/app_icon.dart';

/// The main view responsible for rendering the list, grid, or icon layout of installed applications.
class InstalledAppsView extends StatelessWidget {
  final HomeState state;
  const InstalledAppsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.filteredApps.isEmpty) {
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

    // Ensure the layout order matches remote_apps_view.dart for visual consistency across tabs.
    if (state.appsViewType == 2) {
      return _InstalledAppIconView(state: state);
    }

    if (state.appsViewType == 1) {
      return _InstalledAppGridView(state: state);
    }

    return _InstalledAppListView(state: state);
  }
}

class _InstalledAppListView extends StatelessWidget {
  final HomeState state;
  const _InstalledAppListView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Attach the controller to synchronize scrolling with the main window's scrollbar.
      controller: state.scrollController,
      itemCount: state.filteredApps.length,
      itemBuilder: (context, index) {
        final app = state.filteredApps[index];
        final bool isSelected = state.selectedAppId == app.uniqueId;
        final dateStr = app.installDate != null
            ? '${app.installDate!.year}-${app.installDate!.month.toString().padLeft(2, '0')}-${app.installDate!.day.toString().padLeft(2, '0')}'
            : 'Unknown';

        return Card(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 1.0)
                : const BorderSide(color: Color.fromARGB(100, 166, 166, 166), width: 1.0),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            selected: isSelected,
            onTap: () {
              state.selectApp(isSelected ? null : app.uniqueId);
            },
            leading: AppIcon(iconPath: app.iconPath, size: 36),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    app.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (app.version != null && app.version!.isNotEmpty && state.settings.listViewShowVersion)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(app.version!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ],
            ),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.settings.listViewShowDescription) ...[
                  const SizedBox(height: 4),
                  Text(app.description, style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
                if (state.settings.listViewShowAppId) ...[
                  const SizedBox(height: 4),
                  Text(app.application, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                if (app.categories.isNotEmpty && state.settings.listViewShowCategory) ...[
                  const SizedBox(height: 4),
                  Text(app.categories.first, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            trailing: Builder(
              builder: (context) {
                List<String> trailingLines = [];
                if (state.settings.listViewShowDate) trailingLines.add('Installed: $dateStr');
                if (state.settings.listViewShowSize) trailingLines.add('Size: ${app.size}');
                if (trailingLines.isEmpty) return const SizedBox.shrink();
                return Text(trailingLines.join('\n'), textAlign: TextAlign.right);
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _InstalledAppGridView extends StatelessWidget {
  final HomeState state;
  const _InstalledAppGridView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return GridView.builder(
      controller: state.scrollController,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300 * textScale,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.filteredApps.length,
      itemBuilder: (context, index) {
        final app = state.filteredApps[index];
        final bool isSelected = state.selectedAppId == app.uniqueId;
        final dateStr = app.installDate != null
            ? '${app.installDate!.year}-${app.installDate!.month.toString().padLeft(2, '0')}-${app.installDate!.day.toString().padLeft(2, '0')}'
            : 'Unknown';

        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: isSelected
                ? BorderSide(color: Theme.of(context).primaryColor, width: 1.0)
                : const BorderSide(color: Color.fromARGB(100, 166, 166, 166), width: 1.0),
          ),
          child: InkWell(
            onTap: () {
              state.selectApp(isSelected ? null : app.uniqueId);
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIcon(iconPath: app.iconPath, size: 48),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (app.categories.isNotEmpty && state.settings.gridViewShowCategory)
                              Text(
                                app.categories.first,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (state.settings.gridViewShowDate)
                              Text(
                                'Installed: $dateStr',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            if (state.settings.gridViewShowSize)
                              Text(
                                'Size: ${app.size}',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                      if (app.version != null && app.version!.isNotEmpty && state.settings.gridViewShowVersion)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Text(app.version!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ],
                  ),
                  if (state.settings.gridViewShowAppId)
                    Text(
                      app.application,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      app.description,
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InstalledAppIconView extends StatelessWidget {
  final HomeState state;
  const _InstalledAppIconView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
      itemCount: state.filteredApps.length,
      itemBuilder: (context, index) {
        final app = state.filteredApps[index];
        final bool isSelected = state.selectedAppId == app.uniqueId;

        return InkWell(
          onTap: () => state.selectApp(isSelected ? null : app.uniqueId),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.0),
                  )
                : null,
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
                      if (app.version != null && app.version!.isNotEmpty && state.settings.iconViewShowVersion)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            app.version!,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                AppIcon(iconPath: app.iconPath, size: 48),

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
        );
      },
    );
  }
}
