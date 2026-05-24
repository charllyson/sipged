import 'package:flutter_bloc/flutter_bloc.dart';

import 'photo_gallery_data.dart';
import 'photo_gallery_repository.dart';
import 'photo_gallery_state.dart';

class PhotoGalleryCubit extends Cubit<PhotoGalleryState> {
  PhotoGalleryCubit({
    required PhotoGalleryRepository repository,
  })  : _repository = repository,
        super(PhotoGalleryState.initial());

  final PhotoGalleryRepository _repository;

  Future<void> loadPhotos() async {
    emit(
      state.copyWith(
        status: PhotoGalleryStatus.loading,
        clearError: true,
      ),
    );

    try {
      final photos = await _repository.getPhotos();

      emit(
        state.copyWith(
          status: PhotoGalleryStatus.success,
          photos: photos,
          groupOrder: _sanitizeGroupOrder(
            currentOrder: state.groupOrder,
            photos: photos,
          ),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PhotoGalleryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> reloadPhotos() async {
    try {
      final photos = await _repository.getPhotos();
      final availableIds = photos.map((photo) => photo.id).toSet();

      final selectedPhotoIds = state.selectedPhotoIds.where((id) {
        return availableIds.contains(id);
      }).toList();

      emit(
        state.copyWith(
          status: PhotoGalleryStatus.success,
          photos: photos,
          selectedPhotoIds: selectedPhotoIds,
          selectionMode: selectedPhotoIds.isNotEmpty && state.selectionMode,
          groupOrder: _sanitizeGroupOrder(
            currentOrder: state.groupOrder,
            photos: photos,
          ),
          dragSelecting: false,
          clearDragSelectionAction: true,
          dragVisitedPhotoIds: const <String>[],
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PhotoGalleryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void setThumbnailSize(double value) {
    emit(
      state.copyWith(
        thumbnailSize: value,
      ),
    );
  }

  void setClassificationDraft(String value) {
    emit(
      state.copyWith(
        classificationDraft: value,
      ),
    );
  }

  void applyClassificationToSelectedPhotos() {
    final groupName = state.classificationDraft.trim();

    if (groupName.isEmpty || state.selectedPhotoIds.isEmpty) {
      return;
    }

    final selectedIds = state.selectedPhotoIdsSet;

    final updatedPhotos = state.photos.map((photo) {
      if (!selectedIds.contains(photo.id)) {
        return photo;
      }

      return photo.copyWith(
        groupName: groupName,
      );
    }).toList();

    final updatedOrder = _ensureGroupInOrder(
      groupName: groupName,
      currentOrder: state.groupOrder,
      photos: updatedPhotos,
    );

    emit(
      state.copyWith(
        photos: updatedPhotos,
        groupOrder: updatedOrder,
        selectedPhotoIds: const <String>[],
        selectionMode: false,
        classificationDraft: '',
        dragSelecting: false,
        clearDragSelectionAction: true,
        dragVisitedPhotoIds: const <String>[],
      ),
    );
  }

  void clearClassificationFromSelectedPhotos() {
    if (state.selectedPhotoIds.isEmpty) {
      return;
    }

    final selectedIds = state.selectedPhotoIdsSet;

    final updatedPhotos = state.photos.map((photo) {
      if (!selectedIds.contains(photo.id)) {
        return photo;
      }

      return photo.copyWith(
        clearGroupName: true,
      );
    }).toList();

    emit(
      state.copyWith(
        photos: updatedPhotos,
        groupOrder: _sanitizeGroupOrder(
          currentOrder: state.groupOrder,
          photos: updatedPhotos,
        ),
        selectedPhotoIds: const <String>[],
        selectionMode: false,
        classificationDraft: '',
        dragSelecting: false,
        clearDragSelectionAction: true,
        dragVisitedPhotoIds: const <String>[],
      ),
    );
  }

  void reorderGroupToIndex({
    required String draggedGroupId,
    required int targetIndex,
  }) {
    final dragged = draggedGroupId.trim();

    if (dragged.isEmpty) {
      return;
    }

    final order = state.classifiedGroupNames;
    final draggedIndex = order.indexOf(dragged);

    if (draggedIndex < 0) {
      return;
    }

    order.removeAt(draggedIndex);

    var adjustedTargetIndex = targetIndex;

    if (draggedIndex < targetIndex) {
      adjustedTargetIndex = targetIndex - 1;
    }

    final safeIndex = adjustedTargetIndex.clamp(0, order.length);

    order.insert(safeIndex, dragged);

    emit(
      state.copyWith(
        groupOrder: order,
      ),
    );
  }

  void moveGroupToEnd({
    required String draggedGroupId,
  }) {
    final dragged = draggedGroupId.trim();

    if (dragged.isEmpty) {
      return;
    }

    final order = state.classifiedGroupNames;

    if (!order.contains(dragged)) {
      return;
    }

    order.remove(dragged);
    order.add(dragged);

    emit(
      state.copyWith(
        groupOrder: order,
      ),
    );
  }

  void toggleSelectionMode() {
    if (state.selectionMode) {
      emit(
        state.copyWith(
          selectionMode: false,
          selectedPhotoIds: const <String>[],
          classificationDraft: '',
          dragSelecting: false,
          clearDragSelectionAction: true,
          dragVisitedPhotoIds: const <String>[],
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        selectionMode: true,
        dragSelecting: false,
        clearDragSelectionAction: true,
        dragVisitedPhotoIds: const <String>[],
      ),
    );
  }

  void enableSelectionWithPhoto(PhotoGalleryData photo) {
    final selectedIds = state.selectedPhotoIdsSet;
    selectedIds.add(photo.id);

    emit(
      state.copyWith(
        selectionMode: true,
        selectedPhotoIds: _sortPhotoIdsByCurrentOrder(selectedIds),
        dragSelecting: false,
        clearDragSelectionAction: true,
        dragVisitedPhotoIds: const <String>[],
      ),
    );
  }

  void togglePhotoSelection(PhotoGalleryData photo) {
    if (!state.selectionMode) return;

    final selectedIds = state.selectedPhotoIdsSet;

    if (selectedIds.contains(photo.id)) {
      selectedIds.remove(photo.id);
    } else {
      selectedIds.add(photo.id);
    }

    emit(
      state.copyWith(
        selectedPhotoIds: _sortPhotoIdsByCurrentOrder(selectedIds),
      ),
    );
  }

  void startDragSelection(PhotoGalleryData? photo) {
    if (!state.selectionMode || photo == null) return;

    final alreadySelected = state.selectedPhotoIdsSet.contains(photo.id);

    final action = alreadySelected
        ? PhotoGalleryDragAction.unselect
        : PhotoGalleryDragAction.select;

    emit(
      state.copyWith(
        dragSelecting: true,
        dragSelectionAction: action,
        dragVisitedPhotoIds: const <String>[],
      ),
    );

    applyDragSelectionToPhoto(photo);
  }

  void updateDragSelection(PhotoGalleryData? photo) {
    if (!state.selectionMode || !state.dragSelecting || photo == null) {
      return;
    }

    applyDragSelectionToPhoto(photo);
  }

  void endDragSelection() {
    if (!state.dragSelecting) return;

    emit(
      state.copyWith(
        dragSelecting: false,
        clearDragSelectionAction: true,
        dragVisitedPhotoIds: const <String>[],
      ),
    );
  }

  void applyDragSelectionToPhoto(PhotoGalleryData photo) {
    if (!state.selectionMode) return;

    final action = state.dragSelectionAction;

    if (action == null) return;

    final visitedIds = state.dragVisitedPhotoIdsSet;

    if (visitedIds.contains(photo.id)) {
      return;
    }

    final selectedIds = state.selectedPhotoIdsSet;

    switch (action) {
      case PhotoGalleryDragAction.select:
        selectedIds.add(photo.id);
        break;

      case PhotoGalleryDragAction.unselect:
        selectedIds.remove(photo.id);
        break;
    }

    visitedIds.add(photo.id);

    emit(
      state.copyWith(
        selectedPhotoIds: _sortPhotoIdsByCurrentOrder(selectedIds),
        dragVisitedPhotoIds: _sortPhotoIdsByCurrentOrder(visitedIds),
      ),
    );
  }

  List<String> _sortPhotoIdsByCurrentOrder(Set<String> ids) {
    final sorted = <String>[];

    for (final photo in state.photos) {
      if (ids.contains(photo.id)) {
        sorted.add(photo.id);
      }
    }

    return sorted;
  }

  List<String> _sanitizeGroupOrder({
    required List<String> currentOrder,
    required List<PhotoGalleryData> photos,
  }) {
    final existingGroups = photos
        .map((photo) => photo.cleanGroupName)
        .where((name) => name.isNotEmpty)
        .toSet();

    final result = <String>[];

    for (final groupName in currentOrder) {
      if (existingGroups.contains(groupName) && !result.contains(groupName)) {
        result.add(groupName);
      }
    }

    final missingGroups = existingGroups.where((groupName) {
      return !result.contains(groupName);
    }).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    result.addAll(missingGroups);

    return result;
  }

  List<String> _ensureGroupInOrder({
    required String groupName,
    required List<String> currentOrder,
    required List<PhotoGalleryData> photos,
  }) {
    final result = _sanitizeGroupOrder(
      currentOrder: currentOrder,
      photos: photos,
    );

    if (!result.contains(groupName)) {
      result.add(groupName);
    }

    return result;
  }
}