import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_types.dart';

class GeoWorkspaceSnapController {
  const GeoWorkspaceSnapController({
    this.snapThreshold = 10.0,
    this.panelPadding = 0.0,
  });

  final double snapThreshold;
  final double panelPadding;

  GeoWorkspaceResolvedRect resolveMoveSnap({
    required String itemId,
    required Rect desiredRect,
    required Size panelSize,
    required List<GeoWorkspaceItemData> items,
  }) {
    final candidatesX = <double>{
      panelPadding,
      panelSize.width / 2,
      math.max(panelPadding, panelSize.width - panelPadding),
    };

    final candidatesY = <double>{
      panelPadding,
      panelSize.height / 2,
      math.max(panelPadding, panelSize.height - panelPadding),
    };

    for (final item in items) {
      if (item.id == itemId) continue;

      final rect = Rect.fromLTWH(
        item.offset.dx,
        item.offset.dy,
        item.size.width,
        item.size.height,
      );

      candidatesX.addAll([rect.left, rect.center.dx, rect.right]);
      candidatesY.addAll([rect.top, rect.center.dy, rect.bottom]);
    }

    double left = desiredRect.left;
    double top = desiredRect.top;
    final width = desiredRect.width;
    final height = desiredRect.height;

    final itemXPoints = {
      GeoWorkspaceSnapEdge.left: desiredRect.left,
      GeoWorkspaceSnapEdge.centerX: desiredRect.center.dx,
      GeoWorkspaceSnapEdge.right: desiredRect.right,
    };

    final itemYPoints = {
      GeoWorkspaceSnapEdge.top: desiredRect.top,
      GeoWorkspaceSnapEdge.centerY: desiredRect.center.dy,
      GeoWorkspaceSnapEdge.bottom: desiredRect.bottom,
    };

    double? snappedGuideX;
    double? snappedGuideY;

    double bestDx = snapThreshold + 1;
    double bestDy = snapThreshold + 1;

    for (final entry in itemXPoints.entries) {
      for (final candidate in candidatesX) {
        final diff = (entry.value - candidate).abs();
        if (diff < bestDx && diff <= snapThreshold) {
          bestDx = diff;
          snappedGuideX = candidate;

          switch (entry.key) {
            case GeoWorkspaceSnapEdge.left:
              left = candidate;
              break;
            case GeoWorkspaceSnapEdge.centerX:
              left = candidate - (width / 2);
              break;
            case GeoWorkspaceSnapEdge.right:
              left = candidate - width;
              break;
            case GeoWorkspaceSnapEdge.top:
            case GeoWorkspaceSnapEdge.centerY:
            case GeoWorkspaceSnapEdge.bottom:
              break;
          }
        }
      }
    }

    for (final entry in itemYPoints.entries) {
      for (final candidate in candidatesY) {
        final diff = (entry.value - candidate).abs();
        if (diff < bestDy && diff <= snapThreshold) {
          bestDy = diff;
          snappedGuideY = candidate;

          switch (entry.key) {
            case GeoWorkspaceSnapEdge.top:
              top = candidate;
              break;
            case GeoWorkspaceSnapEdge.centerY:
              top = candidate - (height / 2);
              break;
            case GeoWorkspaceSnapEdge.bottom:
              top = candidate - height;
              break;
            case GeoWorkspaceSnapEdge.left:
            case GeoWorkspaceSnapEdge.centerX:
            case GeoWorkspaceSnapEdge.right:
              break;
          }
        }
      }
    }

    final clamped = clampRect(
      rect: Rect.fromLTWH(left, top, width, height),
      panelSize: panelSize,
    );

    return GeoWorkspaceResolvedRect(
      rect: clamped,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GeoWorkspaceGuideLines(
        vertical: snappedGuideX,
        horizontal: snappedGuideY,
      )
          : null,
    );
  }

  GeoWorkspaceResolvedRect resolveResizeSnap({
    required String itemId,
    required Rect desiredRect,
    required GeoWorkspaceResizeHandle handle,
    required Size panelSize,
    required List<GeoWorkspaceItemData> items,
  }) {
    final candidatesX = <double>{
      panelPadding,
      panelSize.width / 2,
      math.max(panelPadding, panelSize.width - panelPadding),
    };

    final candidatesY = <double>{
      panelPadding,
      panelSize.height / 2,
      math.max(panelPadding, panelSize.height - panelPadding),
    };

    for (final item in items) {
      if (item.id == itemId) continue;

      final rect = Rect.fromLTWH(
        item.offset.dx,
        item.offset.dy,
        item.size.width,
        item.size.height,
      );

      candidatesX.addAll([rect.left, rect.center.dx, rect.right]);
      candidatesY.addAll([rect.top, rect.center.dy, rect.bottom]);
    }

    double left = desiredRect.left;
    double top = desiredRect.top;
    double right = desiredRect.right;
    double bottom = desiredRect.bottom;

    double? snappedGuideX;
    double? snappedGuideY;

    void snapX(bool useLeft, bool useCenter, bool useRight) {
      double best = snapThreshold + 1;

      if (useLeft) {
        for (final candidate in candidatesX) {
          final diff = (left - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            left = candidate;
            snappedGuideX = candidate;
          }
        }
      }

      if (useCenter) {
        final center = (left + right) / 2;
        for (final candidate in candidatesX) {
          final diff = (center - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            final half = (right - left) / 2;
            left = candidate - half;
            right = candidate + half;
            snappedGuideX = candidate;
          }
        }
      }

      if (useRight) {
        for (final candidate in candidatesX) {
          final diff = (right - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            right = candidate;
            snappedGuideX = candidate;
          }
        }
      }
    }

    void snapY(bool useTop, bool useCenter, bool useBottom) {
      double best = snapThreshold + 1;

      if (useTop) {
        for (final candidate in candidatesY) {
          final diff = (top - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            top = candidate;
            snappedGuideY = candidate;
          }
        }
      }

      if (useCenter) {
        final center = (top + bottom) / 2;
        for (final candidate in candidatesY) {
          final diff = (center - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            final half = (bottom - top) / 2;
            top = candidate - half;
            bottom = candidate + half;
            snappedGuideY = candidate;
          }
        }
      }

      if (useBottom) {
        for (final candidate in candidatesY) {
          final diff = (bottom - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            bottom = candidate;
            snappedGuideY = candidate;
          }
        }
      }
    }

    switch (handle) {
      case GeoWorkspaceResizeHandle.right:
        snapX(false, false, true);
        break;
      case GeoWorkspaceResizeHandle.bottom:
        snapY(false, false, true);
        break;
      case GeoWorkspaceResizeHandle.bottomRight:
        snapX(false, false, true);
        snapY(false, false, true);
        break;
      case GeoWorkspaceResizeHandle.left:
        snapX(true, false, false);
        break;
      case GeoWorkspaceResizeHandle.top:
        snapY(true, false, false);
        break;
      case GeoWorkspaceResizeHandle.topLeft:
        snapX(true, false, false);
        snapY(true, false, false);
        break;
      case GeoWorkspaceResizeHandle.topRight:
        snapX(false, false, true);
        snapY(true, false, false);
        break;
      case GeoWorkspaceResizeHandle.bottomLeft:
        snapX(true, false, false);
        snapY(false, false, true);
        break;
    }

    final normalized = normalizeResizeRect(
      rect: Rect.fromLTRB(left, top, right, bottom),
      panelSize: panelSize,
    );

    return GeoWorkspaceResolvedRect(
      rect: normalized,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GeoWorkspaceGuideLines(
        vertical: snappedGuideX,
        horizontal: snappedGuideY,
      )
          : null,
    );
  }

  Rect normalizeResizeRect({
    required Rect rect,
    required Size panelSize,
  }) {
    double left = rect.left;
    double top = rect.top;
    double right = rect.right;
    double bottom = rect.bottom;

    if (right < left) {
      final tmp = left;
      left = right;
      right = tmp;
    }

    if (bottom < top) {
      final tmp = top;
      top = bottom;
      bottom = tmp;
    }

    final minW = GeoWorkspaceItemData.minSize.width;
    final minH = GeoWorkspaceItemData.minSize.height;

    if ((right - left) < minW) {
      right = left + minW;
    }

    if ((bottom - top) < minH) {
      bottom = top + minH;
    }

    left = left.clamp(
      panelPadding,
      math.max(panelPadding, panelSize.width - minW),
    );
    top = top.clamp(
      panelPadding,
      math.max(panelPadding, panelSize.height - minH),
    );

    right = right.clamp(left + minW, panelSize.width);
    bottom = bottom.clamp(top + minH, panelSize.height);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect clampRect({
    required Rect rect,
    required Size panelSize,
  }) {
    final maxX = math.max(panelPadding, panelSize.width - rect.width);
    final maxY = math.max(panelPadding, panelSize.height - rect.height);

    return Rect.fromLTWH(
      rect.left.clamp(panelPadding, maxX).toDouble(),
      rect.top.clamp(panelPadding, maxY).toDouble(),
      rect.width,
      rect.height,
    );
  }
}