import 'package:flutter/material.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/images/carousel/carousel_photo.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/photo_gallery_dialog.dart';
import 'package:sipged/_widgets/images/carousel/photo_item.dart';
import 'package:sipged/_widgets/images/carousel/photo_thumb.dart';

class PhotoCarousel extends StatelessWidget {
  final Widget? leading;
  final List<PhotoItem> items;
  final void Function(int index)? onRemove;
  final void Function(BuildContext context, int index, PhotoItem item)? onTapItem;
  final CarouselPhotoTheme theme;

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
    final items = <PhotoItem>[
      ...existingUrls.map((u) => PhotoUrlItem(u, meta: existingMetaByUrl?[u])),
      ...List.generate(newPhotos.length, (i) {
        final p = newPhotos[i];
        final meta = (i < newMetas.length) ? newMetas[i] : null;
        return PhotoBytesItem.fromPicked(p, meta: meta);
      }),
    ];

    void Function(int)? onRemove;
    if (onRemoveExisting != null || onRemoveNew != null) {
      onRemove = (int idx) {
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
        separatorBuilder: (_, _) => SizedBox(width: theme.spacing),
        itemBuilder: (context, globalIndex) {
          if (hasLeading && globalIndex == 0) {
            return SizedBox(
              width: theme.itemSize,
              height: theme.itemSize,
              child: leading!,
            );
          }

          final idx = hasLeading ? globalIndex - 1 : globalIndex;
          if (idx < 0 || idx >= items.length) {
            return const SizedBox.shrink();
          }

          final item = items[idx];

          Future<void> defaultTap() {
            return showPhotoGalleryDialog(
              context,
              items: items,
              initialIndex: idx,
            );
          }

          return PhotoThumb(
            item: item,
            theme: theme,
            onTap: onTapItem == null
                ? defaultTap
                : () => onTapItem!(context, idx, item),
            onRemove: onRemove == null ? null : () => onRemove!(idx),
          );
        },
      ),
    );
  }
}