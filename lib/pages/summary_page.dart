import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../utils/formatting.dart';
import '../widgets/portfolio_widgets.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key, this.portfolio});

  final Portfolio? portfolio;

  @override
  Widget build(BuildContext context) {
    final portfolio = this.portfolio;
    if (portfolio == null) {
      return const NoPortfolioLoaded();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortfolioSummaryHeader(portfolio: portfolio),
          const SizedBox(height: 12),
          SortableAccountsTable(
            accounts: portfolio.accounts,
            columns: [
              AccountColumn(
                title: 'Account Name',
                flex: 2,
                compare: (a, b) => a.name.compareTo(b.name),
                builder: (a) => Text(a.name),
              ),
              AccountColumn(
                title: 'Type',
                compare: (a, b) => a.type.label.compareTo(b.type.label),
                builder: (a) => Text(a.type.label),
              ),
              AccountColumn(
                title: 'Balance',
                right: true,
                compare: (a, b) => a.balance.compareTo(b.balance),
                builder: (a) =>
                    rightAlign(Text(appCurrency.format(a.balance))),
              ),
              AccountColumn(
                title: 'Updated',
                compare: (a, b) => a.updated.compareTo(b.updated),
                builder: (a) => Text(formatDate(a.updated)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
