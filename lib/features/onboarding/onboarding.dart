import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../theme/brand_tokens.dart';
import '../../widgets/awning_edge.dart';

const _seenKey = 'onboarding_seen_v1';

/// Whether the three intro cards were already shown on this device.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_seenKey) ?? false;
});

Future<void> markOnboardingSeen(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_seenKey, true);
  ref.invalidate(onboardingSeenProvider);
}

/// Three cards on first start: the map, finding stands, the team.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      markOnboardingSeen(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cards = [
      (Icons.map_rounded, BrandColors.red, l.onb1Title, l.onb1Text),
      (Icons.search_rounded, BrandColors.green, l.onb2Title, l.onb2Text),
      (Icons.groups_rounded, BrandColors.ink, l.onb3Title, l.onb3Text),
    ];
    return Scaffold(
      backgroundColor: BrandColors.paper,
      body: Column(
        children: [
          const AwningEdge(stripeWidth: 28, bandHeight: 44),
          SafeArea(
            top: false,
            bottom: false,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => markOnboardingSeen(ref),
                child: Text(l.onbSkip),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final (icon, color, title, body) in cards)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 168,
                          height: 168,
                          decoration: BoxDecoration(
                            color: BrandColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: BrandColors.line),
                          ),
                          child: Icon(icon, size: 84, color: color),
                        ),
                        const SizedBox(height: 40),
                        Text(title, textAlign: TextAlign.center, style: brandDisplay(44)),
                        const SizedBox(height: 12),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BrandColors.inkSoft, height: 1.4),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index ? BrandColors.red : BrandColors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_index < 2 ? l.onbNext : l.onbStart),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
