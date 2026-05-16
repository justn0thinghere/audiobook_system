import 'package:flutter/material.dart';

import '_json_helpers.dart';

class ChildProfile {
  final String childId;
  final String? caregiverId;
  final String name;
  final int age;
  final String avatarEmoji;
  final String avatarColorHex;
  final String? favoriteGenre;
  final int listeningMinutes;
  final DateTime? createdAt;

  const ChildProfile({
    required this.childId,
    this.caregiverId,
    required this.name,
    required this.age,
    required this.avatarEmoji,
    required this.avatarColorHex,
    this.favoriteGenre,
    this.listeningMinutes = 0,
    this.createdAt,
  });

  Color get avatarColor => _hexToColor(avatarColorHex);

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      childId: safeString(json['child_id']),
      caregiverId: safeNullableString(json['caregiver_id']),
      name: safeString(json['name'], 'Child'),
      age: safeInt(json['age']) ?? 0,
      avatarEmoji: safeString(json['avatar_emoji'], '🌟'),
      avatarColorHex: safeString(json['avatar_color'], '#F5D5DD'),
      favoriteGenre: safeNullableString(json['favorite_genre']),
      listeningMinutes: safeInt(json['listening_minutes']) ?? 0,
      createdAt: safeDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'child_id': childId,
        if (caregiverId != null) 'caregiver_id': caregiverId,
        'name': name,
        'age': age,
        'avatar_emoji': avatarEmoji,
        'avatar_color': avatarColorHex,
        'favorite_genre': favoriteGenre,
        'listening_minutes': listeningMinutes,
      };

  ChildProfile copyWith({
    String? name,
    int? age,
    String? avatarEmoji,
    String? avatarColorHex,
    String? favoriteGenre,
    int? listeningMinutes,
  }) {
    return ChildProfile(
      childId: childId,
      caregiverId: caregiverId,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      favoriteGenre: favoriteGenre ?? this.favoriteGenre,
      listeningMinutes: listeningMinutes ?? this.listeningMinutes,
      createdAt: createdAt,
    );
  }

  static Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFF5D5DD;
    return Color(value);
  }

  static String colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
