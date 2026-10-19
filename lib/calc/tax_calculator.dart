import 'dart:math';

import '../models/plan_constants.dart';
import '../models/plan_models.dart';

/// Federal and Utah income tax on a year of income. The federal return is
/// progressive and stacks capital gains above ordinary income, so a gain can
/// land in a lower band than wages do; Utah taxes the whole stack at one rate.
abstract final class TaxCalculator {
  /// [rate] percent of [amount].
  static double _percentageOf(double amount, double rate) => amount * rate / 100;

  /// The three layers of a year's taxable income: the standard deduction
  /// shelters the bottom, then ordinary income, then gains.
  static ({double ordinaryTaxable, double gainsTaxable, double stackTop}) _stack(double ordinaryIncome, double capitalGains) {
    final ordinaryTaxable = max(0.0, ordinaryIncome - PlanConstants.standardDeduction);
    final totalTaxable = max(0.0, ordinaryIncome + capitalGains - PlanConstants.standardDeduction);

    return (ordinaryTaxable: ordinaryTaxable, gainsTaxable: totalTaxable - ordinaryTaxable, stackTop: totalTaxable);
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

  /// Federal income tax on [ordinaryIncome] and [capitalGains], with the topmost
  /// marginal rate reached. Gains occupy whatever room ordinary income left.
  static ({double tax, double topRate}) federal(double ordinaryIncome, double capitalGains) {
    final stack = _stack(ordinaryIncome, capitalGains);

    final (ordinaryTax, ordinaryTopRate) = _walk(stack.ordinaryTaxable, PlanConstants.ordinaryIncomeTaxBrackets);

    // The gains bands are indexed against the top of the whole stack, so a band
    // ordinary income has already reached past must still advance the bound.
    var gainsTax = 0.0;
    var gainsTopRate = 0.0;
    var lowerBound = stack.ordinaryTaxable;

    for (final (upperBound, rate) in PlanConstants.capitalGainsTaxBrackets) {
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
  /// its own: it conforms to the federal [standardDeduction].
  static double state(double ordinaryIncome, double capitalGains) {
    final taxable = max(0.0, ordinaryIncome + capitalGains - PlanConstants.standardDeduction);

    return _walk(taxable, PlanConstants.stateIncomeTaxBrackets).$1;
  }

  /// Record [ordinaryIncome] and [capitalGains] against [totals]: the tax as the
  /// column's total, its two parts as the lines above it, and the headroom to
  /// the next federal band as notes.
  static void record(PlanTotals totals, double ordinaryIncome, double capitalGains) {
    final federalTax = federal(ordinaryIncome, capitalGains);
    final stateTax = state(ordinaryIncome, capitalGains);

    totals.tax = federalTax.tax + stateTax;
    totals.taxBracket = federalTax.topRate;

    if (federalTax.tax > 0) totals.add(PlanColumn.tax, "Federal Tax", federalTax.tax);
    if (stateTax > 0) totals.add(PlanColumn.tax, "Utah Tax", stateTax);

    _noteHeadroom(totals, ordinaryIncome, capitalGains);
  }

  /// How much further [position] could go before the band above it starts, or
  /// null in the uncapped top band, which has nothing above it.
  static double? _headroomToNextBand(double position, List<(double?, double)> brackets) {
    if (position <= 0) return null;

    for (final (upperBound, _) in brackets) {
      if (upperBound == null) return null;
      if (position < upperBound) return upperBound - position;
    }

    return null;
  }

  /// Whether [position] has reached the uncapped top band, where there is no
  /// further headroom to report.
  static bool _inTopBand(double position, List<(double?, double)> brackets) {
    if (position <= 0) return false;

    var lower = 0.0;
    for (final (upperBound, _) in brackets) {
      if (upperBound == null) return position >= lower;
      lower = upperBound;
    }

    return false;
  }

  /// Note how much further each layer of the federal stack could go before the
  /// band above it starts. Gains sit on top of the whole stack, so either kind
  /// of income counts toward them; a layer with nothing in it gets no note.
  static void _noteHeadroom(PlanTotals totals, double ordinaryIncome, double capitalGains) {
    final stack = _stack(ordinaryIncome, capitalGains);

    void note(List<(double?, double)> brackets, double position, String description, String atTopDescription) {
      if (position <= 0) return;

      final headroom = _headroomToNextBand(position, brackets);
      if (headroom != null) {
        totals.note(PlanColumn.tax, description, headroom);
      } else if (_inTopBand(position, brackets)) {
        totals.note(PlanColumn.tax, atTopDescription);
      }
    }

    note(PlanConstants.ordinaryIncomeTaxBrackets, stack.ordinaryTaxable, 'Ordinary income to next federal bracket', 'Top federal bracket already');
    note(
      PlanConstants.capitalGainsTaxBrackets,
      stack.gainsTaxable > 0 ? stack.stackTop : 0,
      'Income to next capital gains bracket',
      'Top capital gains bracket already',
    );
  }
}
