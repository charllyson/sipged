// lib/_blocs/system/user/user_data.dart

import 'package:flutter/material.dart';

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

  if (value is Map) {
    final list = value.entries
        .where((entry) {
      final raw = entry.value;

      if (raw is Map) {
        final enabled = raw['enabled'];
        final active = raw['active'];
        final allowed = raw['allowed'];

        if (enabled == false || active == false || allowed == false) {
          return false;
        }
      }

      return raw == true || raw != null;
    })
        .map((entry) => entry.key.toString().trim())
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

List<String> _cleanStringList(Iterable<String> values) {
  final list = values
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

class UserData {
  const UserData({
    this.uid,
    this.name,
    this.surname,
    this.cpf,
    this.email,
    this.password,
    this.gender,
    this.urlPhoto,
    this.cellPhone,
    this.baseRole,
    this.baseProfile,
    this.createUser,
    this.dateToBirthday,
    this.themeDark,
    this.geoPoint,
    this.profileWork = false,
    this.profileLegal = false,
    this.isActive = true,
    this.isBlocked = false,
    this.isDeleted = false,
    this.deactivatedAt,
    this.blockedAt,
    this.deletedAt,
    this.deactivatedReason,
    this.blockedReason,
    this.deletedReason,
    this.tenantIds = const <String>[],
    this.primaryTenantId,
    this.activeTenantId,
    this.rawData = const <String, dynamic>{},
  });

  final String? uid;
  final String? name;
  final String? surname;
  final String? cpf;
  final String? email;
  final String? password;
  final String? gender;

  final String? urlPhoto;
  final String? cellPhone;

  final String? baseRole;
  final String? baseProfile;

  final DateTime? createUser;
  final DateTime? dateToBirthday;

  final bool? themeDark;

  /// Mantido como Object para não acoplar o modelo a GeoPoint/Firebase.
  /// No SIPGED, o user_firebase.dart pode salvar e carregar GeoPoint aqui.
  final Object? geoPoint;

  final bool? profileWork;
  final bool? profileLegal;

  final bool? isActive;
  final bool? isBlocked;
  final bool? isDeleted;

  final DateTime? deactivatedAt;
  final DateTime? blockedAt;
  final DateTime? deletedAt;

  final String? deactivatedReason;
  final String? blockedReason;
  final String? deletedReason;

  final List<String> tenantIds;

  final String? primaryTenantId;
  final String? activeTenantId;

  /// Substitui o antigo userSnap.data().
  /// Mantém dados extras vindos do banco sem acoplar o Data ao Firestore.
  final Map<String, dynamic> rawData;

  bool get isDeletedStatus => isDeleted == true;

  bool get isBlockedStatus => isBlocked == true && isDeleted != true;

  bool get isInactiveStatus {
    return isActive == false && isBlocked != true && isDeleted != true;
  }

  bool get hasStatusRestriction {
    return isInactiveStatus || isBlockedStatus || isDeletedStatus;
  }

  bool get hasAnyTenantAccess => tenantIds.isNotEmpty;

  bool get hasValidUid => (uid ?? '').trim().isNotEmpty;

  String get fullName {
    final n = (name ?? '').trim();
    final s = (surname ?? '').trim();

    return [n, s].where((e) => e.isNotEmpty).join(' ').trim();
  }

  bool hasTenantAccess(String? tenantId) {
    final clean = tenantId?.trim();

    if (clean == null || clean.isEmpty) return false;

    return tenantIds.any(
          (id) => id.trim().toLowerCase() == clean.toLowerCase(),
    );
  }

  String? get effectiveTenantId {
    final active = activeTenantId?.trim();

    if (active != null && active.isNotEmpty && hasTenantAccess(active)) {
      return active;
    }

    final primary = primaryTenantId?.trim();

    if (primary != null && primary.isNotEmpty && hasTenantAccess(primary)) {
      return primary;
    }

    if (tenantIds.isNotEmpty) {
      return tenantIds.first;
    }

    return null;
  }

  String get statusLabel {
    if (isDeletedStatus) return 'APAGADO';
    if (isBlockedStatus) return 'BLOQUEADO';
    if (isInactiveStatus) return 'INATIVO';
    return 'ATIVO';
  }

  IconData get statusIcon {
    if (isDeletedStatus) return Icons.delete_forever_rounded;
    if (isBlockedStatus) return Icons.block_rounded;
    if (isInactiveStatus) return Icons.person_off_rounded;
    return Icons.check_circle_rounded;
  }

  Color get statusColor {
    if (isDeletedStatus) return const Color(0xFF991B1B);
    if (isBlockedStatus) return const Color(0xFFDC2626);
    if (isInactiveStatus) return const Color(0xFF667085);
    return const Color(0xFF2563EB);
  }

  Color get statusLightColor {
    if (isDeletedStatus) return const Color(0xFFFEE2E2);
    if (isBlockedStatus) return const Color(0xFFFEE2E2);
    if (isInactiveStatus) return const Color(0xFFF2F4F7);
    return const Color(0xFFEFF6FF);
  }

  Color get statusBorderColor {
    if (isDeletedStatus) return const Color(0xFFFCA5A5);
    if (isBlockedStatus) return const Color(0xFFFCA5A5);
    if (isInactiveStatus) return const Color(0xFFD0D5DD);
    return const Color(0xFFBFDBFE);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      ...rawData,
      'name': name,
      'surname': surname,
      'email': email,
      'cpf': cpf,
      'password': password,
      'gender': gender,
      'photo': urlPhoto,
      'photoUrl': urlPhoto,
      'photoURL': urlPhoto,
      'profilePhotoUrl': urlPhoto,
      'cellPhone': cellPhone,
      'themeDark': themeDark ?? false,
      'geoPoint': geoPoint,
      'dateToBirthday': dateToBirthday,
      'createUser': createUser,
      'baseRole': baseRole,
      'baseProfile': baseProfile,
      'profileWork': profileWork ?? false,
      'profileLegal': profileLegal ?? false,
      'isActive': isActive ?? true,
      'isBlocked': isBlocked ?? false,
      'isDeleted': isDeleted ?? false,
      'deactivatedAt': deactivatedAt,
      'blockedAt': blockedAt,
      'deletedAt': deletedAt,
      'deactivatedReason': deactivatedReason,
      'blockedReason': blockedReason,
      'deletedReason': deletedReason,
      'tenantIds': _cleanStringList(tenantIds),
      'primaryTenantId': primaryTenantId,
      'activeTenantId': activeTenantId,
    };
  }

  UserData copyWith({
    String? uid,
    String? name,
    String? surname,
    String? cpf,
    String? email,
    String? password,
    String? gender,
    String? urlPhoto,
    String? cellPhone,
    DateTime? createUser,
    DateTime? dateToBirthday,
    bool? themeDark,
    Object? geoPoint,
    String? baseRole,
    String? baseProfile,
    bool? profileWork,
    bool? profileLegal,
    bool? isActive,
    bool? isBlocked,
    bool? isDeleted,
    DateTime? deactivatedAt,
    DateTime? blockedAt,
    DateTime? deletedAt,
    String? deactivatedReason,
    String? blockedReason,
    String? deletedReason,
    List<String>? tenantIds,
    String? primaryTenantId,
    String? activeTenantId,
    Map<String, dynamic>? rawData,
    bool clearPrimaryTenantId = false,
    bool clearActiveTenantId = false,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      urlPhoto: urlPhoto ?? this.urlPhoto,
      cellPhone: cellPhone ?? this.cellPhone,
      createUser: createUser ?? this.createUser,
      dateToBirthday: dateToBirthday ?? this.dateToBirthday,
      themeDark: themeDark ?? this.themeDark,
      geoPoint: geoPoint ?? this.geoPoint,
      baseRole: baseRole ?? this.baseRole,
      baseProfile: baseProfile ?? this.baseProfile,
      profileWork: profileWork ?? this.profileWork,
      profileLegal: profileLegal ?? this.profileLegal,
      isActive: isActive ?? this.isActive,
      isBlocked: isBlocked ?? this.isBlocked,
      isDeleted: isDeleted ?? this.isDeleted,
      deactivatedAt: deactivatedAt ?? this.deactivatedAt,
      blockedAt: blockedAt ?? this.blockedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deactivatedReason: deactivatedReason ?? this.deactivatedReason,
      blockedReason: blockedReason ?? this.blockedReason,
      deletedReason: deletedReason ?? this.deletedReason,
      tenantIds: tenantIds ?? this.tenantIds,
      primaryTenantId:
      clearPrimaryTenantId ? null : primaryTenantId ?? this.primaryTenantId,
      activeTenantId:
      clearActiveTenantId ? null : activeTenantId ?? this.activeTenantId,
      rawData: rawData ?? this.rawData,
    );
  }

  UserData copyDetached() {
    return copyWith(
      rawData: Map<String, dynamic>.from(rawData),
      tenantIds: List<String>.from(tenantIds),
    );
  }

  static UserData empty() {
    return const UserData(
      uid: null,
      name: '',
      surname: '',
      cpf: '',
      email: '',
      password: null,
      gender: null,
      urlPhoto: null,
      cellPhone: '',
      createUser: null,
      dateToBirthday: null,
      themeDark: false,
      geoPoint: null,
      baseRole: null,
      baseProfile: null,
      profileWork: false,
      profileLegal: false,
      isActive: true,
      isBlocked: false,
      isDeleted: false,
      tenantIds: <String>[],
      primaryTenantId: null,
      activeTenantId: null,
      rawData: <String, dynamic>{},
    );
  }

  static List<String> tenantIdsFromRawData(Map<String, dynamic> data) {
    final ids = <String>[
      ..._stringListFromDynamic(data['tenantIds']),
      ..._stringListFromDynamic(data['allowedTenantIds']),
      ..._stringListFromDynamic(data['accessibleTenantIds']),
      ..._stringListFromDynamic(data['companyIds']),
      ..._stringListFromDynamic(data['allowedCompanyIds']),
      ..._stringListFromDynamic(data['accessibleCompanyIds']),
      ..._stringListFromDynamic(data['tenantAccess']),
      ..._stringListFromDynamic(data['tenantsAccess']),
      ..._stringListFromDynamic(data['companyAccess']),
      ..._stringListFromDynamic(data['companiesAccess']),
      ..._stringListFromDynamic(data['tenantRoles']),
      ..._stringListFromDynamic(data['tenantModuleOverrides']),
      ..._stringListFromDynamic(data['tenants']),
      ..._stringListFromDynamic(data['companies']),
      ..._stringListFromDynamic(data['allowedTenants']),
    ];

    return _cleanStringList(ids);
  }
}