import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/calc/tax_calculator.dart';
import 'package:retirement_calculator/models/plan_constants.dart';

/// The taxable part of the Social Security benefit, per the worksheet in
/// Publication 915.
double taxable({required double benefit, double otherIncome = 0, double deductions = 0}) =>
    TaxCalculator.taxableSocialSecurity(benefit: benefit, otherIncome: otherIncome, deductions: deductions);

void main() {
  group('taxable social security', () {
    test('the worksheet examples from Publication 915', () {
      // Example 2: a joint return with a small benefit and enough other income
      // to reach the threshold, but no more.
      expect(taxable(benefit: 5600, otherIncome: 29750, deductions: 1000), 0, reason: 'none of the benefit is taxable');

      // Example 3: a joint return with a benefit and enough income to sit
      // above the second threshold, where part of the benefit is taxed.
      expect(taxable(benefit: 10000, otherIncome: 40500), 6275);
    });

    test('a benefit below the first threshold is untaxed', () {
      // The benefit alone puts the combined income under the threshold.
      expect(taxable(benefit: 40000), 0);
    });

    test('the income above the first threshold is taxed at half', () {
      // A benefit of 80,000 counts 40,000 toward the combined income, which is
      // 8,000 over the threshold: half of that is the taxable part, and the
      // band is narrow enough that none of it reaches the higher rate.
      expect(taxable(benefit: 80000), 4000);
    });

    test('the income above the second threshold is taxed at the maximum rate', () {
      // A benefit of 100,000 counts 50,000 toward the combined income, which is
      // 18,000 over the threshold: 12,000 of it at half and 6,000 at 85 percent.
      expect(taxable(benefit: 100000), 11100);
    });

    test('no more of the benefit is taxed than its maximum share', () {
      // A benefit of 10,000 with a great deal of income: the tax would exceed
      // 85 percent of the benefit, so it is capped there.
      expect(taxable(benefit: 10000, otherIncome: 500000), 8500);
    });

    test('the adjustments to income come off the combined income', () {
      // The same income with a deduction taken off it leaves the benefit
      // untaxed, where without the deduction it would not be.
      expect(taxable(benefit: 10000, otherIncome: 50000), greaterThan(0));
      expect(taxable(benefit: 10000, otherIncome: 50000, deductions: 30000), 0);
    });

    test('a benefit of nothing is taxed at nothing', () {
      expect(taxable(benefit: 0, otherIncome: 200000), 0);
    });

    test('the thresholds are the ones the worksheet uses', () {
      // Neither threshold is indexed for inflation, so they stay put.
      expect(PlanConstants.socialSecurityFirstThreshold, 32000);
      expect(PlanConstants.socialSecuritySecondThreshold, 44000);
    });
  });
}
