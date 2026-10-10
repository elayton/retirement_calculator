class PlanParameters {
  final int retirementAge = 60;
  final int socialSecurityAge = 70;
  final int spouseSocialSecurityAge = 67;
  final double budget = 7500; // Per month.
  final double medicalInsuranceExpenses = 2871; // Per month.
  final double premiumTaxCredits = 2224; // Per month.
  final double medicareExpenses = 2 * 203; // Per month.
  final double inflationRate = 0;
  final double baseSalary = 170000;
  final double employee401kContributionRate = 6;
  final double employer401kContributionRate = 6;
  final double bonusRate = 10;
  final double brokerageGrowthRate = 5;
  final double fourOhOneKGrowthRate = 8;
  final double traditionalIraGrowthRate = 8;
  final double rothIraGrowthRate = 8;
  final List<int> downMarketAges = const [];
  final double downMarketRate = -50;
  final double brokerageContributions = 0;
  final double rothIraContributions = 0;
  final double hsaInvestmentThreshold = 2500;
  final double hsaGrowthRate = 4;
  final int rothIraConversionAge = 60;
  final double rothIraConversion = 80000;

  const PlanParameters();
}
