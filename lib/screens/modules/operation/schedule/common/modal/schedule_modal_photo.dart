// lib/screens/modules/operation/schedule/common/modal/schedule_modal_photo.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/adapters/image_adapter_loader.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/photo_gallery_dialog.dart';
import 'package:sipged/_widgets/images/carousel/photo_picker_square.dart';
import 'package:sipged/_widgets/images/carousel/photo_preview_page.dart';

class ScheduleModalPhoto extends StatelessWidget {
  const ScheduleModalPhoto({
    super.key,
    required this.isMulti,
    required this.picking,
    required this.saving,
    required this.existingUrls,
    required this.existingMetaByUrl,
    required this.newPhotos,
    this.currentUserId,
    this.onAddNewPhoto,
    this.onAddNewPhotos,
    this.onPickPhotos,
    this.onRemoveNew,
    this.onRemoveExisting,
    this.onEditNewPhoto,
  });

  final bool isMulti;
  final bool picking;
  final bool saving;

  final String? currentUserId;

  final List<String> existingUrls;
  final Map<String, Map<String, dynamic>> existingMetaByUrl;
  final List<PhotoData> newPhotos;

  final Future<void> Function(PhotoData photo)? onAddNewPhoto;
  final Future<void> Function(List<PhotoData> photos)? onAddNewPhotos;
  final Future<void> Function()? onPickPhotos;

  final void Function(int index)? onRemoveNew;
  final void Function(int index)? onRemoveExisting;

  final Future<void> Function(int index, PhotoData photo)? onEditNewPhoto;

  static const CarouselPhotoTheme _theme = CarouselPhotoTheme(
    itemSize: 96,
    spacing: 8,
  );

  @override
  Widget build(BuildContext context) {
    if (isMulti) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            'Em seleção múltipla não é possível adicionar fotos. '
                'As fotos atuais de cada estaca/faixa serão preservadas.',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    final disabled = picking || saving;

    final existingPhotos = _buildExistingPhotos();

    final allPhotos = <PhotoData>[
      ...existingPhotos,
      ...newPhotos,
    ];

    return CarouselPhoto.fromPhotos(
      leading: PhotoPickerSquare(
        enabled: !disabled,
        uploadedBy: currentUserId,
        resolveAddressFromPhotoGps: true,
        captureLocationWhenCameraHasNoGps: true,
        imageQuality: 88,
        maxWidth: 1920,
        maxHeight: 1920,
        editorMaxScale: 5.0,
        editorExportQuality: 88,
        editorCircleCrop: false,
        editorAspectRatios: const <double>[
          1.0,
          4 / 3,
          3 / 2,
          16 / 9,
        ],
        onPickFromCamera: onAddNewPhoto == null
            ? null
            : (photo) async {
          await onAddNewPhoto!(photo);
        },
        onPickFromGallery: onAddNewPhoto == null
            ? null
            : (photo) async {
          await onAddNewPhoto!(photo);
        },
        onPickMultipleFromGallery:
        (onAddNewPhotos == null && onAddNewPhoto == null)
            ? null
            : (photos) async {
          if (photos.isEmpty) return;

          if (onAddNewPhotos != null) {
            await onAddNewPhotos!(photos);
            return;
          }

          final addOne = onAddNewPhoto;

          if (addOne == null) return;

          for (final photo in photos) {
            await addOne(photo);
          }
        },
        onTap: kIsWeb && onPickPhotos != null ? onPickPhotos : null,
      ),
      photos: allPhotos,
      carouselId: 'schedule_modal_photos',
      title: 'Fotos da execução',
      onTapPhoto: disabled
          ? null
          : (context, index, photo) async {
        final existingCount = existingPhotos.length;

        if (index < existingCount) {
          await showPhotoGalleryDialog(
            context,
            photos: existingPhotos,
            initialIndex: index,
          );
          return;
        }

        final newIndex = index - existingCount;

        if (newIndex < 0 || newIndex >= newPhotos.length) {
          return;
        }

        final edited = await _openPreviewFlow(
          context: context,
          photo: newPhotos[newIndex],
        );

        if (edited == null) return;

        await onEditNewPhoto?.call(newIndex, edited);
      },
      onRemove: disabled
          ? null
          : (index) {
        final existingCount = existingPhotos.length;

        if (index < existingCount) {
          onRemoveExisting?.call(index);
          return;
        }

        onRemoveNew?.call(index - existingCount);
      },
      theme: _theme,
    );
  }

  Future<PhotoData?> _openPreviewFlow({
    required BuildContext context,
    required PhotoData photo,
  }) async {
    Uint8List? sourceBytes = photo.bytes;

    if ((sourceBytes == null || sourceBytes.isEmpty) &&
        photo.bestFullUrl != null &&
        photo.bestFullUrl!.trim().isNotEmpty) {
      try {
        sourceBytes = await loadImageBytes(photo.bestFullUrl!.trim());
      } catch (e, s) {
        debugPrint('[ScheduleModalPhoto] Falha ao baixar foto para edição: $e');
        debugPrintStack(stackTrace: s);
        sourceBytes = null;
      }
    }

    if (sourceBytes == null || sourceBytes.isEmpty) {
      return null;
    }

    if (!context.mounted) return null;

    final finalBytes = await Navigator.of(context, rootNavigator: true)
        .push<Uint8List?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoPreviewPage(
          originalBytes: sourceBytes!,
          outputJpegQuality: 88,
          previewFit: BoxFit.contain,
          showOverlayInPreview: true,
          allowEditCrop: true,
          editorMaxScale: 5.0,
          editorAspectRatios: const <double>[
            1.0,
            4 / 3,
            3 / 2,
            16 / 9,
          ],
          stampDate: photo.takenAt,
          stampName: photo.name,
          stampLatitude: photo.lat,
          stampLongitude: photo.lng,
          stampDevice: _deviceLabel(photo),
          stampAddress: photo.address,
          stampCity: photo.city,
          stampState: photo.state,
        ),
      ),
    );

    if (finalBytes == null || finalBytes.isEmpty) {
      return null;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowMicros = DateTime.now().microsecondsSinceEpoch;

    return photo.copyWith(
      id: '${photo.id}_edited_$nowMicros',
      name: _editedName(photo.name, nowMs),
      bytes: finalBytes,
      clearUrl: true,
      clearThumbUrl: true,
      stamped: true,
      sizeBytes: finalBytes.length,
      uploadedAtMs: nowMs,
      uploadedBy: currentUserId ?? photo.uploadedBy,
    );
  }

  List<PhotoData> _buildExistingPhotos() {
    return existingUrls.map((url) {
      final meta = existingMetaByUrl[url];

      if (meta != null) {
        return PhotoData.fromMap({
          ...meta,
          'id': meta['id'] ?? url,
          'url': meta['url'] ?? url,
          'name': meta['name'] ?? _nameFromUrl(url),
        });
      }

      return PhotoData.fromUrl(
        id: url,
        name: _nameFromUrl(url),
        url: url,
      );
    }).toList(growable: false);
  }

  static String? _deviceLabel(PhotoData photo) {
    final parts = <String>[
      photo.make?.trim() ?? '',
      photo.model?.trim() ?? '',
    ].where((item) => item.isNotEmpty).toList(growable: false);

    if (parts.isEmpty) return null;

    return parts.join(' ');
  }

  static String _editedName(String originalName, int nowMs) {
    final clean = originalName.trim();

    if (clean.isEmpty) {
      return 'foto_editada_$nowMs.jpg';
    }

    final noQuery = clean.split('?').first;
    final lastSlash = noQuery.lastIndexOf('/');
    final fileName = lastSlash >= 0 ? noQuery.substring(lastSlash + 1) : noQuery;

    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;

    final safeBase = base
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (safeBase.isEmpty) {
      return 'foto_editada_$nowMs.jpg';
    }

    return '${safeBase}_editada_$nowMs.jpg';
  }

  static String _nameFromUrl(String url) {
    final clean = url.split('?').first.trim();

    if (clean.isEmpty) {
      return 'foto.jpg';
    }

    final parts = clean.split('/');

    if (parts.isEmpty || parts.last.trim().isEmpty) {
      return 'foto.jpg';
    }

    return parts.last.trim();
  }
}