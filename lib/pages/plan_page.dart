import 'package:flutter/material.dart';

import '../models/plan_models.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import '../models/plan_timeline.dart';
import '../models/portfolio_models.dart';
import '../calc/plan_calculator.dart';
import '../widgets/plan_sidebar.dart';
import '../widgets/portfolio_widgets.dart';
import '../widgets/balance_tooltip.dart';
import '../utils/formatting.dart';

class PlanPage extends StatefulWidget {
  final Portfolio? portfolio;

  const PlanPage({super.key, this.portfolio});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {

  final PlanTimeline _timeline = PlanTimeline();
  late final PlanParametersMap _parametersMap = PlanParametersMap(
    minAge: DateTime.now().year - PlanConstants.birthday.year,
    initial: PlanParameters.withDefaults(),
  );

  /// The age of the row the sidebar is showing; tapping a row in the table
  /// selects it, and the sidebar then shows that age's parameters.
  int? _selectedAge;

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.portfolio;
    if (portfolio == null) return const NoPortfolioLoaded();

    final columns = PlanColumn.values;

    final timeline = _timeline;
    final parametersMap = _parametersMap;

    var totals = PlanTotals.fromPortfolio(portfolio);

    final calculator = PlanCalculator(portfolioDate: portfolio.exportedDate, timeline: timeline, parametersMap: parametersMap, totals: totals);

    final rows = <(int, PlanTotals)>[];
    var age = parametersMap.minAge;

    while (age <= PlanConstants.longevityAge) {
      totals = calculator.calculateTotalsFor(age);
      rows.add((age, totals));
      ++age;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Beside the table on wide pages, above it when there is no room.
        final selectedAge = _selectedAge ?? parametersMap.minAge;
        final sidebar = PlanSidebar(
          parametersMap: parametersMap,
          timeline: timeline,
          age: selectedAge,
          enabled: _selectedAge != null,
          onChanged: () => setState(() {}),
        );
        final table = SizedBox(width: double.infinity, child: _planTable(context, columns, rows, timeline));

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

  /// Open the row for [age]; the sidebar then shows that age's parameters.
  /// Tapping the open row again closes the selection.
  void _selectAge(int age) {
    setState(() => _selectedAge = _selectedAge == age ? null : age);
  }

  /// Row tint: working years orange, retired years green, except for the
  /// stretch between retirement and penalty-free IRA withdrawals, which is blue
  /// when retirement comes first and red when the IRA age does.
  Color _rowTint(int age, PlanTimeline timeline) {
    final retirementAge = timeline.retirementAge;
    final iraWithdrawalAge = PlanConstants.iraWithdrawalAge;
    final afterRetirement = age > retirementAge;

    if (retirementAge < iraWithdrawalAge && afterRetirement && age <= iraWithdrawalAge) {
      return Colors.blue.withValues(alpha: 0.12);
    }
    if (retirementAge > iraWithdrawalAge && !afterRetirement && age > iraWithdrawalAge) {
      return Colors.red.withValues(alpha: 0.12);
    }

    return (afterRetirement ? Colors.green : Colors.orange).withValues(alpha: 0.12);
  }

  /// The row's background: its working or retired tint, overlaid with a mark
  /// for the row the sidebar is showing.
  Color _rowColor(int age, PlanTimeline timeline, bool alternate) {
    final background = Color.alphaBlend(
      _rowTint(age, timeline),
      alternate ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.surface,
    );

    if (age != _selectedAge) return background;

    // Tinted pink for the selected row, blended over the row background.
    return Color.alphaBlend(Colors.pink.withValues(alpha: 0.2), background);
  }

  /// One cell of the projection table. Every column but the bracket holds a
  /// balance and so opens a breakdown on hover.
  Widget _cell(PlanColumn column, PlanTotals totals) => switch (column) {
    PlanColumn.expenses when totals.unpaidExpenses > 0 => BalanceTooltip(
        balance: totals.balanceOf(column),
        textColor: Colors.red,
      ),
    PlanColumn.taxBracket => rightAlign(Text(formatPercent(totals.taxBracket))),
    PlanColumn.tax when totals.unpaidTaxes > 0 => BalanceTooltip(
        balance: totals.balanceOf(column),
        textColor: Colors.red,
      ),
    PlanColumn.tax => BalanceTooltip(balance: totals.balanceOf(column)),
    _ => BalanceTooltip(balance: totals.balanceOf(column)),
  };

  Widget _tableCell(PlanColumn column, PlanTotals totals) => tableCell(_cell(column, totals));

  /// The per-age projection table. Tapping a row selects it, which is what
  /// makes the sidebar show that age's parameters.
  Widget _planTable(BuildContext context, List<PlanColumn> columns, List<(int, PlanTotals)> rows, PlanTimeline timeline) {
    return Table(
      border: TableBorder(verticalInside: BorderSide(width: 1, color: Theme.of(context).colorScheme.outlineVariant)),
      // The age column is sized to its own contents rather than a share of the
      // table, so the header keeps to one line at any width.
      columnWidths: {0: const IntrinsicColumnWidth(), for (var i = 1; i <= columns.length; i++) i: const FlexColumnWidth()},
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
              color: _rowColor(row.$1, timeline, i.isOdd),
              border:
                  {
                    timeline.retirementAge,
                    PlanConstants.iraWithdrawalAge,
                    PlanConstants.medicareStartAge,
                    PlanConstants.firstRmdAge,
                    timeline.secondarySocialSecurityAge,
                    timeline.primarySocialSecurityAge,
                  }.contains(row.$1)
                  ? Border(bottom: BorderSide(width: 1, color: Theme.of(context).colorScheme.outline))
                  : null,
            ),
            children: [
              // The row opens on any of its cells, and so selects the age.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectAge(row.$1),
                child: tableCell(Text('${row.$1}')),
              ),
              for (final c in columns)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectAge(row.$1),
                  child: _tableCell(c, row.$2),
                ),
            ],
          ),
      ],
    );
  }
  
}
