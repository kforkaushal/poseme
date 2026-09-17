import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final elevatedBg =
        isDark ? AppTheme.darkBgElevated : AppTheme.lightBgElevated;
    final borderColor =
        isDark ? AppTheme.darkBorderHairline : AppTheme.lightBorderHairline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // APPEARANCE SECTION
          _SectionHeader(title: 'appearance', color: secondaryTextColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Custom monochrome theme selector — strictly no color outside gray tokens.
                // SegmentedButton was replaced because Material3 tints the selected segment
                // teal/cyan from the colorScheme, which violates the B&W design brief.
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: Row(
                    children: ThemeMode.values.map((mode) {
                      final isSelected = settings.themeMode == mode;
                      final label = switch (mode) {
                        ThemeMode.light => 'Light',
                        ThemeMode.dark => 'Dark',
                        ThemeMode.system => 'System',
                      };
                      final isFirst = mode == ThemeMode.values.first;
                      final isLast = mode == ThemeMode.values.last;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => settingsNotifier.setThemeMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? textColor : elevatedBg,
                              borderRadius: BorderRadius.horizontal(
                                left: isFirst
                                    ? const Radius.circular(AppTheme.radiusSmall)
                                    : Radius.zero,
                                right: isLast
                                    ? const Radius.circular(AppTheme.radiusSmall)
                                    : Radius.zero,
                              ),
                              border: Border.all(color: borderColor),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color:
                                    isSelected ? elevatedBg : secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CAMERA SECTION
          _SectionHeader(title: 'camera', color: secondaryTextColor),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                // Grid Lines Toggle
                SwitchListTile.adaptive(
                  value: settings.showGridLines,
                  onChanged: (_) => settingsNotifier.toggleGridLines(),
                  title: Text(
                    'Grid lines (rule of thirds)',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  subtitle: Text(
                    'Show alignment guides on viewfinder',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  activeTrackColor: textColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                Divider(color: borderColor, height: 1),

                // Crosshair Toggle
                SwitchListTile.adaptive(
                  value: settings.showCrosshair,
                  onChanged: (_) => settingsNotifier.toggleCrosshair(),
                  title: Text(
                    'Center crosshair',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  subtitle: Text(
                    'Show center mark to level and compose shots',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  activeTrackColor: textColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                Divider(color: borderColor, height: 1),

                // Mirror Front Camera
                SwitchListTile.adaptive(
                  value: settings.mirrorFrontCamera,
                  onChanged: (_) =>
                      settingsNotifier.toggleMirrorFrontCamera(),
                  title: Text(
                    'Mirror front camera preview',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  subtitle: Text(
                    'Match overlay orientation to selfie feed',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  activeTrackColor: textColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                Divider(color: borderColor, height: 1),

                // Save to system gallery
                SwitchListTile.adaptive(
                  value: settings.saveToSystemGallery,
                  onChanged: (_) =>
                      settingsNotifier.toggleSaveToSystemGallery(),
                  title: Text(
                    'Save to device photos',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  subtitle: Text(
                    settings.saveToSystemGallery
                        ? 'Saved to camera roll and in-app gallery'
                        : 'Saved to in-app gallery only',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  activeTrackColor: textColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                Divider(color: borderColor, height: 1),

                // Brand Watermark Toggle
                SwitchListTile(
                  value: settings.addWatermark,
                  onChanged: (_) => settingsNotifier.toggleWatermark(),
                  title: Text(
                    'Brand watermark',
                    style: TextStyle(fontSize: 15, color: textColor),
                  ),
                  subtitle: Text(
                    settings.addWatermark
                        ? 'Subtle Pose Me logo on saved photos'
                        : 'No watermark on saved photos',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                  ),
                  activeTrackColor: textColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                Divider(color: borderColor, height: 1),

                // Default Opacity Slider
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Default overlay opacity',
                            style: TextStyle(fontSize: 15, color: textColor),
                          ),
                          Text(
                            '${(settings.defaultOpacity * 100).round()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: settings.defaultOpacity,
                          min: 0.1,
                          max: 0.9,
                          divisions: 16,
                          onChanged: (val) {
                            settingsNotifier.setDefaultOpacity(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ABOUT SECTION
          _SectionHeader(title: 'about', color: secondaryTextColor),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/logo_full.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pose Me',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (build 1)',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: borderColor, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    title: Text('Licenses',
                        style: TextStyle(fontSize: 14, color: textColor)),
                    trailing: Icon(Icons.chevron_right,
                        size: 18, color: secondaryTextColor),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Pose Me',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
