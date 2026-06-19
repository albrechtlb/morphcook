import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/recipe.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';

class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _currentStep = 0;
  double _servingsScale = 1.0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;
  bool _completed = false;
  bool _flash = false;

  final _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _remainingSeconds = _current.timerSeconds ?? 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
    _audio.dispose();
    super.dispose();
  }

  RecipeStep get _current => widget.recipe.method[_currentStep];

  void _startTimer() {
    if (_current.timerSeconds == null || _current.timerSeconds == 0) return;
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timerRunning = false;
          t.cancel();
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _remainingSeconds = _current.timerSeconds ?? 0;
    });
  }

  Future<void> _onTimerComplete() async {
    final profile = context.read<ProfileService>().profile;
    if (profile.visualAlertEnabled) {
      setState(() => _flash = true);
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _flash = false);
    }
    try {
      await _audio.play(AssetSource('audio/timer_done.wav'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.method.length - 1) {
      setState(() {
        _timer?.cancel();
        _currentStep++;
        _timerRunning = false;
        _remainingSeconds = _current.timerSeconds ?? 0;
      });
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _timer?.cancel();
        _currentStep--;
        _timerRunning = false;
        _remainingSeconds = _current.timerSeconds ?? 0;
      });
    }
  }

  void _finish() {
    _timer?.cancel();
    context.read<DataStoreService>().recordCooked(widget.recipe.id);
    setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileService>().profile;
    final reduceMotion = profile.reduceMotion ?? MediaQuery.of(context).disableAnimations;
    return Theme(
      data: AppTheme.darkCookTheme,
      child: Scaffold(
        backgroundColor: AppTheme.darkCookTheme.scaffoldBackgroundColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(recipe: widget.recipe, scale: _servingsScale, onScale: (v) => setState(() => _servingsScale = v)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (profile.quickNextTapEnabled) {
                          _nextStep();
                        }
                      },
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.9),
                        itemCount: widget.recipe.method.length,
                        onPageChanged: (i) => setState(() {
                          _timer?.cancel();
                          _currentStep = i;
                          _timerRunning = false;
                          _remainingSeconds = _current.timerSeconds ?? 0;
                        }),
                        itemBuilder: (context, i) {
                          final step = widget.recipe.method[i];
                          return _StepCard(step: step, lang: profile.lang, isActive: i == _currentStep, reduceMotion: reduceMotion);
                        },
                      ),
                    ),
                  ),
                  _TimerBar(
                    remaining: _remainingSeconds,
                    total: _current.timerSeconds ?? 0,
                    running: _timerRunning,
                    onStart: _startTimer,
                    onPause: _pauseTimer,
                    onReset: _resetTimer,
                  ),
                  _Controls(
                    current: _currentStep,
                    total: widget.recipe.method.length,
                    onPrev: _prevStep,
                    onNext: _nextStep,
                  ),
                ],
              ),
            ),
            if (_flash)
              Positioned.fill(
                child: AnimatedContainer(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            if (_completed)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('bon appétit', style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('finish'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Recipe recipe;
  final double scale;
  final ValueChanged<double> onScale;
  const _TopBar({required this.recipe, required this.scale, required this.onScale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text(recipe.title.text(context.read<ProfileService>().profile.lang), style: Theme.of(context).textTheme.titleLarge),
              Text('servings: ${(recipe.servings * scale).toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () => onScale((scale - 0.5).clamp(0.5, 4.0))),
              IconButton(icon: const Icon(Icons.add), onPressed: () => onScale((scale + 0.5).clamp(0.5, 4.0))),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final RecipeStep step;
  final String lang;
  final bool isActive;
  final bool reduceMotion;
  const _StepCard({required this.step, required this.lang, required this.isActive, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: isActive
            ? Text(step.text.text(lang), style: Theme.of(context).textTheme.bodyLarge)
                .animate()
                .fadeIn(duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300))
            : Text(step.text.text(lang), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white38)),
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  final int remaining;
  final int total;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  const _TimerBar({
    required this.remaining,
    required this.total,
    required this.running,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final display = '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: total > 0
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(display, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 42, color: Colors.white)),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  onPressed: running ? onPause : onStart,
                ),
                IconButton(icon: const Icon(Icons.replay), color: Colors.white, onPressed: onReset),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class _Controls extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _Controls({required this.current, required this.total, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(onPressed: current > 0 ? onPrev : null, icon: const Icon(Icons.arrow_back), label: const Text('prev')),
          Text('${current + 1} / $total', style: Theme.of(context).textTheme.bodyMedium),
          TextButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward), label: const Text('next')),
        ],
      ),
    );
  }
}
