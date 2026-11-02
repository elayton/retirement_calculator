class PlanParameters {

  /* Expenses. */

  double? budget; // Per month.
  double? medicalInsurance; // Per month.
  double? premiumTaxCredits; // Per month.
  double? medicare; // Per month.

  /// The expected annual rate of inflation.
  double? inflationRate;
  
  /* Income. */

  double? baseSalary;
  double? bonusRate;
  double? employee401kContributionRate;
  double? employer401kContributionRate;

  /* Investment growth rates. */

  double? cashGrowthRate;
  double? brokerageGrowthRate;
  double? fourOhOneKGrowthRate;
  double? traditionalIraGrowthRate;
  double? rothIraGrowthRate;
  double? hsaInvestmentThreshold;
  double? hsaGrowthRate;
  double? downMarketRate;
  double? traditionalIraTaxRate;

  /* Contributions and conversions. */

  double? brokerageContributions;
  double? rothIraContributions;
  double? rothIraConversion;

  /* Tax payment ordering. */

  bool? payTaxesFromBrokerage;
  bool? payTaxesFromTraditionalIra;
  bool? payTaxesFromRothIra;

  /// The expected size of the tax filer's household, used to work out the
  /// federal poverty level the premium tax credit is measured against.
  int? familyMembers;

  PlanParameters();

  PlanParameters.withDefaults() {
    budget = 7500;
    medicalInsurance = 2871;
    premiumTaxCredits = 2224;
    medicare = 2 * 203;
    inflationRate = 0;
    baseSalary = 170000;
    bonusRate = 10;
    employee401kContributionRate = 6;
    employer401kContributionRate = 3;
    cashGrowthRate = 1;
    brokerageGrowthRate = 5;
    fourOhOneKGrowthRate = 8;
    traditionalIraGrowthRate = 8;
    rothIraGrowthRate = 8;
    hsaInvestmentThreshold = 2500;
    hsaGrowthRate = 4;
    downMarketRate = -50;
    traditionalIraTaxRate = 22;
    brokerageContributions = 0;
    rothIraContributions = 0;
    rothIraConversion = 100000;
    payTaxesFromBrokerage = false;
    payTaxesFromTraditionalIra = false;
    payTaxesFromRothIra = true;
    familyMembers = 6;
  }

}

class PlanParametersMap {

  final int minAge;
  final Map<int, PlanParameters> _parametersMap = {};

  late int age;

  PlanParametersMap({required this.minAge, required PlanParameters initial}) {
    _parametersMap[minAge] = initial;
  }

  dynamic _walk(dynamic Function(int age) func) {
    for (int a = age; a >= minAge; --a) {
      final field = func(a);
      if (field != null) return field;
    }
  }

  PlanParameters _getParameters() => _parametersMap.putIfAbsent(age, () => PlanParameters());

  /// The parameters recorded for [age]; an unset set when none were saved for it.
  PlanParameters parametersFor(int age) => _parametersMap[age] ?? PlanParameters();

  double getBudget() => _walk((age) => _parametersMap[age]?.budget) as double;
  void setBudget(double budget) => _getParameters().budget = budget;

  double getMedicalInsurance() => _walk((age) => _parametersMap[age]?.medicalInsurance);
  void setMedicalInsurance(double medicalInsurance) => _getParameters().medicalInsurance = medicalInsurance;

  double getPremiumTaxCredits() => _walk((age) => _parametersMap[age]?.premiumTaxCredits);
  void setPremiumTaxCredits(double premiumTaxCredits) => _getParameters().premiumTaxCredits = premiumTaxCredits;

  double getMedicare() => _walk((age) => _parametersMap[age]?.medicare);
  void setMedicare(double medicare) => _getParameters().medicare = medicare;

  double getInflationRate() => _walk((age) => _parametersMap[age]?.inflationRate);
  void setInflationRate(double inflationRate) => _getParameters().inflationRate = inflationRate;

  double getBaseSalary() => _walk((age) => _parametersMap[age]?.baseSalary);
  void setBaseSalary(double baseSalary) => _getParameters().baseSalary = baseSalary;

  double getBonusRate() => _walk((age) => _parametersMap[age]?.bonusRate);
  void setBonusRate(double bonusRate) => _getParameters().bonusRate = bonusRate;

  double getEmployee401kContributionRate() => _walk((age) => _parametersMap[age]?.employee401kContributionRate);
  void setEmployee401kContributionRate(double employee401kContributionRate) => _getParameters().employee401kContributionRate = employee401kContributionRate;

  double getEmployer401kContributionRate() => _walk((age) => _parametersMap[age]?.employer401kContributionRate);
  void setEmployer401kContributionRate(double employer401kContributionRate) => _getParameters().employer401kContributionRate = employer401kContributionRate;

  double getCashGrowthRate() => _walk((age) => _parametersMap[age]?.cashGrowthRate);
  void setCashGrowthRate(double cashGrowthRate) => _getParameters().cashGrowthRate = cashGrowthRate;

  double getBrokerageGrowthRate() => _walk((age) => _parametersMap[age]?.brokerageGrowthRate);
  void setBrokerageGrowthRate(double brokerageGrowthRate) => _getParameters().brokerageGrowthRate = brokerageGrowthRate;

  double getFourOhOneKGrowthRate() => _walk((age) => _parametersMap[age]?.fourOhOneKGrowthRate);
  void setFourOhOneKGrowthRate(double fourOhoneKGrowthRate) => _getParameters().fourOhOneKGrowthRate = fourOhoneKGrowthRate;

  double getTraditionalIraGrowthRate() => _walk((age) => _parametersMap[age]?.traditionalIraGrowthRate);
  void setTraditionalIraGrowthRate(double traditionalIraGrowthRate) => _getParameters().traditionalIraGrowthRate = traditionalIraGrowthRate;

  double getRothIraGrowthRate() => _walk((age) => _parametersMap[age]?.rothIraGrowthRate);
  void setRothIraGrowthRate(double rothIraGrowthRate) => _getParameters().rothIraGrowthRate = rothIraGrowthRate;

  double getHsaInvestmentThreshold() => _walk((age) => _parametersMap[age]?.hsaInvestmentThreshold);
  void setHsaInvestmentThreshold(double hsaInvestmentThreshold) => _getParameters().hsaInvestmentThreshold = hsaInvestmentThreshold;

  double getHsaGrowthRate() => _walk((age) => _parametersMap[age]?.hsaGrowthRate);
  void setHsaGrowthRate(double hsaGrowthRate) => _getParameters().hsaGrowthRate = hsaGrowthRate;

  double getDownMarketRate() => _walk((age) => _parametersMap[age]?.downMarketRate);
  void setDownMarketRate(double downMarketRate) => _getParameters().downMarketRate = downMarketRate;

  double getTraditionalIraTaxRate() => _walk((age) => _parametersMap[age]?.traditionalIraTaxRate);
  void setTraditionalIraTaxRate(double traditionalIraTaxRate) => _getParameters().traditionalIraTaxRate = traditionalIraTaxRate;

  double getBrokerageContributions() => _walk((age) => _parametersMap[age]?.brokerageContributions);
  void setBrokerageContributions(double brokerageContributions) => _getParameters().brokerageContributions = brokerageContributions;

  double getRothIraContributions() => _walk((age) => _parametersMap[age]?.rothIraContributions);
  void setRothIraContributions(double rothIraContributions) => _getParameters().rothIraContributions = rothIraContributions;

  double getRothIraConversion() => _walk((age) => _parametersMap[age]?.rothIraConversion);
  void setRothIraConversion(double rothIraConversion) => _getParameters().rothIraConversion = rothIraConversion;

  bool getPayTaxesFromBrokerage() => _walk((age) => _parametersMap[age]?.payTaxesFromBrokerage);
  void setPayTaxesFromBrokerage(bool payTaxesFromBrokerage) => _getParameters().payTaxesFromBrokerage = payTaxesFromBrokerage;

  bool getPayTaxesFromTraditionalIra() => _walk((age) => _parametersMap[age]?.payTaxesFromTraditionalIra);
  void setPayTaxesFromTraditionalIra(bool payTaxesFromTraditionalIra) => _getParameters().payTaxesFromTraditionalIra = payTaxesFromTraditionalIra;

  bool getPayTaxesFromRothIra() => _walk((age) => _parametersMap[age]?.payTaxesFromRothIra);
  void setPayTaxesFromRothIra(bool payTaxesFromRothIra) => _getParameters().payTaxesFromRothIra = payTaxesFromRothIra;

  int getFamilyMembers() => _walk((age) => _parametersMap[age]?.familyMembers);
  void setFamilyMembers(int familyMembers) => _getParameters().familyMembers = familyMembers;

}
