class PlanParameters {
  int retirementAge = 60;
  int socialSecurityAge = 70;
  int spouseSocialSecurityAge = 67;
  double budget = 7500; // Per month.
  double medicalInsurance = 2871; // Per month.
  double premiumTaxCredits = 2224; // Per month.
  double medicare = 2 * 203; // Per month.
  double inflationRate = 0;
  double baseSalary = 170000;
  double employee401kContributionRate = 6;
  double employer401kContributionRate = 6;
  double bonusRate = 10;
  double brokerageGrowthRate = 5;
  double fourOhOneKGrowthRate = 8;
  double traditionalIraGrowthRate = 8;
  double rothIraGrowthRate = 8;
  List<int> downMarketAges = const [];
  double downMarketRate = -50;
  double brokerageContributions = 0;
  double rothIraContributions = 0;
  double hsaInvestmentThreshold = 2500;
  double hsaGrowthRate = 4;
  int rothIraConversionAge = 60;
  double rothIraConversion = 80000;
}
