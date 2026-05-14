import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

@immutable
class ExpropriationData {
  static const Object _unset = Object();

  final String? id;
  final String contractId;

  final String registryNumber;
  final String registryOffice;
  final String propertyType;
  final String status;
  final String currentStage;
  final String useOfLand;

  final String address;
  final String city;
  final String state;

  final String roadId;
  final String roadName;
  final String segmentId;
  final double kmStart;
  final double kmEnd;
  final String laneSide;

  final double totalArea;
  final double affectedArea;
  final double remainingArea;

  final bool hasImprovements;
  final String improvementsSummary;

  final double latitude;
  final double longitude;

  final List<Attachment> attachments;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const ExpropriationData({
    this.id,
    required this.contractId,
    this.registryNumber = '',
    this.registryOffice = '',
    this.propertyType = '',
    this.status = '',
    this.currentStage = '',
    this.useOfLand = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.roadId = '',
    this.roadName = '',
    this.segmentId = '',
    this.kmStart = 0,
    this.kmEnd = 0,
    this.laneSide = '',
    this.totalArea = 0,
    this.affectedArea = 0,
    this.remainingArea = 0,
    this.hasImprovements = false,
    this.improvementsSummary = '',
    this.latitude = 0,
    this.longitude = 0,
    this.attachments = const [],
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory ExpropriationData.empty({
    required String contractId,
    String? id,
  }) {
    return ExpropriationData(
      id: id,
      contractId: contractId,
    );
  }

  factory ExpropriationData.fromMap(
      Map<String, dynamic> map, {
        required String id,
        required String contractId,
      }) {
    return ExpropriationData(
      id: id,
      contractId: contractId,
      registryNumber: _readString(map['registryNumber']),
      registryOffice: _readString(map['registryOffice']),
      propertyType: _readString(map['propertyType']),
      status: _readString(map['status']),
      currentStage: _readString(map['currentStage']),
      useOfLand: _readString(map['useOfLand']),
      address: _readString(map['address']),
      city: _readString(map['city']),
      state: _readString(map['state']),
      roadId: _readString(map['roadId']),
      roadName: _readString(map['roadName']),
      segmentId: _readString(map['segmentId']),
      kmStart: _readDouble(map['kmStart']),
      kmEnd: _readDouble(map['kmEnd']),
      laneSide: _readString(map['laneSide']),
      totalArea: _readDouble(map['totalArea']),
      affectedArea: _readDouble(map['affectedArea']),
      remainingArea: _readDouble(map['remainingArea']),
      hasImprovements: _readBool(map['hasImprovements']),
      improvementsSummary: _readString(map['improvementsSummary']),
      latitude: _readDouble(map['latitude']),
      longitude: _readDouble(map['longitude']),
      attachments: _readAttachments(map['attachments']),
      createdAt: _readDate(map['createdAt']),
      createdBy: _readNullableString(map['createdBy']),
      updatedAt: _readDate(map['updatedAt']),
      updatedBy: _readNullableString(map['updatedBy']),
    );
  }

  static List<Attachment> _readAttachments(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (item) => Attachment.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList(growable: false);
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static double _readDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty) return 0;

    return double.tryParse(
      text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim(),
    ) ??
        0;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'sim' ||
          normalized == 'yes';
    }

    return false;
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toMap() {
    return {
      'contractId': contractId.trim(),
      'registryNumber': registryNumber.trim(),
      'registryOffice': registryOffice.trim(),
      'propertyType': propertyType.trim(),
      'status': status.trim(),
      'currentStage': currentStage.trim(),
      'useOfLand': useOfLand.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'roadId': roadId.trim(),
      'roadName': roadName.trim(),
      'segmentId': segmentId.trim(),
      'kmStart': kmStart,
      'kmEnd': kmEnd,
      'laneSide': laneSide.trim(),
      'totalArea': totalArea,
      'affectedArea': affectedArea,
      'remainingArea': remainingArea,
      'hasImprovements': hasImprovements,
      'improvementsSummary': improvementsSummary.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'attachments': attachments.map((item) => item.toMap()).toList(),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };
  }

  ExpropriationData copyWith({
    Object? id = _unset,
    String? contractId,
    String? registryNumber,
    String? registryOffice,
    String? propertyType,
    String? status,
    String? currentStage,
    String? useOfLand,
    String? address,
    String? city,
    String? state,
    String? roadId,
    String? roadName,
    String? segmentId,
    double? kmStart,
    double? kmEnd,
    String? laneSide,
    double? totalArea,
    double? affectedArea,
    double? remainingArea,
    bool? hasImprovements,
    String? improvementsSummary,
    double? latitude,
    double? longitude,
    List<Attachment>? attachments,
    Object? createdAt = _unset,
    Object? createdBy = _unset,
    Object? updatedAt = _unset,
    Object? updatedBy = _unset,
  }) {
    return ExpropriationData(
      id: identical(id, _unset) ? this.id : id as String?,
      contractId: contractId ?? this.contractId,
      registryNumber: registryNumber ?? this.registryNumber,
      registryOffice: registryOffice ?? this.registryOffice,
      propertyType: propertyType ?? this.propertyType,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      useOfLand: useOfLand ?? this.useOfLand,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      roadId: roadId ?? this.roadId,
      roadName: roadName ?? this.roadName,
      segmentId: segmentId ?? this.segmentId,
      kmStart: kmStart ?? this.kmStart,
      kmEnd: kmEnd ?? this.kmEnd,
      laneSide: laneSide ?? this.laneSide,
      totalArea: totalArea ?? this.totalArea,
      affectedArea: affectedArea ?? this.affectedArea,
      remainingArea: remainingArea ?? this.remainingArea,
      hasImprovements: hasImprovements ?? this.hasImprovements,
      improvementsSummary: improvementsSummary ?? this.improvementsSummary,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      attachments: attachments ?? this.attachments,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      createdBy: identical(createdBy, _unset)
          ? this.createdBy
          : createdBy as String?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      updatedBy: identical(updatedBy, _unset)
          ? this.updatedBy
          : updatedBy as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExpropriationData &&
            other.id == id &&
            other.contractId == contractId &&
            other.registryNumber == registryNumber &&
            other.registryOffice == registryOffice &&
            other.propertyType == propertyType &&
            other.status == status &&
            other.currentStage == currentStage &&
            other.useOfLand == useOfLand &&
            other.address == address &&
            other.city == city &&
            other.state == state &&
            other.roadId == roadId &&
            other.roadName == roadName &&
            other.segmentId == segmentId &&
            other.kmStart == kmStart &&
            other.kmEnd == kmEnd &&
            other.laneSide == laneSide &&
            other.totalArea == totalArea &&
            other.affectedArea == affectedArea &&
            other.remainingArea == remainingArea &&
            other.hasImprovements == hasImprovements &&
            other.improvementsSummary == improvementsSummary &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            listEquals(other.attachments, attachments) &&
            other.createdAt == createdAt &&
            other.createdBy == createdBy &&
            other.updatedAt == updatedAt &&
            other.updatedBy == updatedBy);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      contractId,
      registryNumber,
      registryOffice,
      propertyType,
      status,
      currentStage,
      useOfLand,
      address,
      city,
      state,
      roadId,
      roadName,
      segmentId,
      kmStart,
      kmEnd,
      laneSide,
      totalArea,
      affectedArea,
      remainingArea,
      hasImprovements,
      improvementsSummary,
      latitude,
      longitude,
      Object.hashAll(attachments),
      createdAt,
      createdBy,
      updatedAt,
      updatedBy,
    ]);
  }
}