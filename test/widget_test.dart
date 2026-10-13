import 'package:flutter_test/flutter_test.dart';
import 'package:kolkatafish/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KolkataFishApp());
    expect(find.text('KolkataFish'), findsWidgets);
  });
}
