enum SoundMode { off, whiteNoise, breathGuide, heartbeat, mixed }

enum LightMode { off, breathingPulse, sunrise }

class SleepSessionConfig {
  const SleepSessionConfig({
    required this.durationMinutes,
    required this.startBpm,
    required this.endBpm,
    required this.inhaleRatio,
    required this.startBrightness,
    required this.endBrightness,
    required this.soundMode,
    required this.lightMode,
    required this.soundVolume,
    required this.colorWarmth,
    this.notes,
  });

  factory SleepSessionConfig.defaults() {
    return const SleepSessionConfig(
      durationMinutes: 20,
      startBpm: 11,
      endBpm: 6,
      inhaleRatio: 0.4,
      startBrightness: 0.18,
      endBrightness: 0.78,
      soundMode: SoundMode.breathGuide,
      lightMode: LightMode.breathingPulse,
      soundVolume: 0.45,
      colorWarmth: 0.65,
    );
  }

  factory SleepSessionConfig.fromMap(Map<String, Object?> map) {
    return SleepSessionConfig(
      durationMinutes: (map['durationMinutes'] as num?)?.round() ?? 20,
      startBpm: (map['startBpm'] as num?)?.toDouble() ?? 11,
      endBpm: (map['endBpm'] as num?)?.toDouble() ?? 6,
      inhaleRatio: (map['inhaleRatio'] as num?)?.toDouble() ?? 0.4,
      startBrightness: (map['startBrightness'] as num?)?.toDouble() ?? 0.18,
      endBrightness: (map['endBrightness'] as num?)?.toDouble() ?? 0.78,
      soundMode: SoundMode.values.byName(
        (map['soundMode'] as String?) ?? SoundMode.breathGuide.name,
      ),
      lightMode: LightMode.values.byName(
        (map['lightMode'] as String?) ?? LightMode.breathingPulse.name,
      ),
      soundVolume: (map['soundVolume'] as num?)?.toDouble() ?? 0.45,
      colorWarmth: (map['colorWarmth'] as num?)?.toDouble() ?? 0.65,
      notes: map['notes'] as String?,
    );
  }

  final int durationMinutes;
  final double startBpm;
  final double endBpm;
  final double inhaleRatio;
  final double startBrightness;
  final double endBrightness;
  final SoundMode soundMode;
  final LightMode lightMode;
  final double soundVolume;
  final double colorWarmth;
  final String? notes;

  Duration get duration => Duration(minutes: durationMinutes);

  Map<String, Object?> toMap() {
    return {
      'durationMinutes': durationMinutes,
      'startBpm': startBpm,
      'endBpm': endBpm,
      'inhaleRatio': inhaleRatio,
      'startBrightness': startBrightness,
      'endBrightness': endBrightness,
      'soundMode': soundMode.name,
      'lightMode': lightMode.name,
      'soundVolume': soundVolume,
      'colorWarmth': colorWarmth,
      'notes': notes,
    };
  }

  SleepSessionConfig copyWith({
    int? durationMinutes,
    double? startBpm,
    double? endBpm,
    double? inhaleRatio,
    double? startBrightness,
    double? endBrightness,
    SoundMode? soundMode,
    LightMode? lightMode,
    double? soundVolume,
    double? colorWarmth,
    String? notes,
  }) {
    return SleepSessionConfig(
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startBpm: startBpm ?? this.startBpm,
      endBpm: endBpm ?? this.endBpm,
      inhaleRatio: inhaleRatio ?? this.inhaleRatio,
      startBrightness: startBrightness ?? this.startBrightness,
      endBrightness: endBrightness ?? this.endBrightness,
      soundMode: soundMode ?? this.soundMode,
      lightMode: lightMode ?? this.lightMode,
      soundVolume: soundVolume ?? this.soundVolume,
      colorWarmth: colorWarmth ?? this.colorWarmth,
      notes: notes ?? this.notes,
    );
  }
}
