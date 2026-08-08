import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/map/base/map_data.dart';
import 'package:sipged/_widgets/map/base/map_types.dart';

class MapTypeButton extends StatefulWidget {
  const MapTypeButton({
    super.key,
    required this.mapController,
    required this.selectedMapIndex,
    required this.onChanged,
    this.expanded = false,
    this.onExpandedChanged,
    this.collapsedSize = 76,
    this.previewSize = 54,
    this.panelRadius = 24,
    this.backgroundColor = Colors.black38,
    this.compactBackgroundColor = Colors.black38,
    this.selectedColor = const Color(0xFF2196F3),
    this.maxExpandedWidth,
  });

  final MapController mapController;
  final int selectedMapIndex;
  final ValueChanged<int> onChanged;

  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  final double collapsedSize;
  final double previewSize;
  final double panelRadius;

  final Color backgroundColor;
  final Color compactBackgroundColor;
  final Color selectedColor;

  final double? maxExpandedWidth;

  @override
  State<MapTypeButton> createState() => _MapTypeButtonState();
}

class _MapTypeButtonState extends State<MapTypeButton> {
  static const Duration _duration = Duration(milliseconds: 360);
  static const Curve _curve = Curves.easeOutCubic;

  final ScrollController _scrollController = ScrollController();

  bool _internalExpanded = false;

  bool get _isControlled => widget.onExpandedChanged != null;

  bool get _isExpanded => _isControlled ? widget.expanded : _internalExpanded;

  double get _padding => 3.0;

  double get _edgeSafeInset => 2.0;

  double get _effectivePadding => _padding + _edgeSafeInset;

  double get _gap => 8.0;

  double get _tileSize => widget.collapsedSize;

  double get _height => _tileSize + (_effectivePadding * 2);

  double get _collapsedWidth => _tileSize + (_effectivePadding * 2);

  @override
  void initState() {
    super.initState();
    _internalExpanded = widget.expanded;
  }

  @override
  void didUpdateWidget(covariant MapTypeButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isControlled && oldWidget.expanded != widget.expanded) {
      _internalExpanded = widget.expanded;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _safeIndex {
    if (MapTypes.mapBase.isEmpty) return 0;

    if (widget.selectedMapIndex >= 0 &&
        widget.selectedMapIndex < MapTypes.mapBase.length) {
      return widget.selectedMapIndex;
    }

    return 0;
  }

  List<int> get _orderedIndexes {
    return List<int>.generate(
      MapTypes.mapBase.length,
          (index) => index,
    );
  }

  void _setExpanded(bool value) {
    if (_isControlled) {
      widget.onExpandedChanged?.call(value);
    } else {
      if (_internalExpanded == value) return;

      setState(() {
        _internalExpanded = value;
      });
    }
  }

  void _toggleExpanded() {
    if (MapTypes.mapBase.isEmpty) return;
    _setExpanded(!_isExpanded);
  }

  void _forceMapRefresh() {
    Future.microtask(() {
      try {
        final camera = widget.mapController.camera;
        widget.mapController.move(camera.center, camera.zoom);
      } catch (_) {}
    });
  }

  void _selectMap(int index) {
    if (index < 0 || index >= MapTypes.mapBase.length) return;

    final item = MapTypes.mapBase[index];

    if (!item.enabled) return;

    if (index == _safeIndex) {
      return;
    }

    widget.onChanged(index);
    _forceMapRefresh();
  }

  double _calculateExpandedWidth(double screenWidth) {
    final totalItems = MapTypes.mapBase.length;

    if (totalItems <= 1) {
      return _collapsedWidth;
    }

    final desiredWidth = (_effectivePadding * 2) +
        (totalItems * _tileSize) +
        ((totalItems - 1) * _gap);

    final availableWidth = widget.maxExpandedWidth ?? (screenWidth - 24);

    final maxWidth = math.max(
      _collapsedWidth,
      availableWidth,
    );

    return math.min(maxWidth, desiredWidth);
  }

  @override
  Widget build(BuildContext context) {
    if (MapTypes.mapBase.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final expandedWidth = _calculateExpandedWidth(screenWidth);
    final currentWidth = _isExpanded ? expandedWidth : _collapsedWidth;

    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: currentWidth,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.panelRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.panelRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: _duration,
            curve: _curve,
            width: currentWidth,
            height: _height,
            padding: EdgeInsets.all(_effectivePadding),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? widget.backgroundColor
                  : widget.compactBackgroundColor,
              borderRadius: BorderRadius.circular(widget.panelRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1,
              ),
            ),
            child: _isExpanded
                ? _buildExpandedList()
                : _buildCollapsedTile(),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedTile() {
    final item = MapTypes.mapBase[_safeIndex];

    return Center(
      child: _MapTypeTile(
        data: item,
        selected: false,
        selectedColor: widget.selectedColor,
        width: _tileSize,
        height: _tileSize,
        showSelectedBadge: false,
        onTap: _toggleExpanded,
      ),
    );
  }

  Widget _buildExpandedList() {
    return ScrollConfiguration(
      behavior: const _NoGlowScrollBehavior(),
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        itemCount: _orderedIndexes.length,
        separatorBuilder: (_, _) => SizedBox(width: _gap),
        itemBuilder: (context, position) {
          final index = _orderedIndexes[position];
          final item = MapTypes.mapBase[index];
          final selected = index == _safeIndex;

          return _MapTypeTile(
            data: item,
            selected: selected,
            selectedColor: widget.selectedColor,
            width: _tileSize,
            height: _tileSize,
            showSelectedBadge: selected,
            onTap: () => _selectMap(index),
          );
        },
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

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class _MapTypeTile extends StatelessWidget {
  const _MapTypeTile({
    required this.data,
    required this.selected,
    required this.selectedColor,
    required this.width,
    required this.height,
    required this.showSelectedBadge,
    required this.onTap,
  });

  final MapData data;
  final bool selected;
  final Color selectedColor;
  final double width;
  final double height;
  final bool showSelectedBadge;
  final VoidCallback onTap;

  static const double _selectedBorderWidth = 3.0;
  static const double _normalBorderWidth = 1.0;
  static const double _tileRadius = 19.0;
  static const double _safeInset = 1.5;

  @override
  Widget build(BuildContext context) {
    final disabled = !data.enabled;

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(_safeInset),
        child: Opacity(
          opacity: disabled ? 0.42 : 1,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_tileRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: disabled ? null : onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: width,
                height: height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_tileRadius),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.24),
                        blurRadius: 10,
                        spreadRadius: 0.4,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_tileRadius),
                  border: Border.all(
                    color: selected
                        ? selectedColor.withValues(alpha: 1)
                        : Colors.white.withValues(alpha: 0.10),
                    width: selected ? _selectedBorderWidth : _normalBorderWidth,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MapPreviewImage(
                      data: data,
                      iconSize: 28,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.46, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.00),
                            Colors.black.withValues(alpha: 0.08),
                            Colors.black.withValues(alpha: 0.66),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 8,
                      child: Text(
                        data.shortName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: selected ? 12.8 : 12.4,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.15,
                          shadows: const [
                            Shadow(
                              color: Color(0xCC000000),
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showSelectedBadge)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 7,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    if (disabled)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.34),
                        ),
                      ),
                    if (disabled)
                      const Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPreviewImage extends StatelessWidget {
  const _MapPreviewImage({
    required this.data,
    required this.iconSize,
  });

  final MapData data;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (!data.hasPreview) {
      return _MapPreviewFallback(
        data: data,
        iconSize: iconSize,
      );
    }

    return CachedNetworkImage(
      imageUrl: data.previewUrl,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorWidget: (context, url, error) {
        return _MapPreviewFallback(
          data: data,
          iconSize: iconSize,
        );
      },
      placeholder: (context, url) {
        return _MapPreviewFallback(
          data: data,
          iconSize: iconSize,
          loading: true,
        );
      },
    );
  }
}

class _MapPreviewFallback extends StatelessWidget {
  const _MapPreviewFallback({
    required this.data,
    required this.iconSize,
    this.loading = false,
  });

  final MapData data;
  final double iconSize;
  final bool loading;

  bool get _isNoBaseMap {
    return data.url.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isNoBaseMap) {
      return _NoBaseMapPreview(
        data: data,
        iconSize: iconSize,
        loading: loading,
      );
    }

    return CustomPaint(
      painter: _PreviewFallbackPainter(
        accentColor: data.accentColor,
        dark: !data.hasMap,
      ),
      child: Center(
        child: loading
            ? SizedBox(
          width: iconSize * 0.70,
          height: iconSize * 0.70,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: data.accentColor,
          ),
        )
            : Icon(
          data.icon,
          size: iconSize,
          color: data.hasMap ? Colors.white : const Color(0xFFCFD8DC),
        ),
      ),
    );
  }
}

class _NoBaseMapPreview extends StatelessWidget {
  const _NoBaseMapPreview({
    required this.data,
    required this.iconSize,
    required this.loading,
  });

  final MapData data;
  final double iconSize;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7FAFC),
            Color(0xFFE7EEF3),
          ],
        ),
      ),
      child: Center(
        child: loading
            ? SizedBox(
          width: iconSize * 0.70,
          height: iconSize * 0.70,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: data.accentColor,
          ),
        )
            : Icon(
          data.icon,
          size: iconSize,
          color: data.accentColor.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _PreviewFallbackPainter extends CustomPainter {
  const _PreviewFallbackPainter({
    required this.accentColor,
    required this.dark,
  });

  final Color accentColor;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [
          Color(0xFF263238),
          Color(0xFF111827),
        ]
            : [
          const Color(0xFF101820),
          accentColor.withValues(alpha: 0.55),
          const Color(0xFF0B1220),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    final step = math.max(12.0, size.width / 5);

    for (double x = -step; x <= size.width + step; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.45, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y <= size.height + step; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.width * 0.22),
        gridPaint,
      );
    }

    final roadShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..strokeWidth = math.max(8, size.width * 0.085)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = math.max(5, size.width * 0.055)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadInner = Paint()
      ..color = accentColor.withValues(alpha: 0.82)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.76)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.46,
        size.width * 0.54,
        size.height * 0.88,
        size.width * 0.94,
        size.height * 0.32,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.02, size.height * 0.26)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.44,
        size.width * 0.62,
        size.height * 0.07,
        size.width * 0.99,
        size.height * 0.30,
      );

    canvas.drawPath(path1, roadShadow);
    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path1, roadInner);

    canvas.drawPath(path2, roadShadow);
    canvas.drawPath(path2, roadPaint);

    final pinPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    final pinShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    final pinCenter = Offset(size.width * 0.70, size.height * 0.34);

    canvas.drawCircle(
      pinCenter.translate(0, 2),
      size.width * 0.065,
      pinShadow,
    );

    canvas.drawCircle(
      pinCenter,
      size.width * 0.055,
      pinPaint,
    );

    canvas.drawCircle(
      pinCenter,
      size.width * 0.025,
      Paint()..color = Colors.white.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewFallbackPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor || oldDelegate.dark != dark;
  }
}