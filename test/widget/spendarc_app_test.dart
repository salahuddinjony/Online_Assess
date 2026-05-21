import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_assess/core/widgets/spending_line_chart.dart';

void main() {
  testWidgets('SpendingLineChart renders day labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendingLineChart(
            values: const [10, 20, 5, 30, 12, 8, 15],
          ),
        ),
      ),
    );

    expect(find.text('M'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
