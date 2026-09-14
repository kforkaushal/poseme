import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poseme/app/app.dart';

void main() {
  testWidgets('Pose Me! app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PoseMeApp(),
      ),
    );

    // Initial frame pumps cleanly without throwing exceptions
    expect(find.byType(PoseMeApp), findsOneWidget);
  });
}
