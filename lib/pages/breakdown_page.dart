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

class BreakdownPage extends StatefulWidget {
  const BreakdownPage({super.key, this.portfolio});

  final Portfolio? portfolio;

  @override
  State<BreakdownPage> createState() => _BreakdownPageState();
}

class _BreakdownPageState extends State<BreakdownPage> {
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

  Widget _headerCell(String title, int column) {
    final active = _sortColumn == column;
    return _cell(
      InkWell(
        onTap: () => _onSort(column),
        child: _right(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
          ),
        ),
      ),
    );
  }

  Widget _nameHeader() {
    final active = _sortColumn == 0;
    return _cell(
      InkWell(
        onTap: () => _onSort(0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bold('Account Name'),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
            ],
          ],
        ),
      ),
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

    // The distinct account types present in the portfolio, in enum order.
    final types = PortfolioAccountType.values
        .where((t) => portfolio.accounts.any((a) => a.type == t))
        .toList();

    final accounts = [...portfolio.accounts];
    if (_sortColumn != null) {
      accounts.sort((a, b) {
        int c;
        if (_sortColumn == 0) {
          c = a.name.compareTo(b.name);
        } else {
          final t = types[_sortColumn! - 1];
          final av = a.type == t ? a.balance : 0.0;
          final bv = b.type == t ? b.balance : 0.0;
          c = av.compareTo(bv);
        }
        return _ascending ? c : -c;
      });
    }

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
                    _nameHeader(),
                    for (final (i, t) in types.indexed)
                      _headerCell(t.label, i + 1),
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
