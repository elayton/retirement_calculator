import 'package:flutter/material.dart';

import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import '../models/plan_timeline.dart';
import 'plan_widgets.dart';

/// Floor for every rate field: a rate may be negative, down to a total wipeout.
const _minRate = -100.0;

/// Below this page width the sidebar sits above the table instead of beside it.
const planSidebarBreakpoint = 1000.0;

/// The fixed width of the sidebar when it sits beside the table.
const planSidebarWidth = 300.0;

/// Sidebar section titles, in display order. Each one stands in for a group of
/// plan parameters; sections without controls yet render a placeholder body.
const planSidebarSections = <String>['Timeline', 'Expenses', 'Salary', 'Growth', 'Payments', 'Health'];

/// The left sidebar of the plan page: a vertical stack of accordions, one per
/// group of plan parameters.
///
/// It shows the parameters of the age of the selected row, [age]; an edited
/// value is saved back into the parameters of that age, and [onChanged] fires
/// after each edit so the page can rebuild the table.
class PlanSidebar extends StatelessWidget {
  final PlanParametersMap parametersMap;
  final PlanTimeline timeline;
  final int age;
  final VoidCallback onChanged;
  final double width;

  /// Whether the parameters may be edited; while no age row is selected they
  /// hold their value.
  final bool enabled;

  const PlanSidebar({super.key, required this.parametersMap, required this.timeline, required this.age, required this.onChanged, this.width = planSidebarWidth, this.enabled = true});

  /// Whether the parameter shown may be cleared back to what it inherits; the
  /// first row holds the defaults that later rows inherit, so none of its
  /// parameters may be cleared back to nothing.
  bool get _canClear => age != parametersMap.minAge;

  @override
  Widget build(BuildContext context) {
    // The fields read the parameters of the selected age, and save any edits
    // back into that age's parameters.
    parametersMap.age = age;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // One accordion per section; the ones without controls yet show a placeholder.
          for (final (i, title) in planSidebarSections.indexed) ...[
            if (i > 0) const SizedBox(height: 4),
            _SidebarSection(title: title, children: _sectionFields(title, context, enabled)),
          ],
        ],
      ),
    );
  }

  /// The controls belonging to [title], or null for a section with no fields yet.
  List<Widget>? _sectionFields(String title, BuildContext context, bool enabled) {
    return switch (title) {
      'Timeline' => [_timelineFields(context)],
      'Expenses' => [_expenseFields(context, enabled)],
      'Salary' => [_salaryFields(context, enabled)],
      'Growth' => [_growthFields(context, enabled)],
      'Payments' => [_paymentFields(context, enabled)],
      'Health' => [_healthFields(context, enabled)],
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
          value: timeline.retirementAge,
          help: 'Age at which salary income stops and retirement spending begins.',
          onChanged: (value) {
            timeline.retirementAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        IntegerField(
          label: 'Primary Social Security Age',
          value: timeline.primarySocialSecurityAge,
          minValue: 62,
          maxValue: 70,
          help: 'Age at which primary Social Security income begins.',
          onChanged: (value) {
            timeline.primarySocialSecurityAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        IntegerField(
          label: 'Secondary Social Security Age',
          value: timeline.secondarySocialSecurityAge,
          minValue: 62,
          maxValue: 70,
          help: 'Age at which the secondary Social Security income begins.',
          onChanged: (value) {
            timeline.secondarySocialSecurityAge = value;
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
      ],
    );
  }

  /// The controls for monthly expenses.
  Widget _expenseFields(BuildContext context, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Budget',
          value: parametersMap.getBudget(),
          overridden: parametersMap.parametersFor(age).budget != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).budget = null; onChanged(); } : null,
          step: 100,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly spending in retirement, excluding health insurance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setBudget(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Medical Insurance',
          value: parametersMap.getMedicalInsurance(),
          overridden: parametersMap.parametersFor(age).medicalInsurance != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).medicalInsurance = null; onChanged(); } : null,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Private health insurance monthly premium before Medicare starts at ${PlanConstants.medicareStartAge}.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setMedicalInsurance(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Medicare',
          value: parametersMap.getMedicare(),
          overridden: parametersMap.parametersFor(age).medicare != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).medicare = null; onChanged(); } : null,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly premium once Medicare starts at ${PlanConstants.medicareStartAge}.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setMedicare(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Inflation Rate',
          value: parametersMap.getInflationRate(),
          overridden: parametersMap.parametersFor(age).inflationRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).inflationRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Expected annual rate of inflation. Spending, premiums, wages, benefits, and the tax rules all move with it.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setInflationRate(value);
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for earned income while working.
  Widget _salaryFields(BuildContext context, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Base Salary',
          value: parametersMap.getBaseSalary(),
          overridden: parametersMap.parametersFor(age).baseSalary != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).baseSalary = null; onChanged(); } : null,
          step: 5000,
          prefix: r'$',
          help: 'Annual salary before bonus, taxes, and retirement contributions.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setBaseSalary(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Bonus Rate',
          value: parametersMap.getBonusRate(),
          overridden: parametersMap.parametersFor(age).bonusRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).bonusRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual bonus, as a percentage of the base salary.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setBonusRate(value);
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the annual return assumed on each account.
  Widget _growthFields(BuildContext context, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberField(
          label: 'Cash Growth Rate',
          value: parametersMap.getCashGrowthRate(),
          overridden: parametersMap.parametersFor(age).cashGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).cashGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the cash balance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setCashGrowthRate(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Brokerage Growth Rate',
          value: parametersMap.getBrokerageGrowthRate(),
          overridden: parametersMap.parametersFor(age).brokerageGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).brokerageGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the taxable brokerage balance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setBrokerageGrowthRate(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: '401(k) Growth Rate',
          value: parametersMap.getFourOhOneKGrowthRate(),
          overridden: parametersMap.parametersFor(age).fourOhOneKGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).fourOhOneKGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the 401(k) balance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setFourOhOneKGrowthRate(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Traditional IRA Growth Rate',
          value: parametersMap.getTraditionalIraGrowthRate(),
          overridden: parametersMap.parametersFor(age).traditionalIraGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).traditionalIraGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the pre-tax traditional IRA balance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setTraditionalIraGrowthRate(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'Roth IRA Growth Rate',
          value: parametersMap.getRothIraGrowthRate(),
          overridden: parametersMap.parametersFor(age).rothIraGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).rothIraGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the after-tax Roth IRA balance.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setRothIraGrowthRate(value);
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        NumberField(
          label: 'HSA Growth Rate',
          value: parametersMap.getHsaGrowthRate(),
          overridden: parametersMap.parametersFor(age).hsaGrowthRate != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).hsaGrowthRate = null; onChanged(); } : null,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the HSA balance above the cash threshold.',
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setHsaGrowthRate(value);
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the sources the plan pays from.
  Widget _paymentFields(BuildContext context, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaymentSourceOrderField(
          label: 'Pay Expenses From',
          sources: parametersMap.getPayExpensesFrom(),
          onChanged: (sources) {
            parametersMap.setPayExpensesFrom(sources);
            onChanged();
          },
          help: 'The sources expenses are paid from, in the order they are tried.',
          enabled: enabled,
        ),
        const SizedBox(height: 8),
        PaymentSourceOrderField(
          label: 'Pay Taxes From',
          sources: parametersMap.getPayTaxesFrom(),
          onChanged: (sources) {
            parametersMap.setPayTaxesFrom(sources);
            onChanged();
          },
          help: 'The sources taxes are paid from, in the order they are tried.',
          enabled: enabled,
        ),
      ],
    );
  }

  /// The controls for household health coverage.
  Widget _healthFields(BuildContext context, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntegerField(
          label: 'Family Members',
          value: parametersMap.getFamilyMembers(),
          overridden: parametersMap.parametersFor(age).familyMembers != null,
          onCleared: _canClear ? () { parametersMap.parametersFor(age).familyMembers = null; onChanged(); } : null,
          minValue: 1,
          help: "Expected household size, used to work out the federal poverty level the premium tax credit is measured against.",
          enabled: enabled,
          onChanged: (value) {
            parametersMap.setFamilyMembers(value);
            onChanged();
          },
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
