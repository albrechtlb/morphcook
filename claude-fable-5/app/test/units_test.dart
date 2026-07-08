import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/logic/units.dart';

void main() {
  group('Quantity addition', () {
    test('same count unit aggregates: 2 cloves + 3 cloves = 5 cloves', () {
      final sum = const Quantity(2, 'clove') + const Quantity(3, 'clove');
      expect(sum.amount, 5);
      expect(sum.unit, 'clove');
    });

    test('different count units do not aggregate', () {
      expect(
          const Quantity(1, 'clove').canAddTo(const Quantity(1, 'piece')),
          isFalse);
    });

    test('count and mass do not aggregate', () {
      expect(const Quantity(1, 'piece').canAddTo(const Quantity(100, 'g')),
          isFalse);
    });

    test('ml + tbsp converts through the volume family', () {
      final sum = const Quantity(30, 'ml') + const Quantity(2, 'tbsp');
      expect(sum.unit, 'tbsp');
      expect(sum.amount, 4); // 30 ml + 30 ml = 60 ml = 4 tbsp
    });

    test('tsp + tbsp normalizes', () {
      final sum = const Quantity(3, 'tsp') + const Quantity(1, 'tbsp');
      expect(sum.unit, 'tbsp');
      expect(sum.amount, 2);
    });

    test('g + kg normalizes to kg above 1000 g', () {
      final sum = const Quantity(300, 'g') + const Quantity(1, 'kg');
      expect(sum.unit, 'kg');
      expect(sum.amount, 1.3);
    });

    test('volume crossing 1 l normalizes to litres', () {
      final sum = const Quantity(600, 'ml') + const Quantity(500, 'ml');
      expect(sum.unit, 'l');
      expect(sum.amount, 1.1);
    });

    test('odd ml stays in ml', () {
      final sum = const Quantity(33, 'ml') + const Quantity(40, 'ml');
      expect(sum.unit, 'ml');
      expect(sum.amount, 73);
    });
  });

  group('scaling & display', () {
    test('scaled multiplies amount', () {
      final q = const Quantity(250, 'g').scaled(1.5);
      expect(q.amount, 375);
    });

    test('display trims trailing zeros', () {
      expect(const Quantity(2.0, 'tbsp').display, '2 tbsp');
      expect(const Quantity(2.5, 'tbsp').display, '2.5 tbsp');
      expect(const Quantity(1.333333, 'cup').display, '1.33 cups');
    });

    test('english display pluralizes count units', () {
      expect(const Quantity(1, 'clove').displayFor('en'), '1 clove');
      expect(const Quantity(2, 'clove').displayFor('en'), '2 cloves');
      expect(const Quantity(1, 'piece').displayFor('en'), '1 piece');
      expect(const Quantity(3, 'piece').displayFor('en'), '3 pieces');
    });

    test('german display uses kitchen units and a decimal comma', () {
      expect(const Quantity(2, 'tsp').displayFor('de'), '2 TL');
      expect(const Quantity(1.5, 'tbsp').displayFor('de'), '1,5 EL');
      expect(const Quantity(420, 'g').displayFor('de'), '420 g');
      expect(const Quantity(1, 'clove').displayFor('de'), '1 Zehe');
      expect(const Quantity(2, 'clove').displayFor('de'), '2 Zehen');
      expect(const Quantity(2, 'piece').displayFor('de'), '2 Stück');
      expect(const Quantity(1, 'pinch').displayFor('de'), '1 Prise');
      expect(const Quantity(0.5, 'l').displayFor('de'), '0,5 l');
    });

    test('formatQuantity scales for portioning', () {
      expect(formatQuantity(420 * 1.5, 'g', 'de'), '630 g');
      expect(formatQuantity(1 * 2.5, 'clove', 'de'), '2,5 Zehen');
    });

    test('unknown units fall back to count behavior', () {
      final q = Quantity(1, 'weird-unit');
      expect(q.def.family, UnitFamily.count);
    });
  });
}
