import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';

/// Nostalgic calm — tumblr-era cookbook palette.
/// Paper cream, faded ink, dusty coral, sage teal, mustard amber.
class MorphColors {
  static const paper = Color(0xFFF5EFE0);       // warm aged paper
  static const paperDeep = Color(0xFFEDE3CE);   // shaded paper
  static const ink = Color(0xFF2B2418);         // sepia ink
  static const inkSoft = Color(0xFF5A4F3E);
  static const inkMuted = Color(0xFF8A7C66);
  static const coral = Color(0xFFC84B31);       // dusty coral (alert)
  static const coralSoft = Color(0xFFE08A6F);
  static const teal = Color(0xFF5B8E7D);        // sage teal (calm)
  static const tealSoft = Color(0xFF9DBCB1);
  static const amber = Color(0xFFE8B14F);       // mustard amber
  static const plum = Color(0xFF7A4A6B);
  static const divider = Color(0xFFC9BC9F);
  static const chipOff = Color(0xFFD8CDB4);
  static const chipOn = Color(0xFF2B2418);
}

class MorphFonts {
  static TextStyle display({Color color = MorphColors.ink, double size = 32, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontStyle: FontStyle.italic, fontSize: size, fontWeight: weight, color: color, height: 1.05);

  static TextStyle displayUpright({Color color = MorphColors.ink, double size = 28, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: 1.1);

  static TextStyle serif({Color color = MorphColors.ink, double size = 16, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.playfairDisplay(fontSize: size, fontWeight: weight, color: color, height: 1.35);

  static TextStyle mono({Color color = MorphColors.inkSoft, double size = 11, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.08);

  static TextStyle hand({Color color = MorphColors.inkSoft, double size = 18}) =>
      GoogleFonts.caveat(fontSize: size, color: color, height: 1.2);

  static TextStyle label({Color color = MorphColors.inkSoft, double size = 12}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color, letterSpacing: 1.2, fontWeight: FontWeight.w500);
}

class MorphDurations {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
}

/// Paper grain overlay painted behind content.
class PaperGrain extends StatelessWidget {
  final Widget child;
  const PaperGrain({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(),
      child: child,
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = MorphColors.ink.withOpacity(0.025);
    for (var i = 0; i < size.width * size.height / 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Striped SVG-ish placeholder for recipe/dish hero images.
/// Uses diagonal stripes tinted with the dish's stripe color, plus caption.
class StripedPlaceholder extends StatelessWidget {
  final String stripeColorHex;
  final String? caption;
  final String? lang;
  final double height;
  final double rotation;
  const StripedPlaceholder({
    super.key,
    required this.stripeColorHex,
    this.caption,
    this.lang = 'en',
    this.height = 200,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final stripe = _parseHex(stripeColorHex);
    return Transform.rotate(
      angle: rotation,
      child: ClipRect(
        child: CustomPaint(
          painter: _StripePainter(stripe),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: caption == null
                ? null
                : Align(
                    alignment: const Alignment(0, 0.85),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Transform.rotate(
                        angle: -rotation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: MorphColors.paper.withOpacity(0.85),
                          child: Text(
                            caption!,
                            style: MorphFonts.mono(size: 10, color: MorphColors.inkSoft),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
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
    final bg = Paint()..color = MorphColors.paperDeep;
    canvas.drawRect(Offset.zero & size, bg);
    final stripePaint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.square;
    const gap = 26.0;
    final diag = size.width + size.height;
    for (var d = -size.height; d < diag; d += gap) {
      canvas.drawLine(Offset(-d, 0), Offset(-d + size.height, size.height), stripePaint);
    }
    final thin = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 2;
    for (var d = -size.height; d < diag; d += gap) {
      canvas.drawLine(Offset(-d + 4, 0), Offset(-d + size.height + 4, size.height), thin);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) => oldDelegate.color != color;
}

Color _parseHex(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

/// Polaroid-style recipe card with slight rotation.
class PolaroidCard extends StatelessWidget {
  final Widget child;
  final double rotation;
  final Color? borderColor;
  const PolaroidCard({super.key, required this.child, this.rotation = 0, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        decoration: BoxDecoration(
          color: MorphColors.paper,
          border: Border.all(color: borderColor ?? MorphColors.divider, width: 1),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(2, 4)),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}

/// Dashed horizontal rule.
class DashedRule extends StatelessWidget {
  final Color color;
  final double thickness;
  const DashedRule({super.key, this.color = MorphColors.divider, this.thickness = 1});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 6.0;
        final available = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final count = (available / (dashWidth * 2)).floor().clamp(0, 10000);
        return Row(
          children: List.generate(count, (_) => Container(
            width: dashWidth,
            height: thickness,
            color: color,
            margin: EdgeInsets.only(right: dashWidth),
          )),
        );
      },
    );
  }
}

extension ColorExtension on String {
  Color toColor() => _parseHex(this);
}

// Localized text helper that takes LText.
String ltr(LText t, String lang) {
  return t[lang] ?? t['en'] ?? '';
}
