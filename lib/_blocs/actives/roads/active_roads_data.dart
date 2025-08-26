import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ActiveRoadsData extends ChangeNotifier {
  late final String? id;

  final String? acronym;
  final String? uf;
  final String? segmentType;
  final String? descCoin;
  final String? roadCode;
  final String? initialSegment;
  final String? finalSegment;
  final double? initialKm;
  final double? finalKm;
  final double? extension;
  final String? stateSurface;
  final String? works;
  final String? coincidentFederal;
  final String? administration;
  final String? legalAct;
  final String? coincidentState;
  final String? coincidentStateSurface;
  final String? jurisdiction;
  final String? surface;
  final String? unitLocal;
  final String? coincident;
  final String? initialLatSegment;
  final String? initialLongSegment;
  final String? finalLatSegment;
  final String? finalLongSegment;
  final String? regional;
  final String? previousNumber;
  final String? revestmentType;
  final int? tmd;
  final int? tracksNumber;
  final int? maximumSpeed;
  final String? conservationCondition;
  final String? drainage;
  final int? vsa;
  final String? roadName;
  final String? state;
  final String? direction;
  final String? managingAgency;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;

  final List<LatLng>? points;

  ActiveRoadsData({
    this.id,
    this.acronym,
    this.uf,
    this.segmentType,
    this.descCoin,
    this.roadCode,
    this.initialSegment,
    this.finalSegment,
    this.initialKm,
    this.finalKm,
    this.extension,
    this.stateSurface,
    this.works,
    this.coincidentFederal,
    this.administration,
    this.legalAct,
    this.coincidentState,
    this.coincidentStateSurface,
    this.jurisdiction,
    this.surface,
    this.unitLocal,
    this.coincident,
    this.initialLatSegment,
    this.initialLongSegment,
    this.finalLatSegment,
    this.finalLongSegment,
    this.regional,
    this.previousNumber,
    this.revestmentType,
    this.tmd,
    this.tracksNumber,
    this.maximumSpeed,
    this.conservationCondition,
    this.drainage,
    this.vsa,
    this.roadName,
    this.state,
    this.direction,
    this.managingAgency,
    this.description,
    this.metadata,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.points,
  });


  /// Cria a partir de snapshot do Firebase
  factory ActiveRoadsData.fromDocument(DocumentSnapshot snapshot) {
    if (!snapshot.exists) throw Exception("Documento não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Dados estão vazios");
    return ActiveRoadsData.fromMap(data, id: snapshot.id);
  }

  /// Cria a partir de um network genérico
  factory ActiveRoadsData.fromMap(Map<String, dynamic> map, {String? id}) {
    return ActiveRoadsData(
      id: id ?? map['id'],
      acronym: map['acronym'],
      uf: map['uf'],
      segmentType: map['segmentType'],
      descCoin: map['descCoin'],
      roadCode: map['roadCode'],
      initialSegment: map['initialSegment'],
      finalSegment: map['finalSegment'],
      initialKm: _toDouble(map['initialKm']),
      finalKm: _toDouble(map['finalKm']),
      extension: _toDouble(map['extension']),
      stateSurface: map['stateSurface'],
      works: map['works'],
      coincidentFederal: map['coincidentFederal'],
      administration: map['administration'],
      legalAct: map['legalAct'],
      coincidentState: map['coincidentState'],
      coincidentStateSurface: map['coincidentStateSurface'],
      jurisdiction: map['jurisdiction'],
      surface: map['surface'],
      unitLocal: map['unitLocal'],
      coincident: map['coincident'],
      initialLatSegment: map['initialLatSegment'],
      initialLongSegment: map['initialLongSegment'],
      finalLatSegment: map['finalLatSegment'],
      finalLongSegment: map['finalLongSegment'],
      regional: map['regional'],
      previousNumber: map['previousNumber'],
      revestmentType: map['revestmentType'],
      tmd: _toInt(map['tmd']),
      tracksNumber: _toInt(map['tracksNumber']),
      maximumSpeed: _toInt(map['maximumSpeed']),
      conservationCondition: map['conservationCondition'],
      drainage: map['drainage'],
      vsa: _toInt(['vsa']),
      roadName: map['roadName'],
      state: map['state'],
      direction: map['direction'],
      managingAgency: map['managingAgency'],
      description: map['description'],
      metadata: map['metadata'],
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
      points: _parsePoints(map['points']),
    );
  }

  /// Converte para um network para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'acronym': acronym,
      'uf': uf,
      'segmentType': segmentType,
      'descCoin': descCoin,
      'roadCode': roadCode,
      'initialSegment': initialSegment,
      'finalSegment': finalSegment,
      'initialKm': initialKm,
      'finalKm': finalKm,
      'extension': extension,
      'stateSurface': stateSurface,
      'works': works,
      'coincidentFederal': coincidentFederal,
      'administration': administration,
      'legalAct': legalAct,
      'coincidentState': coincidentState,
      'coincidentStateSurface': coincidentStateSurface,
      'jurisdiction': jurisdiction,
      'surface': surface,
      'unitLocal': unitLocal,
      'coincident': coincident,
      'initialLatSegment': initialLatSegment,
      'initialLongSegment': initialLongSegment,
      'finalLatSegment': finalLatSegment,
      'finalLongSegment': finalLongSegment,
      'regional': regional,
      'previousNumber': previousNumber,
      'revestmentType': revestmentType,
      'tmd': tmd,
      'tracksNumber': tracksNumber,
      'maximumSpeed': maximumSpeed,
      'conservationCondition': conservationCondition,
      'drainage': drainage,
      'vsa': vsa,
      'roadName': roadName,
      'state': state,
      'direction': direction,
      'managingAgency': managingAgency,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
      'points': points?.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
    };
  }
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<LatLng>? _parsePoints(dynamic value) {
  if (value is List) {
    return value
        .map<LatLng?>((e) {
          if (e is GeoPoint) return LatLng(e.latitude, e.longitude);
          if (e is Map && e['lat'] != null && e['lng'] != null) {
            return LatLng(
              (e['lat'] as num).toDouble(),
              (e['lng'] as num).toDouble(),
            );
          }
          return null;
        })
        .whereType<LatLng>()
        .toList();
  }
  return null;
}

extension RoadDataExtensions on ActiveRoadsData {
  List<MapEntry<String, String>> toEntries() {
    return [
      MapEntry('Rodovia', acronym ?? ''),
      MapEntry('UF', uf ?? ''),
      MapEntry('Extensão', extension?.toStringAsFixed(2) ?? '--'),
      MapEntry('Trecho', state ?? ''),
      MapEntry('Tipo Pavimento', stateSurface ?? ''),
      MapEntry('Pontos', points?.length.toString() ?? ''),
      MapEntry('ID', id ?? ''),
      MapEntry('Criado em', createdAt?.toString() ?? ''),
      MapEntry('Atualizado em', updatedAt?.toString() ?? ''),
      MapEntry('Deletado em', deletedAt?.toString() ?? ''),
      MapEntry('Criado por', createdBy ?? ''),
      MapEntry('Atualizado por', updatedBy ?? ''),
      MapEntry('Deletado por', deletedBy ?? ''),
      MapEntry('Detalhes', description ?? ''),
      MapEntry('Segmento', segmentType ?? ''),
      MapEntry('Código', roadCode ?? ''),
      MapEntry('Segmento Inicial', initialSegment ?? ''),
      MapEntry('Segmento Final', finalSegment ?? ''),
      MapEntry('Km Inicial', initialKm?.toString() ?? ''),
      MapEntry('Km Final', finalKm?.toString() ?? ''),
      MapEntry('Extensão', extension?.toString() ?? ''),
      MapEntry('Pavimento', stateSurface ?? ''),
      MapEntry('Trabalho', works ?? ''),
      MapEntry('Coincidente Federal', coincidentFederal ?? ''),
      MapEntry('Administração', administration ?? ''),
      MapEntry('Lei', legalAct ?? ''),
      MapEntry('Coincidente Estadual', coincidentState ?? ''),
      MapEntry('Pavimento Estadual', coincidentStateSurface ?? ''),
      MapEntry('Jurisdição', jurisdiction ?? ''),
      MapEntry('Pavimento', surface ?? ''),
      MapEntry('Unidade Local', unitLocal ?? ''),
      MapEntry('Coincidente', coincident ?? ''),
      MapEntry('Lat Inicial', initialLatSegment ?? ''),
      MapEntry('Long Inicial', initialLongSegment ?? ''),
      MapEntry('Lat Final', finalLatSegment ?? ''),
      MapEntry('Long Final', finalLongSegment ?? ''),
      MapEntry('Regional', regional ?? ''),
      MapEntry('Número Anterior', previousNumber ?? ''),
      MapEntry('Revest. Tipo', revestmentType ?? ''),
      MapEntry('TMD', tmd?.toString() ?? ''),
      MapEntry('Trilhos', tracksNumber?.toString() ?? ''),
      MapEntry('Vel. Máx.', maximumSpeed?.toString() ?? ''),
      MapEntry('Condic. Conservação', conservationCondition ?? ''),
      MapEntry('Drenagem', drainage ?? ''),
      MapEntry('VSA', vsa?.toString() ?? ''),
      MapEntry('Nome', roadName ?? ''),
      MapEntry('Estado', state ?? ''),
      MapEntry('Direção', direction ?? ''),
      MapEntry('Agência de Gestão', managingAgency ?? ''),
      MapEntry('Descrição', description ?? ''),
      MapEntry('Metadata', metadata?.toString() ?? ''),
    ];
  }
}
