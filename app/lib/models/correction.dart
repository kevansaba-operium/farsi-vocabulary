import 'dart:convert';

/// A user-authored correction to a vocabulary entry.
/// Stored as JSON in a Hive Box<String> keyed by [entryId].
class Correction {
  final String entryId;
  final String? farsi;
  final String? transliteration;
  final String? english;
  final String? partOfSpeech;
  final String? notes;

  const Correction({
    required this.entryId,
    this.farsi,
    this.transliteration,
    this.english,
    this.partOfSpeech,
    this.notes,
  });

  bool get isEmpty =>
      farsi == null &&
      transliteration == null &&
      english == null &&
      partOfSpeech == null &&
      notes == null;

  Correction copyWith({
    String? farsi,
    String? transliteration,
    String? english,
    String? partOfSpeech,
    String? notes,
  }) {
    return Correction(
      entryId: entryId,
      farsi: farsi ?? this.farsi,
      transliteration: transliteration ?? this.transliteration,
      english: english ?? this.english,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        if (farsi != null) 'farsi': farsi,
        if (transliteration != null) 'transliteration': transliteration,
        if (english != null) 'english': english,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
        if (notes != null) 'notes': notes,
      };

  factory Correction.fromJson(Map<String, dynamic> json) => Correction(
        entryId: json['entryId'] as String,
        farsi: json['farsi'] as String?,
        transliteration: json['transliteration'] as String?,
        english: json['english'] as String?,
        partOfSpeech: json['partOfSpeech'] as String?,
        notes: json['notes'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory Correction.fromJsonString(String s) =>
      Correction.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
