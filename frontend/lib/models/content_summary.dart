import '_json_helpers.dart';

class ContentSummary {
  final int totalItems;
  final int audioFiles;
  final int textFiles;
  final int aiGenerated;

  const ContentSummary({
    required this.totalItems,
    required this.audioFiles,
    required this.textFiles,
    required this.aiGenerated,
  });

  factory ContentSummary.empty() => const ContentSummary(
        totalItems: 0,
        audioFiles: 0,
        textFiles: 0,
        aiGenerated: 0,
      );

  factory ContentSummary.fromJson(Map<String, dynamic> json) {
    return ContentSummary(
      totalItems: safeInt(json['total_items']) ?? 0,
      audioFiles: safeInt(json['audio_files']) ?? 0,
      textFiles: safeInt(json['text_files']) ?? 0,
      aiGenerated: safeInt(json['ai_generated']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_items': totalItems,
        'audio_files': audioFiles,
        'text_files': textFiles,
        'ai_generated': aiGenerated,
      };
}
