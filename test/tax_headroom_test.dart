import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/calc/plan_calculator.dart';
import 'package:retirement_calculator/models/plan_constants.dart';
import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';

/// One projected year: what income and gains it carried, and the headroom notes
/// recorded against the tax column.
///
/// [salary] is paid only while the year is a working one, and [budget] is met
/// from brokerage once it is not, so a year is one or the other.
({double tax, double federal, double state, double bracket, double ordinary, double gains, double agi, Map<String, double?> notes}) taxYear({
  required int age,
  double salary = 0,
  double budget = 0,
  int socialSecurityAge = 200,
  double brokerage = 0,
}) {
  final working = salary > 0;

  final parameters = PlanParameters()
    // Salary alone, so the ordinary income is exactly what is asked for.
    ..baseSalary = salary
    ..bonusRate = 0
    ..primarySocialSecurityAge = socialSecurityAge
    ..secondarySocialSecurityAge = 200
    ..rothIraConversionAge = 200
    ..medicare = 0
    ..medicalInsurance = 0
    ..premiumTaxCredits = 0
    // A working year keeps its salary; a retired one draws from brokerage instead.
    ..retirementAge = working ? 100 : 0;

  final totals = PlanTotals.fromPortfolio(const Portfolio(type: 'Fidelity FullView', exportedDate: _zero));
  totals.add(PlanColumn.brokerage, 'seed', brokerage + budget * 2);

  final calculator = PlanCalculator(portfolioDate: DateTime.utc(2026, 1, 1), parameters: parameters, totals: totals);
  // The first year runs part-sized, since the export date falls inside it.
  calculator.calculateNext(age - 1);
  final year = calculator.calculateNext(age);

  double part(String name) => year.balanceOf(PlanColumn.tax).adjustments.where((a) => a.$1 == name).fold<double>(0, (sum, a) => sum + a.$2);

  return (
    tax: year.tax,
    federal: part('Federal Tax'),
    state: part('Utah Tax'),
    bracket: year.taxBracket,
    ordinary: year.ordinaryIncome,
    gains: year.capitalGains,
    // The tax is computed on the adjusted gross income, which is the ordinary
    // income less the deductions the plan counts it gross of.
    agi: year.ordinaryIncome - year.agiDeductions,
    notes: {for (final (description, amount) in year.balanceOf(PlanColumn.tax).notes) description: amount},
  );
}

/// The headroom the stacked model implies. Written out longhand rather than
/// shared with the calculator, so the test pins the formula.
({double ordinaryTaxable, double stackTop, double? ordinaryHeadroom, double? gainsHeadroom}) expectHeadroom(
  double ordinary,
  double gains,
) {
  final ordinaryTaxable = max(0.0, ordinary - PlanConstants.standardDeduction);
  final stackTop = max(0.0, ordinary + gains - PlanConstants.standardDeduction);

  // The first band whose upper bound the stack has not yet reached is the one
  // above it, and the room left is that bound less where the stack sits.
  double? headroomFor(double position, List<(double?, double)> brackets) {
    if (position <= 0) return null;
    for (final (upperBound, _) in brackets) {
      if (upperBound == null) return null;
      if (position < upperBound) return upperBound - position;
    }
    return null;
  }

  return (
    ordinaryTaxable: ordinaryTaxable,
    stackTop: stackTop,
    ordinaryHeadroom: headroomFor(ordinaryTaxable, PlanConstants.ordinaryIncomeTaxBrackets),
    gainsHeadroom: gains <= 0 ? null : headroomFor(stackTop, PlanConstants.capitalGainsTaxBrackets),
  );
}

void main() {
  group('tax headroom notes', () {
    test('the tax total is the tax, and the notes do not add to it', () {
      final year = taxYear(age: 2, salary: 200000, budget: 0);

      expect(year.tax, greaterThan(0), reason: 'a salary this size is taxed');
      expect(year.notes, isNotEmpty, reason: 'the headroom should be recorded');
      expect(year.notes.values.whereType<double>().any((headroom) => headroom == year.tax), isFalse, reason: 'a note repeated the tax');
    });

    test('gains inside the 0% federal band still owe Utah tax', () {
      // A draw small enough to sit inside the 0% federal gains band still owes Utah
      // tax, which taxes gains as ordinary income at its flat rate.
      final year = taxYear(age: 2, salary: 0, budget: 20000, brokerage: 100000);

      expect(year.gains, greaterThan(0), reason: 'the year should have drawn from brokerage');
      expect(year.federal, 0, reason: 'the draw is inside the 0% federal gains band');
      expect(year.state, greaterThan(0), reason: 'Utah taxes the same gains');
      expect(year.tax, greaterThan(0));
      expect(year.notes, isNotEmpty, reason: 'there is still room before the gains reach 15% federally');
    });

    test('ordinary headroom is the distance to the start of the band above', () {
      final salary = 100000.0;
      final year = taxYear(age: 2, salary: salary, budget: 0);

      expect(year.ordinary, salary, reason: 'salary alone is the ordinary income');
      expect(year.gains, 0);

      // The headroom is measured from the income the tax is computed on, which
      // is the adjusted gross income.
      final expected = expectHeadroom(year.agi, 0);
      expect(expected.ordinaryTaxable, greaterThan(0));
      expect(year.notes['Ordinary income to next federal bracket'], closeTo(expected.ordinaryHeadroom!, 0.01));
    });

    test('gains headroom counts income of either kind, since gains sit on top', () {
      // Retired, with Social Security underneath and a brokerage draw on top: the
      // gains bands are indexed against the top of the whole stack, so the
      // Social Security eats into the headroom.
      final year = taxYear(age: 67, salary: 0, budget: 60000, socialSecurityAge: 66, brokerage: 500000);

      expect(year.ordinary, greaterThan(0), reason: 'Social Security is taxable ordinary income');
      expect(year.gains, greaterThan(0), reason: 'the draw is taxed as gains');

      final expected = expectHeadroom(year.agi, year.gains);
      expect(expected.stackTop, lessThan(98900), reason: 'the stack must sit inside the 0% gains band for this to be its headroom');
      expect(expected.gainsHeadroom, isNotNull);
      expect(year.notes['Income to next capital gains bracket'], closeTo(expected.gainsHeadroom!, 0.01));
    });

    test('a part of the stack with nothing in it gets no note', () {
      // No gains drawn, so there is no gains band to be in. Ordinary income alone
      // still gets its note.
      final year = taxYear(age: 2, salary: 100000, budget: 0);

      expect(year.gains, 0);
      expect(year.notes.containsKey('Income to next capital gains bracket'), isFalse);
      expect(year.notes.containsKey('Ordinary income to next federal bracket'), isTrue);
    });

    test('the top bracket reports that it is the top rather than a headroom', () {
      // Past $768,700 of taxable income is the uncapped 37% band, which has
      // nothing above it. The salary has to clear it after the deductions and
      // the standard deduction come off.
      final year = taxYear(age: 2, salary: 900000, budget: 0);

      expect(year.agi, greaterThan(768700 + PlanConstants.standardDeduction));
      expect(year.bracket, 37);
      expect(year.notes.containsKey('Ordinary income to next federal bracket'), isFalse);
      expect(year.notes['Top federal bracket already'], isNull);
    });
  });
}

class _Zero implements DateTime {
  const _Zero();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.utc(2026, 1, 1);
}

const _zero = _Zero();