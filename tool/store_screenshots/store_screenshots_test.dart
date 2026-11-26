// Renders the App Store screenshots (1320 × 2868, iPhone 6.9") in German and
// English from the real app widgets, the way the app looks on an iPhone:
// full screen with status bar, Dynamic Island and home indicator, without
// headlines, frames or any other advertising. The sample market is the
// invented example market "Lichterdorf Musterstadt".
//
//   flutter test tool/store_screenshots --update-goldens
//
// Output: docs/app-store/screenshots/<de|en>/NN_<name>.png (06_stand: stand details), plus the bare
// start page for the website (docs/app-store/website-home.png; convert to
// website/assets/app-home.webp, see docs/app-store/README.md).
//
// The map can't be rendered in a test (Google Maps is a native view). Put a
// screenshot taken on an iPhone into tool/store_screenshots/raw/<de|en>/02_map.png
// and it is used as it is; without it that screenshot is skipped.
//
// Any other shot can be replaced by a real device screenshot the same way:
// raw/<de|en>/01_home.png, 03_info.png, 04_team.png, 05_seasons.png.
// See docs/app-store/screenshots-nativ.md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:market_mates/data/models/event.dart';
import 'package:market_mates/data/models/eventImage.dart';
import 'package:market_mates/data/models/profile.dart';
import 'package:market_mates/data/models/stand.dart';
import 'package:market_mates/data/models/team.dart';
import 'package:market_mates/features/events/providers/event_provider.dart';
import 'package:market_mates/features/events/screens/market_section_screens.dart';
import 'package:market_mates/features/events/widgets/event_info.dart';
import 'package:market_mates/features/favorites/providers/favorite_provider.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';
import 'package:market_mates/features/feed/providers/feed_provider.dart';
import 'package:market_mates/features/feed/screens/home_feed_screen.dart';
import 'package:market_mates/features/market_builder/demo/demo_market.dart';
import 'package:market_mates/features/market_builder/models/stand_categories.dart';
import 'package:market_mates/features/seasons/models/season.dart';
import 'package:market_mates/features/seasons/providers/season_provider.dart';
import 'package:market_mates/features/stands/models/stand_style.dart';
import 'package:market_mates/features/stands/widgets/stand_details_sheet.dart';
import 'package:market_mates/features/teams/providers/team_provider.dart';
import 'package:market_mates/l10n/l10n.dart';
import 'package:market_mates/providers/state_provider.dart';
import 'package:market_mates/providers/user_provider.dart';
import 'package:market_mates/services/user_service.dart';
import 'package:market_mates/theme/app_theme.dart';
import 'package:market_mates/theme/brand_tokens.dart';

const _dir = 'tool/store_screenshots';

// ---------------------------------------------------------------- Sample data

StandInEvent _stand(int i) => StandInEvent(standId: 's$i', latitude: 0, longitude: 0);

Event _market(
  String id,
  String name,
  DateTime start,
  DateTime end, {
  required int stands,
  required String image,
  String category = 'christmas_market',
  String description = '',
  String tip = '',
  String ticket = '',
  String organizer = '',
  List<OpeningHour> hours = const [],
}) =>
    Event(
      id: id,
      name: name,
      description: description,
      startTime: start,
      endTime: end,
      latitude: 0,
      longitude: 0,
      category: category,
      teamIds: const [],
      images: [EventImage(url: 'https://example.test/$image', isStandard: true)],
      stands: [for (var i = 0; i < stands; i++) _stand(i)],
      openingHours: hours,
      ticketPrice: ticket,
      organizerName: organizer,
      eventTip: tip,
    );

/// The example market, built exactly like the one the admin creates in the app.
final _altstadt = () {
  final demo = buildDemoMarket(DateTime(2026, 11, 20, 17, 30));
  return _market(
    demo.id,
    demo.name,
    demo.start,
    demo.end,
    stands: demo.stands.length,
    image: 'market_1.jpg',
    description: demo.description,
    tip: demo.eventTip,
    ticket: demo.ticketPrice,
    organizer: demo.organizerName,
    hours: [
      for (final h in demo.openingHours) OpeningHour(days: h.days, open: h.open, close: h.close),
    ],
  );
}();
final _schloss = _market('schloss', 'Weihnachtsmarkt am Schlossplatz', DateTime(2026, 11, 25, 11),
    DateTime(2026, 12, 24, 14), stands: 86, image: 'market_2.jpg');
final _hafen = _market('hafen', 'Lichtermarkt am Hafen', DateTime(2026, 11, 13, 12), DateTime(2027, 1, 3, 20),
    stands: 72, image: 'market_3.jpg');
final _pfingst = _market('pfingst', 'Pfingstmarkt Musterstadt', DateTime(2027, 5, 14, 11), DateTime(2027, 5, 17, 22),
    stands: 64, image: 'market_2.jpg', category: 'pentecost_market');

List<FeedPost> _posts() {
  final seed = (jsonDecode(File('assets/feed/season_2026.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>()
      .where((p) => p['type'] == 'tip')
      .map((raw) => FeedPost.fromMap(raw['id'] as String, Map<String, dynamic>.from(raw)..remove('id')));
  return [
    FeedPost(
      id: 'opening',
      type: FeedPostType.opening,
      title: 'Lichterzauber am Schlossplatz ab 25. November',
      body: 'Zur Eröffnung singt der Kinderchor, danach gehen um 18 Uhr die Lichter an.',
      titleEn: 'Lights on at the Schlossplatz from 25 November',
      bodyEn: 'The children’s choir sings at the opening, then the lights go on at 6 pm.',
      eventId: 'schloss',
      publishAt: DateTime(2026, 11, 18, 9),
      seasonId: 'weihnachten-2026',
    ),
    FeedPost(
      id: 'pfingst-post',
      type: FeedPostType.event,
      title: 'Pfingstmarkt: Programm am Samstag',
      body: 'Live-Musik ab 16 Uhr, Kinderkarussell und Flohmarkt in der Altstadt.',
      titleEn: 'Whitsun market: Saturday programme',
      bodyEn: 'Live music from 4 pm, a children’s carousel and a flea market in the old town.',
      eventId: 'pfingst',
      publishAt: DateTime(2027, 5, 5, 9),
      seasonId: 'pfingsten-2027',
    ),
    ...seed,
  ];
}

List<Season> _seasons() => [
      for (final raw in (jsonDecode(File('assets/seasons/seasons.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>())
        Season.fromMap(raw['id'] as String, Map<String, dynamic>.from(raw)..remove('id')),
    ];

final _team = Team(
  id: 't1',
  name: 'Glühwein-Crew',
  eventId: demoMarketId,
  members: const ['u1', 'u2', 'u3', 'u4'],
  leaderId: 'u1',
  createdAt: DateTime(2026, 11, 20),
  teamCode: 'K7Q2XM',
);

UserProfile _person(String uid, String name, int avatar) => UserProfile(
      uid: uid,
      email: '$uid@example.test',
      name: name,
      role: 'user',
      profilePicture: 'assets/avatars/avatar_$avatar.png',
    );

final _people = [_person('u1', 'Lena', 2), _person('u2', 'Jonas', 5), _person('u3', 'Mia', 7), _person('u4', 'Ben', 9)];

// ---------------------------------------------------------------- Fakes

class _FakeUserService implements UserService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends UserProfileNotifier {
  _Profile() : super(_FakeUserService()) {
    state = AsyncValue.data(_people.first);
  }
}

class _Favs extends FavoritesNotifier {
  _Favs(List<String> ids) : super.empty() {
    state = {'events': ids, 'stands': ['zuckerhaeuschen']};
  }
}

/// Serves the sample images for every Image.network URL.
class _ImageHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _Client();
}

class _Client implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _Request(url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Request implements HttpClientRequest {
  final Uri url;
  _Request(this.url);

  @override
  final HttpHeaders headers = _Headers();

  @override
  Future<HttpClientResponse> close() async =>
      _Response(File('$_dir/images/${url.pathSegments.last}').readAsBytesSync());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Headers implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  final Uint8List bytes;
  _Response(this.bytes);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(bytes).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------- Fonts

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async => ByteData.sublistView(File(path).readAsBytesSync());
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(bytes('$material/Roboto-$f.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(bytes('$material/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('Bebas Neue')..addFont(bytes('$_dir/fonts/BebasNeue-Regular.ttf'))).load();
  final figtree = FontLoader('Figtree');
  for (final f in ['Regular', 'SemiBold', 'ExtraBold']) {
    figtree.addFont(bytes('$_dir/fonts/Figtree-$f.ttf'));
  }
  await figtree.load();
}

// ---------------------------------------------------------------- iOS look

const _screenSize = Size(440, 956); // iPhone 17 Pro Max, × 3 = 1320 × 2868
const _safeTop = 62.0;
const _safeBottom = 34.0;

/// iOS status bar (time, Dynamic Island, signal, Wi-Fi, battery) and home
/// indicator, drawn over the app. [ink] is black on light pages.
class _IosChrome extends StatelessWidget {
  final Color ink;
  const _IosChrome({this.ink = Colors.black});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 11,
            left: (_screenSize.width - 125) / 2,
            child: Container(
              width: 125,
              height: 37,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18.5)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: (_screenSize.width - 125) / 2 + 10,
            height: 59,
            child: Center(
              child: Text('9:41',
                  style: TextStyle(
                      fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 17, letterSpacing: -0.3, color: ink)),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: (_screenSize.width - 125) / 2 + 10,
            height: 59,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Bars(ink),
                const SizedBox(width: 6),
                Icon(Icons.wifi, size: 18, color: ink),
                const SizedBox(width: 6),
                _Battery(ink),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: (_screenSize.width - 139) / 2,
            child: Container(
              width: 139,
              height: 5,
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  final Color ink;
  const _Bars(this.ink);

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 3.5,
              height: 4.0 + i * 2.6,
              margin: const EdgeInsets.only(right: 1.5),
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(1)),
            ),
        ],
      );
}

class _Battery extends StatelessWidget {
  final Color ink;
  const _Battery(this.ink);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 25,
            height: 12,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(2.5)),
              child: const SizedBox.expand(),
            ),
          ),
          Container(
            width: 1.5,
            height: 4,
            margin: const EdgeInsets.only(left: 1),
            color: ink.withValues(alpha: 0.4),
          ),
        ],
      );
}

/// The app screen as the iPhone shows it: safe areas for status bar and home
/// indicator, with the iOS chrome drawn on top.
Widget _phone(Widget app) => MediaQuery(
      data: const MediaQueryData(
        size: _screenSize,
        devicePixelRatio: 3,
        padding: EdgeInsets.only(top: _safeTop, bottom: _safeBottom),
        viewPadding: EdgeInsets.only(top: _safeTop, bottom: _safeBottom),
      ),
      child: Material(
        color: BrandColors.paper,
        child: Stack(
          children: [
            Positioned.fill(child: app),
            const Positioned.fill(child: _IosChrome()),
          ],
        ),
      ),
    );

/// A device screenshot already contains the iOS chrome.
Widget _device(File file) => SizedBox.fromSize(size: _screenSize, child: Image.file(file, fit: BoxFit.cover));

// ---------------------------------------------------------------- Stand details

/// The market map as a flat brand illustration (paper ground, white streets,
/// stand dots with white ring) – the real map can't be rendered in tests.
class _MarketIllustration extends StatelessWidget {
  const _MarketIllustration();

  static const _dots = <(double, double, String)>[
    (0.18, 0.30, 'gluehwein'), (0.30, 0.30, 'food_savory'), (0.42, 0.30, 'crafts'), (0.62, 0.30, 'food_sweet'),
    (0.74, 0.30, 'decoration'), (0.86, 0.30, 'gluehwein'), (0.50, 0.12, 'stage'), (0.50, 0.22, 'kids'),
    (0.38, 0.40, 'food_sweet'), (0.62, 0.40, 'food_savory'), (0.50, 0.50, 'service'), (0.24, 0.40, 'crafts'),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        Widget street(double l, double t, double sw, double sh) => Positioned(
              left: l * w,
              top: t * h,
              width: sw * w,
              height: sh * h,
              child: DecoratedBox(
                decoration: BoxDecoration(color: BrandColors.white, borderRadius: BorderRadius.circular(12)),
              ),
            );
        return ColoredBox(
          color: BrandColors.sand,
          child: Stack(children: [
            street(0.0, 0.27, 1.0, 0.065),
            street(0.44, 0.0, 0.12, 0.62),
            street(0.10, 0.37, 0.80, 0.06),
            for (final (x, y, key) in _dots)
              Positioned(
                left: x * w - 18,
                top: y * h - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: standCategoryFor(key).color,
                    shape: BoxShape.circle,
                    border: Border.all(color: BrandColors.white, width: 3),
                  ),
                  child: Icon(standCategoryFor(key).icon, size: 18, color: BrandColors.white),
                ),
              ),
          ]),
        );
      });
}

/// A stand opened from the map: details sheet over the market.
Widget _standScene(String lang) => Builder(builder: (context) {
      final de = lang == 'de';
      final stand = Stand(
        id: 'zuckerhaeuschen',
        name: 'Zuckerhäuschen',
        description: de
            ? 'Frisch gebackene Crêpes und Waffeln, süß oder mit Apfelmus – direkt neben der Bühne.'
            : 'Freshly made crêpes and waffles, sweet or with apple sauce – right next to the stage.',
        menu: de
            ? ['Crêpes Nutella', 'Crêpes Zimt & Zucker', 'Waffeln', 'Heiße Schokolade', 'Kinderpunsch']
            : ['Nutella crêpes', 'Cinnamon sugar crêpes', 'Waffles', 'Hot chocolate', 'Kids’ punch'],
        promotions: de ? 'Bis 17 Uhr: zweite Waffel halber Preis' : 'Until 5 pm: second waffle half price',
        standCategoryId: 'food_sweet',
      );
      return Stack(children: [
        const Positioned.fill(child: _MarketIllustration()),
        Positioned.fill(child: ColoredBox(color: BrandColors.ink.withValues(alpha: 0.28))),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _screenSize.height * 0.64,
          child: Material(
            color: BrandColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: BrandColors.line, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: StandDetailsContent(
                  stand: stand,
                  style: standStyleFor(context, 'food_sweet', const {}),
                  marketName: _altstadt.name,
                ),
              ),
            ]),
          ),
        ),
      ]);
    });

// ---------------------------------------------------------------- Rendering

Future<void> _shoot(
  WidgetTester tester, {
  required String lang,
  required String file,
  required Widget Function() screen,
  int tab = 0,
  List<String> favorites = const [],
  String? phoneOnlyPath,
}) async {
  // The app sets this in MaterialApp.builder; dates outside widgets use it.
  Intl.defaultLocale = lang;
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      eventsProvider.overrideWith((ref) async => [_altstadt, _schloss, _hafen, _pfingst]),
      feedPostsProvider.overrideWith((ref) => Stream.value(_posts())),
      seasonsProvider.overrideWith((ref) => Stream.value(_seasons())),
      favoritesProvider.overrideWith((ref) => _Favs(favorites)),
      userProfileProvider.overrideWith((ref) => _Profile()),
      bottomNavIndexProvider.overrideWith((ref) => tab),
      myTeamProvider.overrideWith((ref, eventId) => Stream.value(_team)),
      teamMembersProvider.overrideWith((ref, ids) async => _people),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: screen(),
    ),
  ));
  await tester.pump();
  // Let the sample images decode.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile(phoneOnlyPath ?? '../../docs/app-store/screenshots/$lang/$file.png'),
  );
}

/// The device screenshot raw/<lang>/<name>.png if it exists, else [fallback].
Widget Function() _nativeOr(String lang, String name, Widget Function() fallback) {
  final file = File('$_dir/raw/$lang/$name.png');
  return file.existsSync() ? () => _device(file) : () => _phone(fallback());
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = _ImageHttp();
    await initializeDateFormatting();
  });

  for (final lang in ['de', 'en']) {
    testWidgets('screenshots $lang', (tester) async {
      await tester.runAsync(_loadFonts);
      tester.view.physicalSize = _screenSize * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _shoot(tester,
          lang: lang,
          file: '01_home',
          favorites: [demoMarketId],
          screen: _nativeOr(lang, '01_home', () => HomeFeedScreen(clock: () => DateTime(2026, 11, 20, 17, 30))));

      final raw = File('$_dir/raw/$lang/02_map.png');
      if (raw.existsSync()) {
        await _shoot(tester,
            lang: lang,
            file: '02_map',
            screen: () => _device(raw));
      } else {
        debugPrint('Skipping 02_map ($lang): put an iPhone screenshot of the map into ${raw.path}');
      }

      await _shoot(tester,
          lang: lang,
          file: '03_info',
          screen: _nativeOr(
              lang,
              '03_info',
              () => Builder(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(context.l10n.marketInfoAction)),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8),
                        child: EventInfo(event: _altstadt, showMap: false),
                      ),
                    ),
                  )));

      await _shoot(tester,
          lang: lang,
          file: '04_team',
          tab: 2,
          screen: _nativeOr(
              lang, '04_team', () => MarketTeamScreen(event: _altstadt)));

      await _shoot(tester,
          lang: lang,
          file: '06_stand',
          screen: _nativeOr(lang, '06_stand', () => _standScene(lang)));

      await _shoot(tester,
          lang: lang,
          file: '05_seasons',
          screen: _nativeOr(lang, '05_seasons', () => HomeFeedScreen(clock: () => DateTime(2027, 5, 6, 12))));

      if (lang == 'de') {
        tester.view.physicalSize = _screenSize * 2;
        tester.view.devicePixelRatio = 2;
        await _shoot(tester,
            lang: lang,
            file: 'website',
            favorites: [demoMarketId],
            phoneOnlyPath: '../../docs/app-store/website-home.png',
            screen: () => _phone(HomeFeedScreen(clock: () => DateTime(2026, 11, 20, 17, 30))));
      }
    });
  }
}
