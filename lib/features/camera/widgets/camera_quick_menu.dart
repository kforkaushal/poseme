import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/camera_state.dart';
import '../providers/camera_provider.dart';
import '../providers/overlay_provider.dart';

/// Provider retained for API compatibility — callers call show()/keepAlive()
/// but the menu is now always visible (no auto-hide).
final quickMenuVisibilityProvider =
    StateNotifierProvider<QuickMenuVisibilityNotifier, bool>((ref) {
  return QuickMenuVisibilityNotifier();
});

class QuickMenuVisibilityNotifier extends StateNotifier<bool> {
  QuickMenuVisibilityNotifier() : super(true);

  /// No-op: kept so callers do not need to change.
  void show() {}

  /// No-op: kept so callers do not need to change.
  void keepAlive() {}
}

/// Slim horizontal strip of quick-access camera toggles, positioned directly
/// below the top bar. Overlays the viewfinder — does NOT affect preview layout.
///
/// Left to right: Overlay Style → Flash → Ratio → Grid → Crosshair.
/// Auto-hides after 2 seconds of idle like the opacity slider.
class CameraQuickMenu extends ConsumerWidget {
  const CameraQuickMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);
    final settings = ref.watch(settingsProvider);
    final overlayState = ref.watch(overlayProvider);
    final cameraNotifier = ref.read(cameraProvider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final overlayNotifier = ref.read(overlayProvider.notifier);

    // Always-visible container — no AnimatedOpacity/IgnorePointer wrapping.
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
          // ── Overlay Style ──────────────────────────────────────────────────
          _OverlayStyleToggle(
            mode: overlayState.overlayMode,
            isProcessing: overlayState.isProcessingSketch,
            enabled: overlayState.selectedPose != null,
            onTap: () {
              overlayNotifier.cycleOverlayMode();
            },
          ),

          _Divider(),

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

/// Overlay Style toggle — shows Photo or Sketch, with a loading spinner
/// while generation is in progress. Greyed out when no pose is selected.
class _OverlayStyleToggle extends StatelessWidget {
  final OverlayMode mode;
  final bool isProcessing;
  final bool enabled;
  final VoidCallback onTap;

  const _OverlayStyleToggle({
    required this.mode,
    required this.isProcessing,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (mode == OverlayMode.sketch ? Colors.white : Colors.white54)
        : Colors.white24;

    return Expanded(
      child: Tooltip(
        message: enabled
            ? 'Overlay: ${mode == OverlayMode.sketch ? 'Sketch' : 'Photo'}'
            : 'Select a pose to switch overlay style',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: isProcessing
                    ? CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: color,
                      )
                    : Icon(
                        mode == OverlayMode.sketch
                            ? Icons.draw_outlined
                            : Icons.image_outlined,
                        size: 16,
                        color: color,
                      ),
              ),
              const SizedBox(height: 1),
              Text(
                mode == OverlayMode.sketch ? 'Sketch' : 'Photo',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
