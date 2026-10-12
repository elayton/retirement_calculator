import 'package:flutter/material.dart';

import '../models/plan_models.dart';
import '../utils/formatting.dart';

/// Colours for the adjustment amounts. They are picked from the light end of
/// the Material ramps to stay legible on the tooltip's dark default background.
final _positiveColor = Colors.green.shade300;
final _negativeColor = Colors.red.shade300;

/// One currency cell of the plan table, with a tooltip that accounts for the
/// value: the balance it started from, every adjustment applied since, and the
/// total they add up to.
class BalanceTooltip extends StatelessWidget {
  const BalanceTooltip({super.key, required this.balance});

  final PlanBalance balance;

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

/// The tooltip's contents: the starting balance, one line per adjustment, and
/// the total. Amounts line up on the right so the column can be scanned.
class _BalanceBreakdown extends StatelessWidget {
  const _BalanceBreakdown({required this.balance});

  final PlanBalance balance;

  /// An amount as it appears in an adjustment line, signed so the direction is
  /// readable without relying on the colour alone.
  static String _signed(double amount) => '${amount >= 0 ? '+' : ''}${formatCurrency(amount)}';

  static Color _colorFor(double amount) => amount >= 0 ? _positiveColor : _negativeColor;

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
    return IntrinsicWidth(
      // Stretch gives every line the width of the widest one, which is what
      // lines the amounts up on the right.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _line('Initial', formatCurrency(balance.initial)),
          for (final (description, amount) in balance.adjustments) _line(description, _signed(amount), color: _colorFor(amount)),
          const SizedBox(height: 4),
          _line('Total', formatCurrency(balance.total), bold: true),
        ],
      ),
    );
  }
}
