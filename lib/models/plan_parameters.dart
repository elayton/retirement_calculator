class PlanParameters {
  int retirementAge = 60;
  int primarySocialSecurityAge = 70;
  int secondarySocialSecurityAge = 67;
  int rothIraConversionAge = 65;
  List<int> downMarketAges = const [];
  double budget = 7500; // Per month.
  double medicalInsurance = 2871; // Per month.
  double premiumTaxCredits = 2224; // Per month.
  double medicare = 2 * 203; // Per month.
  /// The expected annual rate of inflation. Every nominal amount moves with
  /// it, and so do the tax rules that are indexed for inflation.
  double inflationRate = 0;
  double baseSalary = 170000;
  double bonusRate = 10;
  double employee401kContributionRate = 6;
  double employer401kContributionRate = 3;
  double cashGrowthRate = 1;
  double brokerageAverageCostBasis = 240640.45;
  double brokerageGrowthRate = 5;
  double fourOhOneKGrowthRate = 8;
  double traditionalIraGrowthRate = 8;
  double rothIraGrowthRate = 8;
  double hsaInvestmentThreshold = 2500;
  double hsaGrowthRate = 4;
  double downMarketRate = -50;
  double brokerageContributions = 0;
  double rothIraContributions = 0;
  double rothIraConversion = 100000;
  bool payTaxesFromRothIra = true;
}
