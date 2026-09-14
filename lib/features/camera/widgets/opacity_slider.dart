import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../providers/overlay_provider.dart';

final opacitySliderVisibilityProvider =
    StateNotifierProvider<OpacitySliderVisibilityNotifier, bool>((ref) {
  return OpacitySliderVisibilityNotifier();
});

class OpacitySliderVisibilityNotifier extends StateNotifier<bool> {
  Timer? _idleTimer;

  OpacitySliderVisibilityNotifier() : super(true) {
    _startIdleTimer();
  }

  void show() {
    state = true;
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 2), () {
      state = false;
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}

class OpacitySlider extends ConsumerWidget {
  const OpacitySlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(overlayProvider);
    final isVisible = ref.watch(opacitySliderVisibilityProvider);
    final hasPose = overlayState.selectedPose != null;

    if (!hasPose || !overlayState.isControlsVisible) {
      return const SizedBox.shrink();
    }

    final percentage = (overlayState.opacity * 100).round();
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;

    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: duration,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.controlSurface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.opacity,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: overlayState.opacity,
                    min: 0.05,
                    max: 1.0,
                    onChanged: (val) {
                      ref
                          .read(opacitySliderVisibilityProvider.notifier)
                          .show();
                      ref.read(overlayProvider.notifier).setOpacity(val);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$percentage%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
