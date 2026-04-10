import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_scope_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guide_lines_data.dart';
import 'package:sipged/_widgets/resize/resize_handle.dart';

class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit({
    required WorkspaceScopeData scope,
    required Map<String, List<FeatureData>> initialFeaturesByLayer,
    required this.repository,
    List<WorkspaceData> initialItems = const [],
    this.snapThreshold = 10.0,
    this.panelPadding = 0.0,
  }) : super(
    WorkspaceState.initial(
      scope: scope,
      items: repository.resolveAllItems(
        items: initialItems,
        featuresByLayer: initialFeaturesByLayer,
      ),
      featuresByLayer: initialFeaturesByLayer,
    ),
  );

  final WorkspaceRepository repository;
  final double snapThreshold;
  final double panelPadding;

  Timer? _saveDebounce;
  bool _dirty = false;
  int _loadRequestId = 0;

  Future<void> loadScope({
    WorkspaceScopeData? scope,
    List<WorkspaceData> fallbackItems = const [],
  }) async {
    final nextScope = scope ?? state.scope;
    final changingScope = nextScope != state.scope;

    if (changingScope) {
      _saveDebounce?.cancel();
      await _persistNow();
    }

    final requestId = ++_loadRequestId;
    final versionBeforeLoad = state.dataVersion;

    emit(
      state.copyWith(
        scope: nextScope,
        isLoading: true,
        clearGuides: true,
        clearSelectedItem: true,
        clearActiveFilter: true,
      ),
    );

    try {
      final persisted = await repository.loadWorkspace(scope: nextScope);

      if (isClosed || requestId != _loadRequestId) return;

      final hasLocalChangesDuringLoad =
          state.scope == nextScope && state.dataVersion != versionBeforeLoad;

      final usedFallback = !hasLocalChangesDuringLoad &&
          persisted.isEmpty &&
          fallbackItems.isNotEmpty;

      final baseItems = hasLocalChangesDuringLoad
          ? state.items
          : (persisted.isNotEmpty ? persisted : fallbackItems);

      final normalized = _normalizeItemsForPanel(baseItems, state.panelSize);
      final resolved = repository.resolveAllItems(
        items: normalized,
        featuresByLayer: state.featuresByLayer,
      );

      emit(
        state.copyWith(
          scope: nextScope,
          items: resolved,
          isLoading: false,
          loaded: true,
          dataVersion: state.dataVersion + 1,
          clearSelectedItem: true,
          clearGuides: true,
          clearActiveFilter: true,
        ),
      );

      if (usedFallback) {
        _schedulePersist();
      }
    } catch (_) {
      if (isClosed || requestId != _loadRequestId) return;

      final normalized = _normalizeItemsForPanel(fallbackItems, state.panelSize);
      final resolved = repository.resolveAllItems(
        items: normalized,
        featuresByLayer: state.featuresByLayer,
      );

      emit(
        state.copyWith(
          scope: nextScope,
          items: resolved,
          isLoading: false,
          loaded: true,
          dataVersion: state.dataVersion + 1,
          clearSelectedItem: true,
          clearGuides: true,
          clearActiveFilter: true,
        ),
      );

      if (fallbackItems.isNotEmpty) {
        _schedulePersist();
      }
    }
  }

  void syncExternalFeatures(Map<String, List<FeatureData>> featuresByLayer) {
    if (_sameFeaturesMap(state.featuresByLayer, featuresByLayer)) return;

    final resolvedItems = repository.resolveAllItems(
      items: state.items,
      featuresByLayer: featuresByLayer,
      activeFilter: state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolvedItems,
        featuresByLayer: Map<String, List<FeatureData>>.from(featuresByLayer),
        dataVersion: state.dataVersion + 1,
      ),
    );
  }

  void setPanelSize(Size size) {
    if (size == state.panelSize) return;

    final normalizedItems = _normalizeItemsForPanel(state.items, size);
    final changed = !listEquals(normalizedItems, state.items);

    emit(
      state.copyWith(
        panelSize: size,
        items: normalizedItems,
      ),
    );

    if (changed) {
      _schedulePersist();
    }
  }

  void selectItem(String itemId) {
    if (state.selectedItemId == itemId) return;
    emit(state.copyWith(selectedItemId: itemId));
  }

  void clearSelection() {
    if (state.selectedItemId == null && state.guides == null) return;
    emit(
      state.copyWith(
        clearSelectedItem: true,
        clearGuides: true,
      ),
    );
  }

  void clearGuides() {
    if (state.guides == null) return;
    emit(state.copyWith(clearGuides: true));
  }

  void clearActiveFilter() {
    if (state.activeFilter == null) return;

    final resolvedItems = repository.resolveAllItems(
      items: state.items,
      featuresByLayer: state.featuresByLayer,
      activeFilter: null,
    );

    emit(
      state.copyWith(
        items: resolvedItems,
        clearActiveFilter: true,
        dataVersion: state.dataVersion + 1,
      ),
    );
  }

  void toggleBarFilter({
    required String itemId,
    required String label,
    required double? value,
  }) {
    final item = state.itemByIdOrNull(itemId);
    if (item == null) return;
    if (item.type.name != 'barVertical') return;

    final nextFilter = repository.toggleBarFilter(
      item: item,
      label: label,
      value: value,
      currentFilter: state.activeFilter,
    );

    final resolvedItems = repository.resolveAllItems(
      items: state.items,
      featuresByLayer: state.featuresByLayer,
      activeFilter: nextFilter,
    );

    emit(
      state.copyWith(
        items: resolvedItems,
        activeFilter: nextFilter,
        dataVersion: state.dataVersion + 1,
      ),
    );
  }

  void addItem(WorkspaceData item) {
    final normalizedItem = _normalizeItemForPanel(item, state.panelSize);

    final resolvedItems = repository.resolveAllItems(
      items: [...state.items, normalizedItem],
      featuresByLayer: state.featuresByLayer,
      activeFilter: state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolvedItems,
        selectedItemId: normalizedItem.id,
        clearGuides: true,
        dataVersion: state.dataVersion + 1,
      ),
    );

    _schedulePersist();
  }

  void updateItemGeometry({
    required String itemId,
    required Offset offset,
    required Size size,
    bool persist = true,
  }) {
    final current = state.itemByIdOrNull(itemId);
    if (current == null) return;

    final updated = _normalizeItemForPanel(
      current.copyWith(
        offset: offset,
        size: size,
      ),
      state.panelSize,
    );

    if (updated == current) return;

    final nextItems = state.items.map((item) {
      if (item.id != itemId) return item;
      return updated;
    }).toList(growable: false);

    final resolved = repository.resolveAllItems(
      items: nextItems,
      featuresByLayer: state.featuresByLayer,
      activeFilter: state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolved,
        clearGuides: true,
        dataVersion: state.dataVersion + 1,
      ),
    );

    if (persist) {
      _schedulePersist();
    }
  }

  void updateItemProperty({
    required String itemId,
    required String propertyKey,
    required CatalogData property,
  }) {
    final current = state.itemByIdOrNull(itemId);
    if (current == null) return;

    final updated = current.copyWithUpdatedProperty(propertyKey, property);
    if (updated == current) return;

    final nextItems = state.items.map((item) {
      if (item.id != itemId) return item;
      return updated;
    }).toList(growable: false);

    final resolved = repository.resolveAllItems(
      items: nextItems,
      featuresByLayer: state.featuresByLayer,
      activeFilter: state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolved,
        dataVersion: state.dataVersion + 1,
      ),
    );

    _schedulePersist();
  }

  void updateItemProperties({
    required String itemId,
    required List<CatalogData> properties,
  }) {
    final current = state.itemByIdOrNull(itemId);
    if (current == null) return;

    final updated = current.copyWith(properties: properties);
    if (updated == current) return;

    final nextItems = state.items.map((item) {
      if (item.id != itemId) return item;
      return updated;
    }).toList(growable: false);

    final resolved = repository.resolveAllItems(
      items: nextItems,
      featuresByLayer: state.featuresByLayer,
      activeFilter: state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolved,
        dataVersion: state.dataVersion + 1,
      ),
    );

    _schedulePersist();
  }

  void removeItem(String itemId) {
    final nextItems =
    state.items.where((item) => item.id != itemId).toList(growable: false);

    final wasSelected = state.selectedItemId == itemId;
    final shouldClearFilter = state.activeFilter?.sourceItemId == itemId;

    final resolvedItems = repository.resolveAllItems(
      items: nextItems,
      featuresByLayer: state.featuresByLayer,
      activeFilter: shouldClearFilter ? null : state.activeFilter,
    );

    emit(
      state.copyWith(
        items: resolvedItems,
        clearSelectedItem: wasSelected,
        clearGuides: true,
        clearActiveFilter: shouldClearFilter,
        dataVersion: state.dataVersion + 1,
      ),
    );

    _schedulePersist();
  }

  GuideLinesResolvedRect moveItemLive({
    required String itemId,
    required Rect desiredRect,
  }) {
    final resolved = _resolveMoveSnap(
      itemId: itemId,
      desiredRect: desiredRect,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: resolved.guides,
    );

    return resolved;
  }

  GuideLinesResolvedRect moveItemCommit({
    required String itemId,
    required Rect desiredRect,
  }) {
    final resolved = _resolveMoveSnap(
      itemId: itemId,
      desiredRect: desiredRect,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: null,
    );

    _schedulePersist();
    return resolved;
  }

  GuideLinesResolvedRect resizeItemLive({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final resolved = _resolveResizeSnap(
      itemId: itemId,
      desiredRect: desiredRect,
      handle: handle,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: resolved.guides,
    );

    return resolved;
  }

  GuideLinesResolvedRect resizeItemCommit({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final resolved = _resolveResizeSnap(
      itemId: itemId,
      desiredRect: desiredRect,
      handle: handle,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: null,
    );

    _schedulePersist();
    return resolved;
  }

  void _updateItemRectLocal({
    required String itemId,
    required Rect rect,
    required GuideLinesData? guides,
  }) {
    var changed = false;

    final nextItems = state.items.map((item) {
      if (item.id != itemId) return item;

      final updated = item.copyWith(
        offset: rect.topLeft,
        size: rect.size,
      );

      if (updated != item) changed = true;
      return updated;
    }).toList(growable: false);

    final guidesChanged = state.guides != guides;

    if (!changed && !guidesChanged) return;

    emit(
      state.copyWith(
        items: nextItems,
        guides: guides,
        clearGuides: guides == null,
      ),
    );
  }

  WorkspaceData _normalizeItemForPanel(
      WorkspaceData item,
      Size panelSize,
      ) {
    if (panelSize.isEmpty) return item;

    final rect = clampRect(
      rect: Rect.fromLTWH(
        item.offset.dx,
        item.offset.dy,
        item.size.width,
        item.size.height,
      ),
      panelSize: panelSize,
    );

    if (rect.topLeft == item.offset && rect.size == item.size) {
      return item;
    }

    return item.copyWith(
      offset: rect.topLeft,
      size: rect.size,
    );
  }

  List<WorkspaceData> _normalizeItemsForPanel(
      List<WorkspaceData> items,
      Size panelSize,
      ) {
    if (panelSize.isEmpty) {
      return List<WorkspaceData>.from(items);
    }

    return items
        .map((item) => _normalizeItemForPanel(item, panelSize))
        .toList(growable: false);
  }

  bool _sameFeaturesMap(
      Map<String, List<FeatureData>> a,
      Map<String, List<FeatureData>> b,
      ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      final listA = a[key];
      final listB = b[key];
      if (listB == null) return false;
      if (!listEquals(listA, listB)) return false;
    }

    return true;
  }

  void _schedulePersist() {
    _dirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _persistNow);
  }

  Future<void> _persistNow() async {
    if (!_dirty || isClosed) return;
    _dirty = false;

    emit(state.copyWith(isSaving: true));

    try {
      await repository.saveWorkspace(
        scope: state.scope,
        items: state.items,
      );
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isSaving: false));
      }
    }
  }

  GuideLinesResolvedRect _resolveMoveSnap({
    required String itemId,
    required Rect desiredRect,
  }) {
    final panelSize = state.panelSize;

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

    for (final item in state.items) {
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
      WorkspaceSnapEdge.left: desiredRect.left,
      WorkspaceSnapEdge.centerX: desiredRect.center.dx,
      WorkspaceSnapEdge.right: desiredRect.right,
    };

    final itemYPoints = {
      WorkspaceSnapEdge.top: desiredRect.top,
      WorkspaceSnapEdge.centerY: desiredRect.center.dy,
      WorkspaceSnapEdge.bottom: desiredRect.bottom,
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
            case WorkspaceSnapEdge.left:
              left = candidate;
              break;
            case WorkspaceSnapEdge.centerX:
              left = candidate - (width / 2);
              break;
            case WorkspaceSnapEdge.right:
              left = candidate - width;
              break;
            case WorkspaceSnapEdge.top:
            case WorkspaceSnapEdge.centerY:
            case WorkspaceSnapEdge.bottom:
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
            case WorkspaceSnapEdge.top:
              top = candidate;
              break;
            case WorkspaceSnapEdge.centerY:
              top = candidate - (height / 2);
              break;
            case WorkspaceSnapEdge.bottom:
              top = candidate - height;
              break;
            case WorkspaceSnapEdge.left:
            case WorkspaceSnapEdge.centerX:
            case WorkspaceSnapEdge.right:
              break;
          }
        }
      }
    }

    final clamped = clampRect(
      rect: Rect.fromLTWH(left, top, width, height),
      panelSize: panelSize,
    );

    return GuideLinesResolvedRect(
      rect: clamped,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GuideLinesData(
        vertical: snappedGuideX,
        horizontal: snappedGuideY,
      )
          : null,
    );
  }

  GuideLinesResolvedRect _resolveResizeSnap({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final panelSize = state.panelSize;

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

    for (final item in state.items) {
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
      case ResizeHandle.right:
        snapX(false, false, true);
        break;
      case ResizeHandle.bottom:
        snapY(false, false, true);
        break;
      case ResizeHandle.bottomRight:
        snapX(false, false, true);
        snapY(false, false, true);
        break;
      case ResizeHandle.left:
        snapX(true, false, false);
        break;
      case ResizeHandle.top:
        snapY(true, false, false);
        break;
      case ResizeHandle.topLeft:
        snapX(true, false, false);
        snapY(true, false, false);
        break;
      case ResizeHandle.topRight:
        snapX(false, false, true);
        snapY(true, false, false);
        break;
      case ResizeHandle.bottomLeft:
        snapX(true, false, false);
        snapY(false, false, true);
        break;
    }

    final normalized = normalizeResizeRect(
      rect: Rect.fromLTRB(left, top, right, bottom),
      panelSize: panelSize,
    );

    return GuideLinesResolvedRect(
      rect: normalized,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GuideLinesData(
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

    final minW = WorkspaceData.minSize.width;
    final minH = WorkspaceData.minSize.height;

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
    final width = rect.width.clamp(
      WorkspaceData.minSize.width,
      math.max(WorkspaceData.minSize.width, panelSize.width),
    );
    final height = rect.height.clamp(
      WorkspaceData.minSize.height,
      math.max(WorkspaceData.minSize.height, panelSize.height),
    );

    final maxX = math.max(panelPadding, panelSize.width - width);
    final maxY = math.max(panelPadding, panelSize.height - height);

    return Rect.fromLTWH(
      rect.left.clamp(panelPadding, maxX).toDouble(),
      rect.top.clamp(panelPadding, maxY).toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
  }

  @override
  Future<void> close() async {
    _saveDebounce?.cancel();
    await _persistNow();
    return super.close();
  }
}