import 'package:hive/hive.dart';

part 'vocab_entry.g.dart';

@HiveType(typeId: 0)
class VocabEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farsi;

  @HiveField(2)
  final String transliteration;

  @HiveField(3)
  final String english;

  @HiveField(4)
  final String? partOfSpeech;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final List<VocabExample> examples;

  @HiveField(7)
  final String? imagePath;

  @HiveField(8)
  final List<String> tags;

  @HiveField(9)
  final String sourceFile;

  @HiveField(10)
  final int? lessonNumber;

  @HiveField(11)
  final String? date;

  @HiveField(12)
  final bool needsReview;

  const VocabEntry({
    required this.id,
    required this.farsi,
    required this.transliteration,
    required this.english,
    this.partOfSpeech,
    this.notes = '',
    this.examples = const [],
    this.imagePath,
    this.tags = const [],
    this.sourceFile = '',
    this.lessonNumber,
    this.date,
    this.needsReview = false,
  });

  factory VocabEntry.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>? ?? {};
    final rawExamples = json['examples'] as List<dynamic>? ?? [];
    return VocabEntry(
      id: json['id'] as String? ?? '',
      farsi: json['farsi'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      english: json['english'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      notes: json['notes'] as String? ?? '',
      examples: rawExamples
          .map((e) => VocabExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      imagePath: json['imagePath'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      sourceFile: source['file'] as String? ?? '',
      lessonNumber: source['lesson'] as int?,
      date: source['date'] as String?,
      needsReview: json['needsReview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farsi': farsi,
        'transliteration': transliteration,
        'english': english,
        'partOfSpeech': partOfSpeech,
        'notes': notes,
        'examples': examples.map((e) => e.toJson()).toList(),
        'imagePath': imagePath,
        'tags': tags,
        'source': {
          'file': sourceFile,
          'lesson': lessonNumber,
          'date': date,
        },
        'needsReview': needsReview,
      };

  bool get isEmpty => farsi.isEmpty && english.isEmpty && transliteration.isEmpty;

  String get displayEnglish => english.isNotEmpty ? english : transliteration;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VocabEntry && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 1)
class VocabExample {
  @HiveField(0)
  final String farsi;

  @HiveField(1)
  final String transliteration;

  @HiveField(2)
  final String english;

  const VocabExample({
    this.farsi = '',
    this.transliteration = '',
    this.english = '',
  });

  factory VocabExample.fromJson(Map<String, dynamic> json) => VocabExample(
        farsi: json['farsi'] as String? ?? '',
        transliteration: json['transliteration'] as String? ?? '',
        english: json['english'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'farsi': farsi,
        'transliteration': transliteration,
        'english': english,
      };
}
