/// Unit-aware quantity handling for the smart shopping list.
///
/// Units fall into families; quantities in the same family convert through a
/// base unit (g for mass, ml for volume) and can be aggregated. Count-like
/// units (clove, piece…) only aggregate with themselves.
enum UnitFamily { mass, volume, count }

class UnitDef {
  final String id;
  final UnitFamily family;

  /// Factor to the family base unit (g or ml). 1 for count units.
  final double toBase;

  const UnitDef(this.id, this.family, this.toBase);
}

const Map<String, UnitDef> units = {
  'g': UnitDef('g', UnitFamily.mass, 1),
  'kg': UnitDef('kg', UnitFamily.mass, 1000),
  'ml': UnitDef('ml', UnitFamily.volume, 1),
  'l': UnitDef('l', UnitFamily.volume, 1000),
  'tsp': UnitDef('tsp', UnitFamily.volume, 5),
  'tbsp': UnitDef('tbsp', UnitFamily.volume, 15),
  'cup': UnitDef('cup', UnitFamily.volume, 240),
  'piece': UnitDef('piece', UnitFamily.count, 1),
  'clove': UnitDef('clove', UnitFamily.count, 1),
  'slice': UnitDef('slice', UnitFamily.count, 1),
  'can': UnitDef('can', UnitFamily.count, 1),
  'bunch': UnitDef('bunch', UnitFamily.count, 1),
  'pinch': UnitDef('pinch', UnitFamily.count, 1),
  'sprig': UnitDef('sprig', UnitFamily.count, 1),
};

/// Localized unit labels: (singular, plural) per language. Metric symbols
/// stay symbols; spoon and count units get their German kitchen names
/// (TL/EL, Stück, Zehe…).
const Map<String, Map<String, (String, String)>> _unitLabels = {
  'en': {
    'tsp': ('tsp', 'tsp'),
    'tbsp': ('tbsp', 'tbsp'),
    'cup': ('cup', 'cups'),
    'piece': ('piece', 'pieces'),
    'clove': ('clove', 'cloves'),
    'slice': ('slice', 'slices'),
    'can': ('can', 'cans'),
    'bunch': ('bunch', 'bunches'),
    'pinch': ('pinch', 'pinches'),
    'sprig': ('sprig', 'sprigs'),
  },
  'de': {
    'tsp': ('TL', 'TL'),
    'tbsp': ('EL', 'EL'),
    'cup': ('Tasse', 'Tassen'),
    'piece': ('Stück', 'Stück'),
    'clove': ('Zehe', 'Zehen'),
    'slice': ('Scheibe', 'Scheiben'),
    'can': ('Dose', 'Dosen'),
    'bunch': ('Bund', 'Bund'),
    'pinch': ('Prise', 'Prisen'),
    'sprig': ('Zweig', 'Zweige'),
  },
};

/// Display label for a unit in [lang], pluralized by [amount].
/// g/kg/ml/l pass through as metric symbols.
String unitLabel(String unit, double amount, String lang) {
  final labels = _unitLabels[lang]?[unit] ?? _unitLabels['en']?[unit];
  if (labels == null) return unit;
  return amount == 1 ? labels.$1 : labels.$2;
}

/// Trims trailing zeros and uses the language's decimal separator:
/// 2.0 -> "2", 2.5 -> "2.5" (en) / "2,5" (de).
String formatAmount(double amount, String lang) {
  final rounded = (amount * 100).roundToDouble() / 100;
  final text = rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toString();
  return lang == 'de' ? text.replaceAll('.', ',') : text;
}

/// One quantity line, localized: "420 g", "2 EL", "1 Zehe".
String formatQuantity(double amount, String unit, String lang) =>
    '${formatAmount(amount, lang)} ${unitLabel(unit, amount, lang)}';

class Quantity {
  final double amount;
  final String unit;

  const Quantity(this.amount, this.unit);

  UnitDef get def => units[unit] ?? const UnitDef('piece', UnitFamily.count, 1);

  bool canAddTo(Quantity other) {
    final a = def;
    final b = other.def;
    if (a.family == UnitFamily.count || b.family == UnitFamily.count) {
      return unit == other.unit;
    }
    return a.family == b.family;
  }

  /// Adds two compatible quantities; result is normalized to a display unit.
  Quantity operator +(Quantity other) {
    assert(canAddTo(other));
    if (def.family == UnitFamily.count) {
      return Quantity(amount + other.amount, unit);
    }
    final base = amount * def.toBase + other.amount * other.def.toBase;
    return _fromBase(base, def.family);
  }

  Quantity scaled(double factor) => Quantity(amount * factor, unit);

  static Quantity _fromBase(double base, UnitFamily family) {
    switch (family) {
      case UnitFamily.mass:
        return base >= 1000
            ? Quantity(base / 1000, 'kg')
            : Quantity(base, 'g');
      case UnitFamily.volume:
        if (base >= 1000) return Quantity(base / 1000, 'l');
        // Small volumes read better in spoons: 45 ml -> 3 tbsp.
        if (base < 100 && base % 15 == 0) return Quantity(base / 15, 'tbsp');
        if (base < 100 && base % 5 == 0) return Quantity(base / 5, 'tsp');
        return Quantity(base, 'ml');
      case UnitFamily.count:
        return Quantity(base, 'piece');
    }
  }

  /// Trim trailing zeros: 2.0 -> "2", 2.5 -> "2.5".
  String get display => displayFor('en');

  /// Localized display: German gets kitchen unit names and a decimal comma.
  String displayFor(String lang) => formatQuantity(amount, unit, lang);
}
