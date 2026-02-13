// lib/screens/modules/traffic/dashboard/show_city_details.dart
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';

class ShowCityDetails extends StatelessWidget {
  const ShowCityDetails({
    required this.dados,
    required this.region,
    super.key,
  });

  final List<AccidentsData> dados;
  final String region;

  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  int get _totalMortes => dados.fold(0, (a, b) => a + (b.death ?? 0));
  int get _totalFeridos =>
      dados.fold(0, (a, b) => a + (b.scoresVictims ?? 0));

  Color _chipColor(BuildContext context) =>
      Theme.of(context).colorScheme.secondaryContainer;

  Color _chipTextColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSecondaryContainer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = [...dados]
      ..sort(
            (a, b) => (b.date ?? DateTime(1900))
            .compareTo(a.date ?? DateTime(1900)),
      );

    final total = items.length;

    final size = MediaQuery.of(context).size;
    final double maxW = (size.width * 0.92).clamp(360.0, 980.0);
    final double maxH = (size.height * 0.78).clamp(420.0, 900.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2031), Color(0xFF1B2039)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 16, 8, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_city_rounded,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  region,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () =>
                                Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: 'Registros',
                              value: '$total',
                              color: _chipColor(context),
                              textColor: _chipTextColor(context),
                              icon: Icons.list_alt_rounded,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: 'Mortes',
                              value: '$_totalMortes',
                              color: Colors.red.withValues(alpha: .14),
                              textColor: Colors.red.shade700,
                              icon: Icons.heart_broken_rounded,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              label: 'Feridos',
                              value: '$_totalFeridos',
                              color:
                              Colors.orange.withValues(alpha: .16),
                              textColor:
                              Colors.orange.shade800,
                              icon: Icons
                                  .medical_services_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CONTEÚDO
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(cs: cs, region: region)
                  : Stack(
                children: [
                  const BackgroundClean(),
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        16, 16, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                    const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final acc = items[i];
                      final typeCanonical =
                      AccidentsData.canonicalType(
                        acc.typeOfAccident,
                      );
                      final colorType =
                      AccidentsData.getColorByAccidentType(
                          typeCanonical);
                      final iconType =
                      AccidentsData.iconFor(typeCanonical);

                      return _AccidentCard(
                        colorType: colorType,
                        iconType: iconType,
                        title:
                        '${AccidentsData.getTitleByAccidentType(typeCanonical)} · AL-${acc.highway ?? 'Rodovia não informada'}',
                        subtitle: acc.location
                            ?.isNotEmpty ==
                            true
                            ? acc.location!.trim()
                            : (acc.referencePoint?.trim() ??
                            'Local não informado'),
                        trailingTop: _fmtDate(acc.date),
                        trailingBottom:
                        'Mortes: ${acc.death ?? 0}  •  Feridos: ${acc.scoresVictims ?? 0}',
                        city: acc.city ?? region,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= Widgets internos =======

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccidentCard extends StatelessWidget {
  const _AccidentCard({
    required this.colorType,
    required this.iconType,
    required this.title,
    required this.subtitle,
    required this.trailingTop,
    required this.trailingBottom,
    required this.city,
  });

  final Color colorType;
  final IconData iconType;
  final String title;
  final String subtitle;
  final String trailingTop;
  final String trailingBottom;
  final String city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () {},
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding:
                const EdgeInsets.only(right: 8.0),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorType.withValues(alpha: .16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorType.withValues(alpha: .35),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    iconType,
                    color: colorType,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: theme
                                  .textTheme.bodyMedium
                                  ?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MiniTag(
                            icon: Icons.place_rounded,
                            label: city,
                          ),
                          if (trailingBottom.isNotEmpty)
                            const SizedBox(width: 8),
                          _MiniTag(
                            icon: Icons
                                .health_and_safety_rounded,
                            label: trailingBottom,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trailingTop,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: .5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs, required this.region});
  final ColorScheme cs;
  final String region;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'MUNICÍPIO: $region',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há dados disponíveis para este município.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
