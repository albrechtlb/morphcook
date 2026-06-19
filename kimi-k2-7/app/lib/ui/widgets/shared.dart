import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StripedPlaceholder extends StatelessWidget {
  final Color color;
  final double borderRadius;
  final Widget? child;

  const StripedPlaceholder({
    super.key,
    required this.color,
    this.borderRadius = 0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _StripePainter(color),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.bottomLeft,
          child: child,
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  final Color color;
  _StripePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = color.withOpacity(0.25);
    final paintLight = Paint()..color = color.withOpacity(0.12);
    const stripeWidth = 4.0;
    var x = -size.height;
    while (x < size.width) {
      final rect = Rect.fromPoints(
        Offset(x, 0),
        Offset(x + stripeWidth, size.height),
      );
      canvas.drawRect(rect, ((x / stripeWidth).floor() % 2 == 0) ? paintDark : paintLight);
      x += stripeWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PolaroidCard extends StatelessWidget {
  final Widget child;
  final double rotateDegrees;
  final EdgeInsets padding;
  const PolaroidCard({
    super.key,
    required this.child,
    this.rotateDegrees = -2,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateDegrees * 0.0174533,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.ink.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  final List<String> labels;
  const ChipRow({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (l) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.05),
                border: Border.all(color: AppColors.inkLight),
              ),
              child: Text(
                l,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'JetBrainsMono'),
              ),
            ),
          )
          .toList(),
    );
  }
}
