import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow/main.dart';

void main() {
  testWidgets('EventFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EventFlowApp());
    expect(find.byType(EventFlowApp), findsOneWidget);
  });
}
