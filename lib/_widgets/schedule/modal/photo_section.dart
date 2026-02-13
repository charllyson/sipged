// lib/_widgets/schedule/modal/photo_section.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/photo_carousel.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/photo_picker_square.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/images/carousel/carousel_photo.dart';

class SchedulePhotoSection extends StatelessWidget {
  final bool isMulti;
  final bool picking;
  final bool saving;

  /// URLs já salvas
  final List<String> existingUrls;

  final Map<String, Map<String, dynamic>> existingMetaByUrl;

  /// Fotos novas em memória (bytes)
  final List<Uint8List> newPhotos;

  /// Metadados das fotos novas
  final List<pm.CarouselMetadata> newMetas;

  /// Callback para adicionar nova foto a partir de bytes
  final Future<void> Function(Uint8List bytes, String suggestedName)?
  onAddNewPhotoBytes;

  /// Abre picker genérico (web / múltiplas imagens)
  final Future<void> Function()? onPickPhotos;

  final void Function(int index)? onRemoveNew;
  final void Function(int index)? onRemoveExisting;

  const SchedulePhotoSection({
    super.key,
    required this.isMulti,
    required this.picking,
    required this.saving,
    required this.existingUrls,
    required this.existingMetaByUrl,
    required this.newPhotos,
    required this.newMetas,
    this.onAddNewPhotoBytes,
    this.onPickPhotos,
    this.onRemoveNew,
    this.onRemoveExisting,
  });

  @override
  Widget build(BuildContext context) {
    // Seleção múltipla: não permite anexar/editar fotos
    if (isMulti) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
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

    // ---------- CONVERSÕES PARA OS TIPOS DO CARROSSEL ----------

    // 1) Metadados: Map<String, Map<String,dynamic>>
    //    -> Map<String, CarouselMetadata>
    final Map<String, pm.CarouselMetadata> typedMetaByUrl = {
      for (final entry in existingMetaByUrl.entries)
        entry.key: pm.CarouselMetadata.fromMap(entry.value),
    };

    // 2) Fotos novas: List<Uint8List> -> List<CarouselPhoto>
    final List<CarouselPhoto> typedNewPhotos = [
      for (int i = 0; i < newPhotos.length; i++)
        CarouselPhoto(
          name: 'nova_foto_$i', // aqui é "name", não "fileName"
          bytes: newPhotos[i],
          meta: i < newMetas.length
              ? newMetas[i]
              : const pm.CarouselMetadata(),
        ),
    ];

    return PhotoCarousel.fromSeparated(
      leading: PhotoPickerSquare(
        enabled: !disabled,
        onPickFromCamera: onAddNewPhotoBytes == null
            ? null
            : (bytes) => onAddNewPhotoBytes!(bytes, 'camera.jpg'),
        onPickFromGallery: onAddNewPhotoBytes == null
            ? null
            : (bytes) => onAddNewPhotoBytes!(bytes, 'gallery.jpg'),
        onTap: kIsWeb && onPickPhotos != null ? onPickPhotos : null,
      ),
      existingUrls: existingUrls,
      existingMetaByUrl: typedMetaByUrl,
      newPhotos: typedNewPhotos,
      newMetas: newMetas,
      onRemoveNew: disabled ? null : onRemoveNew,
      onRemoveExisting: disabled ? null : onRemoveExisting,
      theme: const CarouselPhotoTheme(itemSize: 96, spacing: 8),
    );
  }
}
