import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';

class CarouselData {
  final String id;
  final String? title;
  final List<PhotoData> photos;
  final int? createdAtMs;
  final int? updatedAtMs;

  const CarouselData({
    required this.id,
    this.title,
    this.photos = const [],
    this.createdAtMs,
    this.updatedAtMs,
  });

  bool get isEmpty => photos.isEmpty;

  bool get isNotEmpty => photos.isNotEmpty;

  int get length => photos.length;

  CarouselData copyWith({
    String? id,
    String? title,
    List<PhotoData>? photos,
    int? createdAtMs,
    int? updatedAtMs,
    bool clearTitle = false,
    bool clearCreatedAtMs = false,
    bool clearUpdatedAtMs = false,
  }) {
    return CarouselData(
      id: id ?? this.id,
      title: clearTitle ? null : title ?? this.title,
      photos: photos ?? this.photos,
      createdAtMs: clearCreatedAtMs ? null : createdAtMs ?? this.createdAtMs,
      updatedAtMs: clearUpdatedAtMs ? null : updatedAtMs ?? this.updatedAtMs,
    );
  }

  CarouselData addPhoto(PhotoData photo) {
    return copyWith(
      photos: [...photos, photo],
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  CarouselData removeAt(int index) {
    if (index < 0 || index >= photos.length) return this;

    final next = [...photos]..removeAt(index);

    return copyWith(
      photos: next,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  CarouselData replacePhoto(int index, PhotoData photo) {
    if (index < 0 || index >= photos.length) return this;

    final next = [...photos];
    next[index] = photo;

    return copyWith(
      photos: next,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (title != null) 'title': title,
      'photos': photos.map((e) => e.toMap()).toList(),
      if (createdAtMs != null) 'createdAtMs': createdAtMs,
      if (updatedAtMs != null) 'updatedAtMs': updatedAtMs,
    };
  }

  static CarouselData fromMap(Map<String, dynamic> map) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final rawPhotos = map['photos'];

    return CarouselData(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: map['title']?.toString(),
      photos: rawPhotos is List
          ? rawPhotos
          .whereType<Map>()
          .map((e) => PhotoData.fromMap(Map<String, dynamic>.from(e)))
          .toList()
          : const [],
      createdAtMs: parseInt(map['createdAtMs']),
      updatedAtMs: parseInt(map['updatedAtMs']),
    );
  }
}