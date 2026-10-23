import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/calc/plan_calculator.dart';
import 'package:retirement_calculator/calc/tax_calculator.dart';
import 'package:retirement_calculator/models/plan_constants.dart';
import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';

/// One projected year: the MAGI it carried, the income it was made of, the
/// notes recorded against the tax column, and the expense lines of the year
/// after it, which is when the bill for the year is paid.
///
/// [salary] is paid only while the year is a working one, and [budget] is met
/// from brokerage once it is not, so a year is one or the other. [budget] is
/// monthly, like the parameter it stands for.
({
  double magi,
  double ordinary,
  double gains,
  double salary,
  double socialSecurity,
  double taxableSocialSecurity,
  double premiumTaxCredits,
  Map<String, double?> notes,
  Map<String, double> nextExpenses,
}) magiYear({
  required int age,
  double salary = 0,
  double bonusRate = 0,
  double budget = 0,
  bool retired = false,
  int? retirementAge,
  int socialSecurityAge = 200,
  double brokerage = 0,
  double premiumTaxCredits = 0,
}) {
  final parameters = PlanParameters()
    // Salary alone, so the ordinary income is exactly what is asked for.
    ..baseSalary = salary
    ..bonusRate = bonusRate
    ..budget = budget
    ..primarySocialSecurityAge = socialSecurityAge
    ..secondarySocialSecurityAge = 200
    ..rothIraConversionAge = 200
    ..medicare = 0
    ..medicalInsurance = 0
    ..premiumTaxCredits = premiumTaxCredits
    // A working year keeps its salary; a retired one draws from brokerage
    // instead. Retiring the year before leaves the year before it a working
    // one, so no tax is carried into the year under test.
    ..retirementAge = retirementAge ?? (retired ? age - 1 : 100);

  final totals = PlanTotals.fromPortfolio(Portfolio(type: 'Fidelity FullView', exportedDate: DateTime.utc(2026, 1, 1)));
  totals.add(PlanColumn.brokerage, 'seed', brokerage + budget * 24);

  final calculator = PlanCalculator(portfolioDate: DateTime.utc(2026, 1, 1), parameters: parameters, totals: totals);
  // The first year runs part-sized, since the export date falls inside it.
  calculator.calculateNext(age - 1);
  final year = calculator.calculateNext(age);

  // The bill for the year comes with the next year's taxes.
  final nextYear = calculator.calculateNext(age + 1);

  return (
    magi: year.magi,
    ordinary: year.ordinaryIncome,
    gains: year.capitalGains,
    salary: year.salary,
    socialSecurity: year.socialSecurity,
    taxableSocialSecurity: year.taxableSocialSecurity,
    premiumTaxCredits: year.premiumTaxCredits,
    notes: {for (final (description, amount) in year.balanceOf(PlanColumn.tax).notes) description: amount},
    nextExpenses: {for (final (description, amount) in nextYear.balanceOf(PlanColumn.expenses).adjustments) description: amount},
  );
}

/// The whole Social Security benefit starting at [age].
double socialSecurity(int age) => PlanConstants.socialSecurityBenefitByAge[age]! * 12;

/// The pre-tax 401(k) contribution on [salary].
double preTax401k(double salary) => salary * PlanParameters().employee401kContributionRate / 100;

void main() {
  group('modified adjusted gross income', () {
    test('a working year leaves out the pre-tax 401(k) contribution', () {
      // The salary is counted gross of the contribution, so it comes back out:
      // the money went into the account before tax and was never income.
      final salary = 200000.0;
      final magi = TaxCalculator.magi(
        ordinaryIncome: salary,
        capitalGains: 0,
        agiDeductions: preTax401k(salary) + PlanConstants.hsaContributionLimit,
        taxExemptSocialSecurity: 0,
      );

      expect(magi, closeTo(salary - preTax401k(salary) - PlanConstants.hsaContributionLimit, 0.01));
      expect(magi, lessThan(salary));
    });

    test('a bonus is income and carries the contribution with it', () {
      // The contribution is a share of the salary and the bonus together, so the
      // bonus counts at the same rate as the salary it rides on.
      final salary = 100000.0;
      final bonus = salary * 10 / 100;
      final magi = TaxCalculator.magi(
        ordinaryIncome: salary + bonus,
        capitalGains: 0,
        agiDeductions: preTax401k(salary + bonus) + PlanConstants.hsaContributionLimit,
        taxExemptSocialSecurity: 0,
      );

      expect(salary + bonus, 110000);
      expect(magi, closeTo(110000 - preTax401k(110000) - PlanConstants.hsaContributionLimit, 0.01));
    });

    test('the HSA deduction comes out of the MAGI', () {
      // The premium tax credit does not add the HSA deduction back, the way the
      // general MAGI does, so the contribution counts against the figure.
      final salary = 150000.0;
      final magi = TaxCalculator.magi(
        ordinaryIncome: salary,
        capitalGains: 0,
        agiDeductions: preTax401k(salary) + PlanConstants.hsaContributionLimit,
        taxExemptSocialSecurity: 0,
      );

      expect(magi, closeTo(salary - preTax401k(salary) - PlanConstants.hsaContributionLimit, 0.01));
    });

    test('the whole Social Security benefit counts', () {
      // The premium tax credit counts the benefit in full: the taxable part is
      // in the ordinary income, and the tax-exempt part is added back.
      final budget = 5000.0;
      final year = magiYear(age: 64, retirementAge: 63, budget: budget, socialSecurityAge: 62, brokerage: 500000);

      expect(year.salary, 0);
      expect(year.socialSecurity, closeTo(socialSecurity(62), 0.01));
      expect(year.gains, closeTo(budget * 12 - socialSecurity(62), 0.01), reason: 'the rest of the budget comes from brokerage');
      expect(year.magi, closeTo(budget * 12, 0.01), reason: 'the benefit counts in full, so the figure is the budget');
    });

    test('a benefit that is taxed in part counts in full', () {
      // With enough other income the benefit is taxed, but the credit still
      // counts all of it: the taxable part is in the ordinary income, and the
      // tax-exempt part is added back.
      final year = magiYear(age: 65, retirementAge: 64, budget: 20000, socialSecurityAge: 62, brokerage: 500000);

      expect(year.taxableSocialSecurity, greaterThan(0), reason: 'the benefit should be taxed in part');
      expect(year.magi, closeTo(year.ordinary + year.gains + year.socialSecurity - year.taxableSocialSecurity, 0.01));
    });

    test('a retired year takes nothing out', () {
      // There is no salary, so there is no contribution to take out: the MAGI is
      // the Social Security and the brokerage draw alike.
      final year = magiYear(age: 64, retirementAge: 63, budget: 5000, brokerage: 500000);

      expect(year.magi, closeTo(year.ordinary + year.gains + year.socialSecurity - year.taxableSocialSecurity, 0.01));
    });

    test('the MAGI is recorded against the tax column', () {
      final year = magiYear(age: 64, retirementAge: 63, budget: 5000, brokerage: 500000);

      expect(year.notes['MAGI'], closeTo(year.magi, 0.01));
    });

    test('the subsidy cliff is recorded below the MAGI', () {
      final year = magiYear(age: 64, retirementAge: 63, budget: 5000, brokerage: 500000);

      // The premium tax credit is gone above four times the poverty level.
      expect(year.notes['4x Federal Poverty Level'], closeTo(4 * PlanConstants.federalPovertyLevel, 0.01));
      expect(PlanConstants.federalPovertyLevel, 44360, reason: 'the 2026 level for a household of six');

      // It sits below the MAGI, which is the figure it is compared against.
      // A map keeps the order its entries went in, which is the order the
      // tooltip lists them in.
      final descriptions = year.notes.keys.toList();
      expect(descriptions.indexOf('MAGI'), lessThan(descriptions.indexOf('4x Federal Poverty Level')));
    });
  });

  group('the years the MAGI is worked out in', () {
    test('a working year has no MAGI', () {
      // The MAGI is the figure the premium tax credit turns on, so it is only
      // of interest once the salary has stopped.
      final year = magiYear(age: 2, salary: 200000);

      expect(year.magi, 0);
      expect(year.notes.containsKey('MAGI'), isFalse);
      expect(year.notes.containsKey('4x Federal Poverty Level'), isFalse);
    });

    test('a year after retirement has a MAGI', () {
      final year = magiYear(age: 64, retirementAge: 63, budget: 5000, brokerage: 500000);

      expect(year.magi, greaterThan(0));
      expect(year.notes['MAGI'], closeTo(year.magi, 0.01));
    });

    test('the year Medicare starts has a MAGI', () {
      final year = magiYear(age: 65, retirementAge: 64, budget: 5000, brokerage: 500000);

      expect(year.magi, greaterThan(0));
      expect(year.notes['MAGI'], closeTo(year.magi, 0.01));
    });

    test('the years after Medicare starts have no MAGI', () {
      // Medicare takes over at 65, so the year after it starts is the last one
      // the MAGI is worked out in.
      final year = magiYear(age: 67, retirementAge: 66, budget: 5000, brokerage: 500000);

      expect(year.magi, 0);
      expect(year.notes.containsKey('MAGI'), isFalse);
    });
  });

  group('paying the premium tax credits back', () {
    test('the credits are paid back once the MAGI passes four times the poverty level', () {
      // Above the line no credit is allowed at all, so all of the credit
      // received has to be paid back with the return for the year.
      final year = magiYear(age: 64, retirementAge: 63, budget: 20000, brokerage: 1000000, premiumTaxCredits: 2000);

      expect(year.magi, greaterThan(4 * PlanConstants.federalPovertyLevel));
      expect(year.premiumTaxCredits, closeTo(2000 * 12, 0.01), reason: 'the credit received for the year');
      expect(year.notes['Premium Tax Credit Repayment'], closeTo(2000 * 12, 0.01));
    });

    test('the bill comes with the next year\'s taxes', () {
      // The return for the year is filed the year after, so the credit is paid
      // back then and not then.
      final year = magiYear(age: 64, retirementAge: 63, budget: 20000, brokerage: 1000000, premiumTaxCredits: 2000);

      expect(year.nextExpenses['Premium Tax Credit Repayment'], closeTo(2000 * 12, 0.01));
    });

    test('the credits are not paid back below the line', () {
      final year = magiYear(age: 64, retirementAge: 63, budget: 5000, brokerage: 500000, premiumTaxCredits: 2000);

      expect(year.magi, lessThan(4 * PlanConstants.federalPovertyLevel));
      expect(year.notes.containsKey('Premium Tax Credit Repayment'), isFalse);
      expect(year.nextExpenses.containsKey('Premium Tax Credit Repayment'), isFalse);
    });

    test('there is nothing to pay back without credits', () {
      final year = magiYear(age: 64, retirementAge: 63, budget: 20000, brokerage: 1000000);

      expect(year.magi, greaterThan(4 * PlanConstants.federalPovertyLevel));
      expect(year.notes.containsKey('Premium Tax Credit Repayment'), isFalse);
      expect(year.nextExpenses.containsKey('Premium Tax Credit Repayment'), isFalse);
    });
  });
}
