import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../_widgets/map/markers/tagged_marker.dart';

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
      //lastDateIntervention: (data['lastDateIntervention'] as Timestamp?)?.toDate(),
      companyBuild: data['companyBuild'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      altitude: (data['altitude'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'],
    );
  }

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
    linearCostMedia = d.linearCostMedia;
    costEstimate = d.costEstimate;
    companyBuild = d.companyBuild;
    lastDateIntervention = d.lastDateIntervention;
    altitude = d.altitude;
  }
  ActiveOaesData toData() => ActiveOaesData(
    id: id,
    order: order,
    identificationName: identificationName,
    latitude: latitude,
    longitude: longitude,
    score: score,
    state: state,
    road: road,
    region: region,
    extension: extension,
    width: width,
    area: area,
    structureType: structureType,
    relatedContracts: relatedContracts,
    linearCostMedia: linearCostMedia,
    costEstimate: costEstimate,
    companyBuild: companyBuild,
    lastDateIntervention: lastDateIntervention,
    altitude: altitude,
  );

  Map<String, dynamic> toMap() {
    return {
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
      //'lastDateIntervention': lastDateIntervention,
      'companyBuild': companyBuild,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate(); // Caso venha do Firebase direto
    if (value is String) return DateTime.tryParse(value);
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