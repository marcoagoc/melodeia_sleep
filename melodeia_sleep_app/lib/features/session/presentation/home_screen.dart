import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../auth/auth_service.dart';
import '../../auth/firebase_bootstrap.dart';
import '../../journal/domain/sleep_log.dart';
import '../data/sleep_audio_service.dart';
import '../data/sleep_repository.dart';
import '../domain/session_engine.dart';
import '../domain/sleep_session_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.firebaseStatus, super.key});

  final FirebaseBootstrapStatus firebaseStatus;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = SleepRepository();
  final _authService = AuthService();
  final _notesController = TextEditingController();

  SleepSessionConfig _config = SleepSessionConfig.defaults();
  List<SleepLog> _logs = const [];
  User? _user;
  bool _loading = true;
  bool _skippedAuth = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = widget.firebaseStatus.isReady
        ? _authService.currentUser
        : null;
    final config = await _repository.loadLastConfig();
    final logs = await _repository.loadLocalLogs();

    if (user != null) {
      await _repository.syncAllLocalLogs(
        uid: user.uid,
        firebaseReady: widget.firebaseStatus.isReady,
      );
    }

    if (!mounted) return;
    setState(() {
      _user = user;
      _config = config;
      _logs = logs;
      _loading = false;
    });
  }

  void _showSignInScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => fui.SignInScreen(
          providers: [fui.EmailAuthProvider()],
          actions: [
            fui.AuthStateChangeAction<fui.SignedIn>((context, state) {
              Navigator.pop(context);
              _load();
            }),
            fui.AuthStateChangeAction<fui.UserCreated>((context, state) {
              Navigator.pop(context);
              _load();
            }),
          ],
        ),
      ),
    ).then((_) {
      _load();
    });
  }

  void _showRegistrationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => fui.RegisterScreen(
          providers: [fui.EmailAuthProvider()],
          actions: [
            fui.AuthStateChangeAction<fui.SignedIn>((context, state) {
              Navigator.pop(context);
              _load();
            }),
            fui.AuthStateChangeAction<fui.UserCreated>((context, state) {
              Navigator.pop(context);
              _load();
            }),
          ],
        ),
      ),
    ).then((_) {
      _load();
    });
  }

  void _suggestRegistration() {
    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(
            'Save your progress!',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Create a registered account to sync your sleep journal and settings to the cloud, so you never lose them if you change devices.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _showRegistrationScreen();
              },
              child: const Text('Register Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() {
      _skippedAuth = false;
    });
    await _load();
  }

  Future<void> _saveConfig(SleepSessionConfig config) async {
    setState(() => _config = config);
    await _repository.saveLastConfig(config);
  }

  Future<void> _startSession() async {
    await _repository.saveLastConfig(_config);
    if (!mounted) return;
    final log = await Navigator.of(context).push<SleepLog>(
      MaterialPageRoute(builder: (_) => ActiveSessionScreen(config: _config)),
    );
    if (log == null) return;
    await _repository.saveLogLocally(log);
    if (_user != null) {
      await _repository.syncLog(
        uid: _user!.uid,
        log: log,
        firebaseReady: widget.firebaseStatus.isReady,
      );
    }
    final logs = await _repository.loadLocalLogs();
    if (!mounted) return;
    setState(() => _logs = logs);

    if (widget.firebaseStatus.isReady && _authService.isAnonymous) {
      _suggestRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (widget.firebaseStatus.isReady && _user == null && !_skippedAuth) {
      return WelcomeScreen(
        onContinueAsGuest: () async {
          setState(() => _loading = true);
          try {
            await _authService.signInAnonymously();
          } catch (e) {
            debugPrint('Failed to sign in anonymously: $e');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Guest mode active locally. (Could not connect online: $e)',
                ),
              ),
            );
          }
          setState(() {
            _skippedAuth = true;
          });
          await _load();
        },
        onSignInRegister: _showSignInScreen,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  firebaseStatus: widget.firebaseStatus,
                  user: _user,
                  onSignIn: _showSignInScreen,
                  onSignOut: _signOut,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              sliver: SliverToBoxAdapter(
                child: SessionSetupCard(
                  config: _config,
                  onChanged: _saveConfig,
                  onStart: _startSession,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverToBoxAdapter(child: JournalCard(logs: _logs)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.firebaseStatus,
    required this.user,
    required this.onSignIn,
    required this.onSignOut,
  });

  final FirebaseBootstrapStatus firebaseStatus;
  final User? user;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Melodeia Sleep',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A calm sound and light coach for slower breathing, sunrise fades, and nightly reflection.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        if (!firebaseStatus.isReady)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.tertiaryContainer.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_outlined, color: colors.onSurface),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      firebaseStatus.message ??
                          'Cloud sync will activate after Firebase setup.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (user?.isAnonymous ?? true)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guest Mode (Offline sync)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onSignIn,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colors.primary,
                    ),
                    child: const Text('Sign In / Register'),
                  ),
                ],
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Synced as ${user?.email ?? "User"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: onSignOut,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: colors.error,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class SessionSetupCard extends StatelessWidget {
  const SessionSetupCard({
    required this.config,
    required this.onChanged,
    required this.onStart,
    super.key,
  });

  final SleepSessionConfig config;
  final ValueChanged<SleepSessionConfig> onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tonight session',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _SliderRow(
              label: 'Duration',
              valueLabel: '${config.durationMinutes} min',
              value: config.durationMinutes.toDouble(),
              min: 5,
              max: 90,
              divisions: 17,
              onChanged: (value) =>
                  onChanged(config.copyWith(durationMinutes: value.round())),
            ),
            _SliderRow(
              label: 'Start breath',
              valueLabel: '${config.startBpm.toStringAsFixed(1)} BPM',
              value: config.startBpm,
              min: 5,
              max: 14,
              divisions: 18,
              onChanged: (value) => onChanged(config.copyWith(startBpm: value)),
            ),
            _SliderRow(
              label: 'End breath',
              valueLabel: '${config.endBpm.toStringAsFixed(1)} BPM',
              value: config.endBpm,
              min: 4,
              max: 10,
              divisions: 12,
              onChanged: (value) => onChanged(config.copyWith(endBpm: value)),
            ),
            _SliderRow(
              label: 'Inhale share',
              valueLabel: '${(config.inhaleRatio * 100).round()}%',
              value: config.inhaleRatio,
              min: 0.3,
              max: 0.55,
              divisions: 5,
              onChanged: (value) =>
                  onChanged(config.copyWith(inhaleRatio: value)),
            ),
            _SliderRow(
              label: 'Brightness',
              valueLabel:
                  '${(config.startBrightness * 100).round()}-${(config.endBrightness * 100).round()}%',
              value: config.endBrightness,
              min: 0.2,
              max: 1,
              divisions: 8,
              onChanged: (value) =>
                  onChanged(config.copyWith(endBrightness: value)),
            ),
            const SizedBox(height: 12),
            Text('Sound mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SoundMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(_soundLabel(mode)),
                  selected: config.soundMode == mode,
                  onSelected: (_) =>
                      onChanged(config.copyWith(soundMode: mode)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Light mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<LightMode>(
              segments: const [
                ButtonSegment(
                  value: LightMode.off,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Off'),
                ),
                ButtonSegment(
                  value: LightMode.breathingPulse,
                  icon: Icon(Icons.blur_circular_outlined),
                  label: Text('Breath'),
                ),
                ButtonSegment(
                  value: LightMode.sunrise,
                  icon: Icon(Icons.wb_sunny_outlined),
                  label: Text('Sunrise'),
                ),
              ],
              selected: {config.lightMode},
              onSelectionChanged: (selection) =>
                  onChanged(config.copyWith(lightMode: selection.first)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.nightlight_round),
              label: const Text('Start sleep session'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Relaxation support only. Melodeia Sleep is not a medical device.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _soundLabel(SoundMode mode) {
    return switch (mode) {
      SoundMode.off => 'Off',
      SoundMode.whiteNoise => 'White noise',
      SoundMode.breathGuide => 'Breath guide',
      SoundMode.heartbeat => 'Heartbeat',
      SoundMode.mixed => 'Mixed',
    };
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(valueLabel),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({required this.config, super.key});

  final SleepSessionConfig config;

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with SingleTickerProviderStateMixin {
  late final SessionEngine _engine;
  final _audioService = SleepAudioService();
  final _notesController = TextEditingController();
  late final Ticker _ticker;

  // Notifiers for decoupled, high-performance micro-rebuilds
  late final ValueNotifier<Duration> _elapsedNotifier;
  late final ValueNotifier<int> _remainingSecondsNotifier;
  late final ValueNotifier<BreathPhase> _phaseNotifier;
  late final ValueNotifier<double> _bpmNotifier;

  Duration _sessionOffset = Duration.zero;
  Duration _lastTickElapsed = Duration.zero;
  bool _paused = false;
  BreathPhase _prevPhase = BreathPhase.complete;

  @override
  void initState() {
    super.initState();
    _engine = SessionEngine(widget.config);
    _audioService.prepare(widget.config.soundMode, widget.config.soundVolume);

    final initialFrame = _engine.frameAt(Duration.zero);
    _elapsedNotifier = ValueNotifier<Duration>(Duration.zero);
    _remainingSecondsNotifier = ValueNotifier<int>(
      initialFrame.remaining.inSeconds,
    );
    _phaseNotifier = ValueNotifier<BreathPhase>(initialFrame.phase);
    _bpmNotifier = ValueNotifier<double>(initialFrame.bpm);

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audioService.stop();
    _audioService.dispose();
    _notesController.dispose();
    _elapsedNotifier.dispose();
    _remainingSecondsNotifier.dispose();
    _phaseNotifier.dispose();
    _bpmNotifier.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_paused) return;
    _lastTickElapsed = elapsed;
    final totalElapsed = _sessionOffset + elapsed;
    final frame = _engine.frameAt(totalElapsed);

    // Notify listeners directly without rebuilding the entire page Scaffold
    _elapsedNotifier.value = totalElapsed;

    final remainingSecs = frame.remaining.inSeconds;
    if (_remainingSecondsNotifier.value != remainingSecs) {
      _remainingSecondsNotifier.value = remainingSecs;
    }

    if (frame.phase != _prevPhase && !frame.isComplete) {
      _prevPhase = frame.phase;
      _phaseNotifier.value = frame.phase;

      if (frame.phase == BreathPhase.inhale) {
        _audioService.playInhaleCue(widget.config.soundVolume);
      } else if (frame.phase == BreathPhase.exhale) {
        _audioService.playExhaleCue(widget.config.soundVolume);
      }
    }

    if (_bpmNotifier.value != frame.bpm) {
      _bpmNotifier.value = frame.bpm;
    }

    if (frame.isComplete) {
      if (_ticker.isActive) _ticker.stop();
      _audioService.stop();
      _showCompletionSheet();
    }
  }

  Future<void> _showCompletionSheet() async {
    if (_ticker.isActive) _ticker.stop();
    await _audioService.stop();
    if (!mounted) return;
    final log = await showModalBottomSheet<SleepLog>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CompletionSheet(
          notesController: _notesController,
          onSave: (rating) {
            Navigator.of(context).pop(
              SleepLog(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                date: DateTime.now(),
                rating: rating,
                notes: _notesController.text.trim(),
                tags: const ['session-complete'],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    Navigator.of(context).pop(log);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glowColor = Color.lerp(
      const Color(0xff12475f),
      const Color(0xffffc76f),
      widget.config.colorWarmth,
    )!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Stop session',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<int>(
                    valueListenable: _remainingSecondsNotifier,
                    builder: (context, remainingSeconds, _) {
                      final duration = Duration(seconds: remainingSeconds);
                      return Text(_formatDuration(duration));
                    },
                  ),
                ],
              ),
              const Spacer(),
              // Optimize: Listen only to elapsed time. Pre-build the glow once and reuse it.
              ValueListenableBuilder<Duration>(
                valueListenable: _elapsedNotifier,
                builder: (context, elapsed, child) {
                  final frame = _engine.frameAt(elapsed);
                  return Transform.scale(
                    scale: frame.scale,
                    child: Opacity(
                      opacity: frame.brightness.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _BreathingCircleGlow(glowColor: glowColor),
              ),
              const SizedBox(height: 44),
              ValueListenableBuilder<BreathPhase>(
                valueListenable: _phaseNotifier,
                builder: (context, phase, _) {
                  final phaseText = switch (phase) {
                    BreathPhase.inhale => 'Breathe in',
                    BreathPhase.exhale => 'Breathe out',
                    BreathPhase.complete => 'Complete',
                  };
                  return Text(
                    phaseText,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: _bpmNotifier,
                builder: (context, bpm, _) {
                  return Text(
                    '${bpm.toStringAsFixed(1)} breaths per minute',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  );
                },
              ),
              const SizedBox(height: 34),
              ValueListenableBuilder<Duration>(
                valueListenable: _elapsedNotifier,
                builder: (context, elapsed, _) {
                  final frame = _engine.frameAt(elapsed);
                  return LinearProgressIndicator(value: frame.progress);
                },
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _paused = !_paused;
                    if (_paused) {
                      if (_ticker.isActive) _ticker.stop();
                      _sessionOffset += _lastTickElapsed;
                      _lastTickElapsed = Duration.zero;
                      _audioService.pause();
                    } else {
                      _ticker.start();
                      _audioService.resume();
                    }
                  });
                },
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                label: Text(_paused ? 'Resume' : 'Pause'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class CompletionSheet extends StatelessWidget {
  const CompletionSheet({
    required this.notesController,
    required this.onSave,
    super.key,
  });

  final TextEditingController notesController;
  final ValueChanged<SleepRating> onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your last night?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => onSave(SleepRating.good),
                  child: const Text('Good'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onSave(SleepRating.okay),
                  child: const Text('Okay'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onSave(SleepRating.bad),
                  child: const Text('Bad'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class JournalCard extends StatelessWidget {
  const JournalCard({required this.logs, super.key});

  final List<SleepLog> logs;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep journal',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              Text(
                'Complete a session to record how the night felt.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...logs
                  .take(5)
                  .map(
                    (log) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_ratingIcon(log.rating)),
                      title: Text(_ratingLabel(log.rating)),
                      subtitle: Text(
                        log.notes.isEmpty ? _formatDate(log.date) : log.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(_formatDate(log.date)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  IconData _ratingIcon(SleepRating rating) {
    return switch (rating) {
      SleepRating.good => Icons.sentiment_satisfied_alt,
      SleepRating.okay => Icons.sentiment_neutral,
      SleepRating.bad => Icons.sentiment_dissatisfied,
    };
  }

  String _ratingLabel(SleepRating rating) {
    return switch (rating) {
      SleepRating.good => 'Good night',
      SleepRating.okay => 'Okay night',
      SleepRating.bad => 'Hard night',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _BreathingCircleGlow extends StatelessWidget {
  const _BreathingCircleGlow({required this.glowColor});

  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            glowColor,
            glowColor.withValues(alpha: 0.45),
            glowColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.2, 0.55, 1.0],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.onContinueAsGuest,
    required this.onSignInRegister,
    super.key,
  });

  final VoidCallback onContinueAsGuest;
  final VoidCallback onSignInRegister;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff091420), Color(0xff060c13)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),
            child: Column(
              children: [
                const Spacer(),
                const _GlowingSessionCircle(),
                const SizedBox(height: 48),
                Text(
                  'Melodeia Sleep',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'A calm sound and light coach for slower breathing, sunrise fades, and nightly reflection.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xffa0b2c6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onSignInRegister,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In / Register'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onContinueAsGuest,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: const Color(0xff8bc5e5),
                    side: const BorderSide(
                      color: Color(0xff3a546c),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start sleeping better tonight. No registration required.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xff556b82),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowingSessionCircle extends StatefulWidget {
  const _GlowingSessionCircle();

  @override
  State<_GlowingSessionCircle> createState() => _GlowingSessionCircleState();
}

class _GlowingSessionCircleState extends State<_GlowingSessionCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xff12475f);
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white,
              glowColor,
              glowColor.withValues(alpha: 0.4),
              glowColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.25, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}
