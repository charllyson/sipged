// lib/_blocs/actives/oaes/active_oaes_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

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

  // anexos (projetos, PDFs etc.)
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

  // ---------- helpers ----------
  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }
    final raw = snap.data();
    return (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) { try { return DateTime.fromMillisecondsSinceEpoch(v); } catch (_) {} }
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
      return v.map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList(growable: true);
    }
    return null;
  }

  // ---------- factories ----------
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
      structureType: data['structureType'] as String?,
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
      structureType: map['structureType'] as String?,
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

  // ---------- clone/copy ----------
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
    attachments = d.attachments == null ? null : List<Attachment>.from(d.attachments!);
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

  // ---------- serialização ----------
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
    return {
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
      if (attachments != null) 'attachments': attachments!.map((a) => a.toMap()).toList(),
      // created*/updated* normalmente via Repository com serverTimestamp
    };
  }
}

// helper para Marker
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
