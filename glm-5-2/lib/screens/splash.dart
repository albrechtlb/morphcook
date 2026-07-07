import 'package:flutter/material.dart';
import '../theme.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MorphColors.paper,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('MorphCook', style: MorphFonts.display(size: 64)),
            const SizedBox(height: 8),
            Text('every body gets a full cookbook', style: MorphFonts.hand(size: 22, color: MorphColors.teal)),
            const SizedBox(height: 24),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: MorphColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}
