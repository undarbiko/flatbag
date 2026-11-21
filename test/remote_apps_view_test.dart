import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/main.dart';
import 'package:flatbag/models/flatpak_remote_app.dart';
import 'package:flatbag/screens/remote_apps_view.dart';
import 'package:flatbag/state/home_state.dart';

ThemeData _buildTheme(Brightness brightness, {Color? cardColor, Color? scaffoldColor}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9BA2FF), brightness: brightness),
    scaffoldBackgroundColor: scaffoldColor,
    cardTheme: cardColor != null ? CardThemeData(color: cardColor) : null,
    extensions: [
      SemanticColors(
        successButton: isDark ? const Color(0xFF5BAA6C) : const Color(0xFF7AE190),
        infoButton: isDark ? const Color(0xFF6586C2) : const Color(0xFF86B0FF),
        warningButton: isDark ? const Color(0xFFCC7B3A) : const Color(0xFFFF994A),
        installedItemTint: isDark ? const Color(0x245BAA6C) : const Color(0x1F4CAF50),
      ),
    ],
  );
}

HomeState _buildState({required int viewType, String? selectedAppId}) {
  final state = HomeState();
  state.currentView = AppView.remoteApps;
  state.isLoading = false;
  state.remoteAppsViewType = viewType;
  state.selectedAppId = selectedAppId;
  state.remoteApps = [
    FlatpakRemoteApp(
      flatpakAppId: 'org.example.installed',
      name: 'Installed App',
      summary: 'Already installed',
      categories: const ['Utility'],
      screenshots: const [],
      releases: const [],
      isInstalled: true,
    ),
    FlatpakRemoteApp(
      flatpakAppId: 'org.example.remote',
      name: 'Remote App',
      summary: 'Not installed',
      categories: const ['Utility'],
      screenshots: const [],
      releases: const [],
      isInstalled: false,
    ),
  ];
  return state;
}

void main() {
  for (final themeCase in [
    (label: 'default light', theme: _buildTheme(Brightness.light)),
    (label: 'pure light', theme: _buildTheme(Brightness.light, cardColor: Colors.white, scaffoldColor: Colors.white)),
    (label: 'dark', theme: _buildTheme(Brightness.dark, scaffoldColor: const Color(0xFF121212))),
  ]) {
    group('RemoteAppsView installed background (${themeCase.label})', () {
      for (final viewCase in [(label: 'List', type: 0), (label: 'Grid', type: 1)]) {
        testWidgets('${viewCase.label} view tints installed card opaquely and preserves selection', (tester) async {
          final state = _buildState(viewType: viewCase.type);
          addTearDown(state.dispose);

          await tester.pumpWidget(
            MaterialApp(
              theme: themeCase.theme,
              home: Scaffold(body: RemoteAppsView(state: state)),
            ),
          );

          final installedCard = tester.widget<Card>(find.ancestor(of: find.text('Installed App'), matching: find.byType(Card)));
          final remoteCard = tester.widget<Card>(find.ancestor(of: find.text('Remote App'), matching: find.byType(Card)));

          expect(installedCard.color, isNotNull);
          expect(installedCard.color!.a, 1.0);
          expect(remoteCard.color, isNull);
          expect(installedCard.color, isNot(themeCase.theme.colorScheme.primaryContainer));

          state.selectedAppId = 'org.example.installed';
          await tester.pumpWidget(
            MaterialApp(
              theme: themeCase.theme,
              home: Scaffold(body: RemoteAppsView(state: state)),
            ),
          );

          final selectedInstalledCard = tester.widget<Card>(find.ancestor(of: find.text('Installed App'), matching: find.byType(Card)));
          expect(selectedInstalledCard.color, themeCase.theme.colorScheme.primaryContainer);
        });
      }

      testWidgets('Icons view tints installed tile without border and preserves selection', (tester) async {
        final state = _buildState(viewType: 2);
        addTearDown(state.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: themeCase.theme,
            home: Scaffold(body: RemoteAppsView(state: state)),
          ),
        );

        final installedInk = tester.widget<Ink>(find.ancestor(of: find.text('Installed App'), matching: find.byType(Ink)));
        final remoteInk = tester.widget<Ink>(find.ancestor(of: find.text('Remote App'), matching: find.byType(Ink)));

        final installedDecoration = installedInk.decoration as BoxDecoration?;
        expect(installedDecoration, isNotNull);
        expect(installedDecoration!.color, isNotNull);
        expect(installedDecoration.color!.a, 1.0);
        expect(installedDecoration.border, isNull);
        expect(installedDecoration.color, isNot(themeCase.theme.colorScheme.primaryContainer));
        expect(remoteInk.decoration, isNull);

        state.selectedAppId = 'org.example.installed';
        await tester.pumpWidget(
          MaterialApp(
            theme: themeCase.theme,
            home: Scaffold(body: RemoteAppsView(state: state)),
          ),
        );

        final selectedInstalledInk = tester.widget<Ink>(find.ancestor(of: find.text('Installed App'), matching: find.byType(Ink)));
        final selectedDecoration = selectedInstalledInk.decoration as BoxDecoration?;
        expect(selectedDecoration?.color, themeCase.theme.colorScheme.primaryContainer);
        expect(selectedDecoration?.border, isNotNull);
      });
    });
  }
}
