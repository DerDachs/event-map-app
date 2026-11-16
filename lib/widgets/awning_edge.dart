import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

/// The scalloped edge of a market stall awning: alternating stripes that end
/// in half circles. It is the one recurring picture element of the app
/// (market cards, start page, empty states), everything else stays calm.
class AwningEdge extends StatelessWidget {
  /// Width of one stripe.
  final double stripeWidth;

  /// Height of the straight part above the scallops.
  final double bandHeight;

  final Color first;
  final Color second;

  const AwningEdge({
    super.key,
    this.stripeWidth = 22,
    this.bandHeight = 6,
    this.first = BrandColors.red,
    this.second = BrandColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: bandHeight + stripeWidth / 2,
        width: double.infinity,
        child: CustomPaint(
          painter: AwningPainter(stripeWidth: stripeWidth, bandHeight: bandHeight, first: first, second: second),
        ),
      ),
    );
  }
}

class AwningPainter extends CustomPainter {
  final double stripeWidth;
  final double bandHeight;
  final Color first;
  final Color second;

  const AwningPainter({
    required this.stripeWidth,
    required this.bandHeight,
    required this.first,
    required this.second,
  });

  /// Number of stripes for [width]; always at least two so the pattern shows.
  static int stripeCount(double width, double stripeWidth) =>
      (width / stripeWidth).round().clamp(2, 1000);

  @override
  void paint(Canvas canvas, Size size) {
    final count = stripeCount(size.width, stripeWidth);
    final w = size.width / count;
    final radius = w / 2;
    for (var i = 0; i < count; i++) {
      final x = i * w;
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w, 0)
        ..lineTo(x + w, bandHeight)
        ..arcToPoint(Offset(x, bandHeight), radius: Radius.circular(radius), clockwise: true)
        ..close();
      canvas.drawPath(path, Paint()..color = i.isEven ? first : second);
    }
  }

  @override
  bool shouldRepaint(AwningPainter old) =>
      old.stripeWidth != stripeWidth || old.bandHeight != bandHeight || old.first != first || old.second != second;
}
