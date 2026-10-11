import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/plan_draft.dart';
import '../models/stand_categories.dart';
import '../services/georeference.dart';

/// Shows the plan image with every stand as a coloured dot.
///
/// Pinch to zoom. Tap a dot to edit it, long-press and drag to move it, tap
/// an empty spot to call [onTapPlan] (add a stand or pick an alignment point).
class PlanCanvas extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;
  final List<DraftStand> stands;
  final List<ControlPoint> controlPoints;
  final ValueChanged<DraftStand>? onStandTap;
  final void Function(DraftStand stand, PlanPoint position)? onStandMoved;
  final ValueChanged<PlanPoint>? onTapPlan;

  const PlanCanvas({
    super.key,
    required this.imageBytes,
    required this.aspectRatio,
    required this.stands,
    this.controlPoints = const [],
    this.onStandTap,
    this.onStandMoved,
    this.onTapPlan,
  });

  @override
  State<PlanCanvas> createState() => _PlanCanvasState();
}

class _PlanCanvasState extends State<PlanCanvas> {
  final _transform = TransformationController();
  PlanPoint? _dragStart;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  PlanPoint _toPlan(Offset local, Size size) => PlanPoint(
        (local.dx / size.width * 1000).clamp(0, 1000).toDouble(),
        (local.dy / size.height * 1000).clamp(0, 1000).toDouble(),
      );

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      maxScale: 8,
      child: Center(
        child: AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: AnimatedBuilder(
            animation: _transform,
            builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
            final size = constraints.biggest;
            // Keep dots the same size on screen while zooming.
            final zoom = _transform.value.getMaxScaleOnAxis();
            const dot = 22.0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.onTapPlan == null
                  ? null
                  : (d) => widget.onTapPlan!(_toPlan(d.localPosition, size)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: Image.memory(widget.imageBytes, fit: BoxFit.fill)),
                  for (final cp in widget.controlPoints)
                    Positioned(
                      left: cp.plan.x / 1000 * size.width - 14 / zoom,
                      top: cp.plan.y / 1000 * size.height - 28 / zoom,
                      child: Icon(Icons.push_pin, size: 28 / zoom, color: Colors.black87),
                    ),
                  for (final stand in widget.stands)
                    Positioned(
                      left: stand.position.x / 1000 * size.width - dot / zoom / 2,
                      top: stand.position.y / 1000 * size.height - dot / zoom / 2,
                      child: GestureDetector(
                        onTap: widget.onStandTap == null ? null : () => widget.onStandTap!(stand),
                        onLongPressStart: (_) => _dragStart = stand.position,
                        onLongPressMoveUpdate: widget.onStandMoved == null
                            ? null
                            : (d) {
                                final start = _dragStart!;
                                widget.onStandMoved!(
                                  stand,
                                  PlanPoint(
                                    (start.x + d.localOffsetFromOrigin.dx / size.width * 1000)
                                        .clamp(0, 1000)
                                        .toDouble(),
                                    (start.y + d.localOffsetFromOrigin.dy / size.height * 1000)
                                        .clamp(0, 1000)
                                        .toDouble(),
                                  ),
                                );
                              },
                        child: _StandDot(stand: stand, size: dot / zoom),
                      ),
                    ),
                ],
              ),
            );
          }),
          ),
        ),
      ),
    );
  }
}

class _StandDot extends StatelessWidget {
  final DraftStand stand;
  final double size;

  const _StandDot({required this.stand, required this.size});

  @override
  Widget build(BuildContext context) {
    final category = standCategoryFor(stand.category);
    final uncertain = stand.confidence == 'low';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: uncertain ? Colors.yellowAccent : Colors.white,
          width: size / 8,
        ),
        boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black45)],
      ),
      child: Icon(category.icon, size: size * 0.6, color: Colors.white),
    );
  }
}
