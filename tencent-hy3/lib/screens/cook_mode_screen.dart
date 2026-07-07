import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CookModeScreen extends StatefulWidget {
  final String recipeId;
  final int servings;

  CookModeScreen({required this.recipeId, this.servings = 2});

  @override
  _CookModeScreenState createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  int _currentStep = 0;
  int _totalSteps = 4;
  bool _timerActive = false;
  int _timerSeconds = 0;
  int _servings = 2;

  @override
  void initState() {
    super.initState();
    _servings = widget.servings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _nextStep,
          child: Container(
            color: Colors.transparent,
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildCurrentStep(),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Döner Kebab',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Colors.white, size: 28),
                onPressed: () {
                  if (_servings > 1) {
                    setState(() {
                      _servings--;
                    });
                  }
                },
              ),
              Text(
                '$_servings',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    _servings++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'step ${_currentStep + 1} of $_totalSteps',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${_currentStep + 1}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
          Text(
            _getStepText(_currentStep),
            textAlign: TextAlign.center,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              height: 1.8,
              color: Colors.white,
            ),
          ),
          if (_timerActive) ...[
            SizedBox(height: 48),
            _buildTimer(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          _formatTime(_timerSeconds),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: AppTheme.stripeTeal,
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _timerActive ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
              onPressed: () {
                setState(() {
                  _timerActive = !_timerActive;
                });
              },
            ),
            SizedBox(width: 32),
            IconButton(
              icon: Icon(Icons.replay, color: Colors.white, size: 48),
              onPressed: () {
                setState(() {
                  _timerSeconds = 0;
                  _timerActive = false;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
            onPressed: _previousStep,
          ),
          Text(
            'tap anywhere to continue',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _timerActive = false;
        _timerSeconds = 0;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _timerActive = false;
        _timerSeconds = 0;
      });
    }
  }

  String _getStepText(int step) {
    final steps = [
      'Slice the beef thinly and season with salt and paprika.',
      'Grill the meat until cooked through, about 5-7 minutes.',
      'Warm the flatbread and slice the vegetables.',
      'Assemble: bread, meat, vegetables, yogurt sauce.',
    ];
    return steps[step % steps.length];
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.paperCream,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.stripeTeal,
              ),
              SizedBox(height: 24),
              Text(
                'enjoy your meal!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'you just cooked vegan döner',
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cook again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('done'),
            ),
          ],
        );
      },
    );
  }
}
