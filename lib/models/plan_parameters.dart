enum PaymentSource {
  cash('Cash'),
  brokerage('Brokerage'),
  traditionalIra('Traditional IRA'),
  rothIra('Roth IRA'),
  hsa('HSA');

  /// Human-readable name displayed in the plan controls.
  final String label;

  const PaymentSource(this.label);

  /// The source a saved plan names, or null when it names none.
  static PaymentSource? sourceFromName(String? name) {
    for (final source in PaymentSource.values) {
      if (source.name == name) return source;
    }
    return null;
  }
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

  /// The parameters as a plan file: each field named alongside its value, the
  /// payment sources named as they are saved, and the unset fields left null.
  Map<String, Object?> toJson() => <String, Object?>{
    'budget': budget,
    'medicalInsurance': medicalInsurance,
    'premiumTaxCredits': premiumTaxCredits,
    'medicare': medicare,
    'inflationRate': inflationRate,
    'baseSalary': baseSalary,
    'bonusRate': bonusRate,
    'employee401kContributionRate': employee401kContributionRate,
    'employer401kContributionRate': employer401kContributionRate,
    'cashGrowthRate': cashGrowthRate,
    'brokerageGrowthRate': brokerageGrowthRate,
    'fourOhOneKGrowthRate': fourOhOneKGrowthRate,
    'traditionalIraGrowthRate': traditionalIraGrowthRate,
    'rothIraGrowthRate': rothIraGrowthRate,
    'hsaInvestmentThreshold': hsaInvestmentThreshold,
    'hsaGrowthRate': hsaGrowthRate,
    'brokerageContributions': brokerageContributions,
    'rothIraContributions': rothIraContributions,
    'rothIraConversion': rothIraConversion,
    'payExpensesFrom': payExpensesFrom?.map((source) => source.name).toList(),
    'payTaxesFrom': payTaxesFrom?.map((source) => source.name).toList(),
    'familyMembers': familyMembers,
  };

  /// Rebuild from a plan file's [json]; fields left out or null are unset, and
  /// so inherit from the parameters of the ages below them.
  static PlanParameters fromJson(Map<String, Object?> json) {
    return PlanParameters(
      budget: (json['budget'] as num?)?.toDouble(),
      medicalInsurance: (json['medicalInsurance'] as num?)?.toDouble(),
      premiumTaxCredits: (json['premiumTaxCredits'] as num?)?.toDouble(),
      medicare: (json['medicare'] as num?)?.toDouble(),
      inflationRate: (json['inflationRate'] as num?)?.toDouble(),
      baseSalary: (json['baseSalary'] as num?)?.toDouble(),
      bonusRate: (json['bonusRate'] as num?)?.toDouble(),
      employee401kContributionRate: (json['employee401kContributionRate'] as num?)?.toDouble(),
      employer401kContributionRate: (json['employer401kContributionRate'] as num?)?.toDouble(),
      cashGrowthRate: (json['cashGrowthRate'] as num?)?.toDouble(),
      brokerageGrowthRate: (json['brokerageGrowthRate'] as num?)?.toDouble(),
      fourOhOneKGrowthRate: (json['fourOhOneKGrowthRate'] as num?)?.toDouble(),
      traditionalIraGrowthRate: (json['traditionalIraGrowthRate'] as num?)?.toDouble(),
      rothIraGrowthRate: (json['rothIraGrowthRate'] as num?)?.toDouble(),
      hsaInvestmentThreshold: (json['hsaInvestmentThreshold'] as num?)?.toDouble(),
      hsaGrowthRate: (json['hsaGrowthRate'] as num?)?.toDouble(),
      brokerageContributions: (json['brokerageContributions'] as num?)?.toDouble(),
      rothIraContributions: (json['rothIraContributions'] as num?)?.toDouble(),
      rothIraConversion: (json['rothIraConversion'] as num?)?.toDouble(),
      payExpensesFrom: _sourcesFromJson(json['payExpensesFrom']),
      payTaxesFrom: _sourcesFromJson(json['payTaxesFrom']),
      familyMembers: (json['familyMembers'] as num?)?.toInt(),
    );
  }

  /// The payment sources a saved source list names, in the order saved; names
  /// that name no source are dropped.
  static List<PaymentSource>? _sourcesFromJson(Object? value) {
    if (value is! List) return null;

    final sources = <PaymentSource>[];
    for (final entry in value) {
      final source = PaymentSource.sourceFromName(entry is String ? entry : null);
      if (source != null) sources.add(source);
    }
    return sources;
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

    // The age of the parameters being shown; the sidebar sets it to the
    // selected age, and a map built from a plan file starts at its first age.
    age = minAge;
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

  /// The parameters as a plan file: the first age alongside the parameters
  /// recorded for each age.
  Map<String, Object?> toJson() => <String, Object?>{
    'minAge': minAge,
    'parameters': <String, Object?>{
      for (final entry in _parametersMap.entries) '${entry.key}': entry.value.toJson(),
    },
  };

  /// Rebuild a plan parameters map from a plan file's [json].
  static PlanParametersMap fromJson(Map<String, Object?> json) {
    final minAge = (json['minAge'] as num?)?.toInt() ?? 0;
    final parameters = <int, PlanParameters>{};

    final savedParameters = json['parameters'];
    if (savedParameters is Map) {
      for (final entry in savedParameters.entries) {
        final age = int.parse(entry.key as String);
        if (age < minAge) continue;

        final saved = entry.value;
        if (saved is Map) {
          parameters[age] = PlanParameters.fromJson(Map<String, Object?>.from(saved.map((key, value) => MapEntry('$key', value))));
        }
      }
    }

    return PlanParametersMap(
      minAge: minAge,
      initial: parameters[minAge] ?? PlanParameters.withDefaults(),
      initialMap: parameters,
    );
  }

}
