abstract final class PlanConstants {
  static final birthday = DateTime(1971, 12, 3);
  static const int longevityAge = 100;

  static const int fourOhOneKWthdrawalAge = 55;
  static const int iraWithdrawalAge = 60;
  static const int medicareStartAge = 65;

  /// The Uniform Lifetime Table's life expectancy factors by account owner's
  /// age, as published by Fidelity: the number of years the account balance is
  /// stretched over when the required minimum distribution is divided from it,
  /// a simplified single life allowance.
  ///
  /// The factor is read off the table for the age the owner turns in the year
  /// the distribution is taken, so the required minimum distribution is the
  /// balance divided by the factor for that year, and not by one fixed
  /// allowance.
  ///
  /// Source: Fidelity's Uniform Lifetime Table,
  /// https://www.fidelity.com/bin-public/060_www_fidelity_com/documents/UniformLifetimeTable.pdf
  static const Map<int, double> uniformLifetimeFactors = <int, double>{
    75: 24.6,
    76: 23.7,
    77: 22.9,
    78: 22.0,
    79: 21.1,
    80: 20.2,
    81: 19.4,
    82: 18.5,
    83: 17.7,
    84: 16.8,
    85: 16.0,
    86: 15.2,
    87: 14.4,
    88: 13.7,
    89: 12.9,
    90: 12.2,
    91: 11.5,
    92: 10.8,
    93: 10.1,
    94: 9.5,
    95: 8.9,
    96: 8.4,
    97: 7.8,
    98: 7.3,
    99: 6.8,
    100: 6.4,
    101: 6.0,
    102: 5.6,
    103: 5.2,
    104: 4.9,
    105: 4.6,
    106: 4.3,
    107: 4.1,
    108: 3.9,
    109: 3.7,
    110: 3.5,
    111: 3.4,
    112: 3.3,
    113: 3.1,
    114: 3.0,
    115: 2.9,
    116: 2.8,
    117: 2.7,
    118: 2.5,
    119: 2.3,
    120: 2.0,
  };

  /// The life-expectancy factor the required minimum distribution is divided
  /// by for an account owner of [age]: the account balance stretched over that
  /// many years, per the Uniform Lifetime Table.
  ///
  /// Returns null when the table has no factor for [age], in which case no
  /// required minimum distribution is worked out.
  static double? rmdFactorFor(int age) => uniformLifetimeFactors[age];

  /// The first age the Uniform Lifetime Table covers, and so the first at
  /// which a required minimum distribution is worked out.
  static int get firstRmdAge => uniformLifetimeFactors.keys.first;

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
