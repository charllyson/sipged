// lib/_widgets/modals/parts/schedule_photo_section.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/carousel/photo_carousel.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_photo_theme.dart';
import 'package:siged/_widgets/carousel/photo_picker_square.dart';
import 'package:siged/_widgets/modals/schedule_modal_controller.dart';

class SchedulePhotoSection extends StatelessWidget {
  const SchedulePhotoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();

    // Seleção múltipla: não permite anexar/editar fotos
    if (c.isMulti) {
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

    // Unitário: mantém carrossel + picker
    return PhotoCarousel.fromSeparated(
      leading: PhotoPickerSquare(
        enabled: !(c.picking || c.saving),
        onPickFromCamera: (bytes) async =>
            c.addNewPhotoBytes(bytes, suggestedName: 'camera.jpg'),
        onPickFromGallery: (bytes) async =>
            c.addNewPhotoBytes(bytes, suggestedName: 'gallery.jpg'),
        onTap: kIsWeb ? c.pickPhotos : null,
      ),
      existingUrls: c.existingUrls,
      existingMetaByUrl: c.existingMetaByUrl,
      newPhotos: c.newPhotos,
      newMetas: c.newMetas,
      onRemoveNew: (c.picking || c.saving) ? null : c.removeNewAt,
      onRemoveExisting: (c.picking || c.saving) ? null : c.removeExistingAt,
      theme: const CarouselPhotoTheme(itemSize: 96, spacing: 8),
    );
  }
}
