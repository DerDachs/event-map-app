/// Kinds of markets. The key is stored as `category` on the event and lets
/// a season pick its markets.
class MarketType {
  final String key;
  final String name;

  const MarketType(this.key, this.name);
}

const marketTypes = <MarketType>[
  MarketType('christmas_market', 'Weihnachtsmarkt'),
  MarketType('easter_market', 'Ostermarkt'),
  MarketType('spring_market', 'Frühlingsmarkt'),
  MarketType('pentecost_market', 'Pfingstmarkt'),
  MarketType('summer_festival', 'Sommerfest'),
  MarketType('autumn_market', 'Herbstmarkt'),
  MarketType('wine_festival', 'Weinfest'),
  MarketType('medieval_market', 'Mittelaltermarkt'),
  MarketType('other', 'Sonstiger Markt'),
];

/// Unknown or empty keys (older markets) count as "other".
MarketType marketTypeFor(String? key) =>
    marketTypes.firstWhere((t) => t.key == key, orElse: () => marketTypes.last);
