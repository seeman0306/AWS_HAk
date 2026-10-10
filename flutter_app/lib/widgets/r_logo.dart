import 'package:flutter/material.dart';

class RLogoWidget extends StatelessWidget {
  final double size;
  final double opacity;
  final bool showShadow;

  const RLogoWidget({
    super.key,
    this.size = 120,
    this.opacity = 1.0,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(size, size * 1.2),
        painter: RLogoPainter(showShadow: showShadow),
      ),
    );
  }
}

class RLogoPainter extends CustomPainter {
  final bool showShadow;

  RLogoPainter({this.showShadow = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gold Linear Gradient Paint
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFE066), // Bright Gold top-left
          Color(0xFFD4AF37), // Metallic Gold
          Color(0xFFA67C00), // Deep Gold bottom-right
          Color(0xFF7A5900), // Rich Dark Gold shadow edge
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    if (showShadow) {
      final shadowPaint = Paint()
        ..color = const Color(0xFFFACC15).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      // Draw subtle glowing background
      canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.55, shadowPaint);
    }

    // Outer path of the geometric 'R'
    final path = Path();

    // 1. Top-Left Block
    path.moveTo(w * 0.18, h * 0.12);
    path.lineTo(w * 0.58, h * 0.12);
    path.lineTo(w * 0.58, h * 0.28);

    // 2. Upper Right Arch Curve
    path.lineTo(w * 0.62, h * 0.28);
    path.cubicTo(w * 0.78, h * 0.28, w * 0.78, h * 0.48, w * 0.62, h * 0.48);
    path.lineTo(w * 0.42, h * 0.48);

    // 3. Diagonal Right Leg
    path.lineTo(w * 0.75, h * 0.88);
    path.lineTo(w * 0.58, h * 0.88);
    path.lineTo(w * 0.32, h * 0.58);

    // 4. Left Vertical Edge & Corner
    path.lineTo(w * 0.32, h * 0.48);
    path.lineTo(w * 0.18, h * 0.48);
    path.close();

    // Inner Cutout Hole for 'R'
    final cutout = Path();
    cutout.moveTo(w * 0.36, h * 0.24);
    cutout.lineTo(w * 0.54, h * 0.24);
    cutout.cubicTo(w * 0.64, h * 0.24, w * 0.64, h * 0.38, w * 0.54, h * 0.38);
    cutout.lineTo(w * 0.36, h * 0.38);
    cutout.close();

    // Combine path minus cutout
    final finalPath = Path.combine(PathOperation.difference, path, cutout);

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
