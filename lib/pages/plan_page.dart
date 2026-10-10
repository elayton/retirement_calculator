import 'package:flutter/material.dart';

import '../models/plan.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import '../models/portfolio.dart';
import '../calc/plan_calculator.dart';
import '../utils/formatting.dart';
import '../widgets/portfolio_widgets.dart';

class PlanPage extends StatelessWidget {
  final Portfolio? portfolio;

  const PlanPage({
    super.key,
    this.portfolio,
  });

  @override
  Widget build(BuildContext context) {
    final portfolio = this.portfolio;
    if (portfolio == null) {
      return const NoPortfolioLoaded();
    }

    final types = <PortfolioAccountType>[
      PortfolioAccountType.cash,
      PortfolioAccountType.brokerage,
      PortfolioAccountType.fourOhOneK,
      PortfolioAccountType.traditionalIra,
      PortfolioAccountType.rothIra,
      PortfolioAccountType.hsa,
    ];

    const parameters = PlanParameters();
    var totals = PlanTotals.fromPortfolio(portfolio);

    final calculator = PlanCalculator(parameters: parameters, totals: totals);

    final rows = <(int, PlanTotals)>[];
    var age = DateTime.now().year - PlanConstants.birthday.year;

    do {
      rows.add((age, totals));
      totals = calculator.calculateNext(age);
    } while (age++ < PlanConstants.longevityAge);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Table(
          border: TableBorder(verticalInside: BorderSide(width: 1, color: Theme.of(context).colorScheme.outlineVariant)),
          columnWidths: {for (var i = 0; i <= types.length; i++) i: const FlexColumnWidth()},
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.outlineVariant)),
              ),
              children: [
                tableCell(boldText('Age')),
                for (final t in types) tableCell(rightAlign(boldText(t.label))),
                tableCell(rightAlign(boldText('Total'))),
              ],
            ),
            for (final (i, row) in rows.indexed)
              TableRow(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    row.$1 <= parameters.retirementAge ? Colors.red.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                    i.isOdd ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
                  ),
                  border:
                      {
                        PlanConstants.iraWithdrawalAge,
                        PlanConstants.medicareStartAge,
                        parameters.spouseSocialSecurityAge,
                        parameters.socialSecurityAge,
                      }.contains(row.$1)
                      ? Border(bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.outline))
                      : null,
                ),
                children: [
                  tableCell(Text('${row.$1}')),
                  for (final t in types) tableCell(rightAlign(Text(appCurrencyWhole.format(row.$2.total(t))))),
                  tableCell(rightAlign(Text(appCurrencyWhole.format(types.fold<double>(0, (sum, t) => sum + row.$2.total(t)))))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
