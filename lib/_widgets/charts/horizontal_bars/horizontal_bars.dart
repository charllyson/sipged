import 'package:flutter/material.dart';

class HorizontalBars extends StatelessWidget {
  final Map<String, int> data;
  final String? highlightKey;
  final void Function(String key) onTapKey;

  const HorizontalBars({super.key,
    required this.data,
    required this.highlightKey,
    required this.onTapKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Sem dados no recorte',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value.toDouble().clamp(1, 999999);

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = entries[i];
        final ratio = (e.value / maxV).clamp(0.0, 1.0);
        final isHighlight = highlightKey != null && highlightKey == e.key;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTapKey(e.key),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: isHighlight ? 0.10 : 0.05)
                  : Colors.black.withValues(alpha: isHighlight ? 0.06 : 0.03),
              border: Border.all(
                color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF6E7BFF), Color(0xFFB66DFF)],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${e.value}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}