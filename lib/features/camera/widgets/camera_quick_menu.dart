import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/camera_state.dart';
import '../providers/camera_provider.dart';

/// Slim horizontal strip of quick-access camera toggles, positioned directly
/// below the top bar. Overlays the viewfinder — does NOT affect preview layout.
///
/// Left to right: Flash → Ratio → Grid → Crosshair
class CameraQuickMenu extends ConsumerWidget {
  const CameraQuickMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final settings = ref.watch(settingsProvider);
    final cameraNotifier = ref.read(cameraProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.controlSurface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ── Flash ──────────────────────────────────────────────────────────
          _QuickToggle(
            icon: _flashIcon(cameraState.flashMode),
            label: _flashLabel(cameraState.flashMode),
            isActive: cameraState.flashMode != FlashMode.off,
            onTap: () => cameraNotifier.cycleFlashMode(),
            tooltip: 'Flash: ${_flashLabel(cameraState.flashMode)}',
          ),

          _Divider(),

          // ── Ratio ──────────────────────────────────────────────────────────
          _QuickToggle(
            icon: Icons.crop_outlined,
            label: cameraState.aspectRatioMode.label,
            isActive: cameraState.aspectRatioMode != CameraAspectRatio.full,
            onTap: () => cameraNotifier.cycleAspectRatio(),
            tooltip: 'Aspect ratio: ${cameraState.aspectRatioMode.label}',
          ),

          _Divider(),

          // ── Grid ───────────────────────────────────────────────────────────
          _QuickToggle(
            icon: Icons.grid_3x3_rounded,
            label: settings.showGridLines ? 'On' : 'Off',
            isActive: settings.showGridLines,
            onTap: () => settingsNotifier.toggleGridLines(),
            tooltip: 'Grid: ${settings.showGridLines ? 'On' : 'Off'}',
          ),

          _Divider(),

          // ── Crosshair ──────────────────────────────────────────────────────
          _QuickToggle(
            icon: Icons.add,
            label: settings.showCrosshair ? 'On' : 'Off',
            isActive: settings.showCrosshair,
            onTap: () => settingsNotifier.toggleCrosshair(),
            tooltip: 'Crosshair: ${settings.showCrosshair ? 'On' : 'Off'}',
          ),
        ],
      ),
    );
  }

  IconData _flashIcon(FlashMode mode) {
    return switch (mode) {
      FlashMode.always => Icons.flash_on,
      FlashMode.auto => Icons.flash_auto,
      FlashMode.off || _ => Icons.flash_off,
    };
  }

  String _flashLabel(FlashMode mode) {
    return switch (mode) {
      FlashMode.always => 'On',
      FlashMode.auto => 'Auto',
      FlashMode.off || _ => 'Off',
    };
  }
}

/// Thin vertical separator between quick-menu items.
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 20,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

/// Single icon + label toggle button in the quick menu.
class _QuickToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _QuickToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.white54,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
