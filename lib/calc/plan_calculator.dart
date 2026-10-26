import 'dart:math';

import '../models/plan_models.dart';
import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';
import 'tax_calculator.dart';
import 'tax_rules.dart';

/// Calculate successive rows of projected account totals by age.
class PlanCalculator {
  final DateTime portfolioDate;
  final PlanParameters parameters;
  late PlanTotals last;

  int? age;
  PlanTotals? next;

  /// Number of iteration steps completed so far.
  int _iteration = 0;

  /// The factor the year's nominal amounts are scaled by: the inflation rate
  /// compounded over the years the projection has run.
  double _inflation = 1;

  /// What one year of inflation is worth.
  double get _inflationYear => 1 + parameters.inflationRate / 100;

  /// The cost basis remaining in the brokerage account, tracked as withdrawals
  /// are taken so the ratio of gain to withdrawal stays honest across years.
  double _brokerageCostBasis = 0;

  /// The total tax paid from accounts this year, used to work out what remains
  /// unpaid after a taxable withdrawal.
  double _taxPaidThisYear = 0;

  /// The tax rules of the current year, retained so a taxable withdrawal can
  /// recompute the tax without re-recording it.
  TaxRules _taxRules = TaxRules.indexed(1);

  /// Begin a projection from [totals], copied into the shape the per-year steps
  /// read and add to.
  PlanCalculator({required this.portfolioDate, required this.parameters, required PlanTotals totals}) {
    last = PlanTotals.fromPlanTotals(totals);
    _brokerageCostBasis = parameters.brokerageAverageCostBasis;
  }

  /// [rate] percent of [amount].
  double _percentageOf(double amount, double rate) => amount * rate / 100;

  /// Scale [amount] to the share of the export year still to come, so a
  /// portfolio exported in June does not project a whole year at once.
  double _prorate(double amount) {
    if (_iteration > 0) return amount;

    final date = portfolioDate;

    final startOfYear = DateTime.utc(date.year);
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(startOfYear).inDays;
    final endOfYear = DateTime.utc(date.year, 12, 31);
    final daysLeftInYear = endOfYear.difference(startOfYear).inDays - dayOfYear;

    return amount * daysLeftInYear / 365;
  }

  /// [monthly] as an annual figure.
  double _monthlyToAnnual(double monthly) => monthly * 12;

  /// Strictly after the retirement age, so the year that reaches it still
  /// counts as working.
  bool _isAfterRetirementAge() => age! > parameters.retirementAge;

  bool _isAfterIraWithdrawalAge() => age! > PlanConstants.iraWithdrawalAge;

  /// Whether Medicare has taken over from private health insurance.
  bool _isAfterMedicareAge() => age! > PlanConstants.medicareStartAge;

  /// Whether the MAGI is worth working out this year: the years after
  /// retirement, up to and including the year Medicare takes over.
  ///
  /// The MAGI is the figure the premium tax credit turns on, so it is only of
  /// interest once the salary has stopped and private insurance is still being
  /// bought, and in the year Medicare takes over.
  bool _isMagiYear() => _isAfterRetirementAge() && !_isAfterMedicareAge();

  bool _isAfterRothConversionAge() => age! > parameters.rothIraConversionAge;

  /// Whether primary Social Security has started.
  bool _isAfterPrimarySocialSecurityAge() => age! > parameters.primarySocialSecurityAge;

  /// Whether secondary Social Security has started.
  bool _isAfterSecondarySocialSecurityAge() => age! > parameters.secondarySocialSecurityAge;

  /// Money going out over the year, and only once retired: the budget plus
  /// whichever health insurance applies, less any premium tax credits, plus
  /// the bill for last year's taxes.
  void _setExpenses() {
    if (_isAfterRetirementAge()) {
      final budget = _monthlyToAnnual(parameters.budget) * _inflation;
      next!.add(PlanColumn.expenses, "Budget", budget);

      if (_isAfterMedicareAge()) {
        final medicare = _monthlyToAnnual(parameters.medicare) * _inflation;
        next!.add(PlanColumn.expenses, "Medicare", medicare);

      } else {
        final medicalInsurance = _monthlyToAnnual(parameters.medicalInsurance) * _inflation;
        next!.add(PlanColumn.expenses, "Medical Insurance", medicalInsurance);

        final premiumTaxCredits = _monthlyToAnnual(parameters.premiumTaxCredits) * _inflation;
        next!.sub(PlanColumn.expenses, "Premium Tax Credits", premiumTaxCredits);

        // The credits received this year are the ones that have to be paid
        // back if the year's income turns out to be too high.
        next!.premiumTaxCredits = premiumTaxCredits;
      }

      // The premium tax credits received last year have to be paid back when
      // last year's income passed above four times the poverty level. The bill
      // comes with last year's taxes, and is worth a year's inflation by the
      // time it is paid.
      final repayment = last.premiumTaxCreditRepayment * _inflationYear;
      if (repayment > 0) {
        next!.add(PlanColumn.expenses, "Premium Tax Credit Repayment", repayment);
      }
    }

    next!.unpaidExpenses = next!.totalOf(PlanColumn.expenses);
  }

  /// Salary and bonus while working.
  void _earnSalary() {
    if (!_isAfterRetirementAge()) {
      final salary = parameters.baseSalary * _inflation;
      next!.add(PlanColumn.income, "Salary", salary);
      next!.salary += salary;
      next!.ordinaryIncome += salary;

      final bonus = _percentageOf(salary, parameters.bonusRate);
      next!.add(PlanColumn.income, "Bonus", bonus);
      next!.salary += bonus;
      next!.ordinaryIncome += bonus;
    }
  }

  void _receiveSocialSecurity() {
    if (_isAfterPrimarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual(PlanConstants.socialSecurityBenefitByAge[parameters.primarySocialSecurityAge] ?? 0) * _inflation;
      next!.add(PlanColumn.income, "Primary Social Security", benefit);
      next!.socialSecurity += benefit;
    }

    if (_isAfterSecondarySocialSecurityAge()) {
      final benefit = _monthlyToAnnual((PlanConstants.socialSecurityBenefitByAge[parameters.secondarySocialSecurityAge] ?? 0) / 2) * _inflation;
      next!.add(PlanColumn.income, "Secondary Social Security", benefit);
      next!.socialSecurity += benefit;
    }

    next!.unpaidExpenses -= next!.totalOf(PlanColumn.income);
  }

  void _contributeTo401k() {
    if (!_isAfterRetirementAge()) {
      final employeeContribution = _percentageOf(next!.salary, parameters.employee401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employee 401(k) Contribution", employeeContribution);

      // The contribution is pre-tax, so it is out of the income.
      next!.agiDeductions += employeeContribution;

      final employerContribution = _percentageOf(next!.salary, parameters.employer401kContributionRate);
      next!.add(PlanColumn.fourOhOneK, "Employer 401(k) Contribution", employerContribution);
    }
  }

  void _contributeToHsa() {
    if (!_isAfterRetirementAge()) {
      final hsaContribution = PlanConstants.hsaContributionLimit * _inflation;
      next!.add(PlanColumn.hsa, "HSA Contribution", hsaContribution);

      // The contribution is deductible, so it is out of the income.
      next!.agiDeductions += hsaContribution;

      // TODO: Add employer HSA contributions.
    }
  }

  /// Withdraw from the brokerage account to pay unpaid expenses.
  void _payExpensesFromBrokerage() {
    if (!_isAfterRetirementAge()) return;
    if (next!.unpaidExpenses <= 0) return;

    final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.brokerage));
    if (withdrawalAmount <= 0) return;

    next!.brokerageWithdrawals += withdrawalAmount;

    // Pay expenses.
    next!.sub(PlanColumn.brokerage, "Pay Expenses", withdrawalAmount);
    next!.unpaidExpenses -= withdrawalAmount;

    // Brokerage withdrawals are taxable as capital gains, adjusted for the
    // average cost basis of the funds: only the part above the cost basis
    // counts as a gain.
    final totalBrokerage = next!.totalOf(PlanColumn.brokerage) + withdrawalAmount;
    final costBasisPortion = totalBrokerage > 0
        ? _brokerageCostBasis * withdrawalAmount / totalBrokerage
        : 0.0;
    // A withdrawal cannot produce a negative gain: at most the whole
    // withdrawal is return of capital, so the gain is floored at zero.
    final capitalGain = max(0.0, withdrawalAmount - costBasisPortion);

    // The cost basis leaves the account alongside the cash.
    _brokerageCostBasis = max(0.0, _brokerageCostBasis - costBasisPortion);

    next!.add(PlanColumn.income, "Withdrawal from Brokerage", withdrawalAmount);
    next!.capitalGains += capitalGain;
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _payExpensesFromTraditionalIra() {
    if (!_isAfterRetirementAge()) return;
    if (!_isAfterIraWithdrawalAge()) return;
    if (next!.unpaidExpenses <= 0) return;

    final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.traditionalIra));
    if (withdrawalAmount <= 0) return;

    next!.traditionalIraWithdrawals += withdrawalAmount;

    // Pay expenses.
    next!.sub(PlanColumn.traditionalIra, "Pay Expenses", withdrawalAmount);
    next!.unpaidExpenses -= withdrawalAmount;

    // Traditional IRA withdrawals are taxable as ordinary income.
    next!.add(PlanColumn.income, "Withdrawal from Traditional IRA", withdrawalAmount);
    next!.ordinaryIncome += withdrawalAmount;
  }

  /// Withdraw from the traditional IRA account to pay unpaid expenses.
  void _payExpensesFromRothIra() {
    if (!_isAfterRetirementAge()) return;
    if (!_isAfterIraWithdrawalAge()) return;
    if (next!.unpaidExpenses <= 0) return;

    final withdrawalAmount = min(next!.unpaidExpenses, next!.totalOf(PlanColumn.rothIra));
    if (withdrawalAmount <= 0) return;

    next!.rothIraWithdrawals += withdrawalAmount;

    // Pay expenses.
    next!.sub(PlanColumn.rothIra, "Pay Expenses", withdrawalAmount);
    next!.unpaidExpenses -= withdrawalAmount;

    // Roth IRA withdrawals are not taxable, so no need to add to income.
  }

  /// Transfer the 401(k) to a traditional IRA immediately after retirement.
  void _transferFourOhOneKToTraditionalIra() {
    if (!_isAfterRetirementAge()) return;

    final transferAmount = next!.totalOf(PlanColumn.fourOhOneK);
    if (transferAmount <= 0) return;

    next!.sub(PlanColumn.fourOhOneK, "Transfer to Traditional IRA", transferAmount);
    next!.add(PlanColumn.traditionalIra, "Transfer from 401(k)", transferAmount);
  }

  void _convertTraditionalIraToRothIra() {
    if (!_isAfterRetirementAge()) return;
    if (!_isAfterRothConversionAge()) return;

    final conversionAmount = min(parameters.rothIraConversion, next!.totalOf(PlanColumn.traditionalIra));
    if (conversionAmount <= 0) return;

    next!.sub(PlanColumn.traditionalIra, "Convert to Roth IRA", conversionAmount);
    next!.traditionalIraWithdrawals += conversionAmount;

    // Convert to Roth IRA.
    next!.add(PlanColumn.rothIra, "Convert from Traditional IRA", conversionAmount);

    // Traditional IRA withdrawals for Roth conversions are taxable as ordinary income.
    next!.add(PlanColumn.income, "Convert to Roth IRA from Traditional IRA", conversionAmount);
    next!.ordinaryIncome += conversionAmount;
  }

  /// Add a year of growth to the cash balance.
  void _growCash() {
    final growthRate = parameters.cashGrowthRate;
    final total = next!.totalOf(PlanColumn.cash);
    final growthAmount = _prorate(_percentageOf(total, growthRate));

    if (growthAmount > 0) {
      next!.add(PlanColumn.cash, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the brokerage balance.
  void _growBrokerage() {
    final growthRate = parameters.brokerageGrowthRate;
    final total = next!.totalOf(PlanColumn.brokerage) - next!.brokerageWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));

    if (growthAmount > 0) {
      next!.add(PlanColumn.brokerage, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the 401(k) balance.
  void _growFourOhOneK() {
    final growthRate = parameters.fourOhOneKGrowthRate;
    final total = next!.totalOf(PlanColumn.fourOhOneK) - next!.fourOhOneKWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));

    if (growthAmount > 0) {
      next!.add(PlanColumn.fourOhOneK, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the pre-tax traditional IRA balance.
  void _growTraditionalIra() {
    final growthRate = parameters.traditionalIraGrowthRate;
    final total = next!.totalOf(PlanColumn.traditionalIra) - next!.traditionalIraWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    
    if (growthAmount > 0) {
      next!.add(PlanColumn.traditionalIra, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the after-tax Roth IRA balance.
  void _growRothIra() {
    final growthRate = parameters.rothIraGrowthRate;
    final total = next!.totalOf(PlanColumn.rothIra) - next!.rothIraWithdrawals;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    
    if (growthAmount > 0) {
      next!.add(PlanColumn.rothIra, "Growth", growthAmount);
    }
  }

  /// Add a year of growth to the invested HSA balance.
  void _growHsa() {
    final growthRate = parameters.hsaGrowthRate;
    final investmentThreshold = parameters.hsaInvestmentThreshold;
    final total = next!.totalOf(PlanColumn.hsa) - investmentThreshold;
    final growthAmount = _prorate(_percentageOf(total, growthRate));
    
    if (growthAmount > 0) {
      next!.add(PlanColumn.hsa, "Growth", growthAmount);
    }
  }

  /// Add the taxable part of the Social Security benefits to ordinary income.
  ///
  /// The benefit is taxed in proportion to the income around it, so the
  /// taxable part can only be worked out once the year's income is settled.
  void _taxableSocialSecurity() {
    if (next!.socialSecurity <= 0) return;

    final taxable = TaxCalculator.taxableSocialSecurity(
      benefit: next!.socialSecurity,
      // The combined income the worksheet measures against takes in the
      // capital gains along with the ordinary income.
      otherIncome: next!.ordinaryIncome + next!.capitalGains,
      deductions: next!.agiDeductions,
    );

    next!.taxableSocialSecurity = taxable;
    next!.ordinaryIncome += taxable;
  }

  /// Record the tax owed on this year's income. See [TaxCalculator].
  void _calculateTax() {
    _taxRules = TaxRules.indexed(_inflation);
    TaxCalculator.record(next!, _taxRules);

    if (!_isAfterRetirementAge()) {
      // Tax before retirement is paid from salary.
      next!.unpaidTaxes = 0;
    }

    // Show the year's tax as a note on expenses, without adding it to them.
    if (next!.tax > 0) {
      next!.note(PlanColumn.expenses, "Taxes", next!.tax);
    }
  }

  /// Clamp a near-zero amount to zero.
  double _clampToZero(double amount) {
    return (amount < 1e-9 ? 0 : amount);
  }

  /// Withdraw this year's tax from the brokerage account when that option is set.
  ///
  /// A brokerage withdrawal is itself taxable, so the amount taken out has to
  /// cover the tax on the withdrawal as well as the tax owed.
  void _payTaxesFromBrokerage() {
    if (!parameters.payTaxesFromBrokerage) return;
    if (next!.unpaidTaxes <= 0) return;
    if (!_isAfterRetirementAge()) return;

    final balance = next!.totalOf(PlanColumn.brokerage);
    if (balance <= 0) return;

    final costBasisRatio = balance > 0 ? _brokerageCostBasis / balance : 0.0;
    final gainRatio = (1 - costBasisRatio).clamp(0.0, 1.0);

    // An approximate marginal rate on the gain portion of the withdrawal: the
    // federal capital gains rate plus the state rate.
    final netFactor = 1 - gainRatio * (PlanConstants.federalCapitalGainsRate + PlanConstants.stateRate) / 100;
    if (netFactor <= 0) return;

    var withdrawalAmount = next!.unpaidTaxes / netFactor;
    if (withdrawalAmount > balance) withdrawalAmount = balance;
    if (withdrawalAmount <= 0) return;

    next!.brokerageWithdrawals += withdrawalAmount;

    final totalBrokerage = next!.totalOf(PlanColumn.brokerage) + withdrawalAmount;
    final costBasisPortion = totalBrokerage > 0
        ? _brokerageCostBasis * withdrawalAmount / totalBrokerage
        : 0.0;
    _brokerageCostBasis = max(0.0, _brokerageCostBasis - costBasisPortion);
    final capitalGain = max(0.0, withdrawalAmount - costBasisPortion);

    next!.sub(PlanColumn.brokerage, "Pay Taxes", withdrawalAmount);
    next!.add(PlanColumn.income, "Withdrawal from Brokerage (Tax)", withdrawalAmount);
    next!.capitalGains += capitalGain;

    _taxPaidThisYear += withdrawalAmount;

    // The withdrawal is taxable, so recompute the tax and what remains unpaid.
    final brokerageAgi = next!.ordinaryIncome - next!.agiDeductions;
    final brokerageFederal = TaxCalculator.federal(_taxRules, brokerageAgi, next!.capitalGains);
    final brokerageState = TaxCalculator.state(_taxRules, brokerageAgi, next!.capitalGains);
    next!.tax = brokerageFederal.tax + brokerageState;
    next!.taxBracket = brokerageFederal.topRate;
    next!.unpaidTaxes = _clampToZero(max(0.0, next!.tax - _taxPaidThisYear));
  }

  /// Withdraw this year's tax from the traditional IRA when that option is set.
  ///
  /// A traditional IRA withdrawal is taxed as ordinary income, so the amount
  /// taken out has to cover the tax on the withdrawal as well.
  void _payTaxesFromTraditionalIra() {
    if (!parameters.payTaxesFromTraditionalIra) return;
    if (next!.unpaidTaxes <= 0) return;
    if (!_isAfterRetirementAge()) return;

    final balance = next!.totalOf(PlanColumn.traditionalIra);
    if (balance <= 0) return;

    final marginalFederalRate = parameters.traditionalIraTaxRate;
    final netFactor = 1 - (marginalFederalRate + PlanConstants.stateRate) / 100;
    if (netFactor <= 0) return;

    var withdrawalAmount = next!.unpaidTaxes / netFactor;
    if (withdrawalAmount > balance) withdrawalAmount = balance;
    if (withdrawalAmount <= 0) return;

    next!.traditionalIraWithdrawals += withdrawalAmount;

    next!.sub(PlanColumn.traditionalIra, "Pay Taxes", withdrawalAmount);
    next!.add(PlanColumn.income, "Withdrawal from Traditional IRA (Tax)", withdrawalAmount);
    next!.ordinaryIncome += withdrawalAmount;

    _taxPaidThisYear += withdrawalAmount;

    final traditionalAgi = next!.ordinaryIncome - next!.agiDeductions;
    final traditionalFederal = TaxCalculator.federal(_taxRules, traditionalAgi, next!.capitalGains);
    final traditionalState = TaxCalculator.state(_taxRules, traditionalAgi, next!.capitalGains);
    next!.tax = traditionalFederal.tax + traditionalState;
    next!.taxBracket = traditionalFederal.topRate;
    next!.unpaidTaxes = _clampToZero(max(0.0, next!.tax - _taxPaidThisYear));
  }

  /// Withdraw this year's tax from the Roth IRA when that option is set.
  void _payTaxesFromRothIra() {
    if (!parameters.payTaxesFromRothIra) return;
    if (next!.unpaidTaxes <= 0) return;
    if (!_isAfterRetirementAge()) return;

    final balance = next!.totalOf(PlanColumn.rothIra);
    if (balance <= 0) return;

    final withdrawalAmount = min(next!.unpaidTaxes, balance);
    if (withdrawalAmount <= 0) return;

    next!.sub(PlanColumn.rothIra, "Pay Taxes", withdrawalAmount);
    _taxPaidThisYear += withdrawalAmount;
    next!.unpaidTaxes = _clampToZero(max(0.0, next!.tax - _taxPaidThisYear));
    // Roth IRA withdrawals are not taxable, so no need to add to income.
  }

  /// Record the year's modified adjusted gross income, the figure the premium
  /// tax credit turns on. See [TaxCalculator.magi].
  ///
  /// Above four times the poverty level the credit allowed is nothing at all,
  /// so all of the credit received has to be paid back with the return for the
  /// year.
  void _calculateMagi() {
    if (_isMagiYear()) {
      final magi = TaxCalculator.magi(
        ordinaryIncome: next!.ordinaryIncome,
        capitalGains: next!.capitalGains,
        agiDeductions: next!.agiDeductions,
        taxExemptSocialSecurity: next!.socialSecurity - next!.taxableSocialSecurity,
      );

      next!.magi = magi;
      next!.note(PlanColumn.tax, 'MAGI', magi);

      // The premium tax credit is gone once the MAGI passes four times the
      // federal poverty level, which moves with the years like the tax rules.
      final povertyLevel = PlanConstants.federalPovertyLevel * _inflation;

      next!.note(PlanColumn.tax, '4x Federal Poverty Level', 4 * povertyLevel);

      if (magi > 4 * povertyLevel && next!.premiumTaxCredits > 0) {
        // TODO: Between one and four times the poverty level only the excess of
        // the credit received over the credit allowed has to be paid back.
        next!.premiumTaxCreditRepayment = next!.premiumTaxCredits;
        next!.note(PlanColumn.tax, 'Premium Tax Credit Repayment', next!.premiumTaxCredits);
      }
    }
  }

  void _unpaidExpenses() {
    // The part of the year's expenses that remains unpaid after income and
    // withdrawals have been applied.
    next!.note(PlanColumn.expenses, "Unpaid Expenses", next!.unpaidExpenses);
  }

  void _unpaidTaxes() {
    // The tax that remains unpaid this year, after any payment from the accounts.
    next!.note(PlanColumn.tax, "Unpaid Taxes", next!.unpaidTaxes);
  }

  /// Advance the account totals by one year and return the new totals.
  PlanTotals calculateNext(int age) {
    this.age = age;
    _taxPaidThisYear = 0;
    next = PlanTotals.fromPlanTotals(last);

    _setExpenses();
    _earnSalary();
    _receiveSocialSecurity();

    _contributeTo401k();
    _contributeToHsa();

    _payExpensesFromBrokerage();
    if (!_isAfterMedicareAge()) _payExpensesFromRothIra();
    _payExpensesFromTraditionalIra();
    _payExpensesFromRothIra();

    _transferFourOhOneKToTraditionalIra();
    _convertTraditionalIraToRothIra();

    _growCash();
    _growBrokerage();
    _growFourOhOneK();
    _growTraditionalIra();
    _growRothIra();
    _growHsa();

    // The taxable part of Social Security depends on the whole year's income,
    // so it can only be worked out once the income is settled.
    _taxableSocialSecurity();

    _calculateTax();
    _payTaxesFromBrokerage();
    _payTaxesFromTraditionalIra();
    _payTaxesFromRothIra();

    _calculateMagi();

    _unpaidExpenses();
    _unpaidTaxes();

    ++_iteration;

    // The next year is worth a year's more inflation than this one.
    _inflation *= _inflationYear;

    last = next!;
    return last;
  }
}
