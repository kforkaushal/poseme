import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/camera/camera_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/home/home_screen.dart';
import 'theme.dart';

/// Global provider controlling the active bottom navigation tab.
/// 0: Home (Pose Grid)
/// 1: Camera (Viewfinder)
/// 2: Gallery (Captured Photos)
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final List<int> _history = [0];

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(navigationIndexProvider);
    if (initialIndex != 0) {
      _history.add(initialIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    // Keep history stack synced with navigationIndexProvider changes
    ref.listen<int>(navigationIndexProvider, (previous, next) {
      if (_history.isEmpty || _history.last != next) {
        _history.remove(next);
        _history.add(next);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF0D0E11) : const Color(0xFFF7F7F8);
    final borderColor =
        isDark ? AppTheme.darkBorderHairline : AppTheme.lightBorderHairline;
    final selectedColor = isDark ? Colors.white : Colors.black;
    final unselectedColor = isDark ? Colors.white38 : Colors.black38;

    final canPop = _history.length <= 1 && selectedIndex == 0;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            final target = _history.last;
            ref.read(navigationIndexProvider.notifier).state = target;
          });
        } else if (selectedIndex != 0) {
          setState(() {
            _history
              ..clear()
              ..add(0);
            ref.read(navigationIndexProvider.notifier).state = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IndexedStack(
          index: selectedIndex,
          children: const [
            HomeScreen(),
            CameraScreen(),
            GalleryScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () =>
                        ref.read(navigationIndexProvider.notifier).state = 0,
                  ),
                  _NavItem(
                    icon: Icons.camera_alt_outlined,
                    activeIcon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    isSelected: selectedIndex == 1,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () =>
                        ref.read(navigationIndexProvider.notifier).state = 1,
                  ),
                  _NavItem(
                    icon: Icons.photo_library_outlined,
                    activeIcon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    isSelected: selectedIndex == 2,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () =>
                        ref.read(navigationIndexProvider.notifier).state = 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected && activeIcon != null ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
