import 'package:flutter_test/flutter_test.dart';
import 'package:retirement_calculator/models/plan_parameters.dart';

void main() {
  group('PlanParametersMap', () {
    group('getBudget', () {
      test('returns the budget set for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        expect(parametersMap.getBudget(), 9000);
      });

      test('returns the budget of the current age over the first age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(7500);

        parametersMap.age = 70;
        parametersMap.setBudget(6000);

        expect(parametersMap.getBudget(), 6000);

        parametersMap.age = 60;
        parametersMap.setBudget(8000);

        expect(parametersMap.getBudget(), 8000);
      });

      test('falls back to the first age when no parameters exist for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
        parametersMap.age = 65;

        expect(parametersMap.getBudget(), 7500);
      });
    });

    group('setBudget', () {
      test('sets the budget in the parameters for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        expect(parametersMap.getBudget(), 9000);
      });

      test('creates new parameters for the current age when none are set', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(7500);

        parametersMap.age = 70;
        parametersMap.setBudget(6000);

        expect(parametersMap.getBudget(), 6000);
      });

      test('overwrites the budget of the parameters for the current age', () {
        final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
        parametersMap.age = 60;
        parametersMap.setBudget(9000);

        parametersMap.setBudget(9500);

        expect(parametersMap.getBudget(), 9500);
      });
    });
  });

  group('getPayTaxesFrom', () {
    test('returns the ordered sources taxes are paid from', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
      parametersMap.age = 60;

      expect(parametersMap.getPayTaxesFrom(), [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra]);
    });

    test('returns the sources set for the current age', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
      parametersMap.age = 60;
      parametersMap.setPayTaxesFrom([PaymentSource.hsa, PaymentSource.brokerage]);

      expect(parametersMap.getPayTaxesFrom(), [PaymentSource.hsa, PaymentSource.brokerage]);
    });
  });

  group('setPayTaxesFrom', () {
    test('sets the ordered sources for the current age', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
      parametersMap.age = 60;
      parametersMap.setPayTaxesFrom([PaymentSource.rothIra, PaymentSource.brokerage]);

      expect(parametersMap.getPayTaxesFrom(), [PaymentSource.rothIra, PaymentSource.brokerage]);
    });

    test('overwrites the sources of the parameters for the current age', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
      parametersMap.age = 60;
      parametersMap.setPayTaxesFrom([PaymentSource.cash]);

      parametersMap.setPayTaxesFrom([PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra]);

      expect(parametersMap.getPayTaxesFrom(), [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra]);
    });
  });

  group('getPayExpensesFrom', () {
    test('returns the ordered sources expenses are paid from', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
      parametersMap.age = 60;

      expect(parametersMap.getPayExpensesFrom(), [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra]);
    });

    test('inherits the sources of the first age over a null list', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters.withDefaults());
      parametersMap.age = 65;
      parametersMap.setPayExpensesFrom(null);

      expect(parametersMap.getPayExpensesFrom(), [PaymentSource.brokerage, PaymentSource.traditionalIra, PaymentSource.rothIra]);
    });
  });

  group('setPayExpensesFrom', () {
    test('sets the ordered sources for the current age', () {
      final parametersMap = PlanParametersMap(minAge: 60, initial: PlanParameters());
      parametersMap.age = 60;
      parametersMap.setPayExpensesFrom([PaymentSource.brokerage, PaymentSource.rothIra]);

      expect(parametersMap.getPayExpensesFrom(), [PaymentSource.brokerage, PaymentSource.rothIra]);
    });
  });
}
