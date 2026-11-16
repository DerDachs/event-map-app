import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import 'awning_edge.dart';

/// An empty or failed screen: says what is missing and what to do next.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;

  /// Optional action, usually a retry.
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 112,
                  color: BrandColors.white,
                  child: Column(
                    children: [
                      const AwningEdge(stripeWidth: 16, bandHeight: 4),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
                        child: Icon(icon, size: 40, color: BrandColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, textAlign: TextAlign.center, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (hint != null) ...[
                const SizedBox(height: 6),
                Text(hint!, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: BrandColors.inkSoft)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
