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

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key, this.portfolio});

  final Portfolio? portfolio;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  int? _sortColumn;
  bool _ascending = true;

  void _onSort(int column) {
    setState(() {
      if (_sortColumn == column) {
        _ascending = !_ascending;
      } else {
        _sortColumn = column;
        _ascending = true;
      }
    });
  }

  int _compare(PortfolioAccount a, PortfolioAccount b, int column) {
    switch (column) {
      case 0:
        return a.name.compareTo(b.name);
      case 1:
        return a.type.label.compareTo(b.type.label);
      case 2:
        return a.balance.compareTo(b.balance);
      case 3:
        return a.updated.compareTo(b.updated);
      default:
        return 0;
    }
  }

  Widget _headerCell(String title, int column, {bool right = false}) {
    final active = _sortColumn == column;
    final label = Row(
      mainAxisAlignment: right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _bold(title)),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            _ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
          ),
        ],
      ],
    );
    return _cell(
      InkWell(onTap: () => _onSort(column), child: right ? _right(label) : label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.portfolio;
    if (portfolio == null) {
      return const Center(child: Text('No portfolio loaded.'));
    }

    final total = portfolio.accounts.fold<double>(
      0,
      (sum, a) => sum + a.balance,
    );

    final accounts = [...portfolio.accounts];
    if (_sortColumn != null) {
      accounts.sort((a, b) {
        final c = _compare(a, b, _sortColumn!);
        return _ascending ? c : -c;
      });
    }

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
                    _headerCell('Account Name', 0),
                    _headerCell('Type', 1),
                    _headerCell('Balance', 2, right: true),
                    _headerCell('Updated', 3),
                  ],
                ),
                // One row per account.
                for (final (i, a) in accounts.indexed)
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
