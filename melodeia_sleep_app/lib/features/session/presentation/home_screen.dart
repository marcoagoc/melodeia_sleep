import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/auth_service.dart';
import '../../auth/firebase_bootstrap.dart';
import '../../journal/domain/sleep_log.dart';
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
    final user = await _authService.ensureAnonymousUser(
      firebaseReady: widget.firebaseStatus.isReady,
    );
    final config = await _repository.loadLastConfig();
    final logs = await _repository.loadLocalLogs();
    if (!mounted) return;
    setState(() {
      _user = user;
      _config = config;
      _logs = logs;
      _loading = false;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _Header(firebaseStatus: widget.firebaseStatus),
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
  const _Header({required this.firebaseStatus});

  final FirebaseBootstrapStatus firebaseStatus;

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
        DecoratedBox(
          decoration: BoxDecoration(
            color: firebaseStatus.isReady
                ? colors.primaryContainer.withValues(alpha: 0.3)
                : colors.tertiaryContainer.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  firebaseStatus.isReady
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: colors.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    firebaseStatus.isReady
                        ? 'Anonymous sync is ready.'
                        : firebaseStatus.message ??
                              'Cloud sync will activate after Firebase setup.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final SessionEngine _engine;
  final _notesController = TextEditingController();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _engine = SessionEngine(widget.config);
    _timer = Timer.periodic(const Duration(milliseconds: 250), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (_paused) return;
    final next = _elapsed + const Duration(milliseconds: 250);
    final frame = _engine.frameAt(next);
    setState(() => _elapsed = frame.elapsed);
    if (frame.isComplete) {
      _timer?.cancel();
      _showCompletionSheet();
    }
  }

  Future<void> _showCompletionSheet() async {
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
    final frame = _engine.frameAt(_elapsed);
    final colors = Theme.of(context).colorScheme;
    final phaseText = switch (frame.phase) {
      BreathPhase.inhale => 'Breathe in',
      BreathPhase.exhale => 'Breathe out',
      BreathPhase.complete => 'Complete',
    };
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
                  Text(_formatDuration(frame.remaining)),
                ],
              ),
              const Spacer(),
              AnimatedScale(
                scale: frame.scale,
                duration: const Duration(milliseconds: 230),
                curve: Curves.easeInOut,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glowColor.withValues(alpha: frame.brightness),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withValues(
                          alpha: frame.brightness * 0.8,
                        ),
                        blurRadius: 90,
                        spreadRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Text(
                phaseText,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${frame.bpm.toStringAsFixed(1)} breaths per minute',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 34),
              LinearProgressIndicator(value: frame.progress),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => setState(() => _paused = !_paused),
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
