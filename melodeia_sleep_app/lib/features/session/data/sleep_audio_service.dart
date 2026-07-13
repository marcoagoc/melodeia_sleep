import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/sleep_session_config.dart';

class SleepAudioService {
  SleepAudioService({AudioPlayer? ambientPlayer, AudioPlayer? cuePlayer})
    : _ambientPlayer = ambientPlayer ?? AudioPlayer(),
      _cuePlayer = cuePlayer ?? AudioPlayer();

  final AudioPlayer _ambientPlayer;
  final AudioPlayer _cuePlayer;

  SoundMode _currentMode = SoundMode.off;

  Future<void> prepare(SoundMode mode, double volume) async {
    _currentMode = mode;
    final clampedVolume = volume.clamp(0.0, 1.0);

    try {
      // Reset players
      await stop();

      if (mode == SoundMode.off) {
        return;
      }

      // Configure Ambient Player
      if (mode == SoundMode.whiteNoise || mode == SoundMode.mixed) {
        await _ambientPlayer.setVolume(clampedVolume);
        await _ambientPlayer.setAsset('assets/audio/white_noise_loop.mp3');
        await _ambientPlayer.setLoopMode(LoopMode.one);
        unawaited(_ambientPlayer.play());
      } else if (mode == SoundMode.heartbeat) {
        await _ambientPlayer.setVolume(clampedVolume);
        await _ambientPlayer.setAsset('assets/audio/heartbeat_loop.mp3');
        await _ambientPlayer.setLoopMode(LoopMode.one);
        unawaited(_ambientPlayer.play());
      }

      // Configure Cue Player volume
      if (mode == SoundMode.breathGuide || mode == SoundMode.mixed) {
        await _cuePlayer.setVolume(clampedVolume);
        await _cuePlayer.setLoopMode(LoopMode.off);
      }
    } catch (e) {
      debugPrint('Error preparing SleepAudioService: $e');
    }
  }

  Future<void> playInhaleCue(double volume) async {
    if (_currentMode != SoundMode.breathGuide &&
        _currentMode != SoundMode.mixed) {
      return;
    }
    try {
      await _cuePlayer.setVolume(volume.clamp(0.0, 1.0));
      await _cuePlayer.setAsset('assets/audio/breath_in.mp3');
      await _cuePlayer.seek(Duration.zero);
      await _cuePlayer.play();
    } catch (e) {
      debugPrint('Error playing inhale cue: $e');
    }
  }

  Future<void> playExhaleCue(double volume) async {
    if (_currentMode != SoundMode.breathGuide &&
        _currentMode != SoundMode.mixed) {
      return;
    }
    try {
      await _cuePlayer.setVolume(volume.clamp(0.0, 1.0));
      await _cuePlayer.setAsset('assets/audio/breath_out.mp3');
      await _cuePlayer.seek(Duration.zero);
      await _cuePlayer.play();
    } catch (e) {
      debugPrint('Error playing exhale cue: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _ambientPlayer.pause();
      await _cuePlayer.pause();
    } catch (e) {
      debugPrint('Error pausing SleepAudioService: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_currentMode == SoundMode.whiteNoise ||
          _currentMode == SoundMode.heartbeat ||
          _currentMode == SoundMode.mixed) {
        unawaited(_ambientPlayer.play());
      }
    } catch (e) {
      debugPrint('Error resuming SleepAudioService: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _ambientPlayer.stop();
      await _cuePlayer.stop();
    } catch (e) {
      debugPrint('Error stopping SleepAudioService: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _ambientPlayer.dispose();
      await _cuePlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing SleepAudioService: $e');
    }
  }
}
