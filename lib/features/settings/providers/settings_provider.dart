import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _keyTheme = 'settings_theme_mode';
  static const _keyGrid = 'settings_show_grid';
  static const _keyTimer = 'settings_timer_seconds';
  static const _keyOpacity = 'settings_default_opacity';
  static const _keyMirror = 'settings_mirror_front';
  static const _keySaveGallery = 'settings_save_gallery';
  static const _keyCrosshair = 'settings_show_crosshair';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_keyTheme);
    ThemeMode themeMode = ThemeMode.dark;
    if (themeStr == 'light') {
      themeMode = ThemeMode.light;
    } else if (themeStr == 'system') {
      themeMode = ThemeMode.system;
    }

    final showGrid = prefs.getBool(_keyGrid) ?? true;
    final timerSec = prefs.getInt(_keyTimer) ?? 0;
    final opacity = prefs.getDouble(_keyOpacity) ?? 0.40;
    final mirror = prefs.getBool(_keyMirror) ?? true;
    final saveGallery = prefs.getBool(_keySaveGallery) ?? true;
    final crosshair = prefs.getBool(_keyCrosshair) ?? false;

    state = AppSettings(
      themeMode: themeMode,
      showGridLines: showGrid,
      timerSeconds: timerSec,
      defaultOpacity: opacity,
      mirrorFrontCamera: mirror,
      saveToSystemGallery: saveGallery,
      showCrosshair: crosshair,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    String val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.system) val = 'system';
    await prefs.setString(_keyTheme, val);
  }

  Future<void> toggleGridLines() async {
    final next = !state.showGridLines;
    state = state.copyWith(showGridLines: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGrid, next);
  }

  Future<void> setTimerSeconds(int seconds) async {
    state = state.copyWith(timerSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimer, seconds);
  }

  Future<void> cycleTimer() async {
    int next;
    if (state.timerSeconds == 0) {
      next = 3;
    } else if (state.timerSeconds == 3) {
      next = 10;
    } else {
      next = 0;
    }
    await setTimerSeconds(next);
  }

  Future<void> setDefaultOpacity(double opacity) async {
    state = state.copyWith(defaultOpacity: opacity);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyOpacity, opacity);
  }

  Future<void> toggleMirrorFrontCamera() async {
    final next = !state.mirrorFrontCamera;
    state = state.copyWith(mirrorFrontCamera: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMirror, next);
  }

  Future<void> toggleSaveToSystemGallery() async {
    final next = !state.saveToSystemGallery;
    state = state.copyWith(saveToSystemGallery: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySaveGallery, next);
  }

  Future<void> toggleCrosshair() async {
    final next = !state.showCrosshair;
    state = state.copyWith(showCrosshair: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCrosshair, next);
  }
}
