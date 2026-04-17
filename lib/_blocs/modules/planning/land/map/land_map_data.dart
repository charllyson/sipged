import 'package:flutter/foundation.dart';

@immutable
class LandMapData {
  final String propertyId;
  final String title;
  final String ownerName;
  final String city;
  final String status;
  final double latitude;
  final double longitude;
  final String roadName;
  final double kmStart;
  final double kmEnd;

  const LandMapData({
    required this.propertyId,
    this.title = '',
    this.ownerName = '',
    this.city = '',
    this.status = '',
    this.latitude = 0,
    this.longitude = 0,
    this.roadName = '',
    this.kmStart = 0,
    this.kmEnd = 0,
  });

  LandMapData copyWith({
    String? propertyId,
    String? title,
    String? ownerName,
    String? city,
    String? status,
    double? latitude,
    double? longitude,
    String? roadName,
    double? kmStart,
    double? kmEnd,
  }) {
    return LandMapData(
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      ownerName: ownerName ?? this.ownerName,
      city: city ?? this.city,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      roadName: roadName ?? this.roadName,
      kmStart: kmStart ?? this.kmStart,
      kmEnd: kmEnd ?? this.kmEnd,
    );
  }
}