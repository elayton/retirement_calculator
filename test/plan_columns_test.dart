import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';
import 'package:retirement_calculator/pages/plan_page.dart';
import 'package:retirement_calculator/widgets/balance_tooltip.dart';

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

void main() {
  testWidgets('the tax columns follow HSA in the header', (tester) async {
    tester.view.physicalSize = const Size(2600, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlanPage(portfolio: _portfolio)),
      ),
    );
    await tester.pumpAndSettle();

    // Read the header left to right, and compare against the whole sequence,
    // so a column landing in the wrong place fails here rather than passing on
    // a pair of neighbouring labels.
    final labels = ['Age', for (final column in PlanColumn.values) column.label];
    // Scoped to the table, since the sidebar labels some of the same columns.
    final table = find.byType(Table).first;
    final centres = {for (final label in labels) label: tester.getCenter(find.descendant(of: table, matching: find.text(label))).dx};
    final actual = centres.keys.toList()..sort((a, b) => centres[a]!.compareTo(centres[b]!));

    expect(actual, labels);

    // The two new columns sit at the end, in the order the plan reads in.
    expect(labels.sublist(labels.length - 2), ['Tax Bracket', 'Tax']);
  });

  testWidgets('the tax columns show a rate and an amount rather than a breakdown', (tester) async {
    tester.view.physicalSize = const Size(2600, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PlanPage(portfolio: _portfolio)),
      ),
    );
    await tester.pumpAndSettle();

    // A rate and a currency figure, so the two columns are populated at all.
    expect(find.textContaining(RegExp(r'^\d+%$')), findsWidgets);
    expect(find.textContaining(RegExp(r'^\$[\d,]+$')), findsWidgets);

    // Neither is a running balance, so neither opens a breakdown on hover:
    // one tooltip per balance column per row, and none for the tax columns.
    final tooltips = tester.widgetList<BalanceTooltip>(find.byType(BalanceTooltip)).length;
    final rows = tester.widgetList<Table>(find.byType(Table)).first.children.length - 1; // less the header
    expect(tooltips, rows * (PlanColumn.values.length - 2));
  });
}
