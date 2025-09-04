import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/markers/tagged_marker.dart';

class ActiveOaesData extends ChangeNotifier {
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
  });

  // ---------- FACTORIES ----------
  factory ActiveOaesData.fromDocument(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Dados da OAE não encontrados');

    return ActiveOaesData(
      id: snapshot.id,
      order: (data['order'] as num?)?.toInt(),
      score: (data['score'] as num?)?.toDouble(),
      state: data['state'],
      road: data['road'],
      region: data['region'],
      identificationName: data['identificationName'],
      extension: (data['extension'] as num?)?.toDouble(),
      width: (data['width'] as num?)?.toDouble(),
      area: (data['area'] as num?)?.toDouble(),
      structureType: data['structureType'],
      relatedContracts: data['relatedContracts'],
      valueIntervention: (data['valueIntervention'] as num?)?.toDouble(),
      linearCostMedia: (data['linearCostMedia'] as num?)?.toDouble(),
      costEstimate: (data['costEstimate'] as num?)?.toDouble(),
      lastDateIntervention: _parseDate(data['lastDateIntervention']), // ✅
      companyBuild: data['companyBuild'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      altitude: (data['altitude'] as num?)?.toDouble(),
      createdAt: _parseDate(data['createdAt']),
      createdBy: data['createdBy'],
      updatedAt: _parseDate(data['updatedAt']),
      updatedBy: data['updatedBy'],
      deletedAt: _parseDate(data['deletedAt']),
      deletedBy: data['deletedBy'],
    );
  }

  factory ActiveOaesData.fromMap(Map<String, dynamic> map) {
    return ActiveOaesData(
      id: map['id'],
      order: (map['order'] as num?)?.toInt(),
      score: (map['score'] as num?)?.toDouble(),
      state: map['state'],
      road: map['road'],
      region: map['region'],
      identificationName: map['identificationName'],
      extension: (map['extension'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      area: (map['area'] as num?)?.toDouble(),
      structureType: map['structureType'],
      relatedContracts: map['relatedContracts'],
      valueIntervention: (map['valueIntervention'] as num?)?.toDouble(),
      linearCostMedia: (map['linearCostMedia'] as num?)?.toDouble(),
      costEstimate: (map['costEstimate'] as num?)?.toDouble(),
      companyBuild: map['companyBuild'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      lastDateIntervention: _parseDate(map['lastDateIntervention']),
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }

  // ---------- CLONES ----------
  ActiveOaesData.fromData(ActiveOaesData d) {
    id = d.id;
    order = d.order;
    identificationName = d.identificationName;
    latitude = d.latitude;
    longitude = d.longitude;
    score = d.score;
    state = d.state;
    road = d.road;
    region = d.region;
    extension = d.extension;
    width = d.width;
    area = d.area;
    structureType = d.structureType;
    relatedContracts = d.relatedContracts;
    valueIntervention = d.valueIntervention; // ✅ faltava
    linearCostMedia = d.linearCostMedia;
    costEstimate = d.costEstimate;
    companyBuild = d.companyBuild;
    lastDateIntervention = d.lastDateIntervention;
    altitude = d.altitude;

    // timestamps/autoria (opcional nos clones de formulário)
    createdAt = d.createdAt;
    createdBy = d.createdBy;
    updatedAt = d.updatedAt;
    updatedBy = d.updatedBy;
    deletedAt = d.deletedAt;
    deletedBy = d.deletedBy;
  }

  ActiveOaesData toData() => ActiveOaesData.fromData(this);

  // ---------- SERIALIZAÇÃO ----------
  /// Mapa completo (com nulls) — útil pra debug/UI
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
    };
  }

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
    );
  }


  /// Mapa “limpo” para Firestore (sem nulls) — evita sobrescrever campos com null.
  Map<String, dynamic> toFirestore() {
    final m = <String, dynamic>{
      if (order != null) 'order': order,
      if (score != null) 'score': score,
      if (state != null) 'state': state,
      if (road != null) 'road': road,
      if (region != null) 'region': region,
      if (identificationName != null) 'identificationName': identificationName,
      if (extension != null) 'extension': extension,
      if (width != null) 'width': width,
      if (area != null) 'area': area,
      if (structureType != null) 'structureType': structureType,
      if (relatedContracts != null) 'relatedContracts': relatedContracts,
      if (valueIntervention != null) 'valueIntervention': valueIntervention,
      if (linearCostMedia != null) 'linearCostMedia': linearCostMedia,
      if (costEstimate != null) 'costEstimate': costEstimate,
      if (lastDateIntervention != null)
        'lastDateIntervention': Timestamp.fromDate(lastDateIntervention!),
      if (companyBuild != null) 'companyBuild': companyBuild,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      // created*/updated* são geridos pelo Repository com serverTimestamp
    };
    return m;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      // Se vier epoch ms em algum fluxo
      try { return DateTime.fromMillisecondsSinceEpoch(value); } catch (_) {}
    }
    return null;
  }
}

extension OAEsDataExtension on ActiveOaesData {
  TaggedChangedMarker<ActiveOaesData>? toTaggedMarker() {
    if (latitude == null || longitude == null) return null;
    return TaggedChangedMarker<ActiveOaesData>(
      point: LatLng(latitude!, longitude!),
      data: this,
      properties: toMap(),
    );
  }
}
