import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/app/main_navigation_screen.dart';

void main() {
  testWidgets('Back button navigates from Camera to Home before exiting',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final element = tester.element(find.byType(MainNavigationScreen));
    final container = ProviderScope.containerOf(element);
    expect(container.read(navigationIndexProvider), 0);

    // Switch to Camera (tab 1)
    container.read(navigationIndexProvider.notifier).state = 1;
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(navigationIndexProvider), 1);

    // Trigger Android back button via PopScope / Navigator
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump(const Duration(milliseconds: 100));

    // Should return to Home (index 0)
    expect(container.read(navigationIndexProvider), 0);
  });

  testWidgets('Back button navigates from Gallery to Home before exiting',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final element = tester.element(find.byType(MainNavigationScreen));
    final container = ProviderScope.containerOf(element);

    // Switch to Gallery (tab 2)
    container.read(navigationIndexProvider.notifier).state = 2;
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(navigationIndexProvider), 2);

    // Trigger Android back button
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pump(const Duration(milliseconds: 100));

    // Should return to Home (index 0)
    expect(container.read(navigationIndexProvider), 0);
  });

  testWidgets(
      'Back track navigates full stack Home -> Gallery -> Camera -> Gallery -> Home',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final element = tester.element(find.byType(MainNavigationScreen));
    final container = ProviderScope.containerOf(element);

    // Go to Gallery (2)
    container.read(navigationIndexProvider.notifier).state = 2;
    await tester.pump(const Duration(milliseconds: 100));

    // Go to Camera (1)
    container.read(navigationIndexProvider.notifier).state = 1;
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(navigationIndexProvider), 1);

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));

    // First back: Camera -> Gallery
    await widgetsAppState.didPopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(navigationIndexProvider), 2);

    // Second back: Gallery -> Home
    await widgetsAppState.didPopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(navigationIndexProvider), 0);
  });
}
