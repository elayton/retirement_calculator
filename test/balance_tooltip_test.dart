import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:retirement_calculator/main.dart';
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

      // Deep end of the ramps, for the light tinted panel the light theme gives.
      expect(colorOf(r'+$250'), Colors.green.shade900);
      expect(colorOf(r'-$100'), Colors.red.shade900);
    });

    testWidgets('the adjustment colours step to the pale end on a dark tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(child: BalanceTooltip(balance: balanceWith(initial: 0, adjustments: [('Budget', 250), ('Growth', -100)]))),
          ),
        ),
      );
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      Color colorOf(String amount) => tester.widget<Text>(find.descendant(of: breakdown, matching: find.text(amount))).style!.color!;

      // The deep steps that read on a light panel would be lost on a dark one.
      expect(colorOf(r'+$250'), Colors.green.shade200);
      expect(colorOf(r'-$100'), Colors.red.shade200);
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

    testWidgets('the lines are evenly spaced and set off from the total', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 1000, adjustments: [('Budget', 250), ('Growth', -100), ('Fees', 25)])));
      await hover(tester, find.byType(BalanceTooltip));

      // Measured on the lines themselves rather than on their text: a text box
      // carries leading above and below the glyphs, which would swamp the gap.
      final rows = <Rect>[];
      for (final line in ['Initial', 'Budget', 'Growth', 'Fees', 'Total']) {
        rows.add(tester.getRect(find.ancestor(of: find.descendant(of: find.byType(IntrinsicWidth), matching: find.text(line)), matching: find.byType(Row))));
      }

      double gapBetween(int i) => rows[i + 1].top - rows[i].bottom;

      // The entries are evenly spaced, where before they were flush and read as
      // one block of text.
      final entryGaps = {gapBetween(0), gapBetween(1), gapBetween(2)};
      expect(entryGaps, hasLength(1), reason: 'the lines are unevenly spaced: $entryGaps');
      expect(entryGaps.single, greaterThan(0));

      // The total stands apart from the entries that add up to it.
      expect(gapBetween(3), greaterThan(entryGaps.single),
          reason: 'the total is not set off from the lines above it');
    });

    testWidgets('the tooltip is padded evenly top and bottom', (tester) async {
      // The padding is the app theme's, so the app has to be the one supplying
      // it; the plain test app below has no tooltip theme of its own. Room for
      // its tab strip, which overflows on the default test surface.
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());
      final tooltipTheme = Theme.of(tester.element(find.byType(Scaffold).first)).tooltipTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(tooltipTheme: tooltipTheme),
          home: Scaffold(body: Center(child: BalanceTooltip(balance: balanceWith(initial: 1000, adjustments: [('Budget', 250)])))),
        ),
      );
      await hover(tester, find.byType(BalanceTooltip));

      final panel = tester.getRect(find.byType(DecoratedBox));
      final body = tester.getRect(find.byType(IntrinsicWidth));

      // The default tooltip padding sits a pixel tighter at one end than the
      // other, which reads as the panel being off-centre on its contents.
      expect((body.top - panel.top).round(), (panel.bottom - body.bottom).round());
    });

    testWidgets('a total-only tooltip is padded evenly top and bottom', (tester) async {
      // The padding is the app theme's, so the app has to be the one supplying
      // it; the plain test app below has no tooltip theme of its own. Room for
      // its tab strip, which overflows on the default test surface.
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());
      final tooltipTheme = Theme.of(tester.element(find.byType(Scaffold).first)).tooltipTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(tooltipTheme: tooltipTheme),
          home: Scaffold(body: Center(child: BalanceTooltip(balance: balanceWith(initial: 0)))),
        ),
      );
      await hover(tester, find.byType(BalanceTooltip));

      final panel = tester.getRect(find.byType(DecoratedBox));
      final body = tester.getRect(find.byType(IntrinsicWidth));
      final total = tester.getRect(
        find.ancestor(of: find.descendant(of: find.byType(IntrinsicWidth), matching: find.text('Total')), matching: find.byType(Row)),
      );

      // Measured on the line itself rather than on the tooltip's contents: the
      // body is the padding plus the line, so it comes out even whatever the
      // line sits inside it, which is not what the eye reads.
      expect((total.top - panel.top).round(), (panel.bottom - total.bottom).round());

      // And the whole of it is inside the panel, where the theme's padding
      // holds it clear of the border.
      expect(body.top, greaterThanOrEqualTo(panel.top));
      expect(body.bottom, lessThanOrEqualTo(panel.bottom));
    });

    testWidgets('the tooltip clears the cell far enough to move the cursor onto', (tester) async {
      tester.view.physicalSize = const Size(1500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MainApp());
      final tooltipTheme = Theme.of(tester.element(find.byType(Scaffold).first)).tooltipTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(tooltipTheme: tooltipTheme),
          home: Scaffold(body: Center(child: BalanceTooltip(balance: balanceWith(initial: 1000, adjustments: [('Budget', 250)])))),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);

      await gesture.moveTo(tester.getCenter(find.byType(BalanceTooltip)));
      await tester.pumpAndSettle();
      expect(find.byType(IntrinsicWidth), findsOneWidget, reason: 'the tooltip did not open on hover');

      final cell = tester.getRect(find.byType(BalanceTooltip));
      final panel = tester.getRect(find.byType(DecoratedBox));

      // Clear air under the cell, so the crossing is a move rather than a jump.
      // Flutter's own default is 24, which is near enough to skim.
      expect(panel.top - cell.bottom, greaterThan(24));

      // And the crossing lands somewhere that keeps the tooltip open. Reading
      // the breakdown should not mean holding the pointer inside the cell,
      // which is what closing on exit would force.
      await gesture.moveTo(Offset(panel.center.dx, panel.top + 1));
      await tester.pumpAndSettle();
      expect(find.byType(IntrinsicWidth), findsOneWidget, reason: 'the tooltip closed as the cursor left the cell');

      // Clear of the panel too, so the assertion above is about holding the
      // pointer and not about the tooltip having simply stuck open.
      await gesture.moveTo(Offset(panel.left - 200, panel.center.dy));
      await tester.pumpAndSettle();
      expect(find.byType(IntrinsicWidth), findsNothing, reason: 'the tooltip outlived the cursor entirely');
    });

    testWidgets('a balance starting at zero leaves the initial line out', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 0, adjustments: [('Budget', 250), ('Growth', -100)])));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      // Nothing was ever there to account for, so the line is dropped.
      expect(find.descendant(of: breakdown, matching: find.text('Initial')), findsNothing);
      expect(find.descendant(of: breakdown, matching: find.text(r'$0')), findsNothing);
      // The rest of the breakdown is untouched: the tooltip still starts at the
      // first real amount rather than at nothing.
      expect(find.descendant(of: breakdown, matching: find.text('Budget')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text('Growth')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text('Total')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'$150')), findsOneWidget);
    });

    testWidgets('a balance of nothing at all shows only the total', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 0)));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      expect(find.descendant(of: breakdown, matching: find.text('Initial')), findsNothing);
      expect(find.descendant(of: breakdown, matching: find.text('Total')), findsOneWidget);
      expect(find.descendant(of: breakdown, matching: find.text(r'$0')), findsOneWidget);
    });

    testWidgets('amounts still line up on the right without the initial line', (tester) async {
      await tester.pumpWidget(app(balanceWith(initial: 0, adjustments: [('Budget', 250), ('Growth', -100)])));
      await hover(tester, find.byType(BalanceTooltip));

      final breakdown = find.byType(IntrinsicWidth);
      final rights = <double>{};
      for (final amount in [r'+$250', r'-$100', r'$150']) {
        final box = tester.renderObject<RenderBox>(find.descendant(of: breakdown, matching: find.text(amount)));
        rights.add(box.localToGlobal(Offset.zero).dx + box.size.width);
      }

      expect(rights, hasLength(1), reason: 'amounts do not share a right edge: $rights');
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
      // Wide enough that the balance columns keep a comfortable width now the
      // table carries the two tax columns as well.
      tester.view.physicalSize = const Size(1900, 700);
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
