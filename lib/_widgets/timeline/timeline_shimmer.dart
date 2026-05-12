// lib/_widgets/timeline/timeline_shimmer.dart
// ou lib/screens/commons/timeline/timeline_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TimelineShimmer extends StatelessWidget {
  final double height;
  final int itemCount;
  final bool showHeader;

  const TimelineShimmer({
    super.key,
    this.height = 310,
    this.itemCount = 4,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFB8C4D3);

    final highlightColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFD7DEE8);

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
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: const _TimelineHeaderSkeleton(),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: ScrollConfiguration(
                  behavior: const _NoGlowScrollBehavior(),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: 4,
                      right: 18,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      final isFirst = index == 0;
                      final isLast = index == itemCount - 1;
                      final isTop = index.isEven;

                      return _TimelineNodeSkeleton(
                        index: index,
                        isFirst: isFirst,
                        isLast: isLast,
                        isTop: isTop,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineHeaderSkeleton extends StatelessWidget {
  const _TimelineHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonBox(
          width: 42,
          height: 42,
          radius: 16,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                width: 185,
                height: 14,
                radius: 7,
              ),
              SizedBox(height: 8),
              _SkeletonBox(
                width: 265,
                height: 11,
                radius: 7,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineNodeSkeleton extends StatelessWidget {
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool isTop;

  static const double _minNodeWidth = 190;
  static const double _maxNodeWidth = 560;

  static const double _nodeHeight = 234;

  static const double _centerLineTop = 117;
  static const double _markerSize = 42;
  static const double _markerTop = _centerLineTop - (_markerSize / 2);
  static const double _markerBottom = _markerTop + _markerSize;

  static const double _cardHeight = 78;
  static const double _cardGap = 18;

  static const double _topCardTop = _markerTop - _cardGap - _cardHeight;
  static const double _bottomCardTop = _markerBottom + _cardGap;

  const _TimelineNodeSkeleton({
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final nodeWidth = _resolveNodeWidth(index);
    final cardTop = isTop ? _topCardTop : _bottomCardTop;

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
            child: const _SkeletonBox(
              width: double.infinity,
              height: 4,
              radius: 99,
            ),
          ),

          Positioned(
            top: isTop ? _topCardTop + _cardHeight : _markerBottom,
            left: (nodeWidth / 2) - 1.5,
            child: const _SkeletonBox(
              width: 3,
              height: _cardGap,
              radius: 99,
            ),
          ),

          Positioned(
            top: _markerTop,
            left: (nodeWidth / 2) - (_markerSize / 2),
            child: const _TimelineMarkerSkeleton(),
          ),

          Positioned(
            top: cardTop,
            left: 10,
            right: 10,
            child: SizedBox(
              height: _cardHeight,
              child: _TimelineCardSkeleton(
                index: index,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _resolveNodeWidth(int index) {
    const widths = <double>[
      230,
      300,
      260,
      390,
      220,
      340,
    ];

    final width = widths[index % widths.length];

    return width.clamp(_minNodeWidth, _maxNodeWidth);
  }
}

class _TimelineMarkerSkeleton extends StatelessWidget {
  const _TimelineMarkerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: _SkeletonCircle(size: 30),
      ),
    );
  }
}

class _TimelineCardSkeleton extends StatelessWidget {
  final int index;

  const _TimelineCardSkeleton({
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidth = _titleWidth(index);
    final subtitleWidth = _subtitleWidth(index);
    final chipOneWidth = _chipOneWidth(index);
    final chipTwoWidth = _chipTwoWidth(index);

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(
            width: 34,
            height: 34,
            radius: 13,
          ),
          const SizedBox(width: 9),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: titleWidth,
                  height: 10,
                  radius: 6,
                ),
                const SizedBox(height: 6),
                _SkeletonBox(
                  width: subtitleWidth,
                  height: 9,
                  radius: 6,
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SkeletonBox(
                      width: chipOneWidth,
                      height: 17,
                      radius: 999,
                    ),
                    if (index.isOdd) ...[
                      const SizedBox(width: 6),
                      _SkeletonBox(
                        width: chipTwoWidth,
                        height: 17,
                        radius: 999,
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

  double _titleWidth(int index) {
    const widths = <double>[
      112,
      178,
      145,
      245,
      96,
      210,
    ];

    return widths[index % widths.length];
  }

  double _subtitleWidth(int index) {
    const widths = <double>[
      92,
      126,
      106,
      150,
      84,
      134,
    ];

    return widths[index % widths.length];
  }

  double _chipOneWidth(int index) {
    const widths = <double>[
      72,
      86,
      78,
      92,
      70,
      88,
    ];

    return widths[index % widths.length];
  }

  double _chipTwoWidth(int index) {
    const widths = <double>[
      58,
      74,
      66,
      96,
      62,
      82,
    ];

    return widths[index % widths.length];
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
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