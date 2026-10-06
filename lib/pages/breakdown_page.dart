import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/portfolio.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

Padding _cell(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  child: child,
);

Text _bold(String text) => Text(
  text,
  style: const TextStyle(fontWeight: FontWeight.bold),
);

Align _right(Widget child) => Align(
  alignment: Alignment.centerRight,
  child: child,
);

class BreakdownPage extends StatelessWidget {
  const BreakdownPage({super.key, this.portfolio});

  final Portfolio? portfolio;

  @override
  Widget build(BuildContext context) {
    final portfolio = this.portfolio;
    if (portfolio == null) {
      return const Center(child: Text('No portfolio loaded.'));
    }

    final total = portfolio.accounts.fold<double>(
      0,
      (sum, a) => sum + a.balance,
    );

    // The distinct account types present in the portfolio, in enum order.
    final types = PortfolioAccountType.values
        .where((t) => portfolio.accounts.any((a) => a.type == t))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Portfolio: '),
                  TextSpan(
                    text: portfolio.type.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: '  ·  Total: '),
                  TextSpan(
                    text: _currency.format(total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              columnWidths: {
                0: const FlexColumnWidth(2),
                for (var i = 1; i <= types.length; i++) i: const FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  children: [
                    _cell(_bold('Name')),
                    for (final t in types) _cell(_right(_bold(t.label))),
                  ],
                ),
                // One row per account.
                for (final (i, a) in portfolio.accounts.indexed)
                  TableRow(
                    decoration: BoxDecoration(
                      color: i.isOdd
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : null,
                    ),
                    children: [
                      _cell(Text(a.name)),
                      for (final t in types)
                        _cell(
                          _right(
                            Text(
                              a.type == t
                                  ? _currency.format(a.balance)
                                  : '',
                            ),
                          ),
                        ),
                    ],
                  ),
                // Totals row for each type.
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        width: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  children: [
                    _cell(_bold('Total')),
                    for (final t in types)
                      _cell(
                        _right(
                          _bold(
                            _currency.format(
                              portfolio.accounts
                                  .where((a) => a.type == t)
                                  .fold<double>(0, (sum, a) => sum + a.balance),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
