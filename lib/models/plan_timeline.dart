class PlanTimeline {

  int retirementAge = 60;
  int primarySocialSecurityAge = 70;
  int secondarySocialSecurityAge = 67;
  int rothIraConversionAge = 65;

  /// The timeline as a plan file: each age alongside the ages its moves set.
  Map<String, Object?> toJson() => <String, Object?>{
    'retirementAge': retirementAge,
    'primarySocialSecurityAge': primarySocialSecurityAge,
    'secondarySocialSecurityAge': secondarySocialSecurityAge,
    'rothIraConversionAge': rothIraConversionAge,
  };

  /// Rebuild the timeline from a plan file's [json]; the ages left out keep
  /// the ones they were given with.
  static PlanTimeline fromJson(Map<String, Object?> json) {
    return PlanTimeline()
      ..retirementAge = (json['retirementAge'] as num?)?.toInt() ?? 60
      ..primarySocialSecurityAge = (json['primarySocialSecurityAge'] as num?)?.toInt() ?? 70
      ..secondarySocialSecurityAge = (json['secondarySocialSecurityAge'] as num?)?.toInt() ?? 67
      ..rothIraConversionAge = (json['rothIraConversionAge'] as num?)?.toInt() ?? 65;
  }
}
