import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/models/portfolio_models.dart';
import 'package:retirement_calculator/pages/plan_page.dart';

final _portfolio = Portfolio(
  type: 'Fidelity Full View',
  exportedDate: DateTime(2026, 10, 1),
  accounts: [
    for (final (type, balance) in const [
      (PortfolioAccountType.cash, 12000.0),
      (PortfolioAccountType.brokerage, 250000.0),
      (PortfolioAccountType.fourOhOneK, 800000.0),
      (PortfolioAccountType.traditionalIra, 400000.0),
    ])
      PortfolioAccount(type: type, name: 'x', institution: 'y', balance: balance, updated: DateTime(2026, 10, 1)),
  ],
);

/// Pumps the plan page at a window [width] wide, and returns the height of the
/// "Age" header alongside a header known to be on one line.
Future<(double age, double single)> headerHeights(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: PlanPage(portfolio: _portfolio)),
    ),
  );
  await tester.pumpAndSettle();

  final table = find.byType(Table).first;
  return (
    tester.getSize(find.descendant(of: table, matching: find.text('Age'))).height,
    tester.getSize(find.descendant(of: table, matching: find.text('HSA'))).height,
  );
}

void main() {
  testWidgets('the Age header stays on one line across window widths', (tester) async {
    // A wrapped header is taller than one beside it that fits, so a taller "Age"
    // means it wrapped.
    for (final width in [1000.0, 1200.0, 1600.0, 2200.0]) {
      final (age, single) = await headerHeights(tester, width);

      expect(
        age,
        lessThanOrEqualTo(single),
        reason:
            'the Age header wrapped at a ${width.toStringAsFixed(0)}px window '
            '($age tall against $single for a header that fits)',
      );
    }
  });

  testWidgets('the age column stays narrower than a currency column', (tester) async {
    tester.view.physicalSize = const Size(2200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlanPage(portfolio: _portfolio)),
      ),
    );
    await tester.pumpAndSettle();

    final table = find.byType(Table).first;
    double widthOf(String label) => tester.getSize(find.descendant(of: table, matching: find.text(label)).first).width;

    // It sizes to "Age" rather than sharing the table out.
    expect(widthOf('Age'), lessThan(widthOf('Brokerage')));
  });
}
