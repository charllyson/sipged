import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';

class DockPanelSnap extends StatelessWidget {
  final bool visible;
  final Rect? previewRect;
  final DockArea? snapArea;
  final Color? backgroundOverlayColor;

  const DockPanelSnap({
    super.key,
    required this.visible,
    required this.previewRect,
    required this.snapArea,
    this.backgroundOverlayColor,
  });

  static const double _maxPreviewThickness = 28.0;
  static const double _minPreviewThickness = 20.0;
  static const double _edgeInset = 2.0;

  Rect _compactPreviewRect(Rect rect, DockArea area) {
    switch (area) {
      case DockArea.top:
        final newHeight = rect.height.clamp(_minPreviewThickness, _maxPreviewThickness).toDouble();
        return Rect.fromLTWH(rect.left, rect.top, rect.width, newHeight);

      case DockArea.bottom:
        final newHeight = rect.height.clamp(_minPreviewThickness, _maxPreviewThickness).toDouble();
        return Rect.fromLTWH(rect.left, rect.bottom - newHeight, rect.width, newHeight);

      case DockArea.left:
        final newWidth = rect.width.clamp(_minPreviewThickness, _maxPreviewThickness).toDouble();
        return Rect.fromLTWH(rect.left, rect.top, newWidth, rect.height);

      case DockArea.right:
        final newWidth = rect.width.clamp(_minPreviewThickness, _maxPreviewThickness).toDouble();
        return Rect.fromLTWH(rect.right - newWidth, rect.top, newWidth, rect.height);

      case DockArea.floating:
        return rect;
    }
  }

  Rect _clampInside(Rect rect, Rect bounds) {
    final left = rect.left.clamp(bounds.left, bounds.right).toDouble();
    final top = rect.top.clamp(bounds.top, bounds.bottom).toDouble();
    final right = rect.right.clamp(bounds.left, bounds.right).toDouble();
    final bottom = rect.bottom.clamp(bounds.top, bounds.bottom).toDouble();

    if (right <= left || bottom <= top) {
      return bounds;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    if (!visible || previewRect == null || snapArea == null) {
      return const SizedBox.shrink();
    }

    final colorBase = backgroundOverlayColor ?? Colors.blue;

    final bounds = previewRect!.deflate(_edgeInset);
    var rect = _compactPreviewRect(bounds, snapArea!);
    rect = _clampInside(rect, bounds);

    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorBase.withValues(alpha: 0.16),
              border: Border.all(
                color: colorBase.withValues(alpha: 0.60),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}