abstract final class PlanConstants {
  static final birthday = DateTime(1971, 12, 3);
  static const int longevityAge = 100;

  static const int fourOhOneKWthdrawalAge = 55;
  static const int iraWithdrawalAge = 60;
  static const int medicareStartAge = 65;
  static const int rmdStartAge = 75;

  /// The life-expectancy divisor the required minimum distribution is divided
  /// by: the account balance stretched over that many years, a simplified
  /// single life allowance.
  static const double rmdDistributionPeriod = 25;

  static const double iraContributionLimit = 8600;
  static const double hsaContributionLimit = 9750;

  static const double standardDeduction = 32200;

  /// Each entry is a (threshold, rate %) pair; a null threshold means no cap.
  static const ordinaryIncomeTaxBrackets = <(double?, double)>[(24800, 10), (100800, 12), (211400, 22), (403550, 24), (512450, 32), (768700, 35), (null, 37)];

  /// Long-term capital gains brackets, shaped like
  /// [ordinaryIncomeTaxBrackets] and stacked above ordinary income.
  static const capitalGainsTaxBrackets = <(double?, double)>[(98900, 0), (613700, 15), (null, 20)];

  /// Utah taxes all income, gains included, at one rate. It has no deduction of
  /// its own, so the federal [standardDeduction] applies.
  static const stateIncomeTaxBrackets = <(double?, double)>[(null, 4.45)];

  /// Approximate marginal federal long-term capital gains rate used when
  /// grossing up a brokerage withdrawal that pays tax.
  static const double federalCapitalGainsRate = 15;

  /// Utah's flat income tax rate, used when grossing up a taxable withdrawal.
  static const double stateRate = 4.45;

  static const socialSecurityBenefitByAge = <int, double>{62: 2860, 63: 3071, 64: 3295, 65: 3581, 66: 3868, 67: 4156, 68: 4195, 69: 4540, 70: 5192};

  /// The Social Security income thresholds. The benefit is untaxed below the
  /// first and taxed at the maximum rate above the second. Neither is indexed
  /// for inflation, so they stay where they are.
  static const double socialSecurityFirstThreshold = 32000;
  static const double socialSecuritySecondThreshold = 44000;

  /// Half the Social Security benefit counts toward the combined income the
  /// thresholds are measured against, and the income above the first threshold
  /// is taxed at half.
  static const double socialSecurityHalfPercentage = 50;

  /// The share of the Social Security benefit that can be taxed, and the rate
  /// the income above the second threshold is taxed at.
  static const double socialSecurityMaximumTaxablePercentage = 85;

  static const int familyMembers = 6;

  /// The federal poverty guidelines, which the premium tax credit is measured
  /// against. They move with the years, so they will need scaling with the
  /// inflation like the tax rules do.
  ///
  /// The base is the guideline for a one-person household less one person's
  /// share, so a household of [familyMembers] is the base plus that many
  /// shares.
  static const double federalPovertyLevelBase = 10280;
  static const double federalPovertyLevelPerPerson = 5680;

  /// The federal poverty level for the household.
  static double get federalPovertyLevel => federalPovertyLevelBase + federalPovertyLevelPerPerson * familyMembers;
}
