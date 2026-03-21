import 'package:flutter/material.dart';
import '../state/home_state.dart';

/// The top toolbar for filtering and searching available updates.
class UpdatesToolbar extends StatelessWidget {
  final HomeState state;

  const UpdatesToolbar({super.key, required this.state});

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
          Expanded(
            flex: 2,
            child: TextField(
              controller: state.searchController,
              style: smallTextStyle,
              textAlignVertical: TextAlignVertical.center,
              decoration: compactDecoration.copyWith(
                labelText: 'Search',
                hintText: 'Find an update...',
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
                        onPressed: () {
                          state.clearSearch();
                        },
                      )
                    : const SizedBox(width: 36),
              ),
              onChanged: (value) {
                state.updateSearch(value);
              },
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
              items: state.availableCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, overflow: TextOverflow.ellipsis, style: smallTextStyle),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  state.setCategory(value);
                }
              },
            ),
          ),
          const SizedBox(width: 24, child: VerticalDivider(indent: 2, endIndent: 2, color: Colors.black26)),
          IconButton(
            iconSize: 20,
            padding: const EdgeInsets.all(4),
            splashRadius: 20,
            icon: const Icon(Icons.refresh),
            tooltip: 'Check for Updates',
            onPressed: () {
              state.fetchUpdates();
            },
          ),
        ],
      ),
    );
  }
}
