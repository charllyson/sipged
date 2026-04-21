import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

DateTime? _dateFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

Timestamp? _dateToFirestore(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value);
}

class SetupData extends Equatable {
  final String id;

  final String label;
  final String? parentId;
  final String? cnpjCompanyContracted;
  final List<String>? municipios;
  final String? companyId;
  final String? companyName;
  final String? fonteRecurso;
  final String? unitId;
  final String? unitName;
  final String? roadId;
  final String? roadName;
  final String? regionId;
  final String? regionName;
  final String? genericId;
  final String? name;
  final String? cnpj;

  final String? logoUrl;
  final String? logoPath;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final Map<String, dynamic> extra;

  const SetupData({
    required this.id,
    required this.label,
    this.parentId,
    this.cnpjCompanyContracted,
    this.municipios,
    this.companyId,
    this.companyName,
    this.fonteRecurso,
    this.unitId,
    this.unitName,
    this.roadId,
    this.roadName,
    this.regionId,
    this.regionName,
    this.genericId,
    this.name,
    this.cnpj,
    this.logoUrl,
    this.logoPath,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.extra = const {},
  });

  const SetupData.empty()
      : id = '',
        label = '',
        parentId = null,
        cnpjCompanyContracted = null,
        municipios = null,
        companyId = null,
        companyName = null,
        fonteRecurso = null,
        unitId = null,
        unitName = null,
        roadId = null,
        roadName = null,
        regionId = null,
        regionName = null,
        genericId = null,
        name = null,
        cnpj = null,
        logoUrl = null,
        logoPath = null,
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        extra = const {};

  factory SetupData.fromMap({
    required String id,
    required Map<String, dynamic>? map,
    String? forcedParentId,
  }) {
    if (map == null) return const SetupData.empty();

    final raw = Map<String, dynamic>.from(map);

    final companyId = raw.remove('companyId')?.toString();
    final companyName = raw.remove('companyName')?.toString();
    final unitId = raw.remove('unitId')?.toString();
    final unitName = raw.remove('unitName')?.toString();
    final regionId = raw.remove('regionId')?.toString();
    final regionName = raw.remove('regionName')?.toString();

    final genericId = raw.remove('id')?.toString();
    final name = raw.remove('name')?.toString();

    final parentId = forcedParentId ?? raw.remove('parentId')?.toString();

    final cnpjValue = (raw.remove('cnpj') ?? '').toString().trim();
    final cnpj = cnpjValue.isEmpty ? null : cnpjValue;

    final logoUrlValue = (raw.remove('logoUrl') ?? '').toString().trim();
    final logoPathValue = (raw.remove('logoPath') ?? '').toString().trim();

    final logoUrl = logoUrlValue.isEmpty ? null : logoUrlValue;
    final logoPath = logoPathValue.isEmpty ? null : logoPathValue;

    List<String>? municipios;
    final municipiosDynamic = raw.remove('municipios');
    if (municipiosDynamic is List) {
      municipios = municipiosDynamic.map((e) => e.toString()).toList();
    }

    final createdAt = _dateFromFirestore(raw.remove('createdAt'));
    final updatedAt = _dateFromFirestore(raw.remove('updatedAt'));
    final createdBy = raw.remove('createdBy')?.toString();
    final updatedBy = raw.remove('updatedBy')?.toString();

    final label = (companyName ??
        regionName ??
        unitName ??
        name ??
        raw.remove('label')?.toString() ??
        '')
        .toString();

    final roadId = genericId;
    final roadName = name;

    return SetupData(
      id: id,
      label: label,
      parentId: parentId,
      cnpjCompanyContracted: cnpj,
      municipios: municipios,
      companyId: companyId,
      companyName: companyName,
      unitId: unitId,
      unitName: unitName,
      roadId: roadId,
      roadName: roadName,
      regionId: regionId,
      regionName: regionName,
      genericId: genericId,
      name: name,
      cnpj: cnpj,
      logoUrl: logoUrl,
      logoPath: logoPath,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      extra: raw,
    );
  }

  factory SetupData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        String? forcedParentId,
      }) {
    return SetupData.fromMap(
      id: doc.id,
      map: doc.data(),
      forcedParentId: forcedParentId,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'companyId': companyId,
      'companyName': companyName,
      'unitId': unitId,
      'unitName': unitName,
      'regionId': regionId,
      'regionName': regionName,
      'id': genericId,
      'name': name,
      'parentId': parentId,
      if (municipios != null) 'municipios': municipios,
      if (cnpjCompanyContracted != null) 'cnpj': cnpjCompanyContracted,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (logoPath != null) 'logoPath': logoPath,
      if (createdAt != null) 'createdAt': _dateToFirestore(createdAt),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': _dateToFirestore(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };

    map.addAll(extra);
    return map;
  }

  SetupData copyWith({
    String? id,
    String? label,
    String? parentId,
    String? cnpjCompanyContracted,
    List<String>? municipios,
    String? companyId,
    String? companyName,
    String? unitId,
    String? unitName,
    String? roadId,
    String? roadName,
    String? regionId,
    String? regionName,
    String? genericId,
    String? name,
    String? cnpj,
    String? logoUrl,
    String? logoPath,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? extra,
  }) {
    return SetupData(
      id: id ?? this.id,
      label: label ?? this.label,
      parentId: parentId ?? this.parentId,
      cnpjCompanyContracted:
      cnpjCompanyContracted ?? this.cnpjCompanyContracted,
      municipios: municipios ?? this.municipios,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      roadId: roadId ?? this.roadId,
      roadName: roadName ?? this.roadName,
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      genericId: genericId ?? this.genericId,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      logoUrl: logoUrl ?? this.logoUrl,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      extra: extra ?? Map<String, dynamic>.from(this.extra),
    );
  }

  @override
  List<Object?> get props => [
    id,
    label,
    parentId,
    cnpjCompanyContracted,
    municipios,
    companyId,
    companyName,
    unitId,
    unitName,
    roadId,
    roadName,
    regionId,
    regionName,
    genericId,
    name,
    cnpj,
    logoUrl,
    logoPath,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    extra,
  ];

  static List<String> moduleName = [
    'DER',
    'DNIT-RO',
    'AM PRECATÓRIOS',
  ];

  static const String defaultModuleLabel = 'DER';
  static String? selectedUF = 'AL';

  static List<String> ufs = const [
    'AC',
    'AL',
    'AM',
    'AP',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MG',
    'MS',
    'MT',
    'PA',
    'PB',
    'PE',
    'PI',
    'PR',
    'RJ',
    'RN',
    'RO',
    'RR',
    'RS',
    'SC',
    'SE',
    'SP',
    'TO'
  ];

  static String? profileKeyForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'profileWork';
      case 'AM PRECATÓRIOS':
        return 'profileLegal';
      case 'DER':
      default:
        return 'profileWork';
    }
  }

  static String flavorForArea(String areaLabel) {
    switch (areaLabel.trim().toUpperCase()) {
      case 'DNIT-RO':
        return 'dnitro';
      case 'AM PRECATÓRIOS':
        return 'amprecatorios';
      case 'DER':
      default:
        return 'der';
    }
  }

  static Gradient gradientForModule(String name) {
    switch (name.toUpperCase()) {
      case 'DNIT-RO':
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'AM PRECATÓRIOS':
        return const LinearGradient(
          colors: [
            Color(0xFF4B0016),
            Color(0xFF800020),
            Color(0xFF955251),
          ],
          stops: [0.0, 0.58, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'DER':
      default:
        return const LinearGradient(
          colors: [
            Color.fromARGB(255, 27, 32, 51),
            Color.fromARGB(255, 144, 202, 249),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}