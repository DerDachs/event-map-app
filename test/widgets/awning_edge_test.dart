import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/widgets/awning_edge.dart';
import 'package:market_mates/widgets/empty_state.dart';
import 'package:market_mates/widgets/favorite_heart.dart';

void main() {
  test('awning always shows at least two stripes and fits the width', () {
    expect(AwningPainter.stripeCount(10, 22), 2);
    expect(AwningPainter.stripeCount(390, 22), 18);
    expect(AwningPainter.stripeCount(390, 22).isEven, isTrue);
  });

  testWidgets('awning takes the full width and height of band plus scallop', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Align(alignment: Alignment.topLeft, child: SizedBox(width: 300, child: AwningEdge(stripeWidth: 20, bandHeight: 6))),
    ));
    final size = tester.getSize(find.byType(AwningEdge));
    expect(size, const Size(300, 16));
  });

  testWidgets('empty state shows title, hint and a working action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: Icons.cloud_off,
          title: 'Keine Verbindung',
          hint: 'Prüf dein Netz.',
          actionLabel: 'Erneut versuchen',
          onAction: () => taps++,
        ),
      ),
    ));
    expect(find.text('Keine Verbindung'), findsOneWidget);
    expect(find.text('Prüf dein Netz.'), findsOneWidget);
    await tester.tap(find.text('Erneut versuchen'));
    expect(taps, 1);
  });

  testWidgets('favorite heart switches icon and reports taps', (tester) async {
    var taps = 0;
    Widget app(bool fav) => MaterialApp(
          home: Scaffold(body: FavoriteHeart(isFavorite: fav, tooltip: 'Merken', onPressed: () => taps++)),
        );
    await tester.pumpWidget(app(false));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(taps, 1);
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
