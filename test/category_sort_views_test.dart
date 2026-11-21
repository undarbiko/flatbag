import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/models/flatpak_app.dart';
import 'package:flatbag/models/flatpak_remote_app.dart';
import 'package:flatbag/screens/category_section_header.dart';
import 'package:flatbag/screens/installed_apps_toolbar.dart';
import 'package:flatbag/screens/installed_apps_view.dart';
import 'package:flatbag/screens/remote_apps_toolbar.dart';
import 'package:flatbag/screens/remote_apps_view.dart';
import 'package:flatbag/state/home_state.dart';

HomeState _buildPopulatedState({required AppView view, required int viewType}) {
  final state = HomeState();
  state.currentView = view;
  state.isLoading = false;
  state.installedAppsViewType = viewType;
  state.remoteAppsViewType = viewType;
  state.selectedCategory = 'All';
  state.sortBy = 'Category';
  state.flatpakInstalledApps = [
    FlatpakApp(
      name: 'Dual App',
      description: 'In two categories',
      application: 'org.example.dual',
      version: '1.0',
      branch: 'stable',
      arch: 'x86_64',
      runtime: 'org.freedesktop.Platform',
      origin: 'flathub',
      installation: 'user',
      ref: 'app/org.example.dual/x86_64/stable',
      active: '1',
      latest: '1',
      size: '10 MB',
      permissions: const [],
      categories: const ['Game', 'Utility'],
      keywords: const [],
    ),
    FlatpakApp(
      name: 'Alpha Game',
      description: 'Game only',
      application: 'org.example.alpha',
      version: '1.0',
      branch: 'stable',
      arch: 'x86_64',
      runtime: 'org.freedesktop.Platform',
      origin: 'flathub',
      installation: 'user',
      ref: 'app/org.example.alpha/x86_64/stable',
      active: '1',
      latest: '1',
      size: '5 MB',
      permissions: const [],
      categories: const ['Game'],
      keywords: const [],
    ),
  ];
  state.remoteApps = [
    FlatpakRemoteApp(
      flatpakAppId: 'org.remote.dual',
      name: 'Remote Dual',
      summary: 'In two categories',
      categories: const ['Game', 'Utility'],
      screenshots: const [],
      releases: const [],
    ),
    FlatpakRemoteApp(
      flatpakAppId: 'org.remote.alpha',
      name: 'Alpha Remote',
      summary: 'Game only',
      categories: const ['Game'],
      screenshots: const [],
      releases: const [],
    ),
  ];
  return state;
}

void main() {
  for (final viewCase in [(label: 'List', type: 0), (label: 'Grid', type: 1), (label: 'Icons', type: 2)]) {
    testWidgets('InstalledAppsView renders category sections and multi-category items in ${viewCase.label} view', (tester) async {
      final state = _buildPopulatedState(view: AppView.installedApps, viewType: viewCase.type);
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: InstalledAppsView(state: state)),
        ),
      );

      expect(find.byType(CategorySectionHeader), findsNWidgets(2));
      expect(find.text('Game (2)'), findsOneWidget);
      expect(find.text('Utility (1)'), findsOneWidget);
      expect(find.text('Dual App'), findsNWidgets(2));
      expect(find.text('Alpha Game'), findsOneWidget);
    });

    testWidgets('RemoteAppsView renders category sections and multi-category items in ${viewCase.label} view', (tester) async {
      final state = _buildPopulatedState(view: AppView.remoteApps, viewType: viewCase.type);
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RemoteAppsView(state: state)),
        ),
      );

      expect(find.byType(CategorySectionHeader), findsNWidgets(2));
      expect(find.text('Game (2)'), findsOneWidget);
      expect(find.text('Utility (1)'), findsOneWidget);
      expect(find.text('Remote Dual'), findsNWidgets(2));
      expect(find.text('Alpha Remote'), findsOneWidget);
    });
  }

  testWidgets('Toolbars rebuild cleanly without assertion when switching category while Category sort is active', (tester) async {
    final state = _buildPopulatedState(view: AppView.installedApps, viewType: 0);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              InstalledAppsToolbar(state: state),
              RemoteAppsToolbar(state: state),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Category'), findsWidgets);

    state.setCategory('Game');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              InstalledAppsToolbar(state: state),
              RemoteAppsToolbar(state: state),
            ],
          ),
        ),
      ),
    );

    expect(state.sortBy, 'Alphabet');
    expect(tester.takeException(), isNull);
  });
}
