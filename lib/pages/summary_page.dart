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
          // The total across all accounts, then one row per account.
          Center(
            child: Text(
              'Portfolio: ${portfolio.type}  \u00B7  Total: ${_currency.format(total)}',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Table(
              border: const TableBorder(
                verticalInside: BorderSide(width: 1, color: Colors.grey),
              ),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.grey),
                    ),
                  ),
                  children: [
                    _cell(_bold('Name')),
                    _cell(_bold('Type')),
                    _cell(_right(_bold('Balance'))),
                    _cell(_bold('Updated')),
                  ],
                ),
                for (final a in portfolio.accounts)
                  TableRow(
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
