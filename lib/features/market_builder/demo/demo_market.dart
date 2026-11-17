import 'dart:math' as math;

/// The example market "Lichterdorf Musterstadt".
///
/// Everything here is invented: the market, its stands, the dishes and the
/// texts. No plan, photo or listing from a third party is used, so the market
/// can be shown in the app, in store screenshots and to the app reviewers
/// without asking anybody. It shows the principle of Market Mate: all stands
/// of a market on one map, grouped by category.
const demoMarketId = 'demo-market';

/// Map position of the market square. Only a place on the map, no data of a
/// real market.
const _centerLatitude = 51.3127;
const _centerLongitude = 9.4797;

class DemoStand {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> menu;
  final String? promotion;

  /// Metres east and north of the market centre.
  final double eastMeters;
  final double northMeters;

  const DemoStand({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.eastMeters,
    required this.northMeters,
    this.menu = const [],
    this.promotion,
  });

  double get latitude => _centerLatitude + northMeters / 111320;

  double get longitude =>
      _centerLongitude + eastMeters / (111320 * math.cos(_centerLatitude * math.pi / 180));
}

class DemoMarket {
  final String id;
  final String name;
  final String description;
  final DateTime start;
  final DateTime end;
  final double latitude;
  final double longitude;
  final List<DemoStand> stands;
  final List<({List<String> days, String open, String close})> openingHours;
  final String organizerName;
  final String organizerInfo;
  final String eventTip;
  final String ticketPrice;

  const DemoMarket({
    required this.id,
    required this.name,
    required this.description,
    required this.start,
    required this.end,
    required this.latitude,
    required this.longitude,
    required this.stands,
    required this.openingHours,
    required this.organizerName,
    required this.organizerInfo,
    required this.eventTip,
    required this.ticketPrice,
  });

  Set<String> get categories => {for (final s in stands) s.category};
}

/// Day abbreviations as the app shows them; `isOpenAt` reads German and
/// English spellings alike.
const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Builds the example market so that it is running around [now]: it began
/// three days ago and lasts 25 more days, long enough for a store review.
DemoMarket buildDemoMarket(DateTime now) {
  final today = DateTime(now.year, now.month, now.day, 12);
  return DemoMarket(
    id: demoMarketId,
    name: 'Lichterdorf Musterstadt',
    description:
        'Ein Beispielmarkt zum Ausprobieren: 24 erfundene Stände rund um den Lichterbrunnen. '
        'Such nach „Crêpes“, filtere nach Glühwein oder gründe ein Team und teile den Code mit Freunden. '
        'Alles hier ist ausgedacht, nichts davon ist ein echter Markt.',
    start: today.subtract(const Duration(days: 3)),
    end: today.add(const Duration(days: 25, hours: 11, minutes: 59)),
    latitude: _centerLatitude,
    longitude: _centerLongitude,
    stands: _stands,
    openingHours: [
      (days: _weekdays, open: '11:00', close: '21:00'),
    ],
    organizerName: 'cellarworks (Beispiel)',
    organizerInfo: 'Der Lichterdorf-Markt ist ein Beispiel von cellarworks und zeigt, wie Market Mate einen Markt darstellt.',
    eventTip: 'Tipp: Wärm dich am Roten Hirsch auf und hol dir danach Crêpes im Zuckerhäuschen.',
    ticketPrice: 'Eintritt frei',
  );
}

const _stands = <DemoStand>[
  // Glühwein & Heißgetränke
  DemoStand(
    id: 'demo-stand-01',
    name: 'Zum Roten Hirsch',
    description: 'Glühwein nach Hausrezept, dazu Feuerzangenbowle am Abend.',
    category: 'gluehwein',
    eastMeters: -36,
    northMeters: 30,
    menu: ['Glühwein rot', 'Weißer Glühwein', 'Feuerzangenbowle', 'Kinderpunsch'],
    promotion: 'Becher zurückgeben, 2 € Pfand zurück',
  ),
  DemoStand(
    id: 'demo-stand-02',
    name: 'Tannennadel-Punsch',
    description: 'Heiße Getränke ohne Alkohol: Punsch, Kakao und Apfelwärmer.',
    category: 'gluehwein',
    eastMeters: 12,
    northMeters: 30,
    menu: ['Waldbeerpunsch', 'Heiße Schokolade', 'Apfelwärmer'],
  ),
  DemoStand(
    id: 'demo-stand-03',
    name: 'Eisbär-Eggnog',
    description: 'Eierpunsch und Heidelbeerglühwein, auf Wunsch mit Sahne.',
    category: 'gluehwein',
    eastMeters: 48,
    northMeters: 30,
    menu: ['Eierpunsch', 'Heidelbeerglühwein'],
  ),
  // Herzhaftes
  DemoStand(
    id: 'demo-stand-04',
    name: 'Kartoffelkönig',
    description: 'Knusprige Reibekuchen mit Apfelmus oder Lachs.',
    category: 'food_savory',
    eastMeters: -36,
    northMeters: 14,
    menu: ['Reibekuchen mit Apfelmus', 'Reibekuchen mit Lachs', 'Kartoffelsuppe'],
  ),
  DemoStand(
    id: 'demo-stand-05',
    name: 'Käsespätzle-Pfanne',
    description: 'Spätzle frisch aus der großen Pfanne, mit Röstzwiebeln.',
    category: 'food_savory',
    eastMeters: 12,
    northMeters: 14,
    menu: ['Käsespätzle', 'Spätzle mit Pilzrahm'],
    promotion: 'Mittags kleine Portion für 5 €',
  ),
  DemoStand(
    id: 'demo-stand-06',
    name: 'Flammlachs am Brunnen',
    description: 'Lachs vom Holzbrett, über offenem Feuer gegart.',
    category: 'food_savory',
    eastMeters: 48,
    northMeters: 14,
    menu: ['Flammlachs im Brötchen', 'Lachsteller'],
  ),
  DemoStand(
    id: 'demo-stand-07',
    name: 'Grünkohl & Pinkel',
    description: 'Norddeutsche Winterküche im Napf.',
    category: 'food_savory',
    eastMeters: 24,
    northMeters: -22,
    menu: ['Grünkohl mit Pinkel', 'Grünkohl vegetarisch'],
  ),
  // Süßes & Gebäck
  DemoStand(
    id: 'demo-stand-08',
    name: 'Zuckerhäuschen',
    description: 'Crêpes süß und herzhaft, direkt vor deinen Augen gebacken.',
    category: 'food_sweet',
    eastMeters: -12,
    northMeters: -2,
    menu: ['Crêpes mit Zimt und Zucker', 'Crêpes mit Nuss-Nougat', 'Crêpes mit Schinken und Käse'],
    promotion: 'Zwei Crêpes für 7 €',
  ),
  DemoStand(
    id: 'demo-stand-09',
    name: 'Mandelzauber',
    description: 'Gebrannte Mandeln, Nüsse und Marzipan.',
    category: 'food_sweet',
    eastMeters: 24,
    northMeters: -2,
    menu: ['Gebrannte Mandeln', 'Zimtnüsse', 'Marzipanbrote'],
  ),
  DemoStand(
    id: 'demo-stand-10',
    name: 'Lebkuchen Nordlicht',
    description: 'Elisenlebkuchen und Printen, schön verpackt zum Mitnehmen.',
    category: 'food_sweet',
    eastMeters: -36,
    northMeters: -22,
    menu: ['Elisenlebkuchen', 'Printen', 'Lebkuchenherzen'],
  ),
  DemoStand(
    id: 'demo-stand-11',
    name: 'Schokofrüchte',
    description: 'Erdbeeren, Bananen und Orangen im Schokomantel.',
    category: 'food_sweet',
    eastMeters: 48,
    northMeters: -22,
    menu: ['Schoko-Erdbeeren', 'Schoko-Bananen', 'Schoko-Orangen'],
  ),
  // Handwerk & Geschenke
  DemoStand(
    id: 'demo-stand-12',
    name: 'Kerzenzieherei Wachsmond',
    description: 'Kerzen zum Selbertauchen und handgegossene Bienenwachslichter.',
    category: 'crafts',
    eastMeters: -60,
    northMeters: 30,
    menu: ['Kerzen tauchen', 'Bienenwachslichter'],
  ),
  DemoStand(
    id: 'demo-stand-13',
    name: 'Filzfreunde',
    description: 'Pantoffeln, Mützen und kleine Tiere aus Wollfilz.',
    category: 'crafts',
    eastMeters: -60,
    northMeters: 14,
    menu: ['Filzpantoffeln', 'Mützen', 'Filztiere'],
  ),
  DemoStand(
    id: 'demo-stand-14',
    name: 'Töpferei Tonkrug',
    description: 'Tassen, Schalen und Adventsleuchter aus der eigenen Werkstatt.',
    category: 'crafts',
    eastMeters: -60,
    northMeters: -2,
    menu: ['Tassen', 'Schalen', 'Adventsleuchter'],
  ),
  DemoStand(
    id: 'demo-stand-15',
    name: 'Holzspielzeug Kiefernhof',
    description: 'Spielzeug aus Holz, ohne Plastik und mit Liebe gedrechselt.',
    category: 'crafts',
    eastMeters: -60,
    northMeters: -22,
    menu: ['Kreisel', 'Holzeisenbahn', 'Kugelbahn'],
  ),
  // Weihnachtsdeko
  DemoStand(
    id: 'demo-stand-16',
    name: 'Sternenlicht',
    description: 'Strohsterne, Lichterketten und Fensterbilder.',
    category: 'decoration',
    eastMeters: 72,
    northMeters: 30,
    menu: ['Strohsterne', 'Lichterketten', 'Fensterbilder'],
  ),
  DemoStand(
    id: 'demo-stand-17',
    name: 'Kugelglanz',
    description: 'Bunter Baumschmuck aus Glas, einzeln verpackt.',
    category: 'decoration',
    eastMeters: 72,
    northMeters: 14,
    menu: ['Glaskugeln', 'Baumspitzen', 'Eiszapfen'],
  ),
  // Für Kinder
  DemoStand(
    id: 'demo-stand-18',
    name: 'Karussell Rosinante',
    description: 'Kleines Kettenkarussell für Kinder bis 10 Jahre.',
    category: 'kids',
    eastMeters: 72,
    northMeters: -2,
    promotion: 'Chip 2 €, fünf Chips 8 €',
  ),
  DemoStand(
    id: 'demo-stand-19',
    name: 'Kinderbäckerei',
    description: 'Plätzchen ausstechen und verzieren, jede Stunde ein neuer Kurs.',
    category: 'kids',
    eastMeters: 72,
    northMeters: -22,
    menu: ['Plätzchen backen', 'Lebkuchenhaus bemalen'],
  ),
  // Bühne & Programm
  DemoStand(
    id: 'demo-stand-20',
    name: 'Bühne am Lichterbrunnen',
    description: 'Chöre, Posaunen und Geschichtenerzähler. Das Programm hängt an der Bühne.',
    category: 'stage',
    eastMeters: 6,
    northMeters: 46,
  ),
  // Service
  DemoStand(
    id: 'demo-stand-21',
    name: 'Infohütte',
    description: 'Lageplan, Fundsachen und Rollstuhlverleih.',
    category: 'service',
    eastMeters: -12,
    northMeters: -38,
  ),
  DemoStand(
    id: 'demo-stand-22',
    name: 'Toiletten',
    description: 'Barrierefrei, in der Nähe der Infohütte.',
    category: 'service',
    eastMeters: 12,
    northMeters: -38,
  ),
  // Sonstiges
  DemoStand(
    id: 'demo-stand-23',
    name: 'Tombola Glückstanne',
    description: 'Los kaufen, Tanne schütteln, Preis abholen. Der Erlös geht an die Musterstädter Tafel.',
    category: 'other',
    eastMeters: 48,
    northMeters: -38,
    promotion: 'Jedes dritte Los gewinnt',
  ),
  DemoStand(
    id: 'demo-stand-24',
    name: 'Wärmehalle',
    description: 'Überdachte Sitzplätze zum Aufwärmen, mit Heizpilzen.',
    category: 'other',
    eastMeters: -36,
    northMeters: -38,
  ),
];
