import 'package:flutter_test/flutter_test.dart';
import 'package:melodeia_sleep_app/features/journal/domain/sleep_log.dart';
import 'package:melodeia_sleep_app/features/session/domain/sleep_session_config.dart';

void main() {
  test('session config round trips through map', () {
    final config = SleepSessionConfig.defaults().copyWith(
      durationMinutes: 30,
      soundMode: SoundMode.mixed,
      lightMode: LightMode.sunrise,
    );

    final restored = SleepSessionConfig.fromMap(config.toMap());

    expect(restored.durationMinutes, 30);
    expect(restored.soundMode, SoundMode.mixed);
    expect(restored.lightMode, LightMode.sunrise);
  });

  test('sleep log round trips through map', () {
    final log = SleepLog(
      id: 'log-1',
      date: DateTime.utc(2026, 7, 7),
      rating: SleepRating.good,
      notes: 'Slept deeply.',
      tags: const ['session-complete'],
      linkedSessionId: 'session-1',
    );

    final restored = SleepLog.fromMap(log.toMap());

    expect(restored.id, 'log-1');
    expect(restored.rating, SleepRating.good);
    expect(restored.notes, 'Slept deeply.');
    expect(restored.tags, ['session-complete']);
    expect(restored.linkedSessionId, 'session-1');
  });
}
