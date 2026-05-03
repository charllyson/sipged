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

class TenantData extends Equatable {
  static const String collectionName = 'tenants';

  final String id;
  final String label;

  final String? tenantId;
  final String? companyId;
  final String? companyName;
  final String? fantasyName;
  final String? cnpj;

  final String? logoUrl;
  final String? logoPath;

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
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.extra = const {},
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
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        extra = const {};

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
      if (tenantId != null) 'tenantId': tenantId,
      if (companyId != null) 'companyId': companyId,
      if (companyName != null) 'companyName': companyName,
      if (fantasyName != null) 'fantasyName': fantasyName,
      if (cnpj != null) 'cnpj': cnpj,
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
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    extra,
  ];
}

class TenantItemData extends Equatable {
  final String id;
  final String label;
  final String? tenantId;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  final Map<String, dynamic> extra;

  const TenantItemData({
    required this.id,
    required this.label,
    this.tenantId,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.extra = const {},
  });

  const TenantItemData.empty()
      : id = '',
        label = '',
        tenantId = null,
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        extra = const {};

  factory TenantItemData.fromMap({
    required String id,
    required Map<String, dynamic>? map,
    String? forcedTenantId,
  }) {
    if (map == null) return const TenantItemData.empty();

    final raw = Map<String, dynamic>.from(map);

    final tenantId = forcedTenantId ?? _cleanString(raw.remove('tenantId'));

    final createdAt = _dateFromFirestore(raw.remove('createdAt'));
    final updatedAt = _dateFromFirestore(raw.remove('updatedAt'));

    final createdBy = _cleanString(raw.remove('createdBy'));
    final updatedBy = _cleanString(raw.remove('updatedBy'));

    final label = (_cleanString(raw.remove('label')) ??
        _cleanString(raw.remove('name')) ??
        _cleanString(raw.remove('unitName')) ??
        _cleanString(raw.remove('roadName')) ??
        _cleanString(raw.remove('regionName')) ??
        _cleanString(raw.remove('companyName')) ??
        _cleanString(raw.remove('fantasyName')) ??
        _cleanString(raw.remove('acronym')) ??
        _cleanString(raw.remove('sigla')) ??
        id)
        .trim();

    raw.remove('id');
    raw.remove('unitId');
    raw.remove('roadId');
    raw.remove('regionId');
    raw.remove('companyId');
    raw.remove('partnerId');
    raw.remove('fundingSourceId');
    raw.remove('programId');
    raw.remove('expenseNatureId');

    return TenantItemData(
      id: id,
      label: label,
      tenantId: tenantId,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      extra: raw,
    );
  }

  factory TenantItemData.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        String? forcedTenantId,
      }) {
    return TenantItemData.fromMap(
      id: doc.id,
      map: doc.data(),
      forcedTenantId: forcedTenantId,
    );
  }

  String? get cnpj {
    final value = extra['cnpj']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get acronym {
    final value = extra['acronym']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> get municipios {
    final value = extra['municipios'];

    if (value is! List) return const <String>[];

    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'label': label.trim(),
      if (tenantId != null) 'tenantId': tenantId,
      if (createdAt != null) 'createdAt': _dateToFirestore(createdAt),
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': _dateToFirestore(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };

    map.addAll(extra);

    return map;
  }

  TenantItemData copyWith({
    String? id,
    String? label,
    String? tenantId,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? extra,
  }) {
    return TenantItemData(
      id: id ?? this.id,
      label: label ?? this.label,
      tenantId: tenantId ?? this.tenantId,
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
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    extra,
  ];
}