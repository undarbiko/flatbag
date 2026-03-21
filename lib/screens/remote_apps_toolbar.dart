import 'package:flutter/material.dart';
import '../state/home_state.dart';

/// The top toolbar for filtering, sorting, and changing the view mode of remote applications.
class RemoteAppsToolbar extends StatelessWidget {
  final HomeState state;

  const RemoteAppsToolbar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const TextStyle smallTextStyle = TextStyle(fontSize: 13);

    const InputDecoration compactDecoration = InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      labelStyle: TextStyle(fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          PopupMenuButton<int>(
            icon: Icon(
              state.appsViewType == 0
                  ? Icons.view_list
                  : state.appsViewType == 1
                  ? Icons.grid_view
                  : Icons.apps,
              size: 21,
            ),
            tooltip: 'Change View',
            padding: const EdgeInsets.all(4),
            splashRadius: 20,
            initialValue: state.appsViewType,
            onSelected: (value) => state.setAppsViewType(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Row(children: [Icon(Icons.view_list, size: 18), SizedBox(width: 8), Text('List')])),
              const PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.grid_view, size: 18), SizedBox(width: 8), Text('Grid')])),
              const PopupMenuItem(value: 2, child: Row(children: [Icon(Icons.apps, size: 18), SizedBox(width: 8), Text('Icons')])),
            ],
          ),
          const SizedBox(width: 4),

          Expanded(
            flex: 2,
            child: TextField(
              controller: state.searchController,
              style: smallTextStyle,
              textAlignVertical: TextAlignVertical.center,
              decoration: compactDecoration.copyWith(
                labelText: 'Search Flathub',
                hintText: 'Search ${state.remoteApps.length} apps on Flathub...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12.5),
                prefixIcon: const Icon(Icons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                suffixIconConstraints: const BoxConstraints(minWidth: 36),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        splashRadius: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Clear search',
                        onPressed: state.clearSearch,
                      )
                    : const SizedBox(width: 36),
              ),
              onChanged: state.updateSearch,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              style: smallTextStyle.copyWith(color: Colors.black87),
              decoration: compactDecoration.copyWith(labelText: 'Category'),
              iconSize: 20,
              value: state.availableCategories.contains(state.selectedCategory) ? state.selectedCategory : 'All',
              items: state.availableCategories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis, style: smallTextStyle),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) state.setCategory(value);
              },
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              style: smallTextStyle.copyWith(color: Colors.black87),
              decoration: compactDecoration.copyWith(labelText: 'Sort By'),
              iconSize: 20,
              value: state.sortBy,
              items: ['Alphabet', 'Date', 'Size']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: smallTextStyle),
                    ),
                  )
                  .toList(),
              onChanged: (val) => state.setSort(val!),
            ),
          ),

          IconButton(
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            splashRadius: 20,
            icon: Icon(state.isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () => state.toggleSortOrder(),
          ),
          const SizedBox(height: 24, child: VerticalDivider(indent: 2, endIndent: 2, color: Colors.black26)),
          IconButton(
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            splashRadius: 20,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Flathub',
            onPressed: () {
              state.runBackgroundUpdate(force: true);
            },
          ),
        ],
      ),
    );
  }
}
