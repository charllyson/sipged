// lib/_blocs/system/tenant/tenant_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

DateTime? _dateFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

Timestamp? _dateToFirestore(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value);
}

String? _cleanString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

List<String> _stringListFromDynamic(dynamic value) {
  if (value == null) return const <String>[];

  if (value is List) {
    final list = value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  if (value is String) {
    final list = value
        .split(RegExp(r'[\n,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  return const <String>[];
}

List<String> _cleanList(List<String> values) {
  final list = values
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

class TenantData extends Equatable {
  final String id;
  final String label;

  final String? tenantId;
  final String? companyId;
  final String? companyName;
  final String? fantasyName;
  final String? cnpj;

  final String? logoUrl;
  final String? logoPath;

  final List<String> units;
  final List<String> roads;
  final List<String> regions;
  final List<String> fundingSources;
  final List<String> programs;
  final List<String> expenseNatures;
  final List<String> companyBodies;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  final Map<String, dynamic> extra;

  const TenantData({
    required this.id,
    required this.label,
    this.tenantId,
    this.companyId,
    this.companyName,
    this.fantasyName,
    this.cnpj,
    this.logoUrl,
    this.logoPath,
    this.units = const <String>[],
    this.roads = const <String>[],
    this.regions = const <String>[],
    this.fundingSources = const <String>[],
    this.programs = const <String>[],
    this.expenseNatures = const <String>[],
    this.companyBodies = const <String>[],
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.extra = const <String, dynamic>{},
  });

  const TenantData.empty()
      : id = '',
        label = '',
        tenantId = null,
        companyId = null,
        companyName = null,
        fantasyName = null,
        cnpj = null,
        logoUrl = null,
        logoPath = null,
        units = const <String>[],
        roads = const <String>[],
        regions = const <String>[],
        fundingSources = const <String>[],
        programs = const <String>[],
        expenseNatures = const <String>[],
        companyBodies = const <String>[],
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        extra = const <String, dynamic>{};

  factory TenantData.fromMap({
    required String id,
    required Map<String, dynamic>? map,
  }) {
    if (map == null) return const TenantData.empty();

    final raw = Map<String, dynamic>.from(map);

    final tenantId = _cleanString(raw.remove('tenantId'));
    final companyId = _cleanString(raw.remove('companyId'));
    final companyName = _cleanString(raw.remove('companyName'));
    final fantasyName = _cleanString(raw.remove('fantasyName'));
    final cnpj = _cleanString(raw.remove('cnpj'));

    final logoUrl = _cleanString(
      raw.remove('logoUrl') ?? raw.remove('logoURL'),
    );
    final logoPath = _cleanString(raw.remove('logoPath'));

    final units = _stringListFromDynamic(raw.remove('units'));
    final roads = _stringListFromDynamic(raw.remove('roads'));
    final regions = _stringListFromDynamic(raw.remove('regions'));
    final fundingSources = _stringListFromDynamic(
      raw.remove('fundingSources') ?? raw.remove('funding_sources'),
    );
    final programs = _stringListFromDynamic(raw.remove('programs'));
    final expenseNatures = _stringListFromDynamic(
      raw.remove('expenseNatures') ?? raw.remove('expense_natures'),
    );
    final companyBodies = _stringListFromDynamic(
      raw.remove('companyBodies') ??
          raw.remove('company_bodies') ??
          raw.remove('partners'),
    );

    final createdAt = _dateFromFirestore(raw.remove('createdAt'));
    final updatedAt = _dateFromFirestore(raw.remove('updatedAt'));

    final createdBy = _cleanString(raw.remove('createdBy'));
    final updatedBy = _cleanString(raw.remove('updatedBy'));

    final effectiveTenantId = tenantId ?? id;
    final effectiveCompanyId = companyId ?? effectiveTenantId;

    final label = (_cleanString(raw.remove('label')) ??
        companyName ??
        fantasyName ??
        _cleanString(raw.remove('name')) ??
        id)
        .trim();

    raw.remove('id');

    return TenantData(
      id: id,
      label: label,
      tenantId: effectiveTenantId,
      companyId: effectiveCompanyId,
      companyName: companyName,
      fantasyName: fantasyName,
      cnpj: cnpj,
      logoUrl: logoUrl,
      logoPath: logoPath,
      units: units,
      roads: roads,
      regions: regions,
      fundingSources: fundingSources,
      programs: programs,
      expenseNatures: expenseNatures,
      companyBodies: companyBodies,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      extra: raw,
    );
  }

  factory TenantData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    return TenantData.fromMap(
      id: doc.id,
      map: doc.data(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'label': label.trim(),
      if (tenantId != null) 'tenantId': tenantId,
      if (companyId != null) 'companyId': companyId,
      if (companyName != null) 'companyName': companyName,
      if (fantasyName != null) 'fantasyName': fantasyName,
      if (cnpj != null) 'cnpj': cnpj,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (logoPath != null) 'logoPath': logoPath,
      'units': _cleanList(units),
      'roads': _cleanList(roads),
      'regions': _cleanList(regions),
      'fundingSources': _cleanList(fundingSources),
      'programs': _cleanList(programs),
      'expenseNatures': _cleanList(expenseNatures),
      'companyBodies': _cleanList(companyBodies),
      if (createdAt != null) 'createdAt': _dateToFirestore(createdAt),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': _dateToFirestore(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };

    map.addAll(extra);

    return map;
  }

  TenantData copyWith({
    String? id,
    String? label,
    String? tenantId,
    String? companyId,
    String? companyName,
    String? fantasyName,
    String? cnpj,
    String? logoUrl,
    String? logoPath,
    List<String>? units,
    List<String>? roads,
    List<String>? regions,
    List<String>? fundingSources,
    List<String>? programs,
    List<String>? expenseNatures,
    List<String>? companyBodies,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? extra,
  }) {
    return TenantData(
      id: id ?? this.id,
      label: label ?? this.label,
      tenantId: tenantId ?? this.tenantId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      fantasyName: fantasyName ?? this.fantasyName,
      cnpj: cnpj ?? this.cnpj,
      logoUrl: logoUrl ?? this.logoUrl,
      logoPath: logoPath ?? this.logoPath,
      units: units ?? this.units,
      roads: roads ?? this.roads,
      regions: regions ?? this.regions,
      fundingSources: fundingSources ?? this.fundingSources,
      programs: programs ?? this.programs,
      expenseNatures: expenseNatures ?? this.expenseNatures,
      companyBodies: companyBodies ?? this.companyBodies,
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
    tenantId,
    companyId,
    companyName,
    fantasyName,
    cnpj,
    logoUrl,
    logoPath,
    units,
    roads,
    regions,
    fundingSources,
    programs,
    expenseNatures,
    companyBodies,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    extra,
  ];
}