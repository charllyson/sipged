// lib/screens/modules/operation/schedule/common/modal/schedule_modal_photo.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/carousel_photo.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/photo_picker_square.dart';

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
  });

  final bool isMulti;
  final bool picking;
  final bool saving;

  final String? currentUserId;

  /// URLs já salvas no Firestore/Storage.
  final List<String> existingUrls;

  /// Metadados antigos vindos do documento da célula.
  final Map<String, Map<String, dynamic>> existingMetaByUrl;

  /// Fotos novas em memória.
  final List<PhotoData> newPhotos;

  /// Callback para adicionar uma nova foto já convertida para PhotoData.
  final Future<void> Function(PhotoData photo)? onAddNewPhoto;

  /// Callback para adicionar várias fotos já convertidas para PhotoData.
  final Future<void> Function(List<PhotoData> photos)? onAddNewPhotos;

  /// Picker múltiplo usado no Web antigo.
  final Future<void> Function()? onPickPhotos;

  final void Function(int index)? onRemoveNew;
  final void Function(int index)? onRemoveExisting;

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
        onPickFromCamera: onAddNewPhoto == null
            ? null
            : (photo) => onAddNewPhoto!(photo),
        onPickFromGallery: onAddNewPhoto == null
            ? null
            : (photo) => onAddNewPhoto!(photo),
        onPickMultipleFromGallery: (onAddNewPhotos == null &&
            onAddNewPhoto == null)
            ? null
            : (photos) async {
          if (onAddNewPhotos != null) {
            await onAddNewPhotos!(photos);
            return;
          }

          for (final photo in photos) {
            await onAddNewPhoto!(photo);
          }
        },
        onTap: kIsWeb && onPickPhotos != null ? onPickPhotos : null,
      ),
      photos: allPhotos,
      carouselId: 'schedule_modal_photos',
      title: 'Fotos da execução',
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
      theme: const CarouselPhotoTheme(
        itemSize: 96,
        spacing: 8,
      ),
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