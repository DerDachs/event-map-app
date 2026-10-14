import 'dart:math' as math;

/// A point on the plan image, on the 0..1000 grid used by the plan analysis
/// (origin top-left, y pointing down).
class PlanPoint {
  final double x;
  final double y;

  const PlanPoint(this.x, this.y);
}

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

/// A plan position whose real-world location is known.
class ControlPoint {
  final String label;
  final PlanPoint plan;
  final GeoPoint geo;

  /// 'geocoded' (found automatically) or 'manual' (placed by the organiser).
  final String source;

  const ControlPoint({
    required this.label,
    required this.plan,
    required this.geo,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'x': plan.x,
        'y': plan.y,
        'latitude': geo.latitude,
        'longitude': geo.longitude,
        'source': source,
      };

  factory ControlPoint.fromMap(Map<String, dynamic> map) => ControlPoint(
        label: map['label'] as String? ?? '',
        plan: PlanPoint((map['x'] as num).toDouble(), (map['y'] as num).toDouble()),
        geo: GeoPoint(
          (map['latitude'] as num).toDouble(),
          (map['longitude'] as num).toDouble(),
        ),
        source: map['source'] as String? ?? 'manual',
      );
}

/// Where to draw the plan image on the map as a ground overlay.
class PlanOverlay {
  final GeoPoint center;
  final double widthMeters;
  final double heightMeters;

  /// Clockwise rotation from north, in degrees.
  final double bearing;

  const PlanOverlay({
    required this.center,
    required this.widthMeters,
    required this.heightMeters,
    required this.bearing,
  });
}

const double _earthRadius = 6378137.0;
double _rad(double deg) => deg * math.pi / 180;

/// Maps positions on the plan image to coordinates.
///
/// Plan coordinates are first scaled so x and y share one unit (the plan
/// image's height), then mapped onto a local east/north metre grid around
/// [origin]. With two control points this is a similarity transform (shift,
/// rotation, uniform scale); with three or more it is an affine transform, which
/// also absorbs plans that are stretched or not drawn to scale.
class Georeference {
  final GeoPoint origin;
  final double aspectRatio;

  // east  = a * u + b * v + c
  // north = d * u + e * v + f
  // where u = x / 1000 * aspectRatio, v = -y / 1000.
  final double a, b, c, d, e, f;

  /// Root mean square distance in metres between the control points and where
  /// the transform puts them. Null when there are no spare points to check.
  final double? rmsErrorMeters;

  final List<ControlPoint> usedPoints;

  const Georeference._({
    required this.origin,
    required this.aspectRatio,
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
    required this.f,
    required this.rmsErrorMeters,
    required this.usedPoints,
  });

  /// Fits a transform through [points]. Returns null with fewer than two
  /// usable points.
  ///
  /// [aspectRatio] is the plan image's width divided by its height.
  static Georeference? fit(List<ControlPoint> points, {required double aspectRatio}) {
    if (points.length < 2) return null;
    final origin = GeoPoint(
      points.map((p) => p.geo.latitude).reduce((s, v) => s + v) / points.length,
      points.map((p) => p.geo.longitude).reduce((s, v) => s + v) / points.length,
    );

    final us = <double>[], vs = <double>[], es = <double>[], ns = <double>[];
    for (final p in points) {
      us.add(p.plan.x / 1000 * aspectRatio);
      vs.add(-p.plan.y / 1000);
      final m = _toMeters(origin, p.geo);
      es.add(m.$1);
      ns.add(m.$2);
    }

    final List<double>? params =
        points.length >= 3 ? _fitAffine(us, vs, es, ns) : _fitSimilarity(us, vs, es, ns);
    if (params == null) return null;

    final dof = points.length - (points.length >= 3 ? 3 : 2);
    double? rms;
    if (dof > 0) {
      var sum = 0.0;
      for (var i = 0; i < points.length; i++) {
        final pe = params[0] * us[i] + params[1] * vs[i] + params[2];
        final pn = params[3] * us[i] + params[4] * vs[i] + params[5];
        sum += math.pow(pe - es[i], 2) + math.pow(pn - ns[i], 2);
      }
      rms = math.sqrt(sum / points.length);
    }

    return Georeference._(
      origin: origin,
      aspectRatio: aspectRatio,
      a: params[0],
      b: params[1],
      c: params[2],
      d: params[3],
      e: params[4],
      f: params[5],
      rmsErrorMeters: rms,
      usedPoints: List.unmodifiable(points),
    );
  }

  /// Like [fit], but ignores control points that disagree with the rest, so a
  /// single wrongly geocoded landmark cannot drag the whole market away.
  ///
  /// Every pair of points proposes a similarity transform; the pair that the
  /// most other points agree with (within [maxErrorMeters]) wins, and the final
  /// transform is fitted through all points that agree with it.
  static Georeference? fitRobust(
    List<ControlPoint> points, {
    required double aspectRatio,
    double maxErrorMeters = 30,
  }) {
    if (points.length < 3) return fit(points, aspectRatio: aspectRatio);

    List<ControlPoint>? bestInliers;
    var bestError = double.infinity;
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final candidate = fit([points[i], points[j]], aspectRatio: aspectRatio);
        if (candidate == null) continue;
        final inliers = <ControlPoint>[];
        var error = 0.0;
        for (final p in points) {
          final e = candidate.errorAt(p);
          if (e <= maxErrorMeters) {
            inliers.add(p);
            error += e;
          }
        }
        if (bestInliers == null ||
            inliers.length > bestInliers.length ||
            (inliers.length == bestInliers.length && error < bestError)) {
          bestInliers = inliers;
          bestError = error;
        }
      }
    }
    return fit(bestInliers ?? points, aspectRatio: aspectRatio);
  }

  GeoPoint toGeo(PlanPoint p) {
    final u = p.x / 1000 * aspectRatio;
    final v = -p.y / 1000;
    final east = a * u + b * v + c;
    final north = d * u + e * v + f;
    return _fromMeters(origin, east, north);
  }

  /// The plan position that [toGeo] maps onto [g], e.g. after a stand was
  /// dragged on the map. Null if the transform cannot be inverted.
  PlanPoint? toPlan(GeoPoint g) {
    final (east, north) = _toMeters(origin, g);
    final det = a * e - b * d;
    if (det.abs() < 1e-12) return null;
    final de = east - c, dn = north - f;
    final u = (e * de - b * dn) / det;
    final v = (a * dn - d * de) / det;
    return PlanPoint(u / aspectRatio * 1000, -v * 1000);
  }

  /// Distance in metres between where [p] really is and where the transform
  /// puts its plan position.
  double errorAt(ControlPoint p) {
    final predicted = toGeo(p.plan);
    final m = _toMeters(p.geo, predicted);
    return math.sqrt(m.$1 * m.$1 + m.$2 * m.$2);
  }

  /// Best-fitting rotated rectangle for the plan image, for previewing the
  /// alignment as a ground overlay.
  PlanOverlay overlay() {
    final center = toGeo(const PlanPoint(500, 500));
    final right = toGeo(const PlanPoint(1000, 500));
    final top = toGeo(const PlanPoint(500, 0));
    final r = _toMeters(center, right);
    final t = _toMeters(center, top);
    final width = 2 * math.sqrt(r.$1 * r.$1 + r.$2 * r.$2);
    final height = 2 * math.sqrt(t.$1 * t.$1 + t.$2 * t.$2);
    // Bearing of the image's "up" direction, clockwise from north.
    final bearing = (math.atan2(t.$1, t.$2) * 180 / math.pi + 360) % 360;
    return PlanOverlay(
      center: center,
      widthMeters: width,
      heightMeters: height,
      bearing: bearing,
    );
  }

  static (double, double) _toMeters(GeoPoint origin, GeoPoint p) {
    final east = _rad(p.longitude - origin.longitude) * _earthRadius * math.cos(_rad(origin.latitude));
    final north = _rad(p.latitude - origin.latitude) * _earthRadius;
    return (east, north);
  }

  static GeoPoint _fromMeters(GeoPoint origin, double east, double north) {
    final lat = origin.latitude + north / _earthRadius * 180 / math.pi;
    final lng = origin.longitude +
        east / (_earthRadius * math.cos(_rad(origin.latitude))) * 180 / math.pi;
    return GeoPoint(lat, lng);
  }

  /// east = p*u - q*v + tx, north = q*u + p*v + ty (least squares).
  static List<double>? _fitSimilarity(
      List<double> us, List<double> vs, List<double> es, List<double> ns) {
    final n = us.length;
    final mu = us.reduce((s, v) => s + v) / n;
    final mv = vs.reduce((s, v) => s + v) / n;
    final me = es.reduce((s, v) => s + v) / n;
    final mn = ns.reduce((s, v) => s + v) / n;
    var sxx = 0.0, sp = 0.0, sq = 0.0;
    for (var i = 0; i < n; i++) {
      final du = us[i] - mu, dv = vs[i] - mv;
      final de = es[i] - me, dn = ns[i] - mn;
      sxx += du * du + dv * dv;
      sp += du * de + dv * dn;
      sq += du * dn - dv * de;
    }
    if (sxx < 1e-12) return null; // all control points on the same plan spot
    final p = sp / sxx, q = sq / sxx;
    final tx = me - p * mu + q * mv;
    final ty = mn - q * mu - p * mv;
    return [p, -q, tx, q, p, ty];
  }

  static List<double>? _fitAffine(
      List<double> us, List<double> vs, List<double> es, List<double> ns) {
    // Normal equations for [u v 1] * [a b c]^T = east (and the same for north).
    final m = List.generate(3, (_) => List.filled(3, 0.0));
    final re = List.filled(3, 0.0), rn = List.filled(3, 0.0);
    for (var i = 0; i < us.length; i++) {
      final row = [us[i], vs[i], 1.0];
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          m[r][c] += row[r] * row[c];
        }
        re[r] += row[r] * es[i];
        rn[r] += row[r] * ns[i];
      }
    }
    final xe = _solve3(m, re), xn = _solve3(m, rn);
    if (xe == null || xn == null) {
      // Control points lie on one line: fall back to the similarity fit.
      return _fitSimilarity(us, vs, es, ns);
    }
    return [...xe, ...xn];
  }

  static List<double>? _solve3(List<List<double>> m, List<double> r) {
    double det3(List<List<double>> x) =>
        x[0][0] * (x[1][1] * x[2][2] - x[1][2] * x[2][1]) -
        x[0][1] * (x[1][0] * x[2][2] - x[1][2] * x[2][0]) +
        x[0][2] * (x[1][0] * x[2][1] - x[1][1] * x[2][0]);
    final det = det3(m);
    // Relative threshold: control points (nearly) on a straight line.
    final scale = m[0][0] * m[1][1] * m[2][2];
    if (det.abs() <= 1e-9 * (scale.abs() + 1e-12)) return null;
    return List.generate(3, (col) {
      final mc = [
        for (var row = 0; row < 3; row++)
          [for (var c = 0; c < 3; c++) c == col ? r[row] : m[row][c]]
      ];
      return det3(mc) / det;
    });
  }
}
