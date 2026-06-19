import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'cook_complete.dart';

class CookModeScreen extends StatefulWidget {
  final String recipeId;
  final String lang;
  const CookModeScreen({super.key, required this.recipeId, required this.lang});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _step = 0;
  int _servings = 4;
  Timer? _timer;
  int _remaining = 0;
  bool _paused = false;
  bool _quickNextEnabled = false;
  bool _visualAlertEnabled = true;
  bool _reduceMotion = false;
  DateTime? _lastTap;
  bool _flash = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _servings = app.corpus.recipeIndex[widget.recipeId]?.servings ?? 4;
    _quickNextEnabled = app.profile.quickNextTapEnabled;
    _visualAlertEnabled = app.profile.visualAlertEnabled;
    _reduceMotion = app.profile.reduceMotion ?? false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _remaining = seconds;
    _paused = false;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        if (_visualAlertEnabled) {
          setState(() => _flash = true);
          _flashTimer?.cancel();
          _flashTimer = Timer(const Duration(seconds: 2), () => setState(() => _flash = false));
        }
      }
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  void _next() {
    final app = context.read<AppState>();
    final recipe = app.corpus.recipeIndex[widget.recipeId]!;
    if (_step < recipe.steps.length - 1) {
      setState(() {
        _step++;
        _timer?.cancel();
        _remaining = 0;
      });
      _maybeStartTimer();
    } else {
      app.recordCooked(widget.recipeId);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CookCompleteScreen(recipeId: widget.recipeId, lang: widget.lang)));
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() {
        _step--;
        _timer?.cancel();
        _remaining = 0;
      });
      _maybeStartTimer();
    }
  }

  void _maybeStartTimer() {
    final app = context.read<AppState>();
    final recipe = app.corpus.recipeIndex[widget.recipeId]!;
    final s = recipe.steps[_step];
    if (s.timerSeconds > 0) _startTimer(s.timerSeconds);
  }

  void _onStepTap() {
    if (!_quickNextEnabled) return;
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 300)) return;
    _lastTap = now;
    HapticFeedback.lightImpact();
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final recipe = app.corpus.recipeIndex[widget.recipeId];
    if (recipe == null) {
      return Scaffold(backgroundColor: MorphColors.ink, body: const Center(child: Text('recipe not found', style: TextStyle(color: MorphColors.paper))));
    }
    final step = recipe.steps[_step];
    final total = recipe.steps.length;
    final scaled = (step.timerSeconds > 0) ? (_remaining > 0 ? _remaining : 0) : 0;
    final flashColor = _step % 2 == 0 ? MorphColors.coral : MorphColors.teal;

    return Scaffold(
      backgroundColor: MorphColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _onStepTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  _header(recipe, total),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('step ${_step + 1}', style: MorphFonts.mono(size: 12, color: MorphColors.amber)),
                          const SizedBox(height: 8),
                          Text(ltr(step.text, widget.lang), style: MorphFonts.serif(size: 22, color: MorphColors.paper),).animate(key: ValueKey(_step)).fadeIn(duration: (_reduceMotion ? 0 : 320).ms),
                          if (step.timerSeconds > 0) ...[
                            const SizedBox(height: 24),
                            _timerCard(scaled),
                          ],
                          const SizedBox(height: 24),
                          _servingsScaler(recipe),
                        ],
                      ),
                    ),
                  ),
                  _controls(),
                ],
              ),
            ),
            if (_flash && _visualAlertEnabled && !_reduceMotion)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: flashColor.withOpacity(0.4))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 200.ms)
                    .then()
                    .fadeOut(duration: 200.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(Recipe recipe, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: MorphColors.paper, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(ltr(recipe.title, widget.lang), style: MorphFonts.display(size: 18, color: MorphColors.paper), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${(_step + 1) / total * 100 ~/ 1}% · ${_step + 1} of $total', style: MorphFonts.mono(size: 10, color: MorphColors.amber)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_quickNextEnabled ? Icons.touch_app : Icons.touch_app_outlined, color: _quickNextEnabled ? MorphColors.amber : MorphColors.paper.withOpacity(0.5), size: 22),
            onPressed: () => setState(() => _quickNextEnabled = !_quickNextEnabled),
            tooltip: 'quick-tap',
          ),
        ],
      ),
    );
  }

  Widget _timerCard(int remaining) {
    final mins = (remaining / 60).floor();
    final secs = remaining % 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MorphColors.paper.withOpacity(0.08),
        border: Border.all(color: MorphColors.amber.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}', style: MorphFonts.displayUpright(size: 48, color: MorphColors.amber)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _togglePause,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause, color: MorphColors.paper, size: 18),
                label: Text(_paused ? 'resume' : 'pause', style: MorphFonts.mono(size: 11, color: MorphColors.paper)),
              ),
              TextButton.icon(
                onPressed: _remaining > 0 ? null : () => _startTimer(recipe?.steps[_step].timerSeconds ?? 0),
                icon: const Icon(Icons.restart_alt, color: MorphColors.paper, size: 18),
                label: Text('restart', style: MorphFonts.mono(size: 11, color: MorphColors.paper)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Recipe? get recipe => context.read<AppState>().corpus.recipeIndex[widget.recipeId];

  Widget _servingsScaler(Recipe recipe) {
    return Row(
      children: [
        Text('servings', style: MorphFonts.mono(size: 11, color: MorphColors.paper.withOpacity(0.7))),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove, color: MorphColors.paper, size: 18),
          onPressed: () => setState(() => _servings = (_servings - 1).clamp(1, 12)),
        ),
        Text('$_servings', style: MorphFonts.serif(size: 20, color: MorphColors.paper)),
        IconButton(
          icon: const Icon(Icons.add, color: MorphColors.paper, size: 18),
          onPressed: () => setState(() => _servings = (_servings + 1).clamp(1, 12)),
        ),
        const SizedBox(width: 8),
        Text('(base ${recipe.servings})', style: MorphFonts.mono(size: 9, color: MorphColors.paper.withOpacity(0.5))),
      ],
    );
  }

  Widget _controls() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            TextButton(
              onPressed: _prev,
              child: Text('prev', style: MorphFonts.mono(size: 12, color: MorphColors.paper.withOpacity(0.7))),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: MorphColors.amber,
                foregroundColor: MorphColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(_step == (recipe?.steps.length ?? 1) - 1 ? 'finish' : 'next', style: MorphFonts.mono(size: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
