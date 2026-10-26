import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dropit/core/widgets/cosmetic_effect.dart';

Widget sample({bool reduce = false, bool ticker = true}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: TickerMode(enabled: ticker, child: const Directionality(
    textDirection: TextDirection.ltr,
    child: CosmeticEffect(color: Colors.amber, circular: true,
      child: SizedBox(width: 100, height: 100)),
  )),
);

void main() {
  testWidgets('Reduced motion and inactive routes schedule no animation', (tester) async {
    await tester.pumpWidget(sample(reduce: true));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(sample(ticker: false));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Effect can complete and dispose its pending restart', (tester) async {
    await tester.pumpWidget(sample());
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
