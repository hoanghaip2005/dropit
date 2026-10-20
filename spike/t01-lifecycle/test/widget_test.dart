import 'package:flutter_test/flutter_test.dart';
import 'package:t01_lifecycle/main.dart';

void main() {
  testWidgets('Màn hình phiên có nút Bắt đầu', (tester) async {
    await tester.pumpWidget(const SpikeApp());
    expect(find.text('Bắt đầu'), findsOneWidget);
  });
}
