enum PaymentSource {
  cash('Cash'),
  brokerage('Brokerage'),
  traditionalIra('Traditional IRA'),
  rothIra('Roth IRA'),
  hsa('HSA');

  /// Human-readable name displayed in the plan controls.
  final String label;

  const PaymentSource(this.label);
}

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

  /* Contributions and conversions. */

  double? brokerageContributions;
  double? rothIraContributions;
  double? rothIraConversion;

  /* Payment source ordering. */

  List<PaymentSource>? payExpensesFrom;
  List<PaymentSource>? payTaxesFrom;

  /// The expected size of the tax filer's household, used to work out the
  /// federal poverty level the premium tax credit is measured against.
  int? familyMembers;

  PlanParameters({
    this.budget,
    this.medicalInsurance,
    this.premiumTaxCredits,
    this.medicare,
    this.inflationRate,
    this.baseSalary,
    this.bonusRate,
    this.employee401kContributionRate,
    this.employer401kContributionRate,
    this.cashGrowthRate,
    this.brokerageGrowthRate,
    this.fourOhOneKGrowthRate,
    this.traditionalIraGrowthRate,
    this.rothIraGrowthRate,
    this.hsaInvestmentThreshold,
    this.hsaGrowthRate,
    this.brokerageContributions,
    this.rothIraContributions,
    this.rothIraConversion,
    this.payExpensesFrom,
    this.payTaxesFrom,
    this.familyMembers,
  });

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
    brokerageContributions = 0;
    rothIraContributions = 0;
    rothIraConversion = 100000;
    payExpensesFrom = [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra, PaymentSource.cash, PaymentSource.hsa];
    payTaxesFrom = [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra, PaymentSource.cash, PaymentSource.hsa];
    familyMembers = 6;
  }

}

class PlanParametersMap {

  final int minAge;
  final Map<int, PlanParameters> _parametersMap = {};

  late int age;

  PlanParametersMap({required this.minAge, required PlanParameters initial, Map<int, PlanParameters>? initialMap}) {
    _parametersMap[minAge] = initial;
    initialMap?.forEach((age, parameters) {
      if (age >= minAge) {
        _parametersMap[age] = parameters;
      }
    });
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

  double getBrokerageContributions() => _walk((age) => _parametersMap[age]?.brokerageContributions);
  void setBrokerageContributions(double brokerageContributions) => _getParameters().brokerageContributions = brokerageContributions;

  double getRothIraContributions() => _walk((age) => _parametersMap[age]?.rothIraContributions);
  void setRothIraContributions(double rothIraContributions) => _getParameters().rothIraContributions = rothIraContributions;

  double getRothIraConversion() => _walk((age) => _parametersMap[age]?.rothIraConversion);
  void setRothIraConversion(double rothIraConversion) => _getParameters().rothIraConversion = rothIraConversion;

  List<PaymentSource>? getPayExpensesFrom() => _walk((age) => _parametersMap[age]?.payExpensesFrom);
  void setPayExpensesFrom(List<PaymentSource>? payExpensesFrom) => _getParameters().payExpensesFrom = payExpensesFrom;

  List<PaymentSource>? getPayTaxesFrom() => _walk((age) => _parametersMap[age]?.payTaxesFrom);
  void setPayTaxesFrom(List<PaymentSource>? payTaxesFrom) => _getParameters().payTaxesFrom = payTaxesFrom;

  int getFamilyMembers() => _walk((age) => _parametersMap[age]?.familyMembers);
  void setFamilyMembers(int familyMembers) => _getParameters().familyMembers = familyMembers;

}
