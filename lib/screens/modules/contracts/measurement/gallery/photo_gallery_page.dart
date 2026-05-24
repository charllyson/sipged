import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/images/gallery/photo_gallery_cubit.dart';
import 'package:sipged/_widgets/images/gallery/photo_gallery_data.dart';
import 'package:sipged/_widgets/images/gallery/photo_gallery_repository.dart';
import 'package:sipged/_widgets/images/gallery/photo_gallery_state.dart';
import 'package:sipged/_widgets/images/gallery/photo_gallery.dart';

class PhotoGalleryPage extends StatelessWidget {
  const PhotoGalleryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhotoGalleryCubit>(
      create: (_) => PhotoGalleryCubit(
        repository: const PhotoGalleryRepository(),
      )..loadPhotos(),
      child: const _ContractPhotoGalleryView(),
    );
  }
}

class _ContractPhotoGalleryView extends StatefulWidget {
  const _ContractPhotoGalleryView();

  @override
  State<_ContractPhotoGalleryView> createState() =>
      _ContractPhotoGalleryViewState();
}

class _ContractPhotoGalleryViewState extends State<_ContractPhotoGalleryView> {
  final Map<String, GlobalKey> _tileKeys = <String, GlobalKey>{};

  Future<void> _reloadPhotos(BuildContext context) async {
    await context.read<PhotoGalleryCubit>().reloadPhotos();
  }

  void _syncTileKeys(List<PhotoGalleryData> photos) {
    final availableIds = photos.map((photo) => photo.id).toSet();

    _tileKeys.removeWhere((id, _) {
      return !availableIds.contains(id);
    });

    for (final photo in photos) {
      _tileKeys.putIfAbsent(
        photo.id,
            () => GlobalKey(debugLabel: 'photo_tile_${photo.id}'),
      );
    }
  }

  PhotoGalleryData? _photoAtGlobalPosition({
    required Offset globalPosition,
    required List<PhotoGalleryData> photos,
  }) {
    for (final photo in photos) {
      final key = _tileKeys[photo.id];
      final context = key?.currentContext;

      if (context == null) {
        continue;
      }

      final renderObject = context.findRenderObject();

      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }

      final localPosition = renderObject.globalToLocal(globalPosition);
      final bounds = Offset.zero & renderObject.size;

      if (bounds.contains(localPosition)) {
        return photo;
      }
    }

    return null;
  }

  void _openPreview({
    required BuildContext context,
    required List<PhotoGalleryData> photos,
    required int index,
  }) {
    final photo = photos[index];

    debugPrint(
      '[ContractPhotoGalleryPage] Foto aberta: ${photo.id}',
    );

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: SipGedPhotoPreviewPage(
              photos: photos,
              initialIndex: index,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhotoGalleryCubit, PhotoGalleryState>(
      listenWhen: (previous, current) {
        return previous.selectedPhotoIds != current.selectedPhotoIds;
      },
      listener: (context, state) {
        debugPrint(
          '[ContractPhotoGalleryPage] Selecionadas: ${state.selectedCount}',
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<PhotoGalleryCubit,
              PhotoGalleryState>(
            builder: (context, state) {
              if (state.isLoading || state.isInitial) {
                return const _GalleryLoadingState();
              }

              if (state.isFailure) {
                return _GalleryErrorState(
                  message: state.errorMessage ?? 'Erro ao carregar a galeria.',
                  onRetry: () => _reloadPhotos(context),
                );
              }

              _syncTileKeys(state.photos);

              return RefreshIndicator(
                onRefresh: () => _reloadPhotos(context),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    final cubit = context.read<PhotoGalleryCubit>();

                    final photo = _photoAtGlobalPosition(
                      globalPosition: event.position,
                      photos: state.photos,
                    );

                    cubit.startDragSelection(photo);
                  },
                  onPointerMove: (event) {
                    final cubit = context.read<PhotoGalleryCubit>();

                    final photo = _photoAtGlobalPosition(
                      globalPosition: event.position,
                      photos: state.photos,
                    );

                    cubit.updateDragSelection(photo);
                  },
                  onPointerUp: (_) {
                    context.read<PhotoGalleryCubit>().endDragSelection();
                  },
                  onPointerCancel: (_) {
                    context.read<PhotoGalleryCubit>().endDragSelection();
                  },
                  child: PhotoGallery(
                    groups: state.groups,
                    tileKeys: _tileKeys,
                    thumbnailSize: state.thumbnailSize,
                    selectionMode: state.selectionMode,
                    selectedPhotoIds: state.selectedPhotoIds,
                    classificationDraft: state.classificationDraft,
                    canApplyClassification: state.canApplyClassification,
                    minThumbnailSize: 72,
                    maxThumbnailSize: 230,
                    spacing: 2,
                    padding: const EdgeInsets.all(2),
                    onClassificationChanged: (value) {
                      context
                          .read<PhotoGalleryCubit>()
                          .setClassificationDraft(value);
                    },
                    onApplyClassification: () {
                      context
                          .read<PhotoGalleryCubit>()
                          .applyClassificationToSelectedPhotos();
                    },
                    onClearClassification: () {
                      context
                          .read<PhotoGalleryCubit>()
                          .clearClassificationFromSelectedPhotos();
                    },
                    onSelectionModeTap: () {
                      context
                          .read<PhotoGalleryCubit>()
                          .toggleSelectionMode();
                    },
                    onThumbnailSizeChanged: (value) {
                      context
                          .read<PhotoGalleryCubit>()
                          .setThumbnailSize(value);
                    },
                    onPhotoTap: (photo) {
                      final allPhotos = state.photos;
                      final index = allPhotos.indexWhere((item) {
                        return item.id == photo.id;
                      });

                      if (index < 0) return;

                      _openPreview(
                        context: context,
                        photos: allPhotos,
                        index: index,
                      );
                    },
                    onReorderGroupToIndex: ({
                      required String draggedGroupId,
                      required int targetIndex,
                    }) {
                      context
                          .read<PhotoGalleryCubit>()
                          .reorderGroupToIndex(
                        draggedGroupId: draggedGroupId,
                        targetIndex: targetIndex,
                      );
                    },
                    onMoveGroupToEnd: (groupId) {
                      context.read<PhotoGalleryCubit>().moveGroupToEnd(
                        draggedGroupId: groupId,
                      );
                    },
                    onPhotoSelectionTap: (photo) {
                      context
                          .read<PhotoGalleryCubit>()
                          .togglePhotoSelection(photo);
                    },
                    onPhotoLongPress: (photo) {
                      context
                          .read<PhotoGalleryCubit>()
                          .enableSelectionWithPhoto(photo);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _GalleryErrorState extends StatelessWidget {
  const _GalleryErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 360,
        ),
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}