import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_assess/core/widgets/budget_arc_meter.dart';

void main() {
  testWidgets('BudgetArcMeter shows percentage and amounts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetArcMeter(
            ratio: 0.65,
            spent: 650,
            limit: 1000,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('65%'), findsOneWidget);
    expect(find.text('\$650 / \$1000'), findsOneWidget);
  });
}
