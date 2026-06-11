class Lesson {
  final String id;
  final String label;
  final String? date;
  final String? file;
  final List<String> entryIds;

  const Lesson({
    required this.id,
    required this.label,
    this.date,
    this.file,
    this.entryIds = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        label: json['label'] as String,
        date: json['date'] as String?,
        file: json['file'] as String?,
        entryIds: (json['entryIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  bool get isLesson =>
      file?.toLowerCase().startsWith('lesson_') ?? label.startsWith('Lesson');
}
