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
  bool? reduceMotion;
  bool visualAlertEnabled;
  bool quickNextTapEnabled;

  Profile({
    this.name = '',
    this.lang = 'en',
    Set<String>? avoidFlags,
    Set<String>? avoidIngredients,
    Set<String>? requiredAttributes,
    this.maxTimeMinutes = 90,
    this.calorieTarget = 600,
    this.preferredEffort = 'medium',
    this.showVariantTags = true,
    this.reduceMotion,
    this.visualAlertEnabled = true,
    this.quickNextTapEnabled = false,
  })  : avoidFlags = avoidFlags ?? <String>{},
        avoidIngredients = avoidIngredients ?? <String>{},
        requiredAttributes = requiredAttributes ?? <String>{};

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] as String? ?? '',
      lang: map['lang'] as String? ?? 'en',
      avoidFlags: (map['avoid_flags'] as List? ?? []).map((e) => e.toString()).toSet(),
      avoidIngredients: (map['avoid_ingredients'] as List? ?? []).map((e) => e.toString()).toSet(),
      requiredAttributes: (map['required_attributes'] as List? ?? []).map((e) => e.toString()).toSet(),
      maxTimeMinutes: (map['max_time_minutes'] as num?)?.toInt() ?? 90,
      calorieTarget: (map['calorie_target'] as num?)?.toInt() ?? 600,
      preferredEffort: map['preferred_effort'] as String? ?? 'medium',
      showVariantTags: map['show_variant_tags'] as bool? ?? true,
      reduceMotion: map['reduce_motion'] as bool?,
      visualAlertEnabled: map['visual_alert_enabled'] as bool? ?? true,
      quickNextTapEnabled: map['quick_next_tap_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'lang': lang,
        'avoid_flags': avoidFlags.toList(),
        'avoid_ingredients': avoidIngredients.toList(),
        'required_attributes': requiredAttributes.toList(),
        'max_time_minutes': maxTimeMinutes,
        'calorie_target': calorieTarget,
        'preferred_effort': preferredEffort,
        'show_variant_tags': showVariantTags,
        'reduce_motion': reduceMotion,
        'visual_alert_enabled': visualAlertEnabled,
        'quick_next_tap_enabled': quickNextTapEnabled,
      };

  Profile copyWith({
    String? name,
    String? lang,
    Set<String>? avoidFlags,
    Set<String>? avoidIngredients,
    Set<String>? requiredAttributes,
    int? maxTimeMinutes,
    int? calorieTarget,
    String? preferredEffort,
    bool? showVariantTags,
    bool? reduceMotion,
    bool? visualAlertEnabled,
    bool? quickNextTapEnabled,
  }) {
    return Profile(
      name: name ?? this.name,
      lang: lang ?? this.lang,
      avoidFlags: avoidFlags ?? this.avoidFlags,
      avoidIngredients: avoidIngredients ?? this.avoidIngredients,
      requiredAttributes: requiredAttributes ?? this.requiredAttributes,
      maxTimeMinutes: maxTimeMinutes ?? this.maxTimeMinutes,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      preferredEffort: preferredEffort ?? this.preferredEffort,
      showVariantTags: showVariantTags ?? this.showVariantTags,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      visualAlertEnabled: visualAlertEnabled ?? this.visualAlertEnabled,
      quickNextTapEnabled: quickNextTapEnabled ?? this.quickNextTapEnabled,
    );
  }
}
