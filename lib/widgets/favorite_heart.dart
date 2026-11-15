import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

/// Heart button on a white disc. When a market is saved the heart pops once,
/// so the tap visibly did something. Skipped when the system asks for less motion.
class FavoriteHeart extends StatefulWidget {
  final bool isFavorite;
  final String tooltip;
  final VoidCallback onPressed;

  const FavoriteHeart({
    super.key,
    required this.isFavorite,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends State<FavoriteHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 65),
  ]).animate(_controller);

  @override
  void didUpdateWidget(FavoriteHeart old) {
    super.didUpdateWidget(old);
    if (!old.isFavorite && widget.isFavorite && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton.filled(
        tooltip: widget.tooltip,
        style: IconButton.styleFrom(
          backgroundColor: BrandColors.white,
          minimumSize: const Size(44, 44),
        ),
        icon: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? BrandColors.red : BrandColors.ink,
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}
