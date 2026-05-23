import 'package:flutter/material.dart';

import '_json_helpers.dart';

class ChildInsight {
  final String childId;
  final String name;
  final String avatarEmoji;
  final String avatarColorHex;
  final String? favoriteGenre;
  final int listeningMinutes;
  final int sessions;
  final int completed;
  final int completionRate;
  final String? topMood;

  const ChildInsight({
    required this.childId,
    required this.name,
    required this.avatarEmoji,
    required this.avatarColorHex,
    this.favoriteGenre,
    this.listeningMinutes = 0,
    this.sessions = 0,
    this.completed = 0,
    this.completionRate = 0,
    this.topMood,
  });

  Color get avatarColor => _hexToColor(avatarColorHex);

  factory ChildInsight.fromJson(Map<String, dynamic> json) {
    return ChildInsight(
      childId: safeString(json['child_id']),
      name: safeString(json['name'], 'Child'),
      avatarEmoji: safeString(json['avatar_emoji'], '🌟'),
      avatarColorHex: safeString(json['avatar_color'], '#F5D5DD'),
      favoriteGenre: safeNullableString(json['favorite_genre']),
      listeningMinutes: safeInt(json['listening_minutes']) ?? 0,
      sessions: safeInt(json['sessions']) ?? 0,
      completed: safeInt(json['completed']) ?? 0,
      completionRate: safeInt(json['completion_rate']) ?? 0,
      topMood: safeNullableString(json['top_mood']),
    );
  }

  static Color _hexToColor(String hex) {
    var cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFF5D5DD;
    return Color(value);
  }
}

class InsightsOverview {
  final int totalChildren;
  final int totalListeningMinutes;
  final int totalSessions;
  final int completedSessions;
  final int completionRate;
  final String? topMood;
  final Map<String, int> moodBreakdown;
  final List<ChildInsight> children;

  const InsightsOverview({
    this.totalChildren = 0,
    this.totalListeningMinutes = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.completionRate = 0,
    this.topMood,
    this.moodBreakdown = const {},
    this.children = const [],
  });

  factory InsightsOverview.empty() => const InsightsOverview();

  factory InsightsOverview.fromJson(Map<String, dynamic> json) {
    final rawMoods = json['mood_breakdown'];
    final moods = <String, int>{};
    if (rawMoods is Map) {
      rawMoods.forEach((key, value) {
        moods[key.toString()] = safeInt(value) ?? 0;
      });
    }
    final rawChildren = json['children'];
    final children = rawChildren is List
        ? rawChildren
            .whereType<Map<String, dynamic>>()
            .map(ChildInsight.fromJson)
            .toList()
        : <ChildInsight>[];

    return InsightsOverview(
      totalChildren: safeInt(json['total_children']) ?? 0,
      totalListeningMinutes: safeInt(json['total_listening_minutes']) ?? 0,
      totalSessions: safeInt(json['total_sessions']) ?? 0,
      completedSessions: safeInt(json['completed_sessions']) ?? 0,
      completionRate: safeInt(json['completion_rate']) ?? 0,
      topMood: safeNullableString(json['top_mood']),
      moodBreakdown: moods,
      children: children,
    );
  }
}
