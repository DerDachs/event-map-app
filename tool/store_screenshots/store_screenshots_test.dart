// Renders the App Store screenshots (1320 × 2868, iPhone 6.9") in German and
// English from the real app widgets with sample data.
//
//   flutter test tool/store_screenshots --update-goldens
//
// Output: docs/app-store/screenshots/<de|en>/NN_<name>.png, plus the bare
// start page for the website (docs/app-store/website-home.png; convert to
// website/assets/app-home.webp, see docs/app-store/README.md).
//
// The map can't be rendered in a test (Google Maps is a native view). Put a
// screenshot taken on an iPhone into tool/store_screenshots/raw/<de|en>/02_map.png
// and it is framed like the others; without it that screenshot is skipped.
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
import 'package:market_mates/data/models/team.dart';
import 'package:market_mates/features/events/providers/event_provider.dart';
import 'package:market_mates/features/events/screens/team_tab.dart';
import 'package:market_mates/features/events/widgets/event_info.dart';
import 'package:market_mates/features/favorites/providers/favorite_provider.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';
import 'package:market_mates/features/feed/providers/feed_provider.dart';
import 'package:market_mates/features/feed/screens/home_feed_screen.dart';
import 'package:market_mates/features/seasons/models/season.dart';
import 'package:market_mates/features/seasons/providers/season_provider.dart';
import 'package:market_mates/features/teams/providers/team_provider.dart';
import 'package:market_mates/l10n/l10n.dart';
import 'package:market_mates/providers/state_provider.dart';
import 'package:market_mates/providers/user_provider.dart';
import 'package:market_mates/screens/layout/base_layout.dart';
import 'package:market_mates/services/user_service.dart';
import 'package:market_mates/theme/app_theme.dart';
import 'package:market_mates/theme/brand_tokens.dart';

const _dir = 'tool/store_screenshots';

// ---------------------------------------------------------------- Texts

/// Headline (Bebas Neue, uppercase) and one supporting line per screenshot.
const _copy = {
  'de': {
    'home': ('Dein Markt in der Hosentasche', 'Termine, Neuigkeiten und Countdown'),
    'map': ('Jede Hütte auf einen Blick', 'Alle Stände auf der Karte – mit Suche'),
    'info': ('Alles Wichtige zum Markt', 'Öffnungszeiten, Eintritt und Tipps'),
    'team': ('Mit Freunden unterwegs', 'Team gründen, Code teilen, zusammen bummeln'),
    'seasons': ('Märkte das ganze Jahr', 'Weihnachten, Pfingsten, Herbst – immer passend'),
  },
  'en': {
    'home': ('Your market in your pocket', 'Dates, news and a countdown'),
    'map': ('Every stall at a glance', 'All stalls on the map – with search'),
    'info': ('Everything about the market', 'Opening hours, entry and tips'),
    'team': ('Out with friends', 'Start a team, share the code, stroll together'),
    'seasons': ('Markets all year round', 'Christmas, Whitsun, autumn – always in season'),
  },
};

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

final _altstadt = _market(
  'altstadt',
  'Altstadt-Weihnachtsmarkt',
  DateTime(2026, 11, 16, 11),
  DateTime(2026, 12, 23, 21),
  stands: 124,
  image: 'market_1.jpg',
  description: 'Rund um das Rathaus stehen über 120 Hütten mit Kunsthandwerk, '
      'Glühwein und regionalen Spezialitäten. Abends taucht die Lichterkette über '
      'den Gassen den ganzen Platz in warmes Licht.',
  tip: 'Unter der Woche am frühen Abend ist es am entspanntesten.',
  ticket: 'frei',
  organizer: 'Stadtmarketing Musterstadt',
  hours: [
    OpeningHour(days: const ['Mo', 'Di', 'Mi', 'Do'], open: '11:00', close: '21:00'),
    OpeningHour(days: const ['Fr', 'Sa'], open: '11:00', close: '22:00'),
    OpeningHour(days: const ['So'], open: '12:00', close: '20:00'),
  ],
);
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
  eventId: 'altstadt',
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
    state = {'events': ids, 'stands': []};
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

// ---------------------------------------------------------------- Frame

const _shotSize = Size(440, 956); // × 3 = 1320 × 2868
const _phoneSize = Size(390, 844);

/// Headline above a phone showing the app; the phone runs off the bottom.
class _StoreShot extends StatelessWidget {
  final String headline;
  final String subline;
  final Widget screen;
  final Color background;

  const _StoreShot({required this.headline, required this.subline, required this.screen, required this.background});

  @override
  Widget build(BuildContext context) {
    const scale = 0.9;
    return Material(
      color: background,
      child: Stack(
        children: [
          Positioned(
            left: 28,
            right: 28,
            top: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontSize: 52,
                    height: 0.95,
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subline,
                  style: const TextStyle(fontFamily: 'Figtree', fontSize: 19, height: 1.3, color: BrandColors.inkSoft),
                ),
              ],
            ),
          ),
          Positioned(
            top: 250,
            left: (_shotSize.width - _phoneSize.width * scale) / 2 - 9,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrandColors.ink,
                  borderRadius: BorderRadius.circular(58),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 20))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: SizedBox.fromSize(size: _phoneSize, child: screen),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app screen with an iPhone status bar.
Widget _phone(Widget app) => MediaQuery(
      data: const MediaQueryData(
        size: _phoneSize,
        devicePixelRatio: 3,
        padding: EdgeInsets.only(top: 54, bottom: 34),
        viewPadding: EdgeInsets.only(top: 54, bottom: 34),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: app),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 54,
            child: Padding(
              padding: EdgeInsets.fromLTRB(44, 18, 36, 0),
              child: Row(
                children: [
                  Text('9:41',
                      style: TextStyle(
                          fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: 16, color: BrandColors.ink)),
                  Spacer(),
                  Icon(Icons.signal_cellular_alt, size: 18, color: BrandColors.ink),
                  SizedBox(width: 4),
                  Icon(Icons.wifi, size: 18, color: BrandColors.ink),
                  SizedBox(width: 4),
                  Icon(Icons.battery_full, size: 20, color: BrandColors.ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );

// ---------------------------------------------------------------- Rendering

Future<void> _shoot(
  WidgetTester tester, {
  required String lang,
  required String file,
  required String key,
  required Widget Function() screen,
  Color background = BrandColors.paper,
  int tab = 0,
  List<String> favorites = const [],
  String? phoneOnlyPath,
}) async {
  final (headline, subline) = _copy[lang]![key]!;
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
      home: phoneOnlyPath != null
          ? _phone(screen())
          : _StoreShot(headline: headline, subline: subline, background: background, screen: _phone(screen())),
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

void main() {
  setUpAll(() async {
    HttpOverrides.global = _ImageHttp();
    await initializeDateFormatting();
  });

  for (final lang in ['de', 'en']) {
    testWidgets('screenshots $lang', (tester) async {
      await tester.runAsync(_loadFonts);
      tester.view.physicalSize = _shotSize * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await _shoot(tester,
          lang: lang,
          file: '01_home',
          key: 'home',
          favorites: ['altstadt'],
          screen: () => HomeFeedScreen(clock: () => DateTime(2026, 11, 20, 17, 30)));

      final raw = File('$_dir/raw/$lang/02_map.png');
      if (raw.existsSync()) {
        await _shoot(tester,
            lang: lang,
            file: '02_map',
            key: 'map',
            background: BrandColors.sand,
            screen: () => Image.file(raw, fit: BoxFit.cover));
      } else {
        debugPrint('Skipping 02_map ($lang): put an iPhone screenshot of the map into ${raw.path}');
      }

      await _shoot(tester,
          lang: lang,
          file: '03_info',
          key: 'info',
          screen: () => BaseLayout(
                title: _altstadt.name,
                body: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16),
                  child: EventInfo(event: _altstadt, showMap: false),
                ),
              ));

      await _shoot(tester,
          lang: lang,
          file: '04_team',
          key: 'team',
          tab: 2,
          background: BrandColors.sand,
          screen: () => BaseLayout(title: _altstadt.name, body: TeamTab(event: _altstadt)));

      await _shoot(tester,
          lang: lang,
          file: '05_seasons',
          key: 'seasons',
          screen: () => HomeFeedScreen(clock: () => DateTime(2027, 5, 6, 12)));

      if (lang == 'de') {
        tester.view.physicalSize = _phoneSize * 2;
        tester.view.devicePixelRatio = 2;
        await _shoot(tester,
            lang: lang,
            file: 'website',
            key: 'home',
            favorites: ['altstadt'],
            phoneOnlyPath: '../../docs/app-store/website-home.png',
            screen: () => HomeFeedScreen(clock: () => DateTime(2026, 11, 20, 17, 30)));
      }
    });
  }
}
