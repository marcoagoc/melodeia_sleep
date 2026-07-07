import 'package:flutter_test/flutter_test.dart';
import 'package:melodeia_sleep_app/features/session/domain/session_engine.dart';
import 'package:melodeia_sleep_app/features/session/domain/sleep_session_config.dart';

void main() {
  test('interpolates BPM from start to end', () {
    final config = SleepSessionConfig.defaults().copyWith(
      durationMinutes: 10,
      startBpm: 12,
      endBpm: 6,
    );
    final engine = SessionEngine(config);

    expect(engine.frameAt(Duration.zero).bpm, 12);
    expect(engine.frameAt(const Duration(minutes: 5)).bpm, closeTo(9, 0.01));
    expect(engine.frameAt(const Duration(minutes: 10)).bpm, 6);
  });

  test('uses longer exhale phase from inhale ratio', () {
    final config = SleepSessionConfig.defaults().copyWith(
      startBpm: 10,
      endBpm: 10,
      inhaleRatio: 0.4,
    );
    final engine = SessionEngine(config);

    expect(
      engine.frameAt(const Duration(milliseconds: 1000)).phase,
      BreathPhase.inhale,
    );
    expect(
      engine.frameAt(const Duration(milliseconds: 3000)).phase,
      BreathPhase.exhale,
    );
  });

  test('sunrise brightness increases over time', () {
    final config = SleepSessionConfig.defaults().copyWith(
      lightMode: LightMode.sunrise,
      startBrightness: 0.1,
      endBrightness: 0.9,
    );
    final engine = SessionEngine(config);

    final start = engine.frameAt(Duration.zero).brightness;
    final middle = engine.frameAt(config.duration ~/ 2).brightness;
    final end = engine.frameAt(config.duration).brightness;

    expect(start, lessThan(middle));
    expect(middle, lessThan(end));
  });
}
