abstract final class PlanConstants {
  static final birthday = DateTime(1971, 12, 3);
  static const int longevityAge = 100;

  static const int fourOhOneKWthdrawalAge = 55;
  static const int iraWithdrawalAge = 60;
  static const int medicareStartAge = 65;
  static const int rmdStartAge = 75;

  static const double iraContributionLimit = 8600;
  static const double hsaContributionLimit = 9750;

  static const double standardDeduction = 32200;

  /// Each entry is a (threshold, rate %) pair; a null threshold means no cap.
  static const taxBrackets = <(double?, double)>[(24800, 10), (100800, 12), (211400, 22), (403550, 24), (512450, 32), (768700, 35), (null, 37)];

  static const double capitalGainsTaxRate = 15;

  static const socialSecurityBenefitByAge = <int, double>{62: 2860, 63: 3071, 64: 3295, 65: 3581, 66: 3868, 67: 4156, 68: 4195, 69: 4540, 70: 5192};

  static const double socialSecurityTaxablePercentage = 85;

  static const int familyMembers = 6;
  static const double federalPovertyLevelBase = 10280;
  static const double federalPovertyLevelPerPerson = 5680;
}
