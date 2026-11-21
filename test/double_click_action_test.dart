import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/models/app_settings.dart';
import 'package:flatbag/models/flatpak_app.dart';
import 'package:flatbag/models/flatpak_remote_app.dart';
import 'package:flatbag/screens/installed_apps_view.dart';
import 'package:flatbag/screens/remote_apps_view.dart';
import 'package:flatbag/screens/settings_view.dart';
import 'package:flatbag/state/home_state.dart';

FlatpakApp _makeInstalledApp(String id, String name) {
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
    active: '1',
    latest: '1',
    size: '10 MB',
    permissions: const [],
    categories: const ['Utility'],
    keywords: const [],
  );
}

FlatpakRemoteApp _makeRemoteApp(String id, String name, {bool isInstalled = false}) {
  return FlatpakRemoteApp(
    flatpakAppId: id,
    name: name,
    summary: 'Summary for $name',
    categories: const ['Utility'],
    screenshots: const [],
    releases: const [],
    isInstalled: isInstalled,
  );
}

void main() {
  group('AppSettings doubleClickMainAction', () {
    test('is enabled by default and serializes/deserializes cleanly', () {
      final defaults = AppSettings();
      expect(defaults.doubleClickMainAction, isTrue);

      final json = defaults.toJson();
      expect(json['doubleClickMainAction'], isTrue);

      final restoredDisabled = AppSettings.fromJson({...json, 'doubleClickMainAction': false});
      expect(restoredDisabled.doubleClickMainAction, isFalse);

      // Backwards compatibility when older settings.json lacks the key
      json.remove('doubleClickMainAction');
      final legacyRestored = AppSettings.fromJson(json);
      expect(legacyRestored.doubleClickMainAction, isTrue);
    });
  });

  group('HomeState.handleItemTap', () {
    late HomeState state;

    setUp(() {
      state = HomeState();
    });

    tearDown(() {
      state.dispose();
    });

    test('selects immediately on first tap, fires main action on second tap within window, keeps selected, and guards triple-click', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      expect(state.handleItemTap('app.a', now: t0), isFalse);
      expect(state.selectedAppId, 'app.a');

      expect(state.handleItemTap('app.a', now: t0.add(const Duration(milliseconds: 150))), isTrue);
      expect(state.selectedAppId, 'app.a');

      // Rapid 3rd tap must not fire main action a second time
      expect(state.handleItemTap('app.a', now: t0.add(const Duration(milliseconds: 250))), isFalse);
      expect(state.selectedAppId, 'app.a');
    });

    test('keeps already-selected item selected across slow taps and double-clicks cleanly', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      expect(state.handleItemTap('app.a', now: t0), isFalse);
      expect(state.selectedAppId, 'app.a');

      // Slow second tap (>300ms) keeps selected without firing main action
      final t1 = t0.add(const Duration(milliseconds: 600));
      expect(state.handleItemTap('app.a', now: t1), isFalse);
      expect(state.selectedAppId, 'app.a');

      // Fast follow-up tap fires main action and keeps selected
      expect(state.handleItemTap('app.a', now: t1.add(const Duration(milliseconds: 120))), isTrue);
      expect(state.selectedAppId, 'app.a');
    });

    test('does not treat fast taps on different items as double-click', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      expect(state.handleItemTap('app.a', now: t0), isFalse);
      expect(state.handleItemTap('app.b', now: t0.add(const Duration(milliseconds: 100))), isFalse);
      expect(state.selectedAppId, 'app.b');
    });

    test('when disabled, never fires double-click and preserves toggle-deselection', () {
      state.settings.doubleClickMainAction = false;
      final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);

      expect(state.handleItemTap('app.a', now: t0), isFalse);
      expect(state.selectedAppId, 'app.a');

      expect(state.handleItemTap('app.a', now: t0.add(const Duration(milliseconds: 100))), isFalse);
      expect(state.selectedAppId, isNull);
    });
  });

  group('View double-click widget integration', () {
    for (final viewCase in [(label: 'List', type: 0), (label: 'Grid', type: 1), (label: 'Icons', type: 2)]) {
      testWidgets('InstalledAppsView (${viewCase.label}) triggers onAppMainAction on double tap and keeps selection', (tester) async {
        final state = HomeState();
        addTearDown(state.dispose);
        state.currentView = AppView.installedApps;
        state.isLoading = false;
        state.installedAppsViewType = viewCase.type;
        final app = _makeInstalledApp('org.example.calc', 'Calculator');
        state.flatpakInstalledApps = [app];

        final executed = <FlatpakApp>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstalledAppsView(state: state, onAppMainAction: executed.add),
            ),
          ),
        );

        await tester.tap(find.text('Calculator'));
        await tester.pump();
        expect(state.selectedAppId, app.uniqueId);
        expect(executed, isEmpty);

        await tester.tap(find.text('Calculator'));
        await tester.pump();
        expect(state.selectedAppId, app.uniqueId);
        expect(executed, [app]);
      });

      testWidgets('RemoteAppsView (${viewCase.label}) triggers onAppMainAction on double tap when enabled and skips when disabled', (tester) async {
        final state = HomeState();
        addTearDown(state.dispose);
        state.currentView = AppView.remoteApps;
        state.isLoading = false;
        state.remoteAppsViewType = viewCase.type;
        final app = _makeRemoteApp('org.example.editor', 'Code Editor');
        state.remoteApps = [app];

        final triggered = <FlatpakRemoteApp>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RemoteAppsView(state: state, onAppMainAction: triggered.add),
            ),
          ),
        );

        await tester.tap(find.text('Code Editor'));
        await tester.pump();
        await tester.tap(find.text('Code Editor'));
        await tester.pump();
        expect(state.selectedAppId, app.flatpakAppId);
        expect(triggered, [app]);

        // Disable setting and verify rapid double tap does not trigger action
        triggered.clear();
        state.settings.doubleClickMainAction = false;
        await tester.tap(find.text('Code Editor'));
        await tester.pump();
        await tester.tap(find.text('Code Editor'));
        await tester.pump();
        expect(triggered, isEmpty);
      });
    }

    testWidgets('SettingsView toggles doubleClickMainAction draft setting', (tester) async {
      final state = HomeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsView(state: state)),
        ),
      );

      expect(state.draftSettings.doubleClickMainAction, isTrue);
      await tester.tap(find.text('Perform Main Action on Double-Click'));
      await tester.pump();
      expect(state.draftSettings.doubleClickMainAction, isFalse);
    });
  });
}
