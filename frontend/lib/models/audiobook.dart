import '_json_helpers.dart';

class Audiobook {
  final String? audiobookId;
  final String title;
  final String? author;
  final String? description;
  final String? topic;
  final String? category;
  final String? difficulty;
  final String? type;
  final String? contentText;
  final String? audioFile;
  final String? sourceFile;
  final String? coverImage;
  final int? durationMinutes;
  final String? language;
  final String? ageGroup;
  final String? tags;
  final bool isGenerated;
  final bool isUserUploaded;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Audiobook({
    this.audiobookId,
    required this.title,
    this.author,
    this.description,
    this.topic,
    this.category,
    this.difficulty,
    this.type,
    this.contentText,
    this.audioFile,
    this.sourceFile,
    this.coverImage,
    this.durationMinutes,
    this.language,
    this.ageGroup,
    this.tags,
    this.isGenerated = false,
    this.isUserUploaded = false,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Audiobook.fromJson(Map<String, dynamic> json) {
    return Audiobook(
      audiobookId: safeNullableString(json['audiobook_id']),
      title: safeString(json['title'], 'Untitled'),
      author: safeNullableString(json['author']),
      description: safeNullableString(json['description']),
      topic: safeNullableString(json['topic']),
      category: safeNullableString(json['category']),
      difficulty: safeNullableString(json['difficulty']),
      type: safeNullableString(json['type']),
      contentText: safeNullableString(json['content_text']),
      audioFile: safeNullableString(json['audio_file']),
      sourceFile: safeNullableString(json['source_file']),
      coverImage: safeNullableString(json['cover_image']),
      durationMinutes: safeInt(json['duration_minutes']),
      language: safeNullableString(json['language']),
      ageGroup: safeNullableString(json['age_group']),
      tags: safeNullableString(json['tags']),
      isGenerated: safeBool(json['is_generated']),
      isUserUploaded: safeBool(json['is_user_uploaded']),
      status: safeNullableString(json['status']),
      createdAt: safeDate(json['created_at']),
      updatedAt: safeDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'audiobook_id': audiobookId,
        'title': title,
        'author': author,
        'description': description,
        'topic': topic,
        'category': category,
        'difficulty': difficulty,
        'type': type,
        'content_text': contentText,
        'audio_file': audioFile,
        'source_file': sourceFile,
        'cover_image': coverImage,
        'duration_minutes': durationMinutes,
        'language': language,
        'age_group': ageGroup,
        'tags': tags,
        'is_generated': isGenerated,
        'is_user_uploaded': isUserUploaded,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
