import 'package:flutter/material.dart';

import '../models/plan_models.dart';
import '../utils/formatting.dart';

/// Colours for the adjustment amounts, stepped by the brightness in effect
/// because the tooltip's tinted background flips with it. The step is the one
/// that clears a 4.5 contrast ratio against the composited panel: the deep end
/// of the ramps on the light tint, the pale end on the dark one. Green and red
/// mark direction rather than carry it alone — the amount is signed, so the
/// colour is the second signal, not the only one.
Color _positiveColor(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade900;

Color _negativeColor(Brightness brightness) =>
    brightness == Brightness.dark ? Colors.red.shade200 : Colors.red.shade900;

/// One currency cell of the plan table, with a tooltip that accounts for the
/// value: the balance it started from, every adjustment applied since, and the
/// total they add up to.
class BalanceTooltip extends StatelessWidget {
  final PlanBalance balance;

  const BalanceTooltip({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      // The breakdown needs its own columns, so it rides along as a widget
      // inside the message rather than as styled text.
      richMessage: TextSpan(
        children: [WidgetSpan(child: _BalanceBreakdown(balance: balance))],
      ),
      // A tooltip only hears the pointer where its child is, so the child takes
      // the width it is offered. That makes the whole cell the hover target
      // rather than just the digits; offered unbounded, as when the widget
      // stands alone, it falls back to the amount's own width.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        // Flexible so a value wider than its column paints as it always has,
        // rather than tripping a flex overflow on the way past.
        children: [Flexible(child: Text(formatCurrency(balance.total)))],
      ),
    );
  }
}

/// Room between one line of the breakdown and the next. Without it the rows sit
/// flush, and a stack of flush rows reads as one block of text while the
/// tooltip's own padding around them looks generous by comparison.
const _lineGap = 4.0;

/// Extra room above the total, on top of [_lineGap]. The total is the result
/// the lines above it arrive at, so it is set apart from them rather than
/// reading as one more entry in the list.
const _summaryGap = 6.0;

/// The tooltip's contents: the starting balance, one line per adjustment, and
/// the total. Amounts line up on the right so the column can be scanned. A
/// balance that starts at zero leaves the first line out.
class _BalanceBreakdown extends StatelessWidget {
  final PlanBalance balance;

  const _BalanceBreakdown({required this.balance});

  /// An amount as it appears in an adjustment line, signed so the direction is
  /// readable without relying on the colour alone.
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

    final lines = <Widget>[
      // A balance can start from nothing, and a line reading "$0" says
      // nothing the adjustments below it do not already say. Dropped rather
      // than shown, so the tooltip starts at the first real amount.
      if (balance.initial != 0) _line('Initial', formatCurrency(balance.initial)),
      for (final (description, amount) in balance.adjustments)
        _line(description, _signed(amount), color: _colorFor(brightness, amount)),
    ];

    return IntrinsicWidth(
      // Stretch gives every line the width of the widest one, which is what
      // lines the amounts up on the right.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The gap rides on the bottom of each line rather than between them,
          // so a line that drops out takes its spacing with it and the rest of
          // the column does not shift.
          for (final line in lines)
            Padding(padding: const EdgeInsets.only(bottom: _lineGap), child: line),
          Padding(
            padding: const EdgeInsets.only(top: _summaryGap),
            child: _line('Total', formatCurrency(balance.total), bold: true),
          ),
        ],
      ),
    );
  }
}
