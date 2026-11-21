import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/models/flatpak_app.dart';
import 'package:flatbag/models/flatpak_remote_app.dart';
import 'package:flatbag/state/home_state.dart';

FlatpakApp _makeInstalledApp({
  required String id,
  required String name,
  required List<String> categories,
}) {
  return FlatpakApp(
    name: name,
    description: 'Description for $name',
    application: id,
    version: '1.0.0',
    branch: 'stable',
    arch: 'x86_64',
    runtime: 'org.freedesktop.Platform',
    origin: 'flathub',
    installation: 'user',
    ref: 'app/$id/x86_64/stable',
    active: 'abc',
    latest: 'abc',
    size: '10 MB',
    permissions: const [],
    categories: categories,
    keywords: const [],
  );
}

FlatpakRemoteApp _makeRemoteApp({
  required String id,
  required String name,
  required List<String> categories,
}) {
  return FlatpakRemoteApp(
    flatpakAppId: id,
    name: name,
    summary: 'Summary for $name',
    categories: categories,
    screenshots: const [],
    releases: const [],
  );
}

void main() {
  late HomeState state;

  setUp(() {
    state = HomeState();
    state.flatpakInstalledApps = [
      _makeInstalledApp(id: 'org.example.zebra', name: 'Zebra', categories: ['Utility', 'Game', 'Game']),
      _makeInstalledApp(id: 'org.example.alpha', name: 'Alpha', categories: ['Game']),
      _makeInstalledApp(id: 'org.example.bravo', name: 'Bravo', categories: ['Audio']),
      _makeInstalledApp(id: 'org.example.uncat', name: 'NoCat', categories: ['Uncategorized']),
      _makeInstalledApp(id: 'org.example.emptycat', name: 'EmptyCat', categories: []),
    ];
    state.remoteApps = [
      _makeRemoteApp(id: 'org.remote.zeta', name: 'Zeta', categories: ['Utility', 'Development']),
      _makeRemoteApp(id: 'org.remote.aardvark', name: 'Aardvark', categories: ['Development']),
      _makeRemoteApp(id: 'org.remote.orphan', name: 'Orphan', categories: []),
    ];
  });

  tearDown(() {
    state.dispose();
  });

  group('Category sort availability and transitions', () {
    test('Category sort is available only for All and All (show uncategorized)', () {
      state.setCategory('All');
      expect(state.canSortByCategory, isTrue);
      expect(state.availableSortOptions, contains('Category'));

      state.setCategory('All (show uncategorized)');
      expect(state.canSortByCategory, isTrue);
      expect(state.availableSortOptions, contains('Category'));

      state.setCategory('Game');
      expect(state.canSortByCategory, isFalse);
      expect(state.availableSortOptions, isNot(contains('Category')));
    });

    test('switching to a specific category resets sortBy from Category to Alphabet', () {
      state.setCategory('All');
      state.setSort('Category');
      expect(state.sortBy, 'Category');
      expect(state.isCategorySortActive, isTrue);

      state.setCategory('Game');
      expect(state.sortBy, 'Alphabet');
      expect(state.isCategorySortActive, isFalse);
    });

    test('setSort ignores Category when a specific category is selected', () {
      state.setCategory('Game');
      state.setSort('Category');
      expect(state.sortBy, 'Alphabet');
    });
  });

  group('HomeState.groupedInstalledApps', () {
    test('groups multi-category apps, deduplicates per category, omits empty/uncategorized under All, sorts A-Z inside', () {
      state.setCategory('All');
      state.setSort('Category');
      state.isAscending = true;

      final groups = state.groupedInstalledApps;
      expect(groups.map((g) => g.category).toList(), ['Audio', 'Game', 'Utility']);
      expect(groups[0].apps.map((a) => a.name).toList(), ['Bravo']);
      expect(groups[1].apps.map((a) => a.name).toList(), ['Alpha', 'Zebra']);
      expect(groups[2].apps.map((a) => a.name).toList(), ['Zebra']);
    });

    test('places Uncategorized at the bottom when All (show uncategorized) is selected', () {
      state.setCategory('All (show uncategorized)');
      state.setSort('Category');
      state.isAscending = true;

      final groups = state.groupedInstalledApps;
      expect(groups.map((g) => g.category).toList(), ['Audio', 'Game', 'Utility', 'Uncategorized']);
      expect(groups.last.apps.map((a) => a.name).toList(), ['EmptyCat', 'NoCat']);
    });

    test('descending order reverses named categories while keeping items A-Z and Uncategorized at the bottom', () {
      state.setCategory('All (show uncategorized)');
      state.setSort('Category');
      state.isAscending = false;

      final groups = state.groupedInstalledApps;
      expect(groups.map((g) => g.category).toList(), ['Utility', 'Game', 'Audio', 'Uncategorized']);
      // Items inside each category stay sorted A-Z
      expect(groups[1].apps.map((a) => a.name).toList(), ['Alpha', 'Zebra']);
      expect(groups.last.apps.map((a) => a.name).toList(), ['EmptyCat', 'NoCat']);
    });

    test('omits categories that become empty after search filtering', () {
      state.setCategory('All');
      state.setSort('Category');
      state.updateSearch('Alpha');

      final groups = state.groupedInstalledApps;
      expect(groups.map((g) => g.category).toList(), ['Game']);
      expect(groups.single.apps.map((a) => a.name).toList(), ['Alpha']);
    });
  });

  group('HomeState.groupedRemoteApps', () {
    test('groups multi-category remote apps, sorts items A-Z, and puts empty-category apps in Uncategorized at bottom', () {
      state.currentView = AppView.remoteApps;
      state.setCategory('All');
      state.setSort('Category');
      state.isAscending = true;

      final groups = state.groupedRemoteApps;
      expect(groups.map((g) => g.category).toList(), ['Development', 'Utility', 'Uncategorized']);
      expect(groups[0].apps.map((a) => a.name).toList(), ['Aardvark', 'Zeta']);
      expect(groups[1].apps.map((a) => a.name).toList(), ['Zeta']);
      expect(groups[2].apps.map((a) => a.name).toList(), ['Orphan']);
    });

    test('reverses remote category order when descending while keeping items A-Z and Uncategorized last', () {
      state.currentView = AppView.remoteApps;
      state.setCategory('All');
      state.setSort('Category');
      state.isAscending = false;

      final groups = state.groupedRemoteApps;
      expect(groups.map((g) => g.category).toList(), ['Utility', 'Development', 'Uncategorized']);
      expect(groups[1].apps.map((a) => a.name).toList(), ['Aardvark', 'Zeta']);
    });
  });
}
