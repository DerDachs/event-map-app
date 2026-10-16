import 'package:flutter/widgets.dart';

import '../features/feed/models/feed_post.dart';
import '../features/market_builder/models/stand_categories.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// Texts in the app's current language (German or English).
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsNames on AppLocalizations {
  String standCategoryName(StandCategory c) => switch (c.key) {
        'gluehwein' => catGluehwein,
        'food_savory' => catFoodSavory,
        'food_sweet' => catFoodSweet,
        'crafts' => catCrafts,
        'decoration' => catDecoration,
        'kids' => catKids,
        'stage' => catStage,
        'service' => catService,
        _ => catOther,
      };

  String feedPostTypeLabel(FeedPostType t) => switch (t) {
        FeedPostType.news => postTypeNews,
        FeedPostType.opening => postTypeOpening,
        FeedPostType.tip => postTypeTip,
        FeedPostType.event => postTypeEvent,
      };
}
