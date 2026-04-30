// lib/_blocs/modules/actives/oaes/active_oaes_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';

class ActiveOaesData {
  String? id;
  int? order;
  double? score;

  String? state;
  String? road;
  String? region;
  String? identificationName;

  double? extension;
  double? width;
  double? area;

  String? structureType;
  String? relatedContracts;
  double? valueIntervention;
  double? linearCostMedia;
  double? costEstimate;

  DateTime? lastDateIntervention;
  String? companyBuild;

  double? latitude;
  double? longitude;
  double? altitude;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  List<Attachment>? attachments;

  ActiveOaesData({
    this.id,
    this.order,
    this.score,
    this.state,
    this.road,
    this.region,
    this.identificationName,
    this.extension,
    this.width,
    this.area,
    this.structureType,
    this.relatedContracts,
    this.valueIntervention,
    this.linearCostMedia,
    this.costEstimate,
    this.lastDateIntervention,
    this.companyBuild,
    this.latitude,
    this.longitude,
    this.altitude,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.attachments,
  });

  // ===========================================================================
  // Helpers
  // ===========================================================================

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }

    final raw = snap.data();
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();

    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } catch (_) {
        return null;
      }
    }

    if (v is String) return DateTime.tryParse(v);

    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;

    if (v is List) {
      return v
          .where((e) => e != null)
          .map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      })
          .toList(growable: true);
    }

    return null;
  }

  // ===========================================================================
  // Factories
  // ===========================================================================

  factory ActiveOaesData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);

    return ActiveOaesData(
      id: snap.id,
      order: _toInt(data['order']),
      score: _toDouble(data['score']),
      state: data['state'] as String?,
      road: data['road'] as String?,
      region: data['region'] as String?,
      identificationName: data['identificationName'] as String?,
      extension: _toDouble(data['extension']),
      width: _toDouble(data['width']),
      area: _toDouble(data['area']),
      structureType: (data['structureType'] ?? data['estructureType']) as String?,
      relatedContracts: data['relatedContracts'] as String?,
      valueIntervention: _toDouble(data['valueIntervention']),
      linearCostMedia: _toDouble(data['linearCostMedia']),
      costEstimate: _toDouble(data['costEstimate']),
      lastDateIntervention: _toDate(data['lastDateIntervention']),
      companyBuild: data['companyBuild'] as String?,
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      altitude: _toDouble(data['altitude']),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      deletedAt: _toDate(data['deletedAt']),
      deletedBy: data['deletedBy'] as String?,
      attachments: _toAttachments(data['attachments']),
    );
  }

  factory ActiveOaesData.fromMap(Map<String, dynamic> map) {
    return ActiveOaesData(
      id: map['id'] as String?,
      order: _toInt(map['order']),
      score: _toDouble(map['score']),
      state: map['state'] as String?,
      road: map['road'] as String?,
      region: map['region'] as String?,
      identificationName: map['identificationName'] as String?,
      extension: _toDouble(map['extension']),
      width: _toDouble(map['width']),
      area: _toDouble(map['area']),
      structureType: (map['structureType'] ?? map['estructureType']) as String?,
      relatedContracts: map['relatedContracts'] as String?,
      valueIntervention: _toDouble(map['valueIntervention']),
      linearCostMedia: _toDouble(map['linearCostMedia']),
      costEstimate: _toDouble(map['costEstimate']),
      companyBuild: map['companyBuild'] as String?,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      altitude: _toDouble(map['altitude']),
      lastDateIntervention: _toDate(map['lastDateIntervention']),
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
      deletedAt: _toDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
      attachments: _toAttachments(map['attachments']),
    );
  }

  // ===========================================================================
  // Clone / copyWith
  // ===========================================================================

  ActiveOaesData.fromData(ActiveOaesData d) {
    id = d.id;
    order = d.order;
    score = d.score;
    state = d.state;
    road = d.road;
    region = d.region;
    identificationName = d.identificationName;
    extension = d.extension;
    width = d.width;
    area = d.area;
    structureType = d.structureType;
    relatedContracts = d.relatedContracts;
    valueIntervention = d.valueIntervention;
    linearCostMedia = d.linearCostMedia;
    costEstimate = d.costEstimate;
    lastDateIntervention = d.lastDateIntervention;
    companyBuild = d.companyBuild;
    latitude = d.latitude;
    longitude = d.longitude;
    altitude = d.altitude;
    createdAt = d.createdAt;
    createdBy = d.createdBy;
    updatedAt = d.updatedAt;
    updatedBy = d.updatedBy;
    deletedAt = d.deletedAt;
    deletedBy = d.deletedBy;
    attachments =
    d.attachments == null ? null : List<Attachment>.from(d.attachments!);
  }

  ActiveOaesData toData() => ActiveOaesData.fromData(this);

  ActiveOaesData copyWith({
    String? id,
    int? order,
    double? score,
    String? state,
    String? road,
    String? region,
    String? identificationName,
    double? extension,
    double? width,
    double? area,
    String? structureType,
    String? relatedContracts,
    double? valueIntervention,
    double? linearCostMedia,
    double? costEstimate,
    DateTime? lastDateIntervention,
    String? companyBuild,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    List<Attachment>? attachments,
  }) {
    return ActiveOaesData(
      id: id ?? this.id,
      order: order ?? this.order,
      score: score ?? this.score,
      state: state ?? this.state,
      road: road ?? this.road,
      region: region ?? this.region,
      identificationName: identificationName ?? this.identificationName,
      extension: extension ?? this.extension,
      width: width ?? this.width,
      area: area ?? this.area,
      structureType: structureType ?? this.structureType,
      relatedContracts: relatedContracts ?? this.relatedContracts,
      valueIntervention: valueIntervention ?? this.valueIntervention,
      linearCostMedia: linearCostMedia ?? this.linearCostMedia,
      costEstimate: costEstimate ?? this.costEstimate,
      lastDateIntervention: lastDateIntervention ?? this.lastDateIntervention,
      companyBuild: companyBuild ?? this.companyBuild,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      attachments: attachments ?? this.attachments,
    );
  }

  // ===========================================================================
  // Serialização
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'score': score,
      'state': state,
      'road': road,
      'region': region,
      'identificationName': identificationName,
      'extension': extension,
      'width': width,
      'area': area,
      'structureType': structureType,
      'relatedContracts': relatedContracts,
      'valueIntervention': valueIntervention,
      'linearCostMedia': linearCostMedia,
      'costEstimate': costEstimate,
      'lastDateIntervention': lastDateIntervention?.toIso8601String(),
      'companyBuild': companyBuild,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
      'attachments': attachments?.map((a) => a.toMap()).toList(),
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{};

    void put(String k, dynamic v) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      map[k] = v;
    }

    put('order', order);
    put('score', score);
    put('state', state);
    put('road', road);
    put('region', region);
    put('identificationName', identificationName);
    put('extension', extension);
    put('width', width);
    put('area', area);
    put('structureType', structureType);
    put('relatedContracts', relatedContracts);
    put('valueIntervention', valueIntervention);
    put('linearCostMedia', linearCostMedia);
    put('costEstimate', costEstimate);

    if (lastDateIntervention != null) {
      map['lastDateIntervention'] = Timestamp.fromDate(lastDateIntervention!);
    }

    put('companyBuild', companyBuild);
    put('latitude', latitude);
    put('longitude', longitude);
    put('altitude', altitude);

    if (attachments != null) {
      map['attachments'] = attachments!.map((a) => a.toMap()).toList();
    }

    return map;
  }

  // ===========================================================================
  // Status / cores
  // ===========================================================================

  static Color getColorByNota(double nota) {
    if (nota == 0) return Colors.green.shade700;
    if (nota == 1) return Colors.red.shade900;
    if (nota == 2) return Colors.orange.shade900;
    if (nota == 3) return Colors.yellow.shade800;
    if (nota == 4) return Colors.purple.shade400;
    if (nota == 5) return Colors.blue.shade700;
    return Colors.grey.shade400;
  }

  static String getLabelByNota(int nota) {
    switch (nota) {
      case 0:
        return 'Restaurada';
      case 1:
        return 'Crítica';
      case 2:
        return 'Problemática';
      case 3:
        return 'Potencialmente problemática';
      case 4:
        return 'Sem problemas sérios';
      case 5:
        return 'Sem problemas';
      default:
        return 'Sem nota';
    }
  }

  static Color colorForScore(num? score) {
    if (score == null) return Colors.grey.shade400;

    final s = score.toDouble();
    if (s.isNaN) return Colors.grey.shade400;

    final c = s.clamp(0, 5).toDouble();
    return getColorByNota(c);
  }

  static List<Color> colorsFromScores(List<num?> scores) {
    return scores.map(colorForScore).toList(growable: false);
  }
}

/// Helpers para uso direto com flutter_map Marker.
extension OAEsDataExtension on ActiveOaesData {
  LatLng? get latLng {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  Map<String, dynamic> get markerProperties {
    return toMap();
  }

  Marker? toMarker({
    required Widget child,
    double width = 42,
    double height = 42,
    Alignment? alignment = Alignment.center,
    bool? rotate,
    Key? key,
  }) {
    final point = latLng;
    if (point == null) return null;

    return Marker(
      key: key,
      point: point,
      width: width,
      height: height,
      alignment: alignment,
      rotate: rotate,
      child: child,
    );
  }
}