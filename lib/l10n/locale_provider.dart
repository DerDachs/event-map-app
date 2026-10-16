import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the user picked in the settings.
enum AppLanguage {
  system(null),
  de('de'),
  en('en');

  final String? code;
  const AppLanguage(this.code);

  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.system);
}

const _prefsKey = 'app_language';

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppLanguage.fromCode(prefs.getString(_prefsKey));
    } catch (_) {
      // Keep following the device language.
    }
  }

  Future<void> set(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    if (language.code == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, language.code!);
    }
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) => AppLanguageNotifier());

/// German devices get German, everyone else English.
Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'de' ? const Locale('de') : const Locale('en');
