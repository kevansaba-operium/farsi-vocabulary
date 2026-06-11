import 'package:hive/hive.dart';

part 'card_state.g.dart';

/// SM-2 spaced repetition state for a single vocabulary card.
@HiveType(typeId: 2)
class CardState {
  @HiveField(0)
  final String entryId;

  /// SM-2 ease factor (starts at 2.5)
  @HiveField(1)
  double easeFactor;

  /// Number of times reviewed
  @HiveField(2)
  int repetitions;

  /// Current interval in days
  @HiveField(3)
  int intervalDays;

  /// Epoch milliseconds of the next due date (null = never reviewed)
  @HiveField(4)
  int? nextDueMs;

  /// Total reviews performed
  @HiveField(5)
  int totalReviews;

  /// Whether the card is in the user's favorites
  @HiveField(6)
  bool isFavorite;

  CardState({
    required this.entryId,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.intervalDays = 1,
    this.nextDueMs,
    this.totalReviews = 0,
    this.isFavorite = false,
  });

  bool get isDue {
    if (nextDueMs == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= nextDueMs!;
  }

  bool get hasBeenStudied => totalReviews > 0;

  DateTime? get nextDue =>
      nextDueMs == null ? null : DateTime.fromMillisecondsSinceEpoch(nextDueMs!);

  /// Record a review with quality 0-5 (SM-2 algorithm).
  /// 0-2 = fail, 3-5 = pass.
  void recordReview(int quality) {
    assert(quality >= 0 && quality <= 5);
    totalReviews++;

    if (quality < 3) {
      // Failed – reset repetitions but keep ease factor
      repetitions = 0;
      intervalDays = 1;
    } else {
      // Passed
      switch (repetitions) {
        case 0:
          intervalDays = 1;
        case 1:
          intervalDays = 6;
        default:
          intervalDays = (intervalDays * easeFactor).round();
      }
      repetitions++;
      // Update ease factor
      easeFactor += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
      if (easeFactor < 1.3) easeFactor = 1.3;
    }

    nextDueMs = DateTime.now()
        .add(Duration(days: intervalDays))
        .millisecondsSinceEpoch;
  }
}
