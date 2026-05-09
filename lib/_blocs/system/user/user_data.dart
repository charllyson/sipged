import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';

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
        .where((entry) => entry.value == true || entry.value != null)
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

class UserData extends ChangeNotifier {
  String? uid;
  String? name;
  String? surname;
  String? cpf;
  String? email;
  String? password;
  String? gender;

  String? urlPhoto;
  XFile? filePhoto;

  String? cellPhone;

  String? baseRole;
  String? baseProfile;

  DateTime? createUser;
  DateTime? dateToBirthday;

  bool? themeDark;
  GeoPoint? geoPoint;

  DocumentSnapshot<Map<String, dynamic>>? userSnap;

  bool? profileWork;
  bool? profileLegal;

  bool? isActive;
  bool? isBlocked;
  bool? isDeleted;

  DateTime? deactivatedAt;
  DateTime? blockedAt;
  DateTime? deletedAt;

  String? deactivatedReason;
  String? blockedReason;
  String? deletedReason;

  /// Empresas/tenants que o usuário pode acessar.
  final List<String> tenantIds;

  /// Empresa padrão do usuário.
  final String? primaryTenantId;

  /// Última empresa selecionada pelo usuário.
  final String? activeTenantId;

  UserData({
    this.uid,
    this.name,
    this.surname,
    this.cpf,
    this.email,
    this.password,
    this.gender,
    this.urlPhoto,
    this.filePhoto,
    this.cellPhone,
    this.createUser,
    this.dateToBirthday,
    this.themeDark,
    this.geoPoint,
    this.userSnap,
    this.baseRole,
    this.baseProfile,
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
  });

  bool get isDeletedStatus => isDeleted == true;

  bool get isBlockedStatus => isBlocked == true && isDeleted != true;

  bool get isInactiveStatus {
    return isActive == false && isBlocked != true && isDeleted != true;
  }

  bool get hasStatusRestriction {
    return isInactiveStatus || isBlockedStatus || isDeletedStatus;
  }

  bool get hasAnyTenantAccess => tenantIds.isNotEmpty;

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

  static BgPalette paletteForUser(UserData? user) {
    return const BgPalette(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF7FBFF),
          Color(0xFFE3F2FD),
        ],
      ),
    );
  }

  factory UserData.fromDocument({
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
  }) {
    if (!snapshot.exists) {
      throw Exception('Documento do usuário não encontrado');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Dados do usuário estão vazios');
    }

    final tenantIds = _stringListFromDynamic(
      data['tenantIds'] ??
          data['tenants'] ??
          data['companies'] ??
          data['companyIds'] ??
          data['allowedTenants'],
    );

    return UserData(
      uid: snapshot.id,
      name: data['name'] as String?,
      surname: data['surname'] as String?,
      cpf: data['cpf'] as String?,
      email: data['email'] as String?,
      password: data['password'] as String?,
      gender: data['gender'] as String?,
      urlPhoto: (data['photo'] ??
          data['photoUrl'] ??
          data['photoURL'] ??
          data['profilePhotoUrl']) as String?,
      cellPhone: data['cellPhone'] as String?,
      themeDark: data['themeDark'] as bool? ?? false,
      dateToBirthday: (data['dateToBirthday'] as Timestamp?)?.toDate(),
      createUser: (data['createUser'] as Timestamp?)?.toDate(),
      geoPoint: data['geoPoint'] as GeoPoint?,
      baseRole: data['baseRole'] as String?,
      baseProfile: data['baseProfile'] as String?,
      userSnap: snapshot,
      profileWork: data['profileWork'] as bool? ?? false,
      profileLegal: data['profileLegal'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      isBlocked: data['isBlocked'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deactivatedAt: (data['deactivatedAt'] as Timestamp?)?.toDate(),
      blockedAt: (data['blockedAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deactivatedReason: data['deactivatedReason'] as String?,
      blockedReason: data['blockedReason'] as String?,
      deletedReason: data['deletedReason'] as String?,
      tenantIds: tenantIds,
      primaryTenantId: data['primaryTenantId']?.toString().trim(),
      activeTenantId: data['activeTenantId']?.toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
      'dateToBirthday':
      dateToBirthday != null ? Timestamp.fromDate(dateToBirthday!) : null,
      'createUser':
      createUser != null ? Timestamp.fromDate(createUser!) : Timestamp.now(),
      'lastSignIn': Timestamp.now(),
      'baseRole': baseRole,
      'baseProfile': baseProfile,
      'profileWork': profileWork ?? false,
      'profileLegal': profileLegal ?? false,
      'isActive': isActive ?? true,
      'isBlocked': isBlocked ?? false,
      'isDeleted': isDeleted ?? false,
      'deactivatedAt':
      deactivatedAt != null ? Timestamp.fromDate(deactivatedAt!) : null,
      'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deactivatedReason': deactivatedReason,
      'blockedReason': blockedReason,
      'deletedReason': deletedReason,
      'tenantIds': _cleanStringList(tenantIds),
      'primaryTenantId': primaryTenantId,
      'activeTenantId': activeTenantId,
    };
  }

  UserData copyDetached() {
    return UserData(
      uid: uid,
      name: name,
      surname: surname,
      cpf: cpf,
      email: email,
      password: password,
      gender: gender,
      urlPhoto: urlPhoto,
      filePhoto: filePhoto,
      cellPhone: cellPhone,
      createUser: createUser,
      dateToBirthday: dateToBirthday,
      themeDark: themeDark,
      geoPoint: geoPoint,
      userSnap: userSnap,
      baseRole: baseRole,
      baseProfile: baseProfile,
      profileWork: profileWork,
      profileLegal: profileLegal,
      isActive: isActive,
      isBlocked: isBlocked,
      isDeleted: isDeleted,
      deactivatedAt: deactivatedAt,
      blockedAt: blockedAt,
      deletedAt: deletedAt,
      deactivatedReason: deactivatedReason,
      blockedReason: blockedReason,
      deletedReason: deletedReason,
      tenantIds: tenantIds,
      primaryTenantId: primaryTenantId,
      activeTenantId: activeTenantId,
    );
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
    XFile? filePhoto,
    String? cellPhone,
    DateTime? createUser,
    DateTime? dateToBirthday,
    bool? themeDark,
    GeoPoint? geoPoint,
    DocumentSnapshot<Map<String, dynamic>>? userSnap,
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
      filePhoto: filePhoto ?? this.filePhoto,
      cellPhone: cellPhone ?? this.cellPhone,
      createUser: createUser ?? this.createUser,
      dateToBirthday: dateToBirthday ?? this.dateToBirthday,
      themeDark: themeDark ?? this.themeDark,
      geoPoint: geoPoint ?? this.geoPoint,
      userSnap: userSnap ?? this.userSnap,
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
      primaryTenantId: primaryTenantId ?? this.primaryTenantId,
      activeTenantId: activeTenantId ?? this.activeTenantId,
    );
  }

  void update({
    String? name,
    String? surname,
    String? cpf,
    String? email,
    String? gender,
    String? urlPhoto,
    XFile? filePhoto,
    String? cellPhone,
    bool? themeDark,
    GeoPoint? geoPoint,
    DateTime? dateToBirthday,
    String? baseRole,
    String? baseProfile,
    bool? profileWork,
    bool? profileLegal,
    bool? isActive,
    bool? isBlocked,
    bool? isDeleted,
    List<String>? tenantIds,
    String? primaryTenantId,
    String? activeTenantId,
  }) {
    this.name = name ?? this.name;
    this.surname = surname ?? this.surname;
    this.cpf = cpf ?? this.cpf;
    this.email = email ?? this.email;
    this.gender = gender ?? this.gender;
    this.urlPhoto = urlPhoto ?? this.urlPhoto;
    this.filePhoto = filePhoto ?? this.filePhoto;
    this.cellPhone = cellPhone ?? this.cellPhone;
    this.themeDark = themeDark ?? this.themeDark;
    this.geoPoint = geoPoint ?? this.geoPoint;
    this.dateToBirthday = dateToBirthday ?? this.dateToBirthday;
    this.baseRole = baseRole ?? this.baseRole;
    this.baseProfile = baseProfile ?? this.baseProfile;
    this.profileWork = profileWork ?? this.profileWork;
    this.profileLegal = profileLegal ?? this.profileLegal;
    this.isActive = isActive ?? this.isActive;
    this.isBlocked = isBlocked ?? this.isBlocked;
    this.isDeleted = isDeleted ?? this.isDeleted;

    notifyListeners();
  }

  static UserData empty() {
    return UserData(
      uid: null,
      name: '',
      surname: '',
      cpf: '',
      email: '',
      password: null,
      gender: null,
      urlPhoto: null,
      filePhoto: null,
      cellPhone: '',
      createUser: null,
      dateToBirthday: null,
      themeDark: false,
      geoPoint: null,
      userSnap: null,
      baseRole: null,
      baseProfile: null,
      profileWork: false,
      profileLegal: false,
      isActive: true,
      isBlocked: false,
      isDeleted: false,
      tenantIds: const <String>[],
      primaryTenantId: null,
      activeTenantId: null,
    );
  }

  String get fullName {
    final n = (name ?? '').trim();
    final s = (surname ?? '').trim();

    return [n, s].where((e) => e.isNotEmpty).join(' ').trim();
  }

  bool get hasValidUid => (uid ?? '').trim().isNotEmpty;
}