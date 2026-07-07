class Profile {
  String name;
  String lang;
  Set<String> avoidFlags;
  Set<String> avoidIngredients;
  Set<String> requiredAttributes;
  int maxTimeMinutes;
  int calorieTarget;
  String preferredEffort;
  bool showVariantTags;
  bool reduceMotion;
  bool visualAlertEnabled;
  bool quickNextTapEnabled;

  Profile({
    this.name = '',
    this.lang = 'en',
    Set<String>? avoidFlags,
    Set<String>? avoidIngredients,
    Set<String>? requiredAttributes,
    this.maxTimeMinutes = 120,
    this.calorieTarget = 600,
    this.preferredEffort = 'medium',
    this.showVariantTags = true,
    this.reduceMotion = false,
    this.visualAlertEnabled = true,
    this.quickNextTapEnabled = false,
  })  : avoidFlags = avoidFlags ?? {},
        avoidIngredients = avoidIngredients ?? {},
        requiredAttributes = requiredAttributes ?? {};

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] ?? '',
      lang: json['lang'] ?? 'en',
      avoidFlags: Set<String>.from(json['avoid_flags'] ?? []),
      avoidIngredients: Set<String>.from(json['avoid_ingredients'] ?? []),
      requiredAttributes: Set<String>.from(json['required_attributes'] ?? []),
      maxTimeMinutes: json['max_time_minutes'] ?? 120,
      calorieTarget: json['calorie_target'] ?? 600,
      preferredEffort: json['preferred_effort'] ?? 'medium',
      showVariantTags: json['show_variant_tags'] ?? true,
      reduceMotion: json['reduceMotion'] ?? false,
      visualAlertEnabled: json['visualAlertEnabled'] ?? true,
      quickNextTapEnabled: json['quickNextTapEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lang': lang,
      'avoid_flags': avoidFlags.toList(),
      'avoid_ingredients': avoidIngredients.toList(),
      'required_attributes': requiredAttributes.toList(),
      'max_time_minutes': maxTimeMinutes,
      'calorie_target': calorieTarget,
      'preferred_effort': preferredEffort,
      'show_variant_tags': showVariantTags,
      'reduceMotion': reduceMotion,
      'visualAlertEnabled': visualAlertEnabled,
      'quickNextTapEnabled': quickNextTapEnabled,
    };
  }

  bool get isComplete =>
      name.isNotEmpty && (avoidFlags.isNotEmpty || avoidIngredients.isNotEmpty);
}
