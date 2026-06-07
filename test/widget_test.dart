import 'package:flutter_test/flutter_test.dart';

import 'package:crush_the_fq/main.dart';

void main() {
  testWidgets('App launches with loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CrushTheFQApp());

    // 验证加载画面显示开始按钮
    expect(find.text('开始游戏'), findsOneWidget);
    expect(find.text('3D 手势找不同'), findsOneWidget);
  });
}
