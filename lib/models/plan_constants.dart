abstract final class PlanConstants {
  static final birthday = DateTime(1971, 12, 3);
  static const longevityAge = 100;

  static const iraWithdrawalAge = 60;
  static const medicareStartAge = 65;

  static const iraContributionLimit = 8600;
  static const hsaContributionLimit = 9750;

  static const standardDeduction = 32200;

  /// Each entry is a (threshold, rate %) pair; a null threshold means no cap.
  static const taxBrackets = <(int?, int)>[(24800, 10), (100800, 12), (211400, 22), (403550, 24), (512450, 32), (768700, 35), (null, 37)];

  static const capitalGainsTaxRate = 15;

  static const socialSecurityBenefitByAge = <int, int>{62: 2860, 63: 3071, 64: 3295, 65: 3581, 66: 3868, 67: 4156, 68: 4195, 69: 4540, 70: 5192};

  static const socialSecurityTaxablePercentage = 85;

  static const familyMembers = 6;
  static const federalPovertyLevelBase = 10280;
  static const federalPovertyLevelPerPerson = 5680;
}
