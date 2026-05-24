// lib/_widgets/images/gallery/photo_gallery_data.dart

class PhotoGalleryData {
  const PhotoGalleryData({
    required this.id,
    required this.url,
    this.groupName,
  });

  final String id;
  final String url;

  /// Nome visual do grupo/classificação.
  /// Ex: Terraplenagem, CBUQ de maio, Drenagem, Sinalização.
  final String? groupName;

  String get cleanGroupName {
    return groupName?.trim() ?? '';
  }

  bool get hasGroup {
    return cleanGroupName.isNotEmpty;
  }

  PhotoGalleryData copyWith({
    String? id,
    String? url,
    String? groupName,
    bool clearGroupName = false,
  }) {
    return PhotoGalleryData(
      id: id ?? this.id,
      url: url ?? this.url,
      groupName: clearGroupName ? null : groupName ?? this.groupName,
    );
  }

  factory PhotoGalleryData.fromMap(Map<String, dynamic> map) {
    return PhotoGalleryData(
      id: (map['id'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      groupName: map['groupName']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'groupName': groupName,
    };
  }
}

class SipGedGalleryPhotoGroup {
  const SipGedGalleryPhotoGroup({
    required this.id,
    required this.title,
    required this.photos,
    required this.classified,
  });

  final String id;
  final String title;
  final List<PhotoGalleryData> photos;
  final bool classified;

  int get count => photos.length;
}