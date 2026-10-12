import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';
import 'package:retirement_calculator/pages/plan_page.dart';
import 'package:retirement_calculator/widgets/balance_tooltip.dart';

/// A portfolio with an account in most columns, so the table has cells to hover.
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

/// Moves a mouse pointer onto [finder], which is what reveals a tooltip.
Future<void> hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
}

PlanBalance balanceWith({double initial = 0, List<(String, double)> adjustments = const []}) {
  final balance = PlanBalance(initial: initial);
  for (final (description, amount) in adjustments) {
    balance.add(description, amount);
  }
  return balance;
}

Widget app(PlanBalance balance) => MaterialApp(
  home: Scaffold(
    body: Center(child: BalanceTooltip(balance: balance)),
  ),
);

void main() {
  group('BalanceTooltip', () {
    testWidgets('the cell shows the total', (tester) async {
      final balance = balanceWith(initial: 1000, adjustments: [('', 250), ('', -100)]);
      await tester.pumpWidget(app(balance));

      expect(balance.total, 1150);
      expect(find.text(r'$1,150'), findsOneWidget);
    });

    testWidgets('hovering lists the initial value, every adjustment and the total', (tester) async {
      final balance = balanceWith(initial: 1000, adjustments: [('Budget', 250), ('Growth', -100), ('Fees', 25)]);
      await tester.pumpWidget(app(balance));

      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      expect(breakdown, findsOneWidget, reason: 'the tooltip did not open on hover');

      expect(find.descendant(of: breakdown, matching: find.text('Initial')), findsOneWidget);
      for (final description in ['Budget', 'Growth', 'Fees']) {
        expect(
          find.descendant(of: breakdown, matching: find.text(description)),
          findsOneWidget,
          reason: '"$description" is missing',
        );
      }
      expect(find.descendant(of: breakdown, matching: find.text('Total')), findsOneWidget);

      // The starting balance and the total are plain currency; adjustments
      // carry an explicit sign.
      expect(find.descendant(of: breakdown, matching: find.text(r'$1,000')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'+$250')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'-$100')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'+$25')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'$1,175')), findsOneWidget);
    });

    testWidgets('adjustments are green when positive and red when negative', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 0, adjustments: [('Budget', 250), ('Growth', -100)])));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      Color colorOf(String amount) => tester.widget<Text>(find.descendant(of: breakdown, matching: find.text(amount))).style!.color!;

      expect(colorOf(r'+$250'), Colors.green.shade300);
      expect(colorOf(r'-$100'), Colors.red.shade300);
    });

    testWidgets('the total is bold', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 1000, adjustments: [('', 250)])));
      await hover(tester, find.byType(BalanceTooltip));

      final total = tester.widget<Text>(find.descendant(of: find.byType(IntrinsicWidth), matching: find.text('Total')));
      expect(total.style?.fontWeight, FontWeight.bold);

      // The starting balance is context, not a result, so it stays unbolded.
      final initial = tester.widget<Text>(find.descendant(of: find.byType(IntrinsicWidth), matching: find.text('Initial')));
      expect(initial.style?.fontWeight, isNull);
    });

    testWidgets('amounts line up on the right', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 1000, adjustments: [('Budget', 250), ('Growth', -100)])));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      final rights = <double>{};
      for (final amount in [r'$1,000', r'+$250', r'-$100', r'$1,150']) {
        final box = tester.renderObject<RenderBox>(find.descendant(of: breakdown, matching: find.text(amount)));
        rights.add(box.localToGlobal(Offset.zero).dx + box.size.width);
      }

      expect(rights, hasLength(1), reason: 'amounts do not share a right edge: $rights');
    });

    testWidgets('a balance with no adjustments still breaks down', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 4200)));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      expect(find.descendant(of: breakdown, matching: find.text('Initial')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text('Total')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'$4,200')), findsNWidgets(2));
    });

    testWidgets('the whole cell is a hover target, not just the amount', (tester) async {
      // Offered a loose width, as a table row offers one: a child that does not
      // ask to fill stays the width of its own text, which is the bug.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BalanceTooltip(balance: balanceWith(initial: 1000)),
              ),
            ),
          ),
        ),
      );

      final cell = tester.getRect(find.byType(BalanceTooltip));
      expect(cell.width, closeTo(300, 0.01), reason: 'the hover target shrank to the width of the digits');

      // A pointer anywhere across the cell opens the tooltip, including at the
      // left edge, well clear of the right-aligned amount.
      for (final dx in [4.0, cell.width / 2, cell.width - 4]) {
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(Offset(cell.left + dx, cell.center.dy));
        await tester.pumpAndSettle();
        expect(find.byType(IntrinsicWidth), findsOneWidget, reason: 'no tooltip at x=${dx.toStringAsFixed(0)}');
        await gesture.removePointer();
      }
    });

    testWidgets('the plan table hovers from the left edge of a cell', (tester) async {
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlanPage(portfolio: _portfolio)),
        ),
      );
      await tester.pumpAndSettle();

      final cell = tester.getRect(find.byType(BalanceTooltip).first);
      // Far wider than the digits it paints.
      expect(cell.width, greaterThan(100));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(Offset(cell.left + 6, cell.center.dy));
      await tester.pumpAndSettle();

      expect(find.byType(IntrinsicWidth), findsOneWidget, reason: 'the left of the cell is not a hover target');
    });

    testWidgets('the amount stays right-aligned in a wide cell', (tester) async {
      // The alignment is offered a loose width, as a table row does.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BalanceTooltip(balance: balanceWith(initial: 1000)),
              ),
            ),
          ),
        ),
      );

      final cell = tester.getRect(find.byType(BalanceTooltip));
      final amount = tester.getRect(find.text(r'$1,000'));
      expect(amount.right, closeTo(cell.right, 0.01));
    });
  });
}
