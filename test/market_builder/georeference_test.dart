import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/market_builder/services/georeference.dart';

// A fictional 120 m x 80 m market around Munich's Marienplatz, drawn on a plan
// image with aspect ratio 1.5, rotated by [rotationDeg] (clockwise).
const _center = GeoPoint(48.13743, 11.57549);
const _aspect = 1.5;

GeoPoint _truth(PlanPoint p, {double rotationDeg = 0, double stretchX = 1}) {
  final u = (p.x / 1000 - 0.5) * 120 * stretchX;
  final v = (0.5 - p.y / 1000) * 80;
  final r = rotationDeg * math.pi / 180;
  final east = u * math.cos(r) + v * math.sin(r);
  final north = -u * math.sin(r) + v * math.cos(r);
  return GeoPoint(
    _center.latitude + north / 6378137.0 * 180 / math.pi,
    _center.longitude +
        east / (6378137.0 * math.cos(_center.latitude * math.pi / 180)) * 180 / math.pi,
  );
}

ControlPoint _cp(double x, double y, {double rotationDeg = 0, double stretchX = 1}) => ControlPoint(
      label: '$x/$y',
      plan: PlanPoint(x, y),
      geo: _truth(PlanPoint(x, y), rotationDeg: rotationDeg, stretchX: stretchX),
      source: 'manual',
    );

double _distance(GeoPoint a, GeoPoint b) {
  final dn = (a.latitude - b.latitude) * math.pi / 180 * 6378137.0;
  final de = (a.longitude - b.longitude) *
      math.pi /
      180 *
      6378137.0 *
      math.cos(a.latitude * math.pi / 180);
  return math.sqrt(dn * dn + de * de);
}

void main() {
  test('needs at least two control points', () {
    expect(Georeference.fit([_cp(100, 100)], aspectRatio: _aspect), isNull);
  });

  test('two points place a rotated plan exactly', () {
    final g = Georeference.fit(
      [_cp(100, 100, rotationDeg: 30), _cp(900, 800, rotationDeg: 30)],
      aspectRatio: _aspect,
    )!;
    for (final p in const [PlanPoint(500, 500), PlanPoint(0, 1000), PlanPoint(750, 250)]) {
      expect(_distance(g.toGeo(p), _truth(p, rotationDeg: 30)), lessThan(0.05));
    }
    expect(g.rmsErrorMeters, isNull);

    final overlay = g.overlay();
    expect(overlay.bearing, closeTo(30, 0.01));
    expect(overlay.widthMeters, closeTo(120, 0.05));
    expect(overlay.heightMeters, closeTo(80, 0.05));
    expect(_distance(overlay.center, _center), lessThan(0.05));
  });

  test('three or more points handle plans that are not to scale', () {
    final points = [
      _cp(50, 50, stretchX: 1.4),
      _cp(950, 100, stretchX: 1.4),
      _cp(500, 950, stretchX: 1.4),
      _cp(100, 900, stretchX: 1.4),
    ];
    final g = Georeference.fit(points, aspectRatio: _aspect)!;
    const p = PlanPoint(800, 600);
    expect(_distance(g.toGeo(p), _truth(p, stretchX: 1.4)), lessThan(0.05));
    expect(g.rmsErrorMeters, lessThan(0.05));
  });

  test('robust fit ignores a wrongly geocoded landmark', () {
    final wrong = ControlPoint(
      label: 'Kirche (falscher Treffer)',
      plan: const PlanPoint(500, 500),
      geo: GeoPoint(_center.latitude + 0.004, _center.longitude), // ~450 m off
      source: 'geocoded',
    );
    final points = [
      _cp(50, 50, rotationDeg: -15),
      _cp(950, 120, rotationDeg: -15),
      _cp(480, 950, rotationDeg: -15),
      wrong,
    ];

    final naive = Georeference.fit(points, aspectRatio: _aspect)!;
    const p = PlanPoint(300, 300);
    expect(_distance(naive.toGeo(p), _truth(p, rotationDeg: -15)), greaterThan(20));

    final robust = Georeference.fitRobust(points, aspectRatio: _aspect)!;
    expect(robust.usedPoints, isNot(contains(wrong)));
    expect(_distance(robust.toGeo(p), _truth(p, rotationDeg: -15)), lessThan(0.5));
  });

  test('points on one spot cannot be fitted', () {
    expect(Georeference.fit([_cp(100, 100), _cp(100, 100)], aspectRatio: _aspect), isNull);
  });

  test('collinear points fall back to a similarity fit', () {
    final g = Georeference.fit(
      [_cp(100, 500), _cp(500, 500), _cp(900, 500)],
      aspectRatio: _aspect,
    )!;
    const p = PlanPoint(500, 100);
    expect(_distance(g.toGeo(p), _truth(p)), lessThan(0.05));
  });

  test('toPlan inverts toGeo, also for stretched plans', () {
    final g = Georeference.fit(
      [_cp(100, 100, rotationDeg: 30, stretchX: 1.3), _cp(900, 200, rotationDeg: 30, stretchX: 1.3),
       _cp(400, 900, rotationDeg: 30, stretchX: 1.3)],
      aspectRatio: _aspect,
    )!;
    for (final p in const [PlanPoint(0, 0), PlanPoint(500, 500), PlanPoint(731, 88)]) {
      final back = g.toPlan(g.toGeo(p))!;
      expect(back.x, closeTo(p.x, 0.01));
      expect(back.y, closeTo(p.y, 0.01));
    }
  });

  test('three points with one misplaced never squash the plan', () {
    // The third point is put 25 m off – before, the affine fit squashed the plan.
    final off = _cp(500, 950);
    final misplaced = ControlPoint(
      label: 'daneben',
      plan: off.plan,
      geo: GeoPoint(off.geo.latitude + 25 / 6378137.0 * 180 / math.pi, off.geo.longitude),
      source: 'manual',
    );
    final g = Georeference.fit([_cp(50, 50), _cp(950, 100), misplaced], aspectRatio: _aspect)!;
    expect(g.isAffine, isFalse);
    final o = g.overlay();
    // Same proportions as the plan image.
    expect(o.widthMeters / o.heightMeters, closeTo(_aspect, 0.001));
  });

  test('four points on nearly one line stay undistorted', () {
    final g = Georeference.fit(
      [_cp(100, 500, stretchX: 1.4), _cp(400, 510, stretchX: 1.4), _cp(700, 495, stretchX: 1.4), _cp(900, 505, stretchX: 1.4)],
      aspectRatio: _aspect,
    )!;
    expect(g.isAffine, isFalse);
    final o = g.overlay();
    expect(o.widthMeters / o.heightMeters, closeTo(_aspect, 0.001));
  });

  test('an implausible affine fit falls back to the similarity fit', () {
    // Four spread points, but stretched 2.5x – more than a plan drawn by hand.
    final g = Georeference.fit(
      [_cp(50, 50, stretchX: 2.5), _cp(950, 100, stretchX: 2.5), _cp(500, 950, stretchX: 2.5), _cp(100, 900, stretchX: 2.5)],
      aspectRatio: _aspect,
    )!;
    expect(g.isAffine, isFalse);
  });

  test('fine tuning moves, turns and scales the whole plan without distortion', () {
    final g = Georeference.fit([_cp(100, 100), _cp(900, 800)], aspectRatio: _aspect)!;
    const p = PlanPoint(500, 500);

    final moved = g.adjusted(eastMeters: 10, northMeters: -5);
    final m = moved.toGeo(p), o = g.toGeo(p);
    final de = (m.longitude - o.longitude) * math.pi / 180 * 6378137.0 * math.cos(o.latitude * math.pi / 180);
    final dn = (m.latitude - o.latitude) * math.pi / 180 * 6378137.0;
    expect(de, closeTo(10, 0.01));
    expect(dn, closeTo(-5, 0.01));

    final turned = g.adjusted(rotationDeg: 20);
    expect(turned.overlay().bearing, closeTo(20, 0.01));
    expect(_distance(turned.overlay().center, g.overlay().center), lessThan(0.01));

    final back = turned.adjusted(rotationDeg: -20).adjusted(scale: 1.1).adjusted(scale: 1 / 1.1);
    for (final q in const [PlanPoint(0, 0), PlanPoint(1000, 700)]) {
      expect(_distance(back.toGeo(q), g.toGeo(q)), lessThan(0.01));
    }
    expect(g.adjusted(scale: 2).overlay().widthMeters, closeTo(240, 0.1));
  });

  test('stored transform restores exactly', () {
    final g = Georeference.fit([_cp(100, 100, rotationDeg: 12), _cp(900, 800, rotationDeg: 12)], aspectRatio: _aspect)!
        .adjusted(eastMeters: 3, rotationDeg: 2);
    final r = Georeference.fromTransformMap(g.toTransformMap())!;
    for (final q in const [PlanPoint(0, 0), PlanPoint(640, 310)]) {
      expect(_distance(r.toGeo(q), g.toGeo(q)), lessThan(0.001));
    }
    expect(Georeference.fromTransformMap({'a': 1}), isNull);
  });
}
