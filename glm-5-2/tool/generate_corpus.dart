// Generates the bundled recipe corpus JSON files.
// Run: dart tool/generate_corpus.dart
// Produces partitions/core-recipes.json and partitions/extended-recipes.json
// plus cuisine partition files.
import 'dart:convert';
import 'dart:io';

const enName = 'en', deName = 'de';

// ---- Template data per dish ----
class DishTemplate {
  final String id;
  final String dishTitle; // sells the food (classic)
  final Map<String, String> hero;
  final Map<String, String> dietSwap; // diet -> title suffix food
  final List<String> classicContains;
  final List<String> vegContains; // what vegetarian version keeps/replaces
  final List<String> veganContains;
  final List<String> baseIngredientIds;
  final String stripe;
  final List<String> techniques;
  final List<String> mealTypes;
  final String partitionId;
  final List<String> secondaryPartitions;
  final List<String> cuisineTags;

  const DishTemplate({
    required this.id,
    required this.dishTitle,
    required this.hero,
    required this.dietSwap,
    required this.classicContains,
    required this.vegContains,
    required this.veganContains,
    required this.baseIngredientIds,
    required this.stripe,
    required this.techniques,
    required this.mealTypes,
    required this.partitionId,
    this.secondaryPartitions = const [],
    required this.cuisineTags,
  });
}

final dishes = <DishTemplate>[
  DishTemplate(
    id: 'doener',
    dishTitle: 'lamb döner',
    hero: {'en': 'street-corner classic, reimagined for every body', 'de': 'strassenklassiker, neu gedacht für jeden'},
    dietSwap: {
      'classic': 'lamb & beef',
      'vegetarian': 'halloumi',
      'vegan': 'seitan',
    },
    classicContains: ['lamb', 'beef', 'gluten', 'dairy', 'nightshades'],
    vegContains: ['dairy', 'gluten', 'nightshades'],
    veganContains: ['gluten', 'soy', 'nightshades'],
    baseIngredientIds: ['onion', 'garlic', 'tomato', 'bell-pepper', 'cumin', 'paprika', 'chili'],
    stripe: '#C84B31',
    techniques: ['grill', 'sauté'],
    mealTypes: ['lunch', 'dinner'],
    partitionId: 'core-recipes',
    secondaryPartitions: ['cuisine-middle-eastern'],
    cuisineTags: ['middle-eastern', 'street-food'],
  ),
  DishTemplate(
    id: 'alfredo',
    dishTitle: 'fettuccine alfredo',
    hero: {'en': 'the silken roman ribbon, yours however you eat', 'de': 'die seidige römische bande, wie auch immer du isst'},
    dietSwap: {
      'classic': 'parmesan & butter',
      'vegetarian': 'parmesan & butter',
      'vegan': 'cashew cream',
    },
    classicContains: ['dairy', 'gluten', 'egg'],
    vegContains: ['dairy', 'gluten', 'egg'],
    veganContains: ['tree-nuts', 'cashews', 'gluten'],
    baseIngredientIds: ['garlic', 'butter', 'parmesan', 'cream'],
    stripe: '#E8B14F',
    techniques: ['simmer', 'pan-fry'],
    mealTypes: ['dinner'],
    partitionId: 'core-recipes',
    secondaryPartitions: ['cuisine-italian'],
    cuisineTags: ['italian', 'pasta'],
  ),
  DishTemplate(
    id: 'pad-thai',
    dishTitle: 'pad thai',
    hero: {'en': 'bangkok night-market tang, written three ways', 'de': 'bangkok nachtmarkt-würze, dreifach notiert'},
    dietSwap: {
      'classic': 'prawn',
      'vegetarian': 'egg',
      'vegan': 'tofu',
    },
    classicContains: ['shellfish', 'fish', 'egg', 'gluten', 'soy', 'nightshades', 'peanuts', 'tree-nuts'],
    vegContains: ['egg', 'gluten', 'soy', 'nightshades', 'peanuts', 'tree-nuts'],
    veganContains: ['gluten', 'soy', 'nightshades', 'peanuts', 'tree-nuts'],
    baseIngredientIds: ['garlic', 'onion', 'chili', 'lime', 'cilantro', 'peanuts'],
    stripe: '#5B8E7D',
    techniques: ['stir-fry'],
    mealTypes: ['lunch', 'dinner'],
    partitionId: 'core-recipes',
    secondaryPartitions: ['cuisine-asian'],
    cuisineTags: ['asian', 'noodles'],
  ),
  DishTemplate(
    id: 'pancakes',
    dishTitle: 'buttermilk pancakes',
    hero: {'en': 'slow sunday morning stack, any which way', 'de': 'ruhiger sonntagmorgen-stapel, jeder art'},
    dietSwap: {
      'classic': 'buttermilk',
      'vegetarian': 'buttermilk',
      'vegan': 'oat milk',
    },
    classicContains: ['dairy', 'egg', 'gluten'],
    vegContains: ['dairy', 'egg', 'gluten'],
    veganContains: ['gluten', 'oats'],
    baseIngredientIds: ['butter', 'egg', 'cream', 'apple'],
    stripe: '#D9843E',
    techniques: ['pan-fry'],
    mealTypes: ['breakfast'],
    partitionId: 'core-recipes',
    secondaryPartitions: [],
    cuisineTags: ['breakfast', 'american'],
  ),
  DishTemplate(
    id: 'ramen',
    dishTitle: 'tonkotsu ramen',
    hero: {'en': 'a bowl that holds the whole evening', 'de': 'eine schüssel, die den ganzen abend trägt'},
    dietSwap: {
      'classic': 'pork belly',
      'vegetarian': 'soft egg',
      'vegan': 'mushroom & tofu',
    },
    classicContains: ['pork', 'egg', 'gluten', 'soy', 'nightshades'],
    vegContains: ['egg', 'gluten', 'soy', 'nightshades'],
    veganContains: ['gluten', 'soy', 'nightshades'],
    baseIngredientIds: ['garlic', 'onion', 'mushroom', 'chili', 'spinach'],
    stripe: '#7A4A3A',
    techniques: ['simmer', 'steam'],
    mealTypes: ['dinner'],
    partitionId: 'core-recipes',
    secondaryPartitions: ['cuisine-asian'],
    cuisineTags: ['asian', 'soup', 'japanese'],
  ),
  DishTemplate(
    id: 'burger',
    dishTitle: 'beef burger',
    hero: {'en': 'the diner puck, pressed for every eater', 'de': 'der diner-puck, für jeden esser gepresst'},
    dietSwap: {
      'classic': 'beef',
      'vegetarian': 'halloumi',
      'vegan': 'black bean patty',
    },
    classicContains: ['beef', 'gluten', 'dairy', 'nightshades'],
    vegContains: ['dairy', 'gluten', 'nightshades'],
    veganContains: ['gluten', 'soy', 'nightshades'],
    baseIngredientIds: ['onion', 'tomato', 'garlic', 'bell-pepper', 'mushroom'],
    stripe: '#A8553A',
    techniques: ['grill', 'pan-fry'],
    mealTypes: ['lunch', 'dinner'],
    partitionId: 'extended-recipes',
    secondaryPartitions: [],
    cuisineTags: ['american', 'grill'],
  ),
  DishTemplate(
    id: 'risotto',
    dishTitle: 'mushroom risotto',
    hero: {'en': 'stirred slowly, eaten slowly, for everyone', 'de': 'langsam gerührt, langsam gegessen, für alle'},
    dietSwap: {
      'classic': 'parmesan & butter',
      'vegetarian': 'parmesan & butter',
      'vegan': 'nutritional yeast',
    },
    classicContains: ['dairy', 'rice'],
    vegContains: ['dairy', 'rice'],
    veganContains: ['rice', 'high-fodmap'],
    baseIngredientIds: ['onion', 'garlic', 'mushroom', 'butter', 'parmesan'],
    stripe: '#B8893F',
    techniques: ['simmer', 'sauté'],
    mealTypes: ['dinner'],
    partitionId: 'extended-recipes',
    secondaryPartitions: ['cuisine-italian'],
    cuisineTags: ['italian', 'rice'],
  ),
];

Map<String, String> L(String en, String de) => {'en': en, 'de': de};

List<String> containsFor(String diet, DishTemplate d, {bool gf = false}) {
  final base = diet == 'classic' ? d.classicContains : (diet == 'vegetarian' ? d.vegContains : d.veganContains);
  final out = List<String>.from(base);
  if (gf) {
    out.remove('gluten');
    out.remove('wheat');
    out.remove('rye');
    out.remove('barley');
  }
  return out;
}

List<Map<String, dynamic>> ingredientsFor(String diet, DishTemplate d, {bool gf = false}) {
  final list = <Map<String, dynamic>>[];
  // common base
  for (final id in d.baseIngredientIds) {
    list.add({
      'id': id,
      'name': L(_ingNameEn(id), _ingNameDe(id)),
      'quantity': _qty(id),
      'unit': _unit(id),
      'aisle': _aisle(id),
    });
  }
  // hero ingredient
  if (diet == 'classic') {
    if (d.id == 'doener') {
      list.add({'id': 'lamb', 'name': L('lamb shoulder', 'lamm Schulter'), 'quantity': 400, 'unit': 'g', 'aisle': 'meat'});
      list.add({'id': 'beef', 'name': L('beef mince', 'rinderhack'), 'quantity': 200, 'unit': 'g', 'aisle': 'meat'});
    } else if (d.id == 'alfredo') {
      list.add({'id': 'parmesan', 'name': L('parmesan', 'parmesan'), 'quantity': 80, 'unit': 'g', 'aisle': 'dairy'});
      list.add({'id': 'butter', 'name': L('butter', 'butter'), 'quantity': 60, 'unit': 'g', 'aisle': 'dairy'});
      list.add({'id': 'cream', 'name': L('double cream', 'sahne'), 'quantity': 150, 'unit': 'ml', 'aisle': 'dairy'});
    } else if (d.id == 'pad-thai') {
      list.add({'id': 'shellfish', 'name': L('prawns', 'garnelen'), 'quantity': 200, 'unit': 'g', 'aisle': 'seafood'});
      list.add({'id': 'fish', 'name': L('fish sauce', 'fischsauce'), 'quantity': 2, 'unit': 'tbsp', 'aisle': 'asian'});
    } else if (d.id == 'pancakes') {
      list.add({'id': 'butter', 'name': L('butter', 'butter'), 'quantity': 50, 'unit': 'g', 'aisle': 'dairy'});
      list.add({'id': 'egg', 'name': L('egg', 'ei'), 'quantity': 2, 'unit': 'pcs', 'aisle': 'dairy'});
      list.add({'id': 'cream', 'name': L('buttermilk', 'buttermilch'), 'quantity': 250, 'unit': 'ml', 'aisle': 'dairy'});
    } else if (d.id == 'ramen') {
      list.add({'id': 'pork', 'name': L('pork belly', 'schweinebauch'), 'quantity': 300, 'unit': 'g', 'aisle': 'meat'});
      list.add({'id': 'egg', 'name': L('egg', 'ei'), 'quantity': 2, 'unit': 'pcs', 'aisle': 'dairy'});
    } else if (d.id == 'burger') {
      list.add({'id': 'beef', 'name': L('beef mince', 'rinderhack'), 'quantity': 500, 'unit': 'g', 'aisle': 'meat'});
      list.add({'id': 'cheese', 'name': L('cheddar', 'cheddar'), 'quantity': 100, 'unit': 'g', 'aisle': 'dairy'});
    } else if (d.id == 'risotto') {
      list.add({'id': 'parmesan', 'name': L('parmesan', 'parmesan'), 'quantity': 80, 'unit': 'g', 'aisle': 'dairy'});
      list.add({'id': 'butter', 'name': L('butter', 'butter'), 'quantity': 50, 'unit': 'g', 'aisle': 'dairy'});
    }
  } else if (diet == 'vegetarian') {
    if (d.id == 'doener' || d.id == 'burger') {
      list.add({'id': 'cheese', 'name': L('halloumi', 'halloumi'), 'quantity': 250, 'unit': 'g', 'aisle': 'dairy'});
    } else if (d.id == 'alfredo' || d.id == 'risotto') {
      list.add({'id': 'parmesan', 'name': L('parmesan', 'parmesan'), 'quantity': 80, 'unit': 'g', 'aisle': 'dairy'});
      list.add({'id': 'butter', 'name': L('butter', 'butter'), 'quantity': 60, 'unit': 'g', 'aisle': 'dairy'});
    } else if (d.id == 'pad-thai') {
      list.add({'id': 'egg', 'name': L('egg', 'ei'), 'quantity': 2, 'unit': 'pcs', 'aisle': 'dairy'});
    } else if (d.id == 'pancakes') {
      list.add({'id': 'egg', 'name': L('egg', 'ei'), 'quantity': 2, 'unit': 'pcs', 'aisle': 'dairy'});
      list.add({'id': 'butter', 'name': L('butter', 'butter'), 'quantity': 50, 'unit': 'g', 'aisle': 'dairy'});
    } else if (d.id == 'ramen') {
      list.add({'id': 'egg', 'name': L('soft-boiled egg', 'weich gekochtes ei'), 'quantity': 2, 'unit': 'pcs', 'aisle': 'dairy'});
    }
  } else {
    // vegan
    if (d.id == 'doener') {
      list.add({'id': 'seitan', 'name': L('seitan', 'seitan'), 'quantity': 300, 'unit': 'g', 'aisle': 'asian'});
      list.add({'id': 'soy', 'name': L('soy sauce', 'sojasauce'), 'quantity': 3, 'unit': 'tbsp', 'aisle': 'asian'});
    } else if (d.id == 'alfredo') {
      list.add({'id': 'cashews', 'name': L('cashews', 'cashewkerne'), 'quantity': 120, 'unit': 'g', 'aisle': 'nuts'});
      list.add({'id': 'soy', 'name': L('soy cream', 'sojasahne'), 'quantity': 150, 'unit': 'ml', 'aisle': 'asian'});
    } else if (d.id == 'pad-thai') {
      list.add({'id': 'tofu', 'name': L('tofu', 'tofu'), 'quantity': 250, 'unit': 'g', 'aisle': 'asian'});
      list.add({'id': 'soy', 'name': L('soy sauce', 'sojasauce'), 'quantity': 3, 'unit': 'tbsp', 'aisle': 'asian'});
    } else if (d.id == 'pancakes') {
      list.add({'id': 'oats', 'name': L('oat milk', 'haferdrink'), 'quantity': 250, 'unit': 'ml', 'aisle': 'grains'});
    } else if (d.id == 'ramen') {
      list.add({'id': 'tofu', 'name': L('tofu', 'tofu'), 'quantity': 200, 'unit': 'g', 'aisle': 'asian'});
      list.add({'id': 'mushroom', 'name': L('shiitake', 'shiitake'), 'quantity': 150, 'unit': 'g', 'aisle': 'vegetables'});
    } else if (d.id == 'burger') {
      list.add({'id': 'black-bean', 'name': L('black beans', 'schwarze bohnen'), 'quantity': 400, 'unit': 'g', 'aisle': 'canned'});
      list.add({'id': 'soy', 'name': L('soy sauce', 'sojasauce'), 'quantity': 2, 'unit': 'tbsp', 'aisle': 'asian'});
    } else if (d.id == 'risotto') {
      list.add({'id': 'nutritional-yeast', 'name': L('nutritional yeast', 'hefeflocken'), 'quantity': 30, 'unit': 'g', 'aisle': 'asian'});
    }
  }
  // pasta/bread/noodle base
  if (d.id == 'alfredo' || d.id == 'pad-thai' || d.id == 'ramen') {
    list.add({
      'id': gf ? 'rice-noodle' : 'wheat-noodle',
      'name': gf ? L('rice noodles', 'reisnudeln') : L('wheat noodles', 'weizennudeln'),
      'quantity': 250, 'unit': 'g', 'aisle': 'grains'
    });
  }
  if (d.id == 'burger') {
    list.add({
      'id': gf ? 'gf-bun' : 'wheat-bun',
      'name': gf ? L('gluten-free bun', 'glutenfreies brötchen') : L('brioche bun', 'brioche brötchen'),
      'quantity': 4, 'unit': 'pcs', 'aisle': 'bakery'
    });
  }
  return list;
}

String _ingNameEn(String id) => {
  'onion': 'onion', 'garlic': 'garlic', 'tomato': 'tomato', 'bell-pepper': 'bell pepper',
  'cumin': 'cumin', 'paprika': 'paprika', 'chili': 'chili', 'lime': 'lime',
  'cilantro': 'cilantro', 'peanuts': 'peanuts', 'butter': 'butter', 'egg': 'egg',
  'cream': 'cream', 'parmesan': 'parmesan', 'apple': 'apple', 'mushroom': 'mushroom',
  'spinach': 'spinach', 'cheese': 'cheese',
}[id] ?? id;

String _ingNameDe(String id) => {
  'onion': 'zwiebel', 'garlic': 'knoblauch', 'tomato': 'tomate', 'bell-pepper': 'paprika',
  'cumin': 'kreuzkümmel', 'paprika': 'paprikapulver', 'chili': 'chili', 'lime': 'limette',
  'cilantro': 'koriander', 'peanuts': 'erdnüsse', 'butter': 'butter', 'egg': 'ei',
  'cream': 'sahne', 'parmesan': 'parmesan', 'apple': 'apfel', 'mushroom': 'pilz',
  'spinach': 'spinat', 'cheese': 'käse',
}[id] ?? id;

double _qty(String id) => {'onion': 1, 'garlic': 3, 'tomato': 2, 'bell-pepper': 1, 'cumin': 1, 'paprika': 1, 'chili': 1, 'lime': 1, 'cilantro': 1, 'peanuts': 50, 'butter': 50, 'egg': 2, 'cream': 150, 'parmesan': 80, 'apple': 1, 'mushroom': 200, 'spinach': 100}[id]?.toDouble() ?? 1;

String _unit(String id) => {'onion': 'pcs', 'garlic': 'cloves', 'tomato': 'pcs', 'bell-pepper': 'pcs', 'cumin': 'tsp', 'paprika': 'tsp', 'chili': 'tsp', 'lime': 'pcs', 'cilantro': 'bunch', 'peanuts': 'g', 'butter': 'g', 'egg': 'pcs', 'cream': 'ml', 'parmesan': 'g', 'apple': 'pcs', 'mushroom': 'g', 'spinach': 'g'}[id] ?? 'pcs';

String _aisle(String id) => {'onion': 'vegetables', 'garlic': 'vegetables', 'tomato': 'vegetables', 'bell-pepper': 'vegetables', 'cumin': 'spices', 'paprika': 'spices', 'chili': 'spices', 'lime': 'fruits', 'cilantro': 'herbs', 'peanuts': 'nuts', 'butter': 'dairy', 'egg': 'dairy', 'cream': 'dairy', 'parmesan': 'dairy', 'apple': 'fruits', 'mushroom': 'vegetables', 'spinach': 'vegetables', 'cheese': 'dairy'}[id] ?? 'pantry';

List<Map<String, dynamic>> stepsFor(DishTemplate d, String diet, {bool gf = false}) {
  final hero = d.dietSwap[diet]!;
  return [
    {
      'n': 1,
      'text': L('prep everything before the heat goes on. $hero, veg, spice.', 'bereite alles vor dem anbraten vor. $hero, gemüse, gewürze.'),
      'timer_seconds': 0,
    },
    {
      'n': 2,
      'text': L('sauté the aromatics until they smell like dinner. ${d.techniques.first}.', 'die aromen anbraten, bis es nach abendessen duftet. ${d.techniques.first}.'),
      'timer_seconds': 300,
    },
    {
      'n': 3,
      'text': L('add the $hero and cook with intent — let the edges catch colour.', 'den $hero zugeben und mit absicht garen — lass die ränder farbe annehmen.'),
      'timer_seconds': 600,
    },
    {
      'n': 4,
      'text': L('fold the spice in. taste. ${gf ? "gluten-free" : "regular"} base goes in now.', 'die gewürze unterheben. probieren. ${gf ? "glutenfreie" : "normale"} basis jetzt zugeben.'),
      'timer_seconds': 240,
    },
    {
      'n': 5,
      'text': L('rest a minute, plate, and eat with your hands if the dish allows.', 'eine minute ruhen lassen, anrichten, und mit händen essen, wenn es das gericht erlaubt.'),
      'timer_seconds': 60,
    },
  ];
}

int caloriesFor(String effort, String calLevel) {
  final base = calLevel == 'low' ? 480 : 720;
  if (effort == 'easy') return base;
  if (effort == 'medium') return base + 20;
  return base + 40;
}

int timeFor(String effort) => effort == 'easy' ? 20 : (effort == 'medium' ? 45 : 75);

String titleFor(DishTemplate d, String diet) {
  if (d.id == 'doener') {
    if (diet == 'vegan') return 'seitan döner';
    if (diet == 'vegetarian') return 'halloumi döner';
    return 'lamb döner';
  }
  if (d.id == 'alfredo') {
    if (diet == 'vegan') return 'cashew alfredo';
    return 'fettuccine alfredo';
  }
  if (d.id == 'pad-thai') {
    if (diet == 'vegan') return 'tofu pad thai';
    if (diet == 'vegetarian') return 'egg pad thai';
    return 'prawn pad thai';
  }
  if (d.id == 'pancakes') {
    if (diet == 'vegan') return 'oat-milk pancakes';
    return 'buttermilk pancakes';
  }
  if (d.id == 'ramen') {
    if (diet == 'vegan') return 'mushroom ramen';
    if (diet == 'vegetarian') return 'egg ramen';
    return 'tonkotsu ramen';
  }
  if (d.id == 'burger') {
    if (diet == 'vegan') return 'black-bean burger';
    if (diet == 'vegetarian') return 'halloumi burger';
    return 'beef burger';
  }
  if (d.id == 'risotto') {
    if (diet == 'vegan') return 'vegan mushroom risotto';
    return 'mushroom risotto';
  }
  return d.dishTitle;
}

String titleDeFor(DishTemplate d, String diet) {
  if (d.id == 'doener') {
    if (diet == 'vegan') return 'seitan döner';
    if (diet == 'vegetarian') return 'halloumi döner';
    return 'lamm döner';
  }
  if (d.id == 'alfredo') {
    if (diet == 'vegan') return 'cashew alfredo';
    return 'fettuccine alfredo';
  }
  if (d.id == 'pad-thai') {
    if (diet == 'vegan') return 'tofu pad thai';
    if (diet == 'vegetarian') return 'ei pad thai';
    return 'garnelen pad thai';
  }
  if (d.id == 'pancakes') {
    if (diet == 'vegan') return 'hafermilch pfannkuchen';
    return 'buttermilch pfannkuchen';
  }
  if (d.id == 'ramen') {
    if (diet == 'vegan') return 'pilz ramen';
    if (diet == 'vegetarian') return 'ei ramen';
    return 'tonkotsu ramen';
  }
  if (d.id == 'burger') {
    if (diet == 'vegan') return 'schwarze-bohnen burger';
    if (diet == 'vegetarian') return 'halloumi burger';
    return 'rind burger';
  }
  if (d.id == 'risotto') {
    if (diet == 'vegan') return 'veganes pilz risotto';
    return 'pilz risotto';
  }
  return d.dishTitle;
}

Map<String, dynamic> buildRecipe(DishTemplate d, String diet, String effort, String calLevel, {bool gf = false}) {
  final id = '${d.id}-$diet-$effort-$calLevel${gf ? '-gf' : ''}';
  final contains = containsFor(diet, d, gf: gf);
  final ingredients = ingredientsFor(diet, d, gf: gf);
  final steps = stepsFor(d, diet, gf: gf);
  final time = timeFor(effort);
  final cal = caloriesFor(effort, calLevel);
  final tags = <String>[...d.cuisineTags, ...d.techniques, ...d.mealTypes];
  if (gf) tags.add('gluten-free');
  return {
    'id': id,
    'dish_id': d.id,
    'title': L(titleFor(d, diet), titleDeFor(d, diet)),
    'diet': diet,
    'effort': effort,
    'calorie_level': calLevel,
    'extra_tags': gf ? ['gluten-free'] : <String>[],
    'contains': contains,
    'attributes': {
      'effort': effort,
      'time_bucket': time <= 15 ? '<=15' : (time <= 30 ? '<=30' : (time <= 60 ? '<=60' : '>60')),
      'calorie_bucket': cal <= 400 ? '<=400' : (cal <= 600 ? '<=600' : (cal <= 800 ? '<=800' : '>800')),
      'technique': d.techniques,
      'meal_type': d.mealTypes,
    },
    'time_minutes': time,
    'calories_per_serving': cal,
    'macros': {'protein': (cal * 0.25 / 4).round(), 'carbs': (cal * 0.45 / 4).round(), 'fat': (cal * 0.30 / 9).round()},
    'servings': 4,
    'ingredients': ingredients,
    'steps': steps,
    'tags': tags,
    'cuisine_tags': d.cuisineTags,
    'frequency_tier': d.partitionId == 'core-recipes' ? 'core' : 'extended',
  };
}

void main() {
  final core = <Map<String, dynamic>>[];
  final extended = <Map<String, dynamic>>[];
  final italian = <Map<String, dynamic>>[];
  final asian = <Map<String, dynamic>>[];
  final middleEastern = <Map<String, dynamic>>[];

  for (final d in dishes) {
    final diets = ['classic', 'vegetarian', 'vegan'];
    final efforts = ['easy', 'medium'];
    final cals = ['low', 'high'];
    for (final diet in diets) {
      for (final eff in efforts) {
        for (final c in cals) {
          // ramen & risotto: only medium
          if ((d.id == 'ramen' || d.id == 'risotto') && eff == 'easy' && diet != 'vegan') continue;
          final r = buildRecipe(d, diet, eff, c);
          (d.partitionId == 'core-recipes' ? core : extended).add(r);
          if (d.secondaryPartitions.contains('cuisine-italian')) italian.add(r);
          if (d.secondaryPartitions.contains('cuisine-asian')) asian.add(r);
          if (d.secondaryPartitions.contains('cuisine-middle-eastern')) middleEastern.add(r);
        }
      }
    }
    // GF sparse extras: doener + alfredo
    if (d.id == 'doener') {
      final r = buildRecipe(d, 'classic', 'medium', 'high', gf: true);
      core.add(r);
      middleEastern.add(r);
    }
    if (d.id == 'alfredo') {
      final r = buildRecipe(d, 'vegan', 'medium', 'high', gf: true);
      core.add(r);
      italian.add(r);
    }
  }

  void write(String path, List<Map<String, dynamic>> recipes) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(JsonEncoder.withIndent('  ').convert({
      'schema_version': 1,
      'recipes': recipes,
    }));
    print('wrote ${recipes.length} recipes -> $path');
  }

  final base = 'assets/partitions';
  write('$base/core-recipes.json', core);
  write('$base/extended-recipes.json', extended);
  write('$base/cuisine-italian.json', italian);
  write('$base/cuisine-asian.json', asian);
  write('$base/cuisine-middle-eastern.json', middleEastern);
  print('done. core=${core.length} extended=${extended.length}');
}
