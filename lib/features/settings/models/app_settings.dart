import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool showGridLines;
  final int timerSeconds;
  final double defaultOpacity;
  final bool mirrorFrontCamera;
  final bool saveToSystemGallery;
  final bool showCrosshair;
  final bool addWatermark;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.showGridLines = true,
    this.timerSeconds = 0,
    this.defaultOpacity = 0.40,
    this.mirrorFrontCamera = true,
    this.saveToSystemGallery = true,
    this.showCrosshair = false,
    this.addWatermark = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? showGridLines,
    int? timerSeconds,
    double? defaultOpacity,
    bool? mirrorFrontCamera,
    bool? saveToSystemGallery,
    bool? showCrosshair,
    bool? addWatermark,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      showGridLines: showGridLines ?? this.showGridLines,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      defaultOpacity: defaultOpacity ?? this.defaultOpacity,
      mirrorFrontCamera: mirrorFrontCamera ?? this.mirrorFrontCamera,
      saveToSystemGallery: saveToSystemGallery ?? this.saveToSystemGallery,
      showCrosshair: showCrosshair ?? this.showCrosshair,
      addWatermark: addWatermark ?? this.addWatermark,
    );
  }
}
