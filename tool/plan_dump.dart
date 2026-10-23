import 'package:retirement_calculator/calc/plan_calculator.dart';
import 'package:retirement_calculator/models/plan_models.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';
import 'package:retirement_calculator/models/portfolio_models.dart';

void main() {
  final parameters = PlanParameters();

  final accounts = [
    for (final (type, balance) in const [
      (PortfolioAccountType.brokerage, 400000.0),
      (PortfolioAccountType.fourOhOneK, 900000.0),
      (PortfolioAccountType.traditionalIra, 500000.0),
      (PortfolioAccountType.rothIra, 200000.0),
    ])
      PortfolioAccount(type: type, name: 'x', institution: 'y', balance: balance, updated: DateTime.utc(2026, 1, 1)),
  ];

  final portfolio = Portfolio(type: 'Fidelity FullView', exportedDate: DateTime.utc(2026, 1, 1), accounts: accounts);

  final calculator = PlanCalculator(
    portfolioDate: DateTime.utc(2026, 1, 1),
    parameters: parameters,
    totals: PlanTotals.fromPortfolio(portfolio),
  );

  for (var age = 55; age < 72; age++) {
    final year = calculator.calculateNext(age);

    final notes = year.balanceOf(PlanColumn.tax).notes;
    final magi = notes.where((n) => n.$1 == 'MAGI').fold<double?>(null, (v, n) => n.$2);
    final repayment = notes.where((n) => n.$1 == 'Premium Tax Credit Repayment').fold<double?>(null, (v, n) => n.$2);

    final expenses = year.balanceOf(PlanColumn.expenses).adjustments
        .where((a) => a.$1.contains('Tax') || a.$1.contains('Premium'))
        .map((a) => '${a.$1}: ${a.$2.toStringAsFixed(0)}')
        .join(', ');

    print('age $age  magi ${magi?.toStringAsFixed(0) ?? '-'}  repayment ${repayment?.toStringAsFixed(0) ?? '-'}  [$expenses]');
  }
}
