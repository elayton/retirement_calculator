import 'dart:math';

import '../models/plan_constants.dart';
import 'tax_rules.dart';

/// Federal and Utah income tax on a year of income. The federal return is
/// progressive and stacks capital gains above ordinary income, so a gain can
/// land in a lower band than wages do; Utah taxes the whole stack at one rate.
abstract final class TaxCalculator {
  /// [rate] percent of [amount].
  static double _percentageOf(double amount, double rate) => amount * rate / 100;

  /// The three layers of a year's taxable income: the standard deduction
  /// shelters the bottom, then ordinary income, then gains.
  static ({double ordinaryTaxable, double gainsTaxable, double stackTop}) stack(TaxRules rules, double agi, double capitalGains) {
    final ordinaryTaxable = max(0.0, agi - rules.standardDeduction);
    final totalTaxable = max(0.0, agi + capitalGains - rules.standardDeduction);

    return (ordinaryTaxable: ordinaryTaxable, gainsTaxable: totalTaxable - ordinaryTaxable, stackTop: totalTaxable);
  }

  /// The taxable part of the Social Security benefits, per the worksheet in
  /// Publication 915.
  ///
  /// The benefit is taxed in proportion to the income around it: none of it
  /// below the first threshold, half of the income above it, and the maximum
  /// rate on the rest, up to the maximum share of the benefit.
  ///
  /// [otherIncome] is the income the year brought besides the benefit, and
  /// [deductions] the adjustments to income taken off it.
  static double taxableSocialSecurity({required double benefit, required double otherIncome, required double deductions}) {
    // Half the benefit counts toward the combined income the thresholds are
    // measured against, and the adjustments to income come off that.
    final combined = _percentageOf(benefit, PlanConstants.socialSecurityHalfPercentage) + otherIncome - deductions;

    // Below the first threshold none of the benefit is taxed.
    final excess = combined - PlanConstants.socialSecurityFirstThreshold;
    if (excess <= 0) return 0;

    // The band between the thresholds is taxed at half, and the income above
    // the second threshold at the maximum rate.
    final width = PlanConstants.socialSecuritySecondThreshold - PlanConstants.socialSecurityFirstThreshold;

    final middle = min(
      _percentageOf(min(excess, width), PlanConstants.socialSecurityHalfPercentage),
      _percentageOf(benefit, PlanConstants.socialSecurityHalfPercentage),
    );

    final above = excess - width;
    final top = above <= 0 ? 0.0 : _percentageOf(above, PlanConstants.socialSecurityMaximumTaxablePercentage);

    // No more of the benefit can be taxed than its maximum share.
    return min(middle + top, _percentageOf(benefit, PlanConstants.socialSecurityMaximumTaxablePercentage));
  }

  /// Tax on [taxable] walked up through [brackets] (upper bound, rate %) pairs,
  /// with the topmost rate reached. A null bound is the uncapped top band.
  static (double tax, double topRate) _walk(double taxable, List<(double?, double)> brackets) {
    var tax = 0.0;
    var topRate = 0.0;
    var lowerBound = 0.0;

    for (final (upperBound, rate) in brackets) {
      // Income has run out before this band starts.
      if (taxable <= lowerBound) break;

      final upper = upperBound ?? taxable;
      tax += _percentageOf(min(taxable, upper) - lowerBound, rate);
      topRate = max(topRate, rate);

      // The uncapped top band closes the walk.
      if (upperBound == null) break;

      lowerBound = upperBound;
    }

    return (tax, topRate);
  }

  /// Federal income tax on [agi] and [capitalGains], with the topmost
  /// marginal rate reached. Gains occupy whatever room ordinary income left.
  ///
  /// The layers of taxable income come in as [stack], so the caller can hand
  /// over one already worked out for the year's income rather than recompute
  /// it.
  static ({double tax, double topRate}) federal(TaxRules rules, double agi, double capitalGains, ({double ordinaryTaxable, double gainsTaxable, double stackTop}) stack) {
    final (ordinaryTax, ordinaryTopRate) = _walk(stack.ordinaryTaxable, rules.ordinaryIncomeBrackets);

    // The gains bands are indexed against the top of the whole stack, so a band
    // ordinary income has already reached past must still advance the bound.
    var gainsTax = 0.0;
    var gainsTopRate = 0.0;
    var lowerBound = stack.ordinaryTaxable;

    for (final (upperBound, rate) in rules.capitalGainsTaxBrackets) {
      if (stack.stackTop <= lowerBound) break;

      final upper = upperBound ?? stack.stackTop;

      if (upper > lowerBound) {
        gainsTax += _percentageOf(min(stack.stackTop, upper) - lowerBound, rate);
        gainsTopRate = max(gainsTopRate, rate);
        lowerBound = upper;
      }

      if (upperBound == null) break;
    }

    return (tax: ordinaryTax + gainsTax, topRate: max(ordinaryTopRate, gainsTopRate));
  }

  /// Utah taxes all income, gains included, at one rate. It has no deduction of
  /// its own: it conforms to the federal [standardDeduction]. It taxes the
  /// Social Security benefit as the federal return does, though it allows a
  /// credit for it that the plan does not model.
  static double state(TaxRules rules, double agi, double capitalGains) {
    final taxable = max(0.0, agi + capitalGains - rules.standardDeduction);

    return _walk(taxable, PlanConstants.stateIncomeTaxBrackets).$1;
  }

  /// The year's modified adjusted gross income, the figure the premium tax
  /// credit turns on.
  ///
  /// The premium tax credit counts the whole Social Security benefit: the
  /// taxable part of it is in the ordinary income already, and the tax-exempt
  /// part is added back here. It counts neither the pre-tax 401(k)
  /// contribution nor the HSA deduction, so the deductions the model's income
  /// is gross of come back out. A deductible traditional IRA contribution
  /// would come out the same way, but the plan makes none: moving money from
  /// the 401(k) into the IRA is a transfer, not a contribution.
  static double magi({
    required double ordinaryIncome,
    required double capitalGains,
    required double agiDeductions,
    required double taxExemptSocialSecurity,
  }) =>
      ordinaryIncome + capitalGains - agiDeductions + taxExemptSocialSecurity;

}
