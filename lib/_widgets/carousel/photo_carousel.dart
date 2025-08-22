// lib/_widgets/carousel/carousel.dart
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/carousel/photo_gallery_dialog.dart';
import 'package:sisged/_widgets/carousel/photo_item.dart';
import 'package:sisged/_widgets/carousel/photo_thumb.dart';
import 'package:sisged/_datas/widgets/pickedPhoto/carousel_photo_theme.dart';
import '../../_datas/widgets/pickedPhoto/carousel_metadata.dart' as pm;
import '../../_datas/widgets/pickedPhoto/carousel_photo.dart';

class PhotoCarousel extends StatelessWidget {
  /// Item extra à esquerda (ex.: botão "Adicionar foto")
  final Widget? leading;

  /// Itens existentes (URL) e/ou novos (bytes)
  final List<PhotoItem> items;

  /// Callback para remover um item (índice na lista `items`)
  final void Function(int index)? onRemove;

  /// Override da ação ao tocar (por item). Se não passar, abre a galeria.
  final void Function(BuildContext context, int index, PhotoItem item)? onTapItem;

  /// Tema/estilo
  final CarouselPhotoTheme theme;

  /// Helper para listas separadas (compat)
  factory PhotoCarousel.fromSeparated({
    Key? key,
    Widget? leading,
    List<String> existingUrls = const [],
    Map<String, pm.CarouselMetadata>? existingMetaByUrl,
    List<CarouselPhoto> newPhotos = const [],
    List<pm.CarouselMetadata> newMetas = const [],
    void Function(int index)? onRemoveExisting,
    void Function(int index)? onRemoveNew,
    CarouselPhotoTheme theme = const CarouselPhotoTheme(),
    void Function(BuildContext, int, PhotoItem)? onTapItem,
  }) {
    final List<PhotoItem> items = [
      ...existingUrls.map((u) => PhotoUrlItem(u, meta: existingMetaByUrl?[u])),
      ...List.generate(newPhotos.length, (i) {
        final p = newPhotos[i];
        final meta = i < newMetas.length ? newMetas[i] : null;
        return PhotoBytesItem.fromPicked(p, meta: meta);
      }),
    ];

    void Function(int)? onRemove;
    if (onRemoveExisting != null || onRemoveNew != null) {
      onRemove = (idx) {
        final existingCount = existingUrls.length;
        if (idx < existingCount) {
          onRemoveExisting?.call(idx);
        } else {
          onRemoveNew?.call(idx - existingCount);
        }
      };
    }

    return PhotoCarousel(
      key: key,
      leading: leading,
      items: items,
      onRemove: onRemove,
      onTapItem: onTapItem,
      theme: theme,
    );
  }

  const PhotoCarousel({
    super.key,
    this.leading,
    required this.items,
    this.onRemove,
    this.onTapItem,
    this.theme = const CarouselPhotoTheme(),
  });

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null;
    final total = (hasLeading ? 1 : 0) + items.length;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: theme.itemSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: theme.listPadding,
        itemCount: total,
        separatorBuilder: (_, __) => SizedBox(width: theme.spacing),
        itemBuilder: (context, globalIndex) {
          if (hasLeading && globalIndex == 0) {
            return SizedBox(width: theme.itemSize, height: theme.itemSize, child: leading!);
          }

          final idx = hasLeading ? globalIndex - 1 : globalIndex;
          final item = items[idx];

          Future<void> defaultTap() async {
            // Abre a GALERIA com setas e imagem "cover" (sem bordas pretas)
            await showPhotoGalleryDialog(
              context,
              items: items,
              initialIndex: idx,
            );
          }

          return PhotoThumb(
            item: item,
            theme: theme,
            onTap: onTapItem == null ? defaultTap : () => onTapItem!(context, idx, item),
            onRemove: onRemove == null ? null : () => onRemove!(idx),
          );
        },
      ),
    );
  }
}
