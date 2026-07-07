enum SleepRating { good, okay, bad }

class SleepLog {
  const SleepLog({
    required this.id,
    required this.date,
    required this.rating,
    required this.notes,
    required this.tags,
    this.linkedSessionId,
  });

  factory SleepLog.fromMap(Map<String, Object?> map) {
    return SleepLog(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      rating: SleepRating.values.byName(map['rating'] as String),
      notes: (map['notes'] as String?) ?? '',
      tags: ((map['tags'] as List?) ?? const <Object?>[])
          .map((tag) => tag.toString())
          .toList(),
      linkedSessionId: map['linkedSessionId'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final SleepRating rating;
  final String notes;
  final List<String> tags;
  final String? linkedSessionId;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'rating': rating.name,
      'notes': notes,
      'tags': tags,
      'linkedSessionId': linkedSessionId,
    };
  }
}
