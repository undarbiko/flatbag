import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/models/flatpak_remote_app.dart';
import 'package:flatbag/state/home_state.dart';

FlatpakRemoteApp _makeRemoteApp({
  required String id,
  required String name,
  DateTime? currentReleaseDate,
  String? size,
}) {
  return FlatpakRemoteApp(
    flatpakAppId: id,
    name: name,
    summary: '',
    categories: const ['Utility'],
    screenshots: const [],
    releases: const [],
    currentReleaseDate: currentReleaseDate,
    size: size,
  );
}

void main() {
  late HomeState state;

  setUp(() {
    state = HomeState();
    state.remoteApps = [
      _makeRemoteApp(
        id: 'org.example.beta',
        name: 'Beta',
        currentReleaseDate: DateTime(2026, 2, 16),
        size: '1.9 GB',
      ),
      _makeRemoteApp(
        id: 'org.example.alpha',
        name: 'Alpha',
        currentReleaseDate: DateTime(2024, 3, 29),
        size: '500 KB',
      ),
      _makeRemoteApp(
        id: 'org.example.gamma',
        name: 'Gamma',
        currentReleaseDate: DateTime(2024, 3, 29),
        size: '125.9 MB',
      ),
      _makeRemoteApp(
        id: 'org.example.undated_b',
        name: 'Undated B',
        currentReleaseDate: null,
        size: '125.9 MB',
      ),
      _makeRemoteApp(
        id: 'org.example.undated_a',
        name: 'Undated A',
        currentReleaseDate: null,
        size: null,
      ),
    ];
  });

  tearDown(() {
    state.dispose();
  });

  group('HomeState.filteredRemoteApps sorting', () {
    test('sorts by Date ascending with null dates first and A-Z tie-breaking', () {
      state.sortBy = 'Date';
      state.isAscending = true;

      final names = state.filteredRemoteApps.map((a) => a.name).toList();
      expect(names, ['Undated A', 'Undated B', 'Alpha', 'Gamma', 'Beta']);
    });

    test('sorts by Date descending with null dates last and A-Z tie-breaking', () {
      state.sortBy = 'Date';
      state.isAscending = false;

      final names = state.filteredRemoteApps.map((a) => a.name).toList();
      expect(names, ['Beta', 'Alpha', 'Gamma', 'Undated A', 'Undated B']);
    });

    test('sorts by Size ascending with A-Z tie-breaking', () {
      state.sortBy = 'Size';
      state.isAscending = true;

      final names = state.filteredRemoteApps.map((a) => a.name).toList();
      expect(names, ['Undated A', 'Alpha', 'Gamma', 'Undated B', 'Beta']);
    });

    test('sorts by Size descending with A-Z tie-breaking', () {
      state.sortBy = 'Size';
      state.isAscending = false;

      final names = state.filteredRemoteApps.map((a) => a.name).toList();
      expect(names, ['Beta', 'Gamma', 'Undated B', 'Alpha', 'Undated A']);
    });

    test('sorts by Alphabet ascending and descending', () {
      state.sortBy = 'Alphabet';
      state.isAscending = true;
      expect(
        state.filteredRemoteApps.map((a) => a.name).toList(),
        ['Alpha', 'Beta', 'Gamma', 'Undated A', 'Undated B'],
      );

      state.isAscending = false;
      expect(
        state.filteredRemoteApps.map((a) => a.name).toList(),
        ['Undated B', 'Undated A', 'Gamma', 'Beta', 'Alpha'],
      );
    });
  });
}
