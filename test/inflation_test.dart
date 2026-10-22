import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/calc/plan_calculator.dart';
import 'package:retirement_calculator/calc/tax_rules.dart';
import 'package:retirement_calculator/models/plan_constants.dart';
import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';

/// The totals of the last of [ages], projected one year at a time.
PlanTotals project(PlanParameters parameters, List<int> ages, {double brokerage = 0}) {
  final totals = PlanTotals.fromPortfolio(Portfolio(type: 'Fidelity FullView', exportedDate: DateTime.utc(2026, 1, 1)));
  if (brokerage > 0) totals.add(PlanColumn.brokerage, 'seed', brokerage);

  final calculator = PlanCalculator(portfolioDate: DateTime.utc(2026, 1, 1), parameters: parameters, totals: totals);

  var year = totals;
  for (final age in ages) {
    year = calculator.calculateNext(age);
  }
  return year;
}

/// The expense line named [description] in [year].
double expense(PlanTotals year, String description) =>
    year.balanceOf(PlanColumn.expenses).adjustments.where((a) => a.$1 == description).fold<double>(0, (sum, a) => sum + a.$2);

void main() {
  group('inflation', () {
    test('the wages inflate with it', () {
      final parameters = PlanParameters()
        ..baseSalary = 100000
        ..bonusRate = 0
        ..inflationRate = 10
        ..retirementAge = 100;

      expect(project(parameters, [40]).salary, closeTo(100000, 0.01), reason: 'the first year is the year of the export');
      expect(project(parameters, [40, 41]).salary, closeTo(110000, 0.01));
      expect(project(parameters, [40, 41, 42]).salary, closeTo(121000, 0.01));
    });

    test('the spending and the premiums inflate with it', () {
      final parameters = PlanParameters()
        ..budget = 1000
        ..medicalInsurance = 500
        ..medicare = 0
        ..premiumTaxCredits = 0
        ..inflationRate = 10
        ..retirementAge = 30;

      final first = project(parameters, [40]);
      expect(expense(first, 'Budget'), closeTo(12000, 0.01));
      expect(expense(first, 'Medical Insurance'), closeTo(6000, 0.01));

      final second = project(parameters, [40, 41]);
      expect(expense(second, 'Budget'), closeTo(13200, 0.01));
      expect(expense(second, 'Medical Insurance'), closeTo(6600, 0.01));
    });

    test('the tax rules are indexed, so the tax scales with the income', () {
      // The income and the rules both grow by the same factor, so the tax grows
      // by it too: inflation on its own leaves the effective rate alone.
      final parameters = PlanParameters()
        ..baseSalary = 200000
        ..bonusRate = 0
        ..inflationRate = 10
        ..retirementAge = 100;

      final first = project(parameters, [40]);
      final second = project(parameters, [40, 41]);

      expect(first.tax, greaterThan(0));
      expect(second.tax, closeTo(first.tax * 1.1, 0.01));
    });

    test('the Social Security thresholds are left where the law left them', () {
      // The benefit inflates but the thresholds do not, so more of the benefit
      // is taxed as the years go by.
      final rules = TaxRules.indexed(2);

      expect(rules.standardDeduction, PlanConstants.standardDeduction * 2);
      expect(PlanConstants.socialSecurityFirstThreshold, 32000);
      expect(PlanConstants.socialSecuritySecondThreshold, 44000);
    });

    test("last year's taxes are worth a year's inflation when they are paid", () {
      final parameters = PlanParameters()
        ..baseSalary = 200000
        ..bonusRate = 0
        ..budget = 5000
        ..medicalInsurance = 0
        ..medicare = 0
        ..premiumTaxCredits = 0
        ..inflationRate = 10
        ..retirementAge = 40;

      final previous = project(parameters, [40, 41], brokerage: 1000000);
      final current = project(parameters, [40, 41, 42], brokerage: 1000000);

      expect(previous.tax, greaterThan(0), reason: 'the year before has to owe some tax');
      expect(expense(current, "Last Year's Taxes"), closeTo(previous.tax * 1.1, 0.01));
    });

    test('no inflation changes nothing', () {
      final parameters = PlanParameters()
        ..baseSalary = 200000
        ..bonusRate = 0
        ..budget = 1000
        ..inflationRate = 0
        ..retirementAge = 30;

      final first = project(parameters, [40]);
      final second = project(parameters, [40, 41]);

      expect(second.salary, first.salary);
      expect(second.tax, closeTo(first.tax, 0.01));
      expect(expense(second, 'Budget'), expense(first, 'Budget'));
    });
  });
}
