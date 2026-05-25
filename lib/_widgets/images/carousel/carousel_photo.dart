import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/carousel_photo_thumb.dart';
import 'package:sipged/_widgets/images/carousel/models/carousel_data.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/photo_gallery_dialog.dart';

class CarouselPhoto extends StatelessWidget {
  final Widget? leading;
  final CarouselData carousel;
  final void Function(int index)? onRemove;
  final void Function(BuildContext context, int index, PhotoData photo)? onTapPhoto;
  final CarouselPhotoTheme theme;

  const CarouselPhoto({
    super.key,
    this.leading,
    required this.carousel,
    this.onRemove,
    this.onTapPhoto,
    this.theme = const CarouselPhotoTheme(),
  });

  factory CarouselPhoto.fromPhotos({
    Key? key,
    Widget? leading,
    required List<PhotoData> photos,
    String carouselId = 'carousel',
    String? title,
    void Function(int index)? onRemove,
    void Function(BuildContext context, int index, PhotoData photo)? onTapPhoto,
    CarouselPhotoTheme theme = const CarouselPhotoTheme(),
  }) {
    return CarouselPhoto(
      key: key,
      leading: leading,
      carousel: CarouselData(
        id: carouselId,
        title: title,
        photos: photos,
      ),
      onRemove: onRemove,
      onTapPhoto: onTapPhoto,
      theme: theme,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLeading = leading != null;
    final total = (hasLeading ? 1 : 0) + carousel.photos.length;

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

          final index = hasLeading ? globalIndex - 1 : globalIndex;

          if (index < 0 || index >= carousel.photos.length) {
            return const SizedBox.shrink();
          }

          final photo = carousel.photos[index];

          Future<void> defaultTap() {
            return showPhotoGalleryDialog(
              context,
              photos: carousel.photos,
              initialIndex: index,
            );
          }

          return CarouselPhotoThumb(
            photo: photo,
            theme: theme,
            onTap: onTapPhoto == null
                ? defaultTap
                : () => onTapPhoto!(context, index, photo),
            onRemove: onRemove == null ? null : () => onRemove!(index),
          );
        },
      ),
    );
  }
}