import 'package:flutter_test/flutter_test.dart';
import 'package:logefacile/main.dart';

void main() {
  testWidgets('LogeFacile démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const LogeFacile());
    expect(find.text('LogeFacile'), findsOneWidget);
  });
}
