import 'package:flutter/material.dart';
import '../state/home_state.dart';
import '../screens/app_icon.dart';

/// The main view displaying a list of available Flatpak updates and End-Of-Life (EOL) migrations.
class UpdatesView extends StatelessWidget {
  final HomeState state;
  const UpdatesView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isCheckingUpdates) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Checking for updates...')],
        ),
      );
    }

    if (state.flatpakUpdates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No updates available', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: state.fetchUpdates, child: const Text('Check Again')),
          ],
        ),
      );
    }

    final updates = state.filteredUpdates;

    if (updates.isEmpty) {
      String message;
      final bool hasSearchFilter = state.searchQuery.isNotEmpty;
      final bool hasCategoryFilter = state.selectedCategory != 'All' && state.selectedCategory != 'All (show uncategorized)';

      if (hasSearchFilter) {
        message = 'No updates found matching "${state.searchQuery}"';
        if (hasCategoryFilter) {
          message += ' in category "${state.selectedCategory}"';
        }
      } else if (hasCategoryFilter) {
        message = 'No updates found in category "${state.selectedCategory}"';
      } else {
        message = 'No updates found.';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: state.scrollController,
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final app = updates[index];
        final bool isEol = app.eolMessage != null;
        final bool isSelected = state.selectedAppId == app.uniqueId;

        final String actionText;
        final Color actionColor;
        if (isEol) {
          if (app.eolRebaseId != null) {
            actionText = 'Migrate';
            actionColor = Colors.orange;
          } else {
            actionText = 'Uninstall';
            actionColor = Colors.red;
          }
        } else {
          actionText = 'Update';
          actionColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isSelected ? Theme.of(context).colorScheme.inversePrimary : null,
          child: ListTile(
            onTap: () => state.selectApp(app.uniqueId),
            selected: isSelected,
            leading: AppIcon(iconPath: app.iconPath, size: 40),
            title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isEol
                ? Text('⚠️ ${app.eolMessage}', style: const TextStyle(color: Colors.deepOrange))
                : Text('New Version: ${app.version}\nBranch: ${app.branch}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Action: '),
                      TextSpan(
                        text: actionText,
                        style: TextStyle(fontWeight: FontWeight.bold, color: actionColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
