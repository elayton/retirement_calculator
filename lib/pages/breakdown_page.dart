import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../utils/formatting.dart';
import '../widgets/portfolio_widgets.dart';

class BreakdownPage extends StatelessWidget {
  const BreakdownPage({
    super.key,
    this.portfolio,
  });

  final Portfolio? portfolio;

  @override
  Widget build(BuildContext context) {
    final portfolio = this.portfolio;
    if (portfolio == null) {
      return const NoPortfolioLoaded();
    }

    // The distinct account types present in the portfolio, in enum order.
    final types = PortfolioAccountType.values.where((t) => portfolio.accounts.any((a) => a.type == t)).toList();

    final totalsRow = [
      boldText('Total'),
      for (final t in types)
        rightAlign(boldText(appCurrency.format(portfolio.accounts.where((a) => a.type == t).fold<double>(0, (sum, a) => sum + a.balance)))),
    ];

    final topTotalsRow = [
      italicText('Total', color: Theme.of(context).colorScheme.onSurfaceVariant),
      for (final t in types)
        rightAlign(
          italicText(
            appCurrency.format(portfolio.accounts.where((a) => a.type == t).fold<double>(0, (sum, a) => sum + a.balance)),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortfolioTypeAndTotal(portfolio: portfolio),
          const SizedBox(height: 12),
          SortableAccountsTable(
            accounts: portfolio.accounts,
            columns: [
              AccountColumn(title: 'Account Name', flex: 2, compare: (a, b) => a.name.compareTo(b.name), builder: (a) => Text(a.name)),
              for (final t in types)
                AccountColumn(
                  title: t.label,
                  right: true,
                  compare: (a, b) {
                    final av = a.type == t ? a.balance : 0.0;
                    final bv = b.type == t ? b.balance : 0.0;
                    return av.compareTo(bv);
                  },
                  builder: (a) => rightAlign(Text(a.type == t ? appCurrency.format(a.balance) : '')),
                ),
            ],
            footerCells: totalsRow,
            topFooterCells: topTotalsRow,
          ),
        ],
      ),
    );
  }
}
