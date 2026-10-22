import '../models/plan_constants.dart';

/// The tax rules of one year: the standard deduction and the two sets of
/// bracket thresholds.
///
/// The amounts are indexed for inflation, so the rules of a later year are
/// worth more than the ones they were written as.  The rates are not, and
/// neither are the Social Security thresholds, which the law has left where
/// they are.
class TaxRules {
  final double standardDeduction;
  final List<(double?, double)> ordinaryIncomeBrackets;
  final List<(double?, double)> capitalGainsTaxBrackets;

  const TaxRules({required this.standardDeduction, required this.ordinaryIncomeBrackets, required this.capitalGainsTaxBrackets});

  /// The rules of a year [inflation] years on, with the indexed amounts scaled
  /// to match.
  factory TaxRules.indexed(double inflation) => TaxRules(
    standardDeduction: PlanConstants.standardDeduction * inflation,
    ordinaryIncomeBrackets: _scale(PlanConstants.ordinaryIncomeTaxBrackets, inflation),
    capitalGainsTaxBrackets: _scale(PlanConstants.capitalGainsTaxBrackets, inflation),
  );

  /// The bracket thresholds scaled by [inflation]. A null threshold is the
  /// uncapped top band, and stays null.
  static List<(double?, double)> _scale(List<(double?, double)> brackets, double inflation) => [
    for (final (threshold, rate) in brackets) (threshold == null ? null : threshold * inflation, rate),
  ];
}
