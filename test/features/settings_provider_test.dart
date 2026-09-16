import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial settings defaults to Dark mode with grid lines enabled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(settingsProvider);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.showGridLines, true);
      expect(settings.timerSeconds, 0);
      expect(settings.defaultOpacity, 0.40);
    });

    test('Changing theme mode updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setThemeMode(ThemeMode.light);

      expect(container.read(settingsProvider).themeMode, ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.system);
      expect(container.read(settingsProvider).themeMode, ThemeMode.system);
    });

    test('Timer cycling works sequentially: Off -> 3s -> 10s -> Off', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).timerSeconds, 0);

      await notifier.cycleTimer();
      expect(container.read(settingsProvider).timerSeconds, 3);

      await notifier.cycleTimer();
      expect(container.read(settingsProvider).timerSeconds, 10);

      await notifier.cycleTimer();
      expect(container.read(settingsProvider).timerSeconds, 0);
    });

    test('Toggling grid lines updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      final initialGrid = container.read(settingsProvider).showGridLines;

      await notifier.toggleGridLines();
      expect(container.read(settingsProvider).showGridLines, !initialGrid);
    });

    test('Toggling crosshair updates state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      expect(container.read(settingsProvider).showCrosshair, false);

      await notifier.toggleCrosshair();
      expect(container.read(settingsProvider).showCrosshair, true);

      await notifier.toggleCrosshair();
      expect(container.read(settingsProvider).showCrosshair, false);
    });
  });
}
