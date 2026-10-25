import 'package:flutter/material.dart';

import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import 'plan_widgets.dart';

/// Floor for every rate field: a rate may be negative, down to a total wipeout.
const _minRate = -100.0;

/// Below this page width the sidebar sits above the table instead of beside it.
const planSidebarBreakpoint = 1000.0;

/// The fixed width of the sidebar when it sits beside the table.
const planSidebarWidth = 300.0;

/// Sidebar section titles, in display order. Each one stands in for a group of
/// plan parameters; sections without controls yet render a placeholder body.
const planSidebarSections = <String>['Timeline', 'Expenses', 'Salary', 'Growth', 'Downturns', 'Options'];

/// The left sidebar of the plan page: a vertical stack of accordions, one per
/// group of plan parameters.
///
/// Parameters are edited in place on [parameters]; [onChanged] fires after each
/// edit so the page can rebuild the table.
class PlanSidebar extends StatelessWidget {
  final PlanParameters parameters;
  final VoidCallback onChanged;
  final double width;

  const PlanSidebar({super.key, required this.parameters, required this.onChanged, this.width = planSidebarWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One accordion per section; the ones without controls yet show a placeholder.
          for (final (i, title) in planSidebarSections.indexed) ...[
            if (i > 0) const SizedBox(height: 4),
            _SidebarSection(title: title, children: _sectionFields(title, context)),
          ],
        ],
      ),
    );
  }

  /// The controls belonging to [title], or null for a section with no fields yet.
  List<Widget>? _sectionFields(String title, BuildContext context) {
    return switch (title) {
      'Timeline' => [_timelineFields(context)],
      'Expenses' => [_expenseFields(context)],
      'Salary' => [_salaryFields(context)],
      'Growth' => [_growthFields(context)],
      'Downturns' => [_downturnFields(context)],
      'Options' => [_optionsFields(context)],
      _ => null,
    };
  }

  /// The controls for the ages that drive the projection.
  Widget _timelineFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntegerField(
          label: 'Retirement Age',
          value: parameters.retirementAge,
          help: 'Age at which salary income stops and retirement spending begins.',
          onChanged: (value) {
            parameters.retirementAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        IntegerField(
          label: 'Primary Social Security Age',
          value: parameters.primarySocialSecurityAge,
          minValue: 62,
          maxValue: 70,
          help: 'Age at which primary Social Security income begins.',
          onChanged: (value) {
            parameters.primarySocialSecurityAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        IntegerField(
          label: 'Secondary Social Security Age',
          value: parameters.secondarySocialSecurityAge,
          minValue: 62,
          maxValue: 70,
          help: 'Age at which the secondary Social Security income begins.',
          onChanged: (value) {
            parameters.secondarySocialSecurityAge = value;
            onChanged();
          },
        ),
        Divider(height: 20, color: Theme.of(context).colorScheme.outlineVariant),
        ConstantField(
          label: '401(k) Withdrawal Age',
          value: PlanConstants.fourOhOneKWthdrawalAge,
          help: 'Rule of 55 allows penalty-free 401(k) withdrawals.',
        ),
        const SizedBox(height: 8),
        ConstantField(
          label: 'IRA Withdrawal Age',
          value: PlanConstants.iraWithdrawalAge,
          help: 'Earliest penalty-free IRA withdrawals.',
        ),
        const SizedBox(height: 8),
        ConstantField(
          label: 'Medicare Start Age',
          value: PlanConstants.medicareStartAge,
          help: 'Medicare premiums replace medical insurance from this age.',
        ),
        const SizedBox(height: 8),
        ConstantField(
          label: 'RMD Start Age',
          value: PlanConstants.rmdStartAge,
          help: 'Required minimum distributions from retirement accounts begin at this age.',
        ),
      ],
    );
  }

  /// The controls for monthly expenses.
  Widget _expenseFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Budget',
          value: parameters.budget,
          step: 100,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly spending in retirement, excluding health insurance.',
          onChanged: (value) {
            parameters.budget = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Medical Insurance',
          value: parameters.medicalInsurance,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Private health insurance monthly premium before Medicare starts at ${PlanConstants.medicareStartAge}.',
          onChanged: (value) {
            parameters.medicalInsurance = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Medicare',
          value: parameters.medicare,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly premium once Medicare starts at ${PlanConstants.medicareStartAge}.',
          onChanged: (value) {
            parameters.medicare = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Inflation Rate',
          value: parameters.inflationRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Expected annual rate of inflation. Spending, premiums, wages, benefits, and the tax rules all move with it.',
          onChanged: (value) {
            parameters.inflationRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for earned income while working.
  Widget _salaryFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Base Salary',
          value: parameters.baseSalary,
          step: 5000,
          prefix: r'$',
          help: 'Annual salary before bonus, taxes, and retirement contributions.',
          onChanged: (value) {
            parameters.baseSalary = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Bonus Rate',
          value: parameters.bonusRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual bonus, as a percentage of the base salary.',
          onChanged: (value) {
            parameters.bonusRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the annual return assumed on each account.
  Widget _growthFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Cash Growth Rate',
          value: parameters.cashGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the cash balance.',
          onChanged: (value) {
            parameters.cashGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Brokerage Growth Rate',
          value: parameters.brokerageGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the taxable brokerage balance.',
          onChanged: (value) {
            parameters.brokerageGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: '401(k) Growth Rate',
          value: parameters.fourOhOneKGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the 401(k) balance.',
          onChanged: (value) {
            parameters.fourOhOneKGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Traditional IRA Growth Rate',
          value: parameters.traditionalIraGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the pre-tax traditional IRA balance.',
          onChanged: (value) {
            parameters.traditionalIraGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Roth IRA Growth Rate',
          value: parameters.rothIraGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the after-tax Roth IRA balance.',
          onChanged: (value) {
            parameters.rothIraGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'HSA Growth Rate',
          value: parameters.hsaGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the HSA balance above the cash threshold.',
          onChanged: (value) {
            parameters.hsaGrowthRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the ages a market drop is applied at, and how deep it is.
  Widget _downturnFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgeListField(
          label: 'Downturn Ages',
          value: parameters.downMarketAges,
          help: 'Ages at which a downturn strikes, separated by commas.',
          onChanged: (value) {
            parameters.downMarketAges = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Downturn Rate',
          value: parameters.downMarketRate,
          decimalPlaces: 2,
          step: 5,
          // A downturn is a loss, so the field has to reach below zero.
          minValue: _minRate,
          suffix: '%',
          help: 'Change applied to the portfolio in a downturn year.',
          onChanged: (value) {
            parameters.downMarketRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for miscellaneous options.
  Widget _optionsFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Pay Taxes from Roth IRA')),
            Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(3, 0),
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: parameters.payTaxesFromRothIra,
                    padding: EdgeInsets.zero,
                    onChanged: (value) {
                      parameters.payTaxesFromRothIra = value;
                      onChanged();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single expandable section; sections without controls show a placeholder.
class _SidebarSection extends StatelessWidget {
  final String title;
  final List<Widget>? children;

  const _SidebarSection({required this.title, this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          // Collapsed by default.
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          children:
              children ??
              [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Coming soon.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
