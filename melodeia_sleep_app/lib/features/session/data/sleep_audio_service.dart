import 'package:just_audio/just_audio.dart';

import '../domain/sleep_session_config.dart';

class SleepAudioService {
  SleepAudioService({AudioPlayer? audioPlayer})
    : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;

  Future<void> prepare(SoundMode mode, double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0, 1));
    // Audio assets are intentionally abstracted here. Drop loopable files into
    // assets/audio/ and map modes to asset paths when production assets exist.
    if (mode == SoundMode.off) {
      await _audioPlayer.stop();
    }
  }

  Future<void> stop() => _audioPlayer.stop();

  Future<void> dispose() => _audioPlayer.dispose();
}
