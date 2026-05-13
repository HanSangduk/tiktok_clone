import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Smoke test 1개. VideoPost 모델은 P02에서 추가되며,
// 모델별 단위 테스트는 모델 정의 후 점진적으로 추가한다.
void main() {
  testWidgets('Splash text renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('TikTok Clone')),
        ),
      ),
    );
    expect(find.text('TikTok Clone'), findsOneWidget);
  });
}
