import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatbag/screens/settings_view.dart';
import 'package:flatbag/state/home_state.dart';

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('SettingsView aligns checkboxes right, uses compact dropdowns, and renders hairline dividers (${brightness.name})', (
      tester,
    ) async {
      final state = HomeState();
      addTearDown(state.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9BA2FF), brightness: brightness)),
          home: Scaffold(body: SettingsView(state: state)),
        ),
      );

      final checkboxes = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).toList();
      expect(checkboxes, isNotEmpty);
      for (final tile in checkboxes) {
        expect(tile.controlAffinity, ListTileControlAffinity.trailing);
      }

      final stringDropdowns = tester.widgetList<DropdownButton<String>>(find.byType(DropdownButton<String>)).toList();
      final intDropdowns = tester.widgetList<DropdownButton<int>>(find.byType(DropdownButton<int>)).toList();
      final doubleDropdowns = tester.widgetList<DropdownButton<double>>(find.byType(DropdownButton<double>)).toList();

      expect(stringDropdowns.length + intDropdowns.length + doubleDropdowns.length, 5);
      for (final dropdown in [...stringDropdowns, ...intDropdowns, ...doubleDropdowns]) {
        expect(dropdown.isDense, isTrue);
      }

      final dividers = tester.widgetList<Divider>(find.byType(Divider)).toList();
      expect(dividers.any((d) => d.thickness == 0.5), isTrue);
      expect(dividers.any((d) => d.thickness == 1.0), isTrue);

      final initialPersist = state.draftSettings.persistWindowSize;
      await tester.tap(find.text('Persist Window Size on Exit'));
      await tester.pump();
      expect(state.draftSettings.persistWindowSize, !initialPersist);
    });
  }
}
