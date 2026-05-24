// lib/_widgets/images/gallery/photo_gallery_repository.dart

import 'photo_gallery_data.dart';

class PhotoGalleryRepository {
  const PhotoGalleryRepository();

  Future<List<PhotoGalleryData>> getPhotos() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const <PhotoGalleryData>[
      PhotoGalleryData(
        id: 'photo_001',
        url: 'https://picsum.photos/id/1011/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_002',
        url: 'https://picsum.photos/id/1015/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_003',
        url: 'https://picsum.photos/id/1036/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_004',
        url: 'https://picsum.photos/id/1043/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_005',
        url: 'https://picsum.photos/id/1056/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_006',
        url: 'https://picsum.photos/id/1067/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_007',
        url: 'https://picsum.photos/id/1074/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_008',
        url: 'https://picsum.photos/id/1084/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_009',
        url: 'https://picsum.photos/id/1080/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_010',
        url: 'https://picsum.photos/id/1081/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_011',
        url: 'https://picsum.photos/id/1082/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_012',
        url: 'https://picsum.photos/id/1083/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_013',
        url: 'https://picsum.photos/id/1025/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_014',
        url: 'https://picsum.photos/id/1039/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_015',
        url: 'https://picsum.photos/id/1044/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_016',
        url: 'https://picsum.photos/id/1050/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_017',
        url: 'https://picsum.photos/id/1060/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_018',
        url: 'https://picsum.photos/id/1069/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_019',
        url: 'https://picsum.photos/id/1076/1400/1400',
      ),
      PhotoGalleryData(
        id: 'photo_020',
        url: 'https://picsum.photos/id/1082/1400/1400',
      ),
    ];
  }
}