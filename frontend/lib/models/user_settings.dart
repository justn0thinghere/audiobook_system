import '_json_helpers.dart';

enum NarratorVoice { calmFemale, warmMale, friendlyChild, soothingElder }

extension NarratorVoiceX on NarratorVoice {
  String get apiValue {
    switch (this) {
      case NarratorVoice.calmFemale:
        return 'calm_female';
      case NarratorVoice.warmMale:
        return 'warm_male';
      case NarratorVoice.friendlyChild:
        return 'friendly_child';
      case NarratorVoice.soothingElder:
        return 'soothing_elder';
    }
  }

  String get label {
    switch (this) {
      case NarratorVoice.calmFemale:
        return 'Calm Female';
      case NarratorVoice.warmMale:
        return 'Warm Male';
      case NarratorVoice.friendlyChild:
        return 'Friendly Child';
      case NarratorVoice.soothingElder:
        return 'Soothing Elder';
    }
  }

  static NarratorVoice fromApi(String? value) {
    switch (value) {
      case 'warm_male':
        return NarratorVoice.warmMale;
      case 'friendly_child':
        return NarratorVoice.friendlyChild;
      case 'soothing_elder':
        return NarratorVoice.soothingElder;
      case 'calm_female':
      default:
        return NarratorVoice.calmFemale;
    }
  }
}

class UserSettings {
  final NarratorVoice narratorVoice;
  final double readingSpeed;
  final double volume;
  final bool reducedAnimations;
  final bool autoPlayNext;
  final bool readAlong;

  const UserSettings({
    this.narratorVoice = NarratorVoice.calmFemale,
    this.readingSpeed = 1.0,
    this.volume = 0.8,
    this.reducedAnimations = true,
    this.autoPlayNext = false,
    this.readAlong = true,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      narratorVoice: NarratorVoiceX.fromApi(safeNullableString(json['narrator_voice'])),
      readingSpeed: safeDouble(json['reading_speed']) ?? 1.0,
      volume: safeDouble(json['volume']) ?? 0.8,
      reducedAnimations: safeBool(json['reduced_animations'], true),
      autoPlayNext: safeBool(json['auto_play_next']),
      readAlong: safeBool(json['read_along'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        'narrator_voice': narratorVoice.apiValue,
        'reading_speed': readingSpeed,
        'volume': volume,
        'reduced_animations': reducedAnimations,
        'auto_play_next': autoPlayNext,
        'read_along': readAlong,
      };

  UserSettings copyWith({
    NarratorVoice? narratorVoice,
    double? readingSpeed,
    double? volume,
    bool? reducedAnimations,
    bool? autoPlayNext,
    bool? readAlong,
  }) {
    return UserSettings(
      narratorVoice: narratorVoice ?? this.narratorVoice,
      readingSpeed: readingSpeed ?? this.readingSpeed,
      volume: volume ?? this.volume,
      reducedAnimations: reducedAnimations ?? this.reducedAnimations,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      readAlong: readAlong ?? this.readAlong,
    );
  }
}
