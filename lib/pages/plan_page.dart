import 'package:flutter/material.dart';

import '../models/plan_models.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import '../models/portfolio_models.dart';
import '../calc/plan_calculator.dart';
import '../utils/formatting.dart';
import '../widgets/plan_widgets.dart';
import '../widgets/portfolio_widgets.dart';

class PlanPage extends StatefulWidget {
  final Portfolio? portfolio;

  const PlanPage({super.key, this.portfolio});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  /// The parameters edited by the sidebar, applied to every rebuild of the table.
  final PlanParameters _parameters = PlanParameters();

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.portfolio;
    if (portfolio == null) {
      return const NoPortfolioLoaded();
    }

    final columns = PlanColumn.values;

    final parameters = _parameters;
    var totals = PlanTotals.fromPortfolio(portfolio);

    final calculator = PlanCalculator(portfolioDate: portfolio.exportedDate, parameters: parameters, totals: totals);

    final rows = <(int, PlanTotals)>[];
    var age = DateTime.now().year - PlanConstants.birthday.year;

    do {
      rows.add((age, totals));
      totals = calculator.calculateNext(age);
    } while (age++ < PlanConstants.longevityAge);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Beside the table on wide pages, above it when there is no room.
        final sidebar = PlanSidebar(parameters: parameters, onChanged: () => setState(() {}));
        final table = SizedBox(width: double.infinity, child: _planTable(context, columns, rows, parameters));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: constraints.maxWidth < planSidebarBreakpoint
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sidebar, const SizedBox(height: 16), table])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sidebar,
                    const SizedBox(width: 16),
                    Expanded(child: table),
                  ],
                ),
        );
      },
    );
  }

  /// The background tint for one row. Working years are red and retired years
  /// green, except for the stretch between retirement age and penalty-free IRA
  /// withdrawals, which is flagged blue when retirement comes first and orange
  /// when the IRA withdrawal age comes first.
  Color _rowTint(int age, PlanParameters parameters) {
    final retirementAge = parameters.retirementAge;
    final iraWithdrawalAge = PlanConstants.iraWithdrawalAge;
    final afterRetirement = age > retirementAge;

    if (retirementAge < iraWithdrawalAge && afterRetirement && age <= iraWithdrawalAge) {
      return Colors.blue.withValues(alpha: 0.12);
    }
    if (retirementAge > iraWithdrawalAge && !afterRetirement && age > iraWithdrawalAge) {
      return Colors.orange.withValues(alpha: 0.12);
    }

    return (afterRetirement ? Colors.green : Colors.red).withValues(alpha: 0.12);
  }

  /// The per-age projection table.
  Widget _planTable(BuildContext context, List<PlanColumn> columns, List<(int, PlanTotals)> rows, PlanParameters parameters) {
    return Table(
      border: TableBorder(verticalInside: BorderSide(width: 1, color: Theme.of(context).colorScheme.outlineVariant)),
      // The age column holds a two-digit number, so it needs only a fraction of the
      // width of a currency column.
      columnWidths: {0: const FlexColumnWidth(0.35), for (var i = 1; i <= columns.length; i++) i: const FlexColumnWidth()},
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.outlineVariant)),
          ),
          children: [tableCell(boldText('Age')), for (final c in columns) tableCell(rightAlign(boldText(c.label)))],
        ),
        for (final (i, row) in rows.indexed)
          TableRow(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                _rowTint(row.$1, parameters),
                i.isOdd ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
              ),
              border:
                  {
                    parameters.retirementAge,
                    PlanConstants.iraWithdrawalAge,
                    PlanConstants.medicareStartAge,
                    PlanConstants.rmdStartAge,
                    parameters.spouseSocialSecurityAge,
                    parameters.socialSecurityAge,
                  }.contains(row.$1)
                  ? Border(bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.outline))
                  : null,
            ),
            children: [tableCell(Text('${row.$1}')), for (final c in columns) tableCell(rightAlign(Text(formatCurrency(row.$2.total(c)))))],
          ),
      ],
    );
  }
}
