import 'package:flutter_test/flutter_test.dart';
import 'package:crush_the_fq/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CrushTheFQApp());
    expect(find.text('启动失败'), findsNothing);
  });
}
