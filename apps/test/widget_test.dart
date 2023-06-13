import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncwave/app/app.dart';

void main() {
  testWidgets('renders onboarding screen on startup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SyncWaveApp()));

    expect(find.text('Welcome to SyncWave'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
