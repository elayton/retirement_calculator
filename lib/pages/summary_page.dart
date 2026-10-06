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

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key, this.portfolio});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The total across all accounts.
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
                  const TextSpan(text: '  \u00B7  Total: '),
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
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
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
                    _cell(_bold('Type')),
                    _cell(_right(_bold('Balance'))),
                    _cell(_bold('Updated')),
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
                      _cell(Text(a.type.label)),
                      _cell(_right(Text(_currency.format(a.balance)))),
                      _cell(Text(a.updated.toString().split(' ').first)),
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
