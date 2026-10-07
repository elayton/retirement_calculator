import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../utils/formatting.dart';

/// Standard padding applied to every cell in portfolio tables.
Padding tableCell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );

Text boldText(String text) => Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

Align rightAlign(Widget child) => Align(
      alignment: Alignment.centerRight,
      child: child,
    );

class NoPortfolioLoaded extends StatelessWidget {
  const NoPortfolioLoaded({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No portfolio loaded.'));
  }
}

/// The "Portfolio: {type} · Total: {amount}" header line.
class PortfolioTypeAndTotal extends StatelessWidget {
  const PortfolioTypeAndTotal({super.key, required this.portfolio});

  final Portfolio portfolio;

  @override
  Widget build(BuildContext context) {
    final total = portfolio.accounts.fold<double>(
      0,
      (sum, a) => sum + a.balance,
    );
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Portfolio: '),
            TextSpan(
              text: portfolio.type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const TextSpan(text: '  ·  Total: '),
            TextSpan(
              text: appCurrency.format(total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Describes one column of a [SortableAccountsTable].
class AccountColumn {
  const AccountColumn({
    required this.title,
    required this.compare,
    required this.builder,
    this.right = false,
    this.flex = 1,
  });

  final String title;
  final bool right;
  final int flex;
  final Comparator<PortfolioAccount> compare;
  final Widget Function(PortfolioAccount account) builder;
}

/// A table of accounts whose columns can be sorted by tapping the header.
class SortableAccountsTable extends StatefulWidget {
  const SortableAccountsTable({
    super.key,
    required this.accounts,
    required this.columns,
    this.footerCells,
  });

  final List<PortfolioAccount> accounts;
  final List<AccountColumn> columns;

  /// Optional content widgets for a totals row rendered below the accounts.
  final List<Widget>? footerCells;

  @override
  State<SortableAccountsTable> createState() => _SortableAccountsTableState();
}

class _SortableAccountsTableState extends State<SortableAccountsTable> {
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

  Widget _headerCell(AccountColumn column, int index) {
    final active = _sortColumn == index;
    final label = Row(
      mainAxisAlignment:
          column.right ? MainAxisAlignment.end : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: boldText(column.title)),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            _ascending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
          ),
        ],
      ],
    );
    return tableCell(
      InkWell(
        onTap: () => _onSort(index),
        child: column.right ? rightAlign(label) : label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = [...widget.accounts];
    if (_sortColumn != null) {
      final column = widget.columns[_sortColumn!];
      accounts.sort((a, b) {
        final c = column.compare(a, b);
        return _ascending ? c : -c;
      });
    }

    return SizedBox(
      width: double.infinity,
      child: Table(
        border: TableBorder(
          verticalInside: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        columnWidths: {
          for (var i = 0; i < widget.columns.length; i++)
            i: FlexColumnWidth(widget.columns[i].flex.toDouble()),
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
              for (var i = 0; i < widget.columns.length; i++)
                _headerCell(widget.columns[i], i),
            ],
          ),
          // One row per account.
          for (final (i, a) in accounts.indexed)
            TableRow(
              decoration: BoxDecoration(
                color: i.isOdd
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
              ),
              children: [
                for (final column in widget.columns)
                  tableCell(column.builder(a)),
              ],
            ),
          if (widget.footerCells != null)
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
                for (final cell in widget.footerCells!) tableCell(cell),
              ],
            ),
        ],
      ),
    );
  }
}
