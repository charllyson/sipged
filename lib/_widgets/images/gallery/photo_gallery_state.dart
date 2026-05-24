// lib/_widgets/images/gallery/photo_gallery_state.dart

import 'package:equatable/equatable.dart';

import 'photo_gallery_data.dart';

enum PhotoGalleryStatus {
  initial,
  loading,
  success,
  failure,
}

enum PhotoGalleryDragAction {
  select,
  unselect,
}

class PhotoGalleryState extends Equatable {
  const PhotoGalleryState({
    this.status = PhotoGalleryStatus.initial,
    this.photos = const <PhotoGalleryData>[],
    this.errorMessage,
    this.thumbnailSize = 118,
    this.selectionMode = false,
    this.selectedPhotoIds = const <String>[],
    this.dragSelecting = false,
    this.dragSelectionAction,
    this.dragVisitedPhotoIds = const <String>[],
    this.classificationDraft = '',
    this.groupOrder = const <String>[],
  });

  final PhotoGalleryStatus status;
  final List<PhotoGalleryData> photos;
  final String? errorMessage;

  final double thumbnailSize;

  final bool selectionMode;
  final List<String> selectedPhotoIds;

  final bool dragSelecting;
  final PhotoGalleryDragAction? dragSelectionAction;
  final List<String> dragVisitedPhotoIds;

  final String classificationDraft;

  /// Ordem manual dos grupos classificados.
  /// Guarda os nomes dos grupos.
  final List<String> groupOrder;

  bool get isInitial => status == PhotoGalleryStatus.initial;
  bool get isLoading => status == PhotoGalleryStatus.loading;
  bool get isSuccess => status == PhotoGalleryStatus.success;
  bool get isFailure => status == PhotoGalleryStatus.failure;

  Set<String> get selectedPhotoIdsSet => selectedPhotoIds.toSet();

  Set<String> get dragVisitedPhotoIdsSet => dragVisitedPhotoIds.toSet();

  int get selectedCount => selectedPhotoIds.length;

  bool get hasSelection => selectedPhotoIds.isNotEmpty;

  bool get canApplyClassification {
    return selectedPhotoIds.isNotEmpty && classificationDraft.trim().isNotEmpty;
  }

  List<PhotoGalleryData> get selectedPhotos {
    final selectedSet = selectedPhotoIdsSet;

    return photos.where((photo) {
      return selectedSet.contains(photo.id);
    }).toList();
  }

  List<SipGedGalleryPhotoGroup> get groups {
    final unclassifiedPhotos = <PhotoGalleryData>[];
    final grouped = <String, List<PhotoGalleryData>>{};

    for (final photo in photos) {
      final groupName = photo.cleanGroupName;

      if (groupName.isEmpty) {
        unclassifiedPhotos.add(photo);
        continue;
      }

      grouped.putIfAbsent(groupName, () => <PhotoGalleryData>[]);
      grouped[groupName]!.add(photo);
    }

    final result = <SipGedGalleryPhotoGroup>[];

    final existingGroupNames = grouped.keys.toSet();

    final orderedNames = <String>[];

    for (final name in groupOrder) {
      if (existingGroupNames.contains(name) && !orderedNames.contains(name)) {
        orderedNames.add(name);
      }
    }

    final unorderedNames = existingGroupNames.where((name) {
      return !orderedNames.contains(name);
    }).toList()
      ..sort((a, b) {
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    orderedNames.addAll(unorderedNames);

    for (final name in orderedNames) {
      result.add(
        SipGedGalleryPhotoGroup(
          id: name,
          title: name,
          photos: grouped[name] ?? const <PhotoGalleryData>[],
          classified: true,
        ),
      );
    }

    if (unclassifiedPhotos.isNotEmpty) {
      result.add(
        SipGedGalleryPhotoGroup(
          id: '__sem_grupo__',
          title: '',
          photos: unclassifiedPhotos,
          classified: false,
        ),
      );
    }

    return result;
  }

  List<String> get classifiedGroupNames {
    final names = <String>{};

    for (final photo in photos) {
      final groupName = photo.cleanGroupName;

      if (groupName.isNotEmpty) {
        names.add(groupName);
      }
    }

    final result = <String>[];

    for (final name in groupOrder) {
      if (names.contains(name) && !result.contains(name)) {
        result.add(name);
      }
    }

    final remaining = names.where((name) {
      return !result.contains(name);
    }).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    result.addAll(remaining);

    return result;
  }

  PhotoGalleryState copyWith({
    PhotoGalleryStatus? status,
    List<PhotoGalleryData>? photos,
    String? errorMessage,
    bool clearError = false,
    double? thumbnailSize,
    bool? selectionMode,
    List<String>? selectedPhotoIds,
    bool? dragSelecting,
    PhotoGalleryDragAction? dragSelectionAction,
    bool clearDragSelectionAction = false,
    List<String>? dragVisitedPhotoIds,
    String? classificationDraft,
    List<String>? groupOrder,
  }) {
    return PhotoGalleryState(
      status: status ?? this.status,
      photos: photos ?? this.photos,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      thumbnailSize: thumbnailSize ?? this.thumbnailSize,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedPhotoIds: selectedPhotoIds ?? this.selectedPhotoIds,
      dragSelecting: dragSelecting ?? this.dragSelecting,
      dragSelectionAction: clearDragSelectionAction
          ? null
          : dragSelectionAction ?? this.dragSelectionAction,
      dragVisitedPhotoIds: dragVisitedPhotoIds ?? this.dragVisitedPhotoIds,
      classificationDraft: classificationDraft ?? this.classificationDraft,
      groupOrder: groupOrder ?? this.groupOrder,
    );
  }

  factory PhotoGalleryState.initial() {
    return const PhotoGalleryState();
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    photos,
    errorMessage,
    thumbnailSize,
    selectionMode,
    selectedPhotoIds,
    dragSelecting,
    dragSelectionAction,
    dragVisitedPhotoIds,
    classificationDraft,
    groupOrder,
  ];
}