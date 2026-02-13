// lib/_blocs/modules/actives/oacs/active_oacs_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/map/markers/tagged_marker.dart';

/// ----------------------------------------------------------------------------
/// OAC (Obra de Arte Corrente) — modelo completo para:
/// - Cadastro / Implantação
/// - Inspeção / Monitoramento de condição
/// - Manutenção (histórico)
/// - Documentação (anexos + fotos)
/// ----------------------------------------------------------------------------
class ActiveOacsData {
  // Identificação
  String? id;
  int? order;

  String? identificationName; // ex: "OAC-AL220-001"
  String? code; // código interno/externo
  String? legacyCode; // código legado (se existir)

  // Localização
  String? state; // UF
  String? municipality;
  String? road; // ex: AL-220
  String? region; // label da regional
  String? kmRef; // km 10+500, ou "10.5"
  String? locality; // povoado/bairro
  String? referencePoint; // marco, ponte próxima etc.

  double? latitude;
  double? longitude;
  double? altitude;

  // Classificação da OAC
  String? oacType; // BUEIRO, SARJETA, GALERIA, DRENO, PASSAGEM MOLHADA...
  String? material; // CONCRETO, AÇO, PEAD, ALVENARIA...
  String? hydraulicType; // tubular, celular, retangular...
  String? environment; // urbano/rural, rio, vala, etc.

  // Dimensões / implantação
  double? length; // m
  double? width; // m
  double? height; // m
  double? diameter; // m (se tubular)
  int? numberOfCells; // células/vãos
  double? slope; // declividade %
  double? coverHeight; // altura de recobrimento (m)
  double? inletElevation; // cota montante
  double? outletElevation; // cota jusante
  double? catchmentArea; // bacia (km²) se tiver
  double? designFlow; // vazão projeto (m³/s)
  String? hydrologyNotes;

  // Implantação (documentação)
  DateTime? implantationDate;
  String? implantationCompany;
  String? implantationContractId;
  String? implantationNotes;

  // Condição / status (monitoramento)
  ///
  /// score 0..5 (mesma lógica do OAE, mas semântica para OAC)
  /// 0: NOVA / OK
  /// 1: CRÍTICA
  /// 2: RUIM
  /// 3: REGULAR
  /// 4: BOA
  /// 5: EXCELENTE
  double? conditionScore;

  String? conditionLabelOverride; // se quiser sobrescrever label
  DateTime? lastInspectionDate;
  DateTime? nextInspectionDate;
  String? lastInspectorUserId;

  // Problemas recorrentes
  bool? hasSiltation;      // assoreamento
  bool? hasObstruction;    // obstrução
  bool? hasErosion;        // erosão
  bool? hasCracks;         // trincas
  bool? hasCorrosion;      // corrosão
  bool? hasDeformation;    // deformação
  bool? hasLeakage;        // infiltração
  String? anomaliesNotes;

  // Custos / estimativas
  double? maintenanceCostEstimate;
  double? lastMaintenanceCost;
  String? maintenanceCostNotes;

  // Relacionamentos
  String? relatedContracts;
  String? responsibleCompany; // operação/manutenção

  // Documentos / anexos e fotos
  List<Attachment>? attachments; // projetos, PDFs etc. (SideListBox)
  List<Attachment>? photos;      // galeria (como no OAE details)

  // Históricos (dentro do documento)
  List<OacInspectionEntry>? inspections;
  List<OacMaintenanceEntry>? maintenances;

  // Auditoria
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  ActiveOacsData({
    this.id,
    this.order,
    this.identificationName,
    this.code,
    this.legacyCode,
    this.state,
    this.municipality,
    this.road,
    this.region,
    this.kmRef,
    this.locality,
    this.referencePoint,
    this.latitude,
    this.longitude,
    this.altitude,
    this.oacType,
    this.material,
    this.hydraulicType,
    this.environment,
    this.length,
    this.width,
    this.height,
    this.diameter,
    this.numberOfCells,
    this.slope,
    this.coverHeight,
    this.inletElevation,
    this.outletElevation,
    this.catchmentArea,
    this.designFlow,
    this.hydrologyNotes,
    this.implantationDate,
    this.implantationCompany,
    this.implantationContractId,
    this.implantationNotes,
    this.conditionScore,
    this.conditionLabelOverride,
    this.lastInspectionDate,
    this.nextInspectionDate,
    this.lastInspectorUserId,
    this.hasSiltation,
    this.hasObstruction,
    this.hasErosion,
    this.hasCracks,
    this.hasCorrosion,
    this.hasDeformation,
    this.hasLeakage,
    this.anomaliesNotes,
    this.maintenanceCostEstimate,
    this.lastMaintenanceCost,
    this.maintenanceCostNotes,
    this.relatedContracts,
    this.responsibleCompany,
    this.attachments,
    this.photos,
    this.inspections,
    this.maintenances,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  // ===========================================================================
  // Converters helpers
  // ===========================================================================
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
    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } catch (_) {}
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

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == 'sim' || s == '1') return true;
      if (s == 'false' || s == 'nao' || s == 'não' || s == '0') return false;
    }
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

  static List<OacInspectionEntry>? _toInspections(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map<OacInspectionEntry>((e) {
        if (e is OacInspectionEntry) return e;
        return OacInspectionEntry.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList(growable: true);
    }
    return null;
  }

  static List<OacMaintenanceEntry>? _toMaintenances(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map<OacMaintenanceEntry>((e) {
        if (e is OacMaintenanceEntry) return e;
        return OacMaintenanceEntry.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList(growable: true);
    }
    return null;
  }

  // ===========================================================================
  // Factories
  // ===========================================================================
  factory ActiveOacsData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    return ActiveOacsData(
      id: snap.id,
      order: _toInt(data['order']),
      identificationName: data['identificationName'] as String?,
      code: data['code'] as String?,
      legacyCode: data['legacyCode'] as String?,
      state: data['state'] as String?,
      municipality: data['municipality'] as String?,
      road: data['road'] as String?,
      region: data['region'] as String?,
      kmRef: data['kmRef'] as String?,
      locality: data['locality'] as String?,
      referencePoint: data['referencePoint'] as String?,
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      altitude: _toDouble(data['altitude']),
      oacType: data['oacType'] as String?,
      material: data['material'] as String?,
      hydraulicType: data['hydraulicType'] as String?,
      environment: data['environment'] as String?,
      length: _toDouble(data['length']),
      width: _toDouble(data['width']),
      height: _toDouble(data['height']),
      diameter: _toDouble(data['diameter']),
      numberOfCells: _toInt(data['numberOfCells']),
      slope: _toDouble(data['slope']),
      coverHeight: _toDouble(data['coverHeight']),
      inletElevation: _toDouble(data['inletElevation']),
      outletElevation: _toDouble(data['outletElevation']),
      catchmentArea: _toDouble(data['catchmentArea']),
      designFlow: _toDouble(data['designFlow']),
      hydrologyNotes: data['hydrologyNotes'] as String?,
      implantationDate: _toDate(data['implantationDate']),
      implantationCompany: data['implantationCompany'] as String?,
      implantationContractId: data['implantationContractId'] as String?,
      implantationNotes: data['implantationNotes'] as String?,
      conditionScore: _toDouble(data['conditionScore']),
      conditionLabelOverride: data['conditionLabelOverride'] as String?,
      lastInspectionDate: _toDate(data['lastInspectionDate']),
      nextInspectionDate: _toDate(data['nextInspectionDate']),
      lastInspectorUserId: data['lastInspectorUserId'] as String?,
      hasSiltation: _toBool(data['hasSiltation']),
      hasObstruction: _toBool(data['hasObstruction']),
      hasErosion: _toBool(data['hasErosion']),
      hasCracks: _toBool(data['hasCracks']),
      hasCorrosion: _toBool(data['hasCorrosion']),
      hasDeformation: _toBool(data['hasDeformation']),
      hasLeakage: _toBool(data['hasLeakage']),
      anomaliesNotes: data['anomaliesNotes'] as String?,
      maintenanceCostEstimate: _toDouble(data['maintenanceCostEstimate']),
      lastMaintenanceCost: _toDouble(data['lastMaintenanceCost']),
      maintenanceCostNotes: data['maintenanceCostNotes'] as String?,
      relatedContracts: data['relatedContracts'] as String?,
      responsibleCompany: data['responsibleCompany'] as String?,
      attachments: _toAttachments(data['attachments']),
      photos: _toAttachments(data['photos']),
      inspections: _toInspections(data['inspections']),
      maintenances: _toMaintenances(data['maintenances']),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      deletedAt: _toDate(data['deletedAt']),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  factory ActiveOacsData.fromMap(Map<String, dynamic> map) {
    return ActiveOacsData(
      id: map['id'] as String?,
      order: _toInt(map['order']),
      identificationName: map['identificationName'] as String?,
      code: map['code'] as String?,
      legacyCode: map['legacyCode'] as String?,
      state: map['state'] as String?,
      municipality: map['municipality'] as String?,
      road: map['road'] as String?,
      region: map['region'] as String?,
      kmRef: map['kmRef'] as String?,
      locality: map['locality'] as String?,
      referencePoint: map['referencePoint'] as String?,
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      altitude: _toDouble(map['altitude']),
      oacType: map['oacType'] as String?,
      material: map['material'] as String?,
      hydraulicType: map['hydraulicType'] as String?,
      environment: map['environment'] as String?,
      length: _toDouble(map['length']),
      width: _toDouble(map['width']),
      height: _toDouble(map['height']),
      diameter: _toDouble(map['diameter']),
      numberOfCells: _toInt(map['numberOfCells']),
      slope: _toDouble(map['slope']),
      coverHeight: _toDouble(map['coverHeight']),
      inletElevation: _toDouble(map['inletElevation']),
      outletElevation: _toDouble(map['outletElevation']),
      catchmentArea: _toDouble(map['catchmentArea']),
      designFlow: _toDouble(map['designFlow']),
      hydrologyNotes: map['hydrologyNotes'] as String?,
      implantationDate: _toDate(map['implantationDate']),
      implantationCompany: map['implantationCompany'] as String?,
      implantationContractId: map['implantationContractId'] as String?,
      implantationNotes: map['implantationNotes'] as String?,
      conditionScore: _toDouble(map['conditionScore']),
      conditionLabelOverride: map['conditionLabelOverride'] as String?,
      lastInspectionDate: _toDate(map['lastInspectionDate']),
      nextInspectionDate: _toDate(map['nextInspectionDate']),
      lastInspectorUserId: map['lastInspectorUserId'] as String?,
      hasSiltation: _toBool(map['hasSiltation']),
      hasObstruction: _toBool(map['hasObstruction']),
      hasErosion: _toBool(map['hasErosion']),
      hasCracks: _toBool(map['hasCracks']),
      hasCorrosion: _toBool(map['hasCorrosion']),
      hasDeformation: _toBool(map['hasDeformation']),
      hasLeakage: _toBool(map['hasLeakage']),
      anomaliesNotes: map['anomaliesNotes'] as String?,
      maintenanceCostEstimate: _toDouble(map['maintenanceCostEstimate']),
      lastMaintenanceCost: _toDouble(map['lastMaintenanceCost']),
      maintenanceCostNotes: map['maintenanceCostNotes'] as String?,
      relatedContracts: map['relatedContracts'] as String?,
      responsibleCompany: map['responsibleCompany'] as String?,
      attachments: _toAttachments(map['attachments']),
      photos: _toAttachments(map['photos']),
      inspections: _toInspections(map['inspections']),
      maintenances: _toMaintenances(map['maintenances']),
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
      deletedAt: _toDate(map['deletedAt']),
      deletedBy: map['deletedBy'] as String?,
    );
  }

  // ===========================================================================
  // Clone / copyWith
  // ===========================================================================
  ActiveOacsData.fromData(ActiveOacsData d) {
    id = d.id;
    order = d.order;
    identificationName = d.identificationName;
    code = d.code;
    legacyCode = d.legacyCode;

    state = d.state;
    municipality = d.municipality;
    road = d.road;
    region = d.region;
    kmRef = d.kmRef;
    locality = d.locality;
    referencePoint = d.referencePoint;

    latitude = d.latitude;
    longitude = d.longitude;
    altitude = d.altitude;

    oacType = d.oacType;
    material = d.material;
    hydraulicType = d.hydraulicType;
    environment = d.environment;

    length = d.length;
    width = d.width;
    height = d.height;
    diameter = d.diameter;
    numberOfCells = d.numberOfCells;
    slope = d.slope;
    coverHeight = d.coverHeight;
    inletElevation = d.inletElevation;
    outletElevation = d.outletElevation;
    catchmentArea = d.catchmentArea;
    designFlow = d.designFlow;
    hydrologyNotes = d.hydrologyNotes;

    implantationDate = d.implantationDate;
    implantationCompany = d.implantationCompany;
    implantationContractId = d.implantationContractId;
    implantationNotes = d.implantationNotes;

    conditionScore = d.conditionScore;
    conditionLabelOverride = d.conditionLabelOverride;
    lastInspectionDate = d.lastInspectionDate;
    nextInspectionDate = d.nextInspectionDate;
    lastInspectorUserId = d.lastInspectorUserId;

    hasSiltation = d.hasSiltation;
    hasObstruction = d.hasObstruction;
    hasErosion = d.hasErosion;
    hasCracks = d.hasCracks;
    hasCorrosion = d.hasCorrosion;
    hasDeformation = d.hasDeformation;
    hasLeakage = d.hasLeakage;
    anomaliesNotes = d.anomaliesNotes;

    maintenanceCostEstimate = d.maintenanceCostEstimate;
    lastMaintenanceCost = d.lastMaintenanceCost;
    maintenanceCostNotes = d.maintenanceCostNotes;

    relatedContracts = d.relatedContracts;
    responsibleCompany = d.responsibleCompany;

    attachments = d.attachments == null ? null : List<Attachment>.from(d.attachments!);
    photos = d.photos == null ? null : List<Attachment>.from(d.photos!);

    inspections = d.inspections?.map((e) => e.copy()).toList();
    maintenances = d.maintenances?.map((e) => e.copy()).toList();

    createdAt = d.createdAt;
    createdBy = d.createdBy;
    updatedAt = d.updatedAt;
    updatedBy = d.updatedBy;
    deletedAt = d.deletedAt;
    deletedBy = d.deletedBy;
  }

  ActiveOacsData toData() => ActiveOacsData.fromData(this);

  ActiveOacsData copyWith({
    String? id,
    int? order,
    String? identificationName,
    String? code,
    String? legacyCode,
    String? state,
    String? municipality,
    String? road,
    String? region,
    String? kmRef,
    String? locality,
    String? referencePoint,
    double? latitude,
    double? longitude,
    double? altitude,
    String? oacType,
    String? material,
    String? hydraulicType,
    String? environment,
    double? length,
    double? width,
    double? height,
    double? diameter,
    int? numberOfCells,
    double? slope,
    double? coverHeight,
    double? inletElevation,
    double? outletElevation,
    double? catchmentArea,
    double? designFlow,
    String? hydrologyNotes,
    DateTime? implantationDate,
    String? implantationCompany,
    String? implantationContractId,
    String? implantationNotes,
    double? conditionScore,
    String? conditionLabelOverride,
    DateTime? lastInspectionDate,
    DateTime? nextInspectionDate,
    String? lastInspectorUserId,
    bool? hasSiltation,
    bool? hasObstruction,
    bool? hasErosion,
    bool? hasCracks,
    bool? hasCorrosion,
    bool? hasDeformation,
    bool? hasLeakage,
    String? anomaliesNotes,
    double? maintenanceCostEstimate,
    double? lastMaintenanceCost,
    String? maintenanceCostNotes,
    String? relatedContracts,
    String? responsibleCompany,
    List<Attachment>? attachments,
    List<Attachment>? photos,
    List<OacInspectionEntry>? inspections,
    List<OacMaintenanceEntry>? maintenances,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ActiveOacsData(
      id: id ?? this.id,
      order: order ?? this.order,
      identificationName: identificationName ?? this.identificationName,
      code: code ?? this.code,
      legacyCode: legacyCode ?? this.legacyCode,
      state: state ?? this.state,
      municipality: municipality ?? this.municipality,
      road: road ?? this.road,
      region: region ?? this.region,
      kmRef: kmRef ?? this.kmRef,
      locality: locality ?? this.locality,
      referencePoint: referencePoint ?? this.referencePoint,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      oacType: oacType ?? this.oacType,
      material: material ?? this.material,
      hydraulicType: hydraulicType ?? this.hydraulicType,
      environment: environment ?? this.environment,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      diameter: diameter ?? this.diameter,
      numberOfCells: numberOfCells ?? this.numberOfCells,
      slope: slope ?? this.slope,
      coverHeight: coverHeight ?? this.coverHeight,
      inletElevation: inletElevation ?? this.inletElevation,
      outletElevation: outletElevation ?? this.outletElevation,
      catchmentArea: catchmentArea ?? this.catchmentArea,
      designFlow: designFlow ?? this.designFlow,
      hydrologyNotes: hydrologyNotes ?? this.hydrologyNotes,
      implantationDate: implantationDate ?? this.implantationDate,
      implantationCompany: implantationCompany ?? this.implantationCompany,
      implantationContractId:
      implantationContractId ?? this.implantationContractId,
      implantationNotes: implantationNotes ?? this.implantationNotes,
      conditionScore: conditionScore ?? this.conditionScore,
      conditionLabelOverride:
      conditionLabelOverride ?? this.conditionLabelOverride,
      lastInspectionDate: lastInspectionDate ?? this.lastInspectionDate,
      nextInspectionDate: nextInspectionDate ?? this.nextInspectionDate,
      lastInspectorUserId: lastInspectorUserId ?? this.lastInspectorUserId,
      hasSiltation: hasSiltation ?? this.hasSiltation,
      hasObstruction: hasObstruction ?? this.hasObstruction,
      hasErosion: hasErosion ?? this.hasErosion,
      hasCracks: hasCracks ?? this.hasCracks,
      hasCorrosion: hasCorrosion ?? this.hasCorrosion,
      hasDeformation: hasDeformation ?? this.hasDeformation,
      hasLeakage: hasLeakage ?? this.hasLeakage,
      anomaliesNotes: anomaliesNotes ?? this.anomaliesNotes,
      maintenanceCostEstimate:
      maintenanceCostEstimate ?? this.maintenanceCostEstimate,
      lastMaintenanceCost: lastMaintenanceCost ?? this.lastMaintenanceCost,
      maintenanceCostNotes: maintenanceCostNotes ?? this.maintenanceCostNotes,
      relatedContracts: relatedContracts ?? this.relatedContracts,
      responsibleCompany: responsibleCompany ?? this.responsibleCompany,
      attachments: attachments ?? this.attachments,
      photos: photos ?? this.photos,
      inspections: inspections ?? this.inspections,
      maintenances: maintenances ?? this.maintenances,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  // ===========================================================================
  // Serialização
  // ===========================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'identificationName': identificationName,
      'code': code,
      'legacyCode': legacyCode,
      'state': state,
      'municipality': municipality,
      'road': road,
      'region': region,
      'kmRef': kmRef,
      'locality': locality,
      'referencePoint': referencePoint,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'oacType': oacType,
      'material': material,
      'hydraulicType': hydraulicType,
      'environment': environment,
      'length': length,
      'width': width,
      'height': height,
      'diameter': diameter,
      'numberOfCells': numberOfCells,
      'slope': slope,
      'coverHeight': coverHeight,
      'inletElevation': inletElevation,
      'outletElevation': outletElevation,
      'catchmentArea': catchmentArea,
      'designFlow': designFlow,
      'hydrologyNotes': hydrologyNotes,
      'implantationDate': implantationDate?.toIso8601String(),
      'implantationCompany': implantationCompany,
      'implantationContractId': implantationContractId,
      'implantationNotes': implantationNotes,
      'conditionScore': conditionScore,
      'conditionLabelOverride': conditionLabelOverride,
      'lastInspectionDate': lastInspectionDate?.toIso8601String(),
      'nextInspectionDate': nextInspectionDate?.toIso8601String(),
      'lastInspectorUserId': lastInspectorUserId,
      'hasSiltation': hasSiltation,
      'hasObstruction': hasObstruction,
      'hasErosion': hasErosion,
      'hasCracks': hasCracks,
      'hasCorrosion': hasCorrosion,
      'hasDeformation': hasDeformation,
      'hasLeakage': hasLeakage,
      'anomaliesNotes': anomaliesNotes,
      'maintenanceCostEstimate': maintenanceCostEstimate,
      'lastMaintenanceCost': lastMaintenanceCost,
      'maintenanceCostNotes': maintenanceCostNotes,
      'relatedContracts': relatedContracts,
      'responsibleCompany': responsibleCompany,
      'attachments': attachments?.map((a) => a.toMap()).toList(),
      'photos': photos?.map((a) => a.toMap()).toList(),
      'inspections': inspections?.map((e) => e.toMap()).toList(),
      'maintenances': maintenances?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  /// Firestore: grava apenas campos setados, com Timestamp em datas.
  Map<String, dynamic> toFirestore() {
    Timestamp? ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

    final map = <String, dynamic>{};

    void put(String k, dynamic v) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      map[k] = v;
    }

    put('order', order);
    put('identificationName', identificationName);
    put('code', code);
    put('legacyCode', legacyCode);

    put('state', state);
    put('municipality', municipality);
    put('road', road);
    put('region', region);
    put('kmRef', kmRef);
    put('locality', locality);
    put('referencePoint', referencePoint);

    put('latitude', latitude);
    put('longitude', longitude);
    put('altitude', altitude);

    put('oacType', oacType);
    put('material', material);
    put('hydraulicType', hydraulicType);
    put('environment', environment);

    put('length', length);
    put('width', width);
    put('height', height);
    put('diameter', diameter);
    put('numberOfCells', numberOfCells);
    put('slope', slope);
    put('coverHeight', coverHeight);
    put('inletElevation', inletElevation);
    put('outletElevation', outletElevation);
    put('catchmentArea', catchmentArea);
    put('designFlow', designFlow);
    put('hydrologyNotes', hydrologyNotes);

    final imp = ts(implantationDate);
    if (imp != null) map['implantationDate'] = imp;
    put('implantationCompany', implantationCompany);
    put('implantationContractId', implantationContractId);
    put('implantationNotes', implantationNotes);

    put('conditionScore', conditionScore);
    put('conditionLabelOverride', conditionLabelOverride);

    final lastI = ts(lastInspectionDate);
    if (lastI != null) map['lastInspectionDate'] = lastI;
    final nextI = ts(nextInspectionDate);
    if (nextI != null) map['nextInspectionDate'] = nextI;
    put('lastInspectorUserId', lastInspectorUserId);

    put('hasSiltation', hasSiltation);
    put('hasObstruction', hasObstruction);
    put('hasErosion', hasErosion);
    put('hasCracks', hasCracks);
    put('hasCorrosion', hasCorrosion);
    put('hasDeformation', hasDeformation);
    put('hasLeakage', hasLeakage);
    put('anomaliesNotes', anomaliesNotes);

    put('maintenanceCostEstimate', maintenanceCostEstimate);
    put('lastMaintenanceCost', lastMaintenanceCost);
    put('maintenanceCostNotes', maintenanceCostNotes);

    put('relatedContracts', relatedContracts);
    put('responsibleCompany', responsibleCompany);

    if (attachments != null) {
      map['attachments'] = attachments!.map((a) => a.toMap()).toList();
    }
    if (photos != null) {
      map['photos'] = photos!.map((a) => a.toMap()).toList();
    }
    if (inspections != null) {
      map['inspections'] = inspections!.map((e) => e.toMap()).toList();
    }
    if (maintenances != null) {
      map['maintenances'] = maintenances!.map((e) => e.toMap()).toList();
    }

    return map;
  }

  // ===========================================================================
  // Status/cores (0..5) – mantendo a semântica do seu painel
  // ===========================================================================
  static Color getColorByNota(double nota) {
    if (nota == 0) return Colors.green.shade700;  // Nova/OK
    if (nota == 1) return Colors.red.shade900;    // Crítica
    if (nota == 2) return Colors.orange.shade900; // Ruim
    if (nota == 3) return Colors.yellow.shade800; // Regular
    if (nota == 4) return Colors.purple.shade400; // Boa
    if (nota == 5) return Colors.blue.shade700;   // Excelente
    return Colors.grey.shade400;
  }

  static String getLabelByNota(int nota) {
    switch (nota) {
      case 0:
        return 'Nova / OK';
      case 1:
        return 'Crítica';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Boa';
      case 5:
        return 'Excelente';
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

  static List<Color> colorsFromScores(List<num?> scores) =>
      scores.map(colorForScore).toList(growable: false);
}

/// ----------------------------------------------------------------------------
/// Inspeção (entrada de histórico)
/// ----------------------------------------------------------------------------
class OacInspectionEntry {
  final String id; // uuid simples (timestamp-based) para diferenciar
  final DateTime date;
  final String? inspectorUserId;
  final double? score; // 0..5
  final String? method; // visual, drone, topografia, etc.
  final String? notes;
  final List<String>? anomalies; // lista curta de tags

  OacInspectionEntry({
    required this.id,
    required this.date,
    this.inspectorUserId,
    this.score,
    this.method,
    this.notes,
    this.anomalies,
  });

  factory OacInspectionEntry.fromMap(Map<String, dynamic> map) {
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    double? dd(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    return OacInspectionEntry(
      id: (map['id'] as String?) ?? 'insp_${DateTime.now().millisecondsSinceEpoch}',
      date: dt(map['date']) ?? DateTime.now(),
      inspectorUserId: map['inspectorUserId'] as String?,
      score: dd(map['score']),
      method: map['method'] as String?,
      notes: map['notes'] as String?,
      anomalies: (map['anomalies'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'inspectorUserId': inspectorUserId,
      'score': score,
      'method': method,
      'notes': notes,
      'anomalies': anomalies,
    };
  }

  OacInspectionEntry copy() => OacInspectionEntry(
    id: id,
    date: date,
    inspectorUserId: inspectorUserId,
    score: score,
    method: method,
    notes: notes,
    anomalies: anomalies == null ? null : List<String>.from(anomalies!),
  );
}

/// ----------------------------------------------------------------------------
/// Manutenção (entrada de histórico)
/// ----------------------------------------------------------------------------
class OacMaintenanceEntry {
  final String id;
  final DateTime date;
  final String? team; // equipe/empresa
  final String? type; // desobstrução, limpeza, recomposição, troca, etc.
  final String? notes;
  final double? cost;
  final bool? emergency;

  OacMaintenanceEntry({
    required this.id,
    required this.date,
    this.team,
    this.type,
    this.notes,
    this.cost,
    this.emergency,
  });

  factory OacMaintenanceEntry.fromMap(Map<String, dynamic> map) {
    DateTime? dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return null;
    }

    double? dd(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '.'));
      return null;
    }

    bool? bb(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == 'sim' || s == '1') return true;
        if (s == 'false' || s == 'nao' || s == 'não' || s == '0') return false;
      }
      return null;
    }

    return OacMaintenanceEntry(
      id: (map['id'] as String?) ?? 'mnt_${DateTime.now().millisecondsSinceEpoch}',
      date: dt(map['date']) ?? DateTime.now(),
      team: map['team'] as String?,
      type: map['type'] as String?,
      notes: map['notes'] as String?,
      cost: dd(map['cost']),
      emergency: bb(map['emergency']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'team': team,
      'type': type,
      'notes': notes,
      'cost': cost,
      'emergency': emergency,
    };
  }

  OacMaintenanceEntry copy() => OacMaintenanceEntry(
    id: id,
    date: date,
    team: team,
    type: type,
    notes: notes,
    cost: cost,
    emergency: emergency,
  );
}

/// helper para Marker
extension OacsDataExtension on ActiveOacsData {
  TaggedChangedMarker<ActiveOacsData>? toTaggedMarker() {
    if (latitude == null || longitude == null) return null;
    return TaggedChangedMarker<ActiveOacsData>(
      point: LatLng(latitude!, longitude!),
      data: this,
      properties: toMap(),
    );
  }
}
