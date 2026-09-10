import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/state/cleaning_app_scope.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({
    required this.taskId,
    required this.taskTitle,
    required this.goalTitle,
    required this.duration,
    this.now,
    super.key,
  });

  final String taskId;
  final String taskTitle;
  final String goalTitle;
  final Duration duration;
  final DateTime Function()? now;

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _endsAt;
  late final int _totalSeconds;
  late int _remainingSeconds;
  bool _isPaused = false;
  bool _hasEnded = false;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.duration.inSeconds;
    _remainingSeconds = _totalSeconds;
    _resumeTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isPaused && !_hasEnded) {
      _updateRemainingTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  void _resumeTimer() {
    _ticker?.cancel();
    _endsAt = _now().add(Duration(seconds: _remainingSeconds));
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
    if (mounted) {
      setState(() => _isPaused = false);
    }
  }

  void _updateRemainingTime() {
    final endsAt = _endsAt;
    if (endsAt == null || _isPaused || _hasEnded) return;

    final milliseconds = endsAt.difference(_now()).inMilliseconds;
    final nextSeconds = milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();

    if (nextSeconds == _remainingSeconds) return;

    setState(() {
      _remainingSeconds = nextSeconds;
      if (_remainingSeconds == 0) {
        _hasEnded = true;
        _ticker?.cancel();
      }
    });
  }

  void _pauseTimer() {
    _updateRemainingTime();
    _ticker?.cancel();
    setState(() => _isPaused = true);
  }

  Future<void> _completeTask() async {
    _ticker?.cancel();
    final saved = await CleaningAppScope.of(
      context,
    ).completeTask(widget.taskId);
    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  void _stopForNow() {
    _ticker?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        _totalSeconds == 0 ? 0.0 : _remainingSeconds / _totalSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus timer'),
        leading: IconButton(
          onPressed: _stopForNow,
          tooltip: 'Stop for now',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              widget.goalTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.taskTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 36),
            Center(
              child: SizedBox.square(
                dimension: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      label: '$_remainingSeconds seconds remaining',
                      child: Text(
                        _formatDuration(_remainingSeconds),
                        style: theme.textTheme.displayMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _hasEnded
                  ? 'Time is up. The effort still counts.'
                  : _isPaused
                      ? 'Paused. Start again when you are ready.'
                      : 'Just this one small thing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 36),
            if (_hasEnded) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark step done'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  ),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Finish early'),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _stopForNow,
                child: const Text('Stop for now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
