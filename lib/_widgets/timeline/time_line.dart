// lib/_widgets/timeline/modern_timeline.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef TimelineDateFormatter = String Function(DateTime date);

class ModernTimelineBadge {
  final String label;
  final IconData icon;
  final Color color;

  const ModernTimelineBadge({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class ModernTimelineEntry<T> {
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final IconData icon;
  final List<ModernTimelineBadge> badges;
  final T? original;

  const ModernTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    required this.icon,
    this.badges = const [],
    this.original,
  });
}

class ModernTimeline extends StatelessWidget {
  final List<ModernTimelineEntry<dynamic>> items;
  final TimelineDateFormatter dateFormatter;

  final String? status;
  final String title;
  final String? subtitle;
  final bool showHeader;
  final double height;

  const ModernTimeline({
    super.key,
    required this.items,
    required this.dateFormatter,
    this.status,
    this.title = 'Linha do tempo',
    this.subtitle,
    this.showHeader = true,
    this.height = 310,
  });

  @override
  Widget build(BuildContext context) {
    final cleanStatus = status?.toUpperCase().trim() ?? '';

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 12,
          top: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              _ModernTimelineHeader(
                title: title,
                subtitle: subtitle ??
                    '${items.length} item${items.length == 1 ? '' : 's'} registrado${items.length == 1 ? '' : 's'}',
                status: cleanStatus,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: ScrollConfiguration(
                behavior: const _NoGlowScrollBehavior(),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 18,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return _ModernTimelineNode(
                      item: item,
                      index: index,
                      isFirst: index == 0,
                      isLast: index == items.length - 1,
                      status: cleanStatus,
                      dateFormatter: dateFormatter,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernTimelineHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const _ModernTimelineHeader({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = status.trim().isNotEmpty;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.timeline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (hasStatus)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _statusColor(status).withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _statusColor(status),
                ),
                const SizedBox(width: 7),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Color _statusColor(String status) {
    final clean = status.toUpperCase().trim();

    if (clean.contains('ANDAMENTO')) {
      return const Color(0xFF2563EB);
    }

    if (clean.contains('CONCLU')) {
      return const Color(0xFF16A34A);
    }

    if (clean.contains('PARALISA')) {
      return const Color(0xFFF97316);
    }

    if (clean.contains('VENC')) {
      return const Color(0xFFDC2626);
    }

    return const Color(0xFF475569);
  }
}

class _ModernTimelineNode extends StatelessWidget {
  final ModernTimelineEntry<dynamic> item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final String status;
  final TimelineDateFormatter dateFormatter;

  static const double _minNodeWidth = 190;
  static const double _maxNodeWidth = 620;

  static const double _nodeHeight = 234;

  static const double _centerLineTop = 117;
  static const double _markerSize = 42;
  static const double _markerTop = _centerLineTop - (_markerSize / 2);
  static const double _markerBottom = _markerTop + _markerSize;

  static const double _cardHeight = 78;
  static const double _cardGap = 18;

  static const double _topCardTop = _markerTop - _cardGap - _cardHeight;
  static const double _bottomCardTop = _markerBottom + _cardGap;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 11.5,
    height: 1.15,
    fontWeight: FontWeight.w900,
    color: Color(0xFF0F172A),
    letterSpacing: -0.1,
  );

  static const TextStyle _chipTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );

  const _ModernTimelineNode({
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.status,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = dateFormatter(item.date);

    final isTop = index.isEven;
    final cardTop = isTop ? _topCardTop : _bottomCardTop;

    final subtitleStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey.shade500,
    );

    final nodeWidth = _resolveNodeWidth(
      context: context,
      title: item.title,
      subtitle: item.subtitle,
      dateText: dateStr,
      badges: item.badges,
      titleStyle: _titleStyle,
      subtitleStyle: subtitleStyle,
      chipTextStyle: _chipTextStyle,
    );

    return SizedBox(
      width: nodeWidth,
      height: _nodeHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: _centerLineTop,
            left: isFirst ? nodeWidth / 2 : 0,
            right: isLast ? nodeWidth / 2 : 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    item.color.withValues(alpha: 0.16),
                    item.color.withValues(alpha: 0.45),
                    item.color.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: isTop ? _topCardTop + _cardHeight : _markerBottom,
            left: (nodeWidth / 2) - 1.5,
            child: Container(
              width: 3,
              height: _cardGap,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            top: _markerTop,
            left: (nodeWidth / 2) - (_markerSize / 2),
            child: Tooltip(
              message: item.title,
              child: Container(
                width: _markerSize,
                height: _markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: item.color.withValues(alpha: 0.24),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.color.withValues(alpha: 0.92),
                          item.color,
                        ],
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: cardTop,
            left: 10,
            right: 10,
            child: SizedBox(
              height: _cardHeight,
              child: _TimelineCard(
                color: item.color,
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                dateText: dateStr,
                badges: item.badges,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _resolveNodeWidth({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String dateText,
    required List<ModernTimelineBadge> badges,
    required TextStyle titleStyle,
    required TextStyle subtitleStyle,
    required TextStyle chipTextStyle,
  }) {
    final titleWidth = _measureTextWidth(
      context: context,
      text: title.toUpperCase().trim(),
      style: titleStyle,
    );

    final subtitleWidth = _measureTextWidth(
      context: context,
      text: subtitle.trim(),
      style: subtitleStyle,
    );

    double chipsWidth = _chipWidth(
      context: context,
      text: dateText,
      style: chipTextStyle,
    );

    for (final badge in badges) {
      chipsWidth += 6 +
          _chipWidth(
            context: context,
            text: badge.label,
            style: chipTextStyle,
          );
    }

    final biggestTextWidth = math.max(
      math.max(titleWidth, subtitleWidth),
      chipsWidth,
    );

    const iconWidth = 34.0;
    const iconGap = 9.0;

    const cardPaddingLeft = 10.0;
    const cardPaddingRight = 10.0;

    const positionedLeft = 10.0;
    const positionedRight = 10.0;

    const breathingRoom = 22.0;

    final requiredNodeWidth = biggestTextWidth +
        iconWidth +
        iconGap +
        cardPaddingLeft +
        cardPaddingRight +
        positionedLeft +
        positionedRight +
        breathingRoom;

    return requiredNodeWidth.clamp(_minNodeWidth, _maxNodeWidth);
  }

  double _measureTextWidth({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    if (text.trim().isEmpty) return 0;

    final textScaler = MediaQuery.textScalerOf(context);

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      maxLines: 1,
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
    )..layout();

    return painter.width;
  }

  double _chipWidth({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    const iconWidth = 11.0;
    const iconGap = 4.0;
    const horizontalPadding = 14.0;

    final textWidth = _measureTextWidth(
      context: context,
      text: text,
      style: style,
    );

    return iconWidth + iconGap + horizontalPadding + textWidth;
  }
}

class _TimelineCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String dateText;
  final List<ModernTimelineBadge> badges;

  const _TimelineCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: color.withValues(alpha: 0.10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade500,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallChip(
                      icon: Icons.calendar_month_rounded,
                      label: dateText,
                      color: color,
                    ),
                    for (final badge in badges) ...[
                      const SizedBox(width: 6),
                      _SmallChip(
                        icon: badge.icon,
                        label: badge.label,
                        color: badge.color,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SmallChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return child;
  }
}