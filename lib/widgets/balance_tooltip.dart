import 'package:flutter/material.dart';

import '../models/plan_models.dart';
import '../utils/formatting.dart';

/// Adjustment colours, stepped by brightness because the tooltip's tinted
/// background flips with it. Green and red mark direction rather than carry it
/// alone: the amount is signed, so the colour is the second signal.
Color _positiveColor(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900;

Color _negativeColor(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.red.shade200 : Colors.red.shade900;

/// Gap between a cell and the tooltip it opens. The pointer has to reach the
/// tooltip before it leaves the cell, and the panel holds it once it is over
/// there, so a wider gap than Flutter's default of 24 costs nothing.
const _tooltipGap = 36.0;

/// One currency cell of the plan table, with a tooltip that accounts for the
/// value: the balance it started from, every adjustment applied since, and the
/// total they add up to.
class BalanceTooltip extends StatelessWidget {
  final PlanBalance balance;

  const BalanceTooltip({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      verticalOffset: _tooltipGap,
      // The breakdown has its own columns, so it rides along as a widget.
      richMessage: TextSpan(
        children: [WidgetSpan(child: _BalanceBreakdown(balance: balance))],
      ),
      // The child takes the width it is offered, which makes the whole cell the
      // hover target; offered unbounded, it falls back to the amount's width.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        // Flexible so a value wider than its column paints as it always has,
        // rather than tripping a flex overflow on the way past.
        children: [Flexible(child: Text(formatCurrency(balance.total)))],
      ),
    );
  }
}

/// Room between one line of the breakdown and the next.
const _lineGap = 4.0;

/// Extra room above the total, on top of [_lineGap], to set it apart from the
/// lines it adds up.
const _summaryGap = 6.0;

/// The tooltip's contents: the starting balance, one line per adjustment, and
/// the total. Amounts line up on the right so the column can be scanned.
class _BalanceBreakdown extends StatelessWidget {
  final PlanBalance balance;

  const _BalanceBreakdown({required this.balance});

  /// An amount as it appears in an adjustment line, signed so the direction is
  /// readable without relying on the colour.
  static String _signed(double amount) => '${amount >= 0 ? '+' : ''}${formatCurrency(amount)}';

  static Color _colorFor(Brightness brightness, double amount) =>
      amount >= 0 ? _positiveColor(brightness) : _negativeColor(brightness);

  Widget _line(String description, String amount, {Color? color, bool bold = false}) {
    // No colour set leaves the tooltip's own text colour, which is what the
    // starting balance and the total should use.
    final style = TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(description, style: style),
        const SizedBox(width: 16),
        const Spacer(),
        Text(amount, style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    final adjustmentLines = <Widget>[
      // A "$0" starting line says nothing the adjustments below it do not already.
      if (balance.initial != 0) _line('Initial', formatCurrency(balance.initial)),
      for (final (description, amount) in balance.adjustments)
        _line(description, _signed(amount), color: _colorFor(brightness, amount)),
    ];

    final noteLines = <Widget>[
      // Notes are context rather than a movement, so they take no colour and no sign.
      for (final (description, amount) in balance.notes)
        _line(description, amount == null ? '' : formatCurrency(amount)),
    ];

    return IntrinsicWidth(
      // Stretch gives every line the width of the widest one, which lines the
      // amounts up on the right.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The gap rides on the bottom of each line, so a line that drops out
          // takes its spacing with it and the rest of the column holds still.
          for (final line in adjustmentLines)
            Padding(padding: const EdgeInsets.only(bottom: _lineGap), child: line),
          Padding(
            // Left off when the total is the only line: carried anyway it would
            // push the lone line down inside the panel.
            padding: EdgeInsets.only(
              top: adjustmentLines.isEmpty ? 0 : _summaryGap,
              bottom: noteLines.isEmpty ? 0 : _lineGap,
            ),
            child: _line('Total', formatCurrency(balance.total), bold: true),
          ),
          // Notes follow the total, set apart from it the same way the total is
          // set apart from the adjustments above, and spaced like the adjustments.
          for (final (index, line) in noteLines.indexed)
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? _summaryGap : 0, bottom: _lineGap),
              child: line,
            ),
        ],
      ),
    );
  }
}
