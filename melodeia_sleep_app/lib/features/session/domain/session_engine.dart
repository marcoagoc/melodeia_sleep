import 'dart:math' as math;

import 'sleep_session_config.dart';

enum BreathPhase { inhale, exhale, complete }

class SessionFrame {
  const SessionFrame({
    required this.elapsed,
    required this.remaining,
    required this.progress,
    required this.bpm,
    required this.phase,
    required this.phaseProgress,
    required this.brightness,
    required this.scale,
    required this.isComplete,
  });

  final Duration elapsed;
  final Duration remaining;
  final double progress;
  final double bpm;
  final BreathPhase phase;
  final double phaseProgress;
  final double brightness;
  final double scale;
  final bool isComplete;
}

class SessionEngine {
  const SessionEngine(this.config);

  final SleepSessionConfig config;

  SessionFrame frameAt(Duration elapsed) {
    final totalMs = math.max(config.duration.inMilliseconds, 1);
    final elapsedMs = elapsed.inMilliseconds.clamp(0, totalMs);
    final progress = elapsedMs / totalMs;
    final bpm = _lerp(config.startBpm, config.endBpm, progress);
    final isComplete = elapsedMs >= totalMs;

    if (isComplete) {
      return SessionFrame(
        elapsed: config.duration,
        remaining: Duration.zero,
        progress: 1,
        bpm: config.endBpm,
        phase: BreathPhase.complete,
        phaseProgress: 1,
        brightness: config.lightMode == LightMode.sunrise
            ? config.endBrightness
            : 0,
        scale: 1,
        isComplete: true,
      );
    }

    final breathMs = 60000 / bpm;
    final cyclePosition = (elapsedMs % breathMs) / breathMs;
    final inhaleRatio = config.inhaleRatio.clamp(0.2, 0.8);
    final isInhale = cyclePosition <= inhaleRatio;
    final phaseProgress = isInhale
        ? cyclePosition / inhaleRatio
        : (cyclePosition - inhaleRatio) / (1 - inhaleRatio);

    final wave = isInhale ? phaseProgress : 1 - phaseProgress;
    final pulseBrightness = _lerp(
      config.startBrightness,
      config.endBrightness,
      _easeInOut(wave),
    );
    final sunriseBrightness = _lerp(
      config.startBrightness,
      config.endBrightness,
      _easeInOut(progress),
    );

    return SessionFrame(
      elapsed: Duration(milliseconds: elapsedMs),
      remaining: Duration(milliseconds: totalMs - elapsedMs),
      progress: progress,
      bpm: bpm,
      phase: isInhale ? BreathPhase.inhale : BreathPhase.exhale,
      phaseProgress: phaseProgress,
      brightness: switch (config.lightMode) {
        LightMode.off => 0,
        LightMode.breathingPulse => pulseBrightness,
        LightMode.sunrise => sunriseBrightness,
      },
      scale: switch (config.lightMode) {
        LightMode.off => 0.82,
        LightMode.breathingPulse => _lerp(0.72, 1, _easeInOut(wave)),
        LightMode.sunrise => _lerp(0.82, 1, _easeInOut(progress)),
      },
      isComplete: false,
    );
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress.clamp(0, 1);
  }

  double _easeInOut(double value) {
    final x = value.clamp(0, 1);
    return 0.5 - (math.cos(x * math.pi) / 2);
  }
}
